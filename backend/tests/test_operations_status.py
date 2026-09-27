"""Platform-only, aggregate worker/outbox visibility checks."""
from datetime import timedelta

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core.config import settings
from app.models.communication import WorkerHeartbeat
from app.modules.communication.outbox import now
from app.worker import OUTBOX_WORKER_NAME, record_worker_heartbeat
from tests.conftest import API, TEST_URL


async def _set_heartbeat(last_seen_at):
    engine = create_async_engine(TEST_URL)
    try:
        async with async_sessionmaker(engine, expire_on_commit=False)() as db:
            heartbeat = await db.get(WorkerHeartbeat, OUTBOX_WORKER_NAME)
            if heartbeat is None:
                db.add(
                    WorkerHeartbeat(
                        worker_name=OUTBOX_WORKER_NAME, last_seen_at=last_seen_at
                    )
                )
            else:
                heartbeat.last_seen_at = last_seen_at
            await db.commit()
    finally:
        await engine.dispose()


async def _record_heartbeat():
    engine = create_async_engine(TEST_URL)
    try:
        await record_worker_heartbeat(async_sessionmaker(engine, expire_on_commit=False))
    finally:
        await engine.dispose()


async def test_operations_status_is_platform_only_and_content_free(client, school):
    denied = await client.get(f"{API}/admin/operations", headers=school["hm"])
    assert denied.status_code == 403

    visible = await client.get(f"{API}/admin/operations", headers=school["sa"])
    assert visible.status_code == 200, visible.text
    body = visible.json()
    assert set(body) == {"outbox", "worker", "providers"}
    assert set(body["outbox"]) == {
        "pending", "due", "processing", "expired_leases", "needs_review",
        "oldest_due_at", "oldest_due_age_seconds",
    }
    assert "message" not in str(body).lower()
    assert "recipient" not in str(body).lower()
    assert body["worker"]["status"] == "not_seen"
    assert body["providers"] == {
        "whatsapp": "simulated",
        "sms": "simulated",
        "push": "simulated",
        "email": "simulated",
    }


async def test_operations_status_reports_fresh_and_stale_worker_heartbeats(client, sa_headers):
    await _record_heartbeat()
    fresh = await client.get(f"{API}/admin/operations", headers=sa_headers)
    assert fresh.status_code == 200, fresh.text
    assert fresh.json()["worker"]["status"] == "healthy"

    await _set_heartbeat(
        now() - timedelta(seconds=settings.OUTBOX_WORKER_STALE_AFTER_SECONDS + 1)
    )
    stale = await client.get(f"{API}/admin/operations", headers=sa_headers)
    assert stale.status_code == 200, stale.text
    worker = stale.json()["worker"]
    assert worker["status"] == "stale"
    assert worker["age_seconds"] >= settings.OUTBOX_WORKER_STALE_AFTER_SECONDS
