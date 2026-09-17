"""Legacy optional broker helper, not used for notification persistence.

Notifications use the transactional database outbox. Never replace an enqueue
failure with inline provider calls: the business transaction may still roll back.
An optional broker hint is not durable notification intent; the DB poller recovers
committed pending work without it.
"""
from __future__ import annotations

import logging
from datetime import timedelta
from typing import Any

from app.core.config import settings

logger = logging.getLogger("app.queue")

# Lazily-created shared arq connection pool. Guarded so the whole app/test suite
# never imports `arq` unless a Redis broker is actually configured and used.
_pool: Any = None


async def _get_pool() -> Any:
    global _pool
    if _pool is None:
        from arq import create_pool
        from arq.connections import RedisSettings

        _pool = await create_pool(RedisSettings.from_dsn(settings.REDIS_URL))
    return _pool


async def enqueue(task: str, *args: Any, defer: float = 0) -> bool:
    """Hand ``task`` (an ``app/worker.py`` function name) to the Redis queue.

    Returns ``True`` when the job was queued, ``False`` when there is no broker
    configured or enqueueing failed. Callers must preserve durable intent before
    calling; ``defer`` is a scheduling hint, not a transaction-commit guarantee.
    """
    if not settings.REDIS_URL:
        return False
    try:
        pool = await _get_pool()
        kwargs = {"_defer_by": timedelta(seconds=defer)} if defer else {}
        await pool.enqueue_job(task, *args, **kwargs)
        return True
    except Exception:
        logger.warning("Broker enqueue unavailable; durable work remains with its owner")
        return False


async def close_pool() -> None:
    """Close the shared pool on app shutdown (no-op if never opened)."""
    global _pool
    if _pool is not None:
        await _pool.aclose()
        _pool = None
