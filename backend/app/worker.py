"""Background worker — consumes tasks enqueued via ``app.core.queue``.

Run one (or more) alongside the API:

    arq app.worker.WorkerSettings

Each task opens its **own** database session (the API's request session is not
available here), does the slow work, and commits. Tasks are idempotent-friendly
and safe to retry: `arq` re-runs a job whose function raises, up to ``max_tries``.

Only this process needs `arq` installed; the API and the test suite import
neither this module nor `arq` (see ``app/core/queue.py``).
"""
from __future__ import annotations

import logging
import uuid

from arq import Retry
from arq.connections import RedisSettings

from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.core.errors import configure_logging

logger = logging.getLogger("app.worker")


async def deliver_message(ctx: dict, message_id: str) -> None:
    """Fan a persisted ``Message`` out to its audience via external providers.

    This is the slow work lifted off the ``POST /communication/broadcasts``
    request path: it loops over the resolved audience calling WhatsApp / SMS /
    push / email providers and records a ``MessageDelivery`` per recipient.
    """
    from app.modules.communication.service import CommunicationService

    async with AsyncSessionLocal() as session:
        try:
            delivered = await CommunicationService(session).deliver_by_id(
                uuid.UUID(message_id)
            )
            if delivered is None:
                # The row isn't visible yet: the enqueuing request hadn't
                # committed when we picked the job up. Back off and retry.
                raise Retry(defer=ctx.get("job_try", 1) * 2)
            await session.commit()
        except Retry:
            raise
        except Exception:
            await session.rollback()
            logger.exception("deliver_message failed for message %s", message_id)
            raise


# Name → callable registry (kept alongside `functions` for clarity/testing).
TASKS = {"deliver_message": deliver_message}


async def _startup(ctx: dict) -> None:
    configure_logging()
    logger.info("arq worker started")


class WorkerSettings:
    """Entry point for ``arq app.worker.WorkerSettings``."""

    functions = list(TASKS.values())
    on_startup = _startup
    redis_settings = (
        RedisSettings.from_dsn(settings.REDIS_URL)
        if settings.REDIS_URL
        else RedisSettings()
    )
    max_tries = 5
    # A failed delivery job keeps its result briefly for inspection, then expires.
    keep_result = 3600
