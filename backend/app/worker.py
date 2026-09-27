"""Optional ARQ adapter; committed database outbox rows are the source of truth.

Run ``arq app.worker.WorkerSettings`` or the Redis-independent
``python -m app.delivery_worker``. Duplicate/stale broker jobs cannot bypass
the outbox's claim, attempt and recovery state.
"""
import uuid

from arq import cron
from arq.connections import RedisSettings
from sqlalchemy.dialects.postgresql import insert

from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.core.errors import configure_logging
from app.models.communication import WorkerHeartbeat
from app.modules.communication.outbox import OutboxWorker

OUTBOX_WORKER_NAME = "notification_outbox"


async def record_worker_heartbeat(sessions=AsyncSessionLocal) -> None:
    """Publish only liveness for the coalesced delivery-worker type."""
    from app.modules.communication.outbox import now

    seen_at = now()
    statement = insert(WorkerHeartbeat).values(
        worker_name=OUTBOX_WORKER_NAME, last_seen_at=seen_at
    ).on_conflict_do_update(
        index_elements=[WorkerHeartbeat.worker_name],
        set_={"last_seen_at": seen_at},
    )
    async with sessions() as db, db.begin():
        await db.execute(statement)


async def deliver_message(ctx: dict, message_id: str) -> None:
    await OutboxWorker(AsyncSessionLocal).process(uuid.UUID(message_id))


async def poll_outbox(ctx: dict) -> None:
    await record_worker_heartbeat()
    await OutboxWorker(AsyncSessionLocal).run_due()
    await record_worker_heartbeat()


async def _startup(ctx: dict) -> None:
    configure_logging()
    await record_worker_heartbeat()


class WorkerSettings:
    functions = [deliver_message, poll_outbox]
    cron_jobs = [cron(poll_outbox, second={0, 10, 20, 30, 40, 50}, run_at_startup=True)]
    on_startup = _startup
    redis_settings = RedisSettings.from_dsn(settings.REDIS_URL) if settings.REDIS_URL else RedisSettings()
    max_tries = 5
    keep_result = 3600
