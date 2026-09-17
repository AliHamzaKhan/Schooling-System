"""Optional ARQ adapter; committed database outbox rows are the source of truth.

Run ``arq app.worker.WorkerSettings`` or the Redis-independent
``python -m app.delivery_worker``. Duplicate/stale broker jobs cannot bypass
the outbox's claim, attempt and recovery state.
"""
import uuid

from arq import cron
from arq.connections import RedisSettings

from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.core.errors import configure_logging
from app.modules.communication.outbox import OutboxWorker


async def deliver_message(ctx: dict, message_id: str) -> None:
    await OutboxWorker(AsyncSessionLocal).process(uuid.UUID(message_id))


async def poll_outbox(ctx: dict) -> None:
    await OutboxWorker(AsyncSessionLocal).run_due()


async def _startup(ctx: dict) -> None:
    configure_logging()


class WorkerSettings:
    functions = [deliver_message, poll_outbox]
    cron_jobs = [cron(poll_outbox, second={0, 10, 20, 30, 40, 50}, run_at_startup=True)]
    on_startup = _startup
    redis_settings = RedisSettings.from_dsn(settings.REDIS_URL) if settings.REDIS_URL else RedisSettings()
    max_tries = 5
    keep_result = 3600
