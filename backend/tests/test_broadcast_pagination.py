"""Broadcast history must paginate only after tenant and audience filtering."""
from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.models.communication import Message
from tests.conftest import API, TEST_URL
from tests.test_broadcast_isolation import another_school
from tests.utils import create_user, login


def broadcasts(school_id: str) -> str:
    return f"{API}/schools/{school_id}/communication/broadcasts"


async def test_broadcast_history_is_bounded_after_visibility_and_tenant_scope(client, school):
    """A full local page cannot be displaced by hidden or foreign-school rows."""
    student = await create_user(client, school["id"], school["hm"], "student")
    student_headers = await login(client, student["email"], student["password"])
    other_school_id = await another_school(client, school["sa"])
    local_ids: list[str] = []
    started = datetime(2026, 1, 1, tzinfo=timezone.utc)

    engine = create_async_engine(TEST_URL)
    try:
        async with async_sessionmaker(engine, expire_on_commit=False)() as db, db.begin():
            # These 101 rows are visible to the student.  The sequence gives a
            # stable ordering independent of UUID generation.
            for index in range(101):
                row = Message(
                    school_id=UUID(school["id"]),
                    title=f"Student update {index}",
                    body=f"student-page-{index}",
                    channel="email",
                    audience_type="students",
                    status="pending",
                    created_at=started + timedelta(seconds=index),
                )
                db.add(row)
                await db.flush()
                local_ids.append(str(row.id))
            # These are newer but not visible to the student.  Pagination must
            # be applied after this audience filter, not before it.
            for index in range(4):
                db.add(Message(
                    school_id=UUID(school["id"]),
                    title=f"Teacher-only {index}",
                    body=f"hidden-page-{index}",
                    channel="email",
                    audience_type="teachers",
                    status="pending",
                    created_at=started + timedelta(seconds=200 + index),
                ))
            # Foreign rows are deliberately newer too; the tenant predicate
            # must exclude them before the page window is selected.
            for index in range(4):
                db.add(Message(
                    school_id=UUID(other_school_id),
                    title=f"Foreign {index}",
                    body=f"foreign-page-{index}",
                    channel="email",
                    audience_type="students",
                    status="pending",
                    created_at=started + timedelta(seconds=300 + index),
                ))

        first = await client.get(broadcasts(school["id"]), headers=student_headers, params={"limit": 100})
        second = await client.get(
            broadcasts(school["id"]), headers=student_headers, params={"limit": 100, "offset": 100},
        )
        assert first.status_code == second.status_code == 200
        assert [item["id"] for item in first.json()] == list(reversed(local_ids[1:]))
        assert [item["id"] for item in second.json()] == [local_ids[0]]
        response_text = first.text + second.text
        assert "hidden-page" not in response_text
        assert "foreign-page" not in response_text

        for params in ({"limit": 101}, {"limit": 0}, {"offset": -1}):
            assert (await client.get(broadcasts(school["id"]), headers=student_headers, params=params)).status_code == 422
    finally:
        await engine.dispose()
