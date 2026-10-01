"""Per-plan storage allowance, the upload ledger and orphan clean-up."""
import importlib.util
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest.mock import AsyncMock, patch
from uuid import UUID, uuid4

from alembic.migration import MigrationContext
from alembic.operations import Operations
from sqlalchemy import inspect, select, text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.models.document import StudentDocument
from app.models.upload import StoredUpload
from app.modules.uploads.cleanup import cleanup_unreferenced
from tests.conftest import TEST_URL
from tests.utils import create_user

API = "/api/v1"
MB = 1024 * 1024


async def _upload(client, school):
    return await client.post(
        f"{API}/schools/{school['id']}/uploads", headers=school["hm"], data={"folder": "documents"},
        files={"file": ("note.pdf", b"%PDF-quota", "application/pdf")},
    )


async def _add_ledger_rows(school_id, rows):
    engine = create_async_engine(TEST_URL)
    try:
        async with async_sessionmaker(engine, expire_on_commit=False)() as db, db.begin():
            for row in rows:
                db.add(row if not isinstance(row, dict) else StoredUpload(school_id=UUID(school_id), **row))
    finally:
        await engine.dispose()


async def test_usage_follows_the_school_plan_and_counts_uploads(client, school):
    usage_url = f"{API}/schools/{school['id']}/uploads/usage"
    before = (await client.get(usage_url, headers=school["hm"])).json()
    assert before == {"used_bytes": 0, "quota_bytes": 20480 * MB, "plan_code": "premium"}

    response = await _upload(client, school)
    assert response.status_code == 201, response.text
    after = (await client.get(usage_url, headers=school["hm"])).json()
    assert after["used_bytes"] == response.json()["size"]

    plans = (await client.get(f"{API}/subscription-plans", headers=school["sa"])).json()
    assert {plan["code"]: plan["storage_quota_mb"] for plan in plans} == {
        "basic": 1024, "standard": 5120, "premium": 20480,
    }


async def test_upload_is_refused_once_the_plan_allowance_is_used(client, school):
    await _add_ledger_rows(school["id"], [{
        "storage_key": f"documents/{uuid4().hex}.pdf", "url": "/media/filler.pdf",
        "folder": "documents", "size_bytes": 20480 * MB,
    }])
    with patch("app.modules.uploads.router.get_storage") as storage:
        storage.return_value.save = AsyncMock()
        response = await _upload(client, school)
    assert response.status_code == 413, response.text
    assert response.json()["error"]["code"] == "storage_quota_exceeded"
    storage.return_value.save.assert_not_awaited()


async def test_cleanup_removes_only_old_unreferenced_ledger_uploads(client, school):
    student = await create_user(client, school["id"], school["hm"], "student")
    old = datetime.now(timezone.utc) - timedelta(days=30)
    kept_key, orphan_key, fresh_key = (f"documents/{school['id']}/{uuid4().hex}.pdf" for _ in range(3))
    await _add_ledger_rows(school["id"], [
        {"storage_key": kept_key, "url": f"/media/{kept_key}", "folder": "documents", "size_bytes": 10, "created_at": old},
        {"storage_key": orphan_key, "url": f"/media/{orphan_key}", "folder": "documents", "size_bytes": 20, "created_at": old},
        {"storage_key": fresh_key, "url": f"/media/{fresh_key}", "folder": "documents", "size_bytes": 30},
        StudentDocument(
            school_id=UUID(school["id"]), student_id=UUID(student["id"]), title="Kept",
            file_url=f"https://school.example/media/{kept_key}",
        ),
    ])
    storage = AsyncMock()
    engine = create_async_engine(TEST_URL)
    try:
        sessions = async_sessionmaker(engine, expire_on_commit=False)
        async with sessions() as db, db.begin():
            dry = await cleanup_unreferenced(db, storage, min_age_days=7)
        assert (dry.orphan_count, dry.orphan_bytes, dry.deleted) == (1, 20, False)
        storage.delete.assert_not_awaited()

        async with sessions() as db, db.begin():
            applied = await cleanup_unreferenced(db, storage, min_age_days=7, apply=True)
        assert (applied.orphan_count, applied.deleted) == (1, True)
        storage.delete.assert_awaited_once_with(orphan_key)
        async with sessions() as db:
            remaining = set((await db.execute(
                select(StoredUpload.storage_key).where(StoredUpload.school_id == UUID(school["id"]))
            )).scalars())
        assert remaining == {kept_key, fresh_key}
    finally:
        await engine.dispose()


async def test_storage_quota_migration_round_trips_on_disposable_schema():
    engine = create_async_engine(TEST_URL)
    schema = "storage_quota_" + uuid4().hex
    path = Path(__file__).parents[1] / "alembic/versions/1b2c3d4e5f6a_storage_quota_and_upload_ledger.py"
    spec = importlib.util.spec_from_file_location("storage_quota", path)
    migration = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(migration)

    def exercise(connection) -> None:
        connection.execute(text(f'CREATE SCHEMA "{schema}"'))
        connection.execute(text(f'SET LOCAL search_path TO "{schema}"'))
        connection.execute(text("CREATE TABLE subscription_plans (id UUID PRIMARY KEY, code VARCHAR(20))"))
        connection.execute(text("CREATE TABLE schools (id UUID PRIMARY KEY)"))
        connection.execute(text("CREATE TABLE users (id UUID PRIMARY KEY)"))
        connection.execute(text(
            "INSERT INTO subscription_plans VALUES (gen_random_uuid(), 'basic'), (gen_random_uuid(), 'custom')"
        ))
        migration.op = Operations(MigrationContext.configure(connection))
        migration.upgrade()
        quotas = dict(connection.execute(text("SELECT code, storage_quota_mb FROM subscription_plans")).all())
        assert quotas == {"basic": 1024, "custom": None}
        assert "stored_uploads" in inspect(connection).get_table_names()

        migration.downgrade()
        assert "stored_uploads" not in inspect(connection).get_table_names()
        assert "storage_quota_mb" not in {
            column["name"] for column in inspect(connection).get_columns("subscription_plans")
        }

    try:
        async with engine.connect() as connection:
            transaction = await connection.begin()
            try:
                await connection.run_sync(exercise)
            finally:
                await transaction.rollback()
    finally:
        await engine.dispose()
