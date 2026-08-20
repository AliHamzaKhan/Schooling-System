"""Background task queue — the API's side of the worker offload.

Slow work that used to run *inside* the HTTP request (notification fan-out to
external providers, etc.) is instead enqueued here and consumed by a separate
worker process (``app/worker.py``) over Redis, using `arq`.

Design notes:

* **Graceful degradation.** [enqueue] returns ``True`` only when the job was
  actually handed to Redis. When ``REDIS_URL`` is unset (local dev / tests) — or
  if Redis is momentarily unreachable — it returns ``False`` and the caller runs
  the work inline on its own request session, so behavior is never lost, only
  offloaded. Callers use the pattern::

      if not await enqueue("deliver_message", str(obj.id), defer=1):
          await self._do_it_inline(obj)

* **The enqueue→commit race.** The API's request session commits at the *end* of
  the request (see ``get_db``), so a freshly-created row isn't visible to the
  worker's separate connection the instant we enqueue. Jobs are enqueued with a
  small ``defer`` and the worker retries if the row isn't visible yet — see
  ``app/worker.py``.

* **No import of ``app.worker`` here.** The inline fallback is the caller's job,
  which keeps this module free of the worker's (arq-importing) code so the API
  and test processes never need `arq` installed.
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
    configured or enqueueing failed — in which case the caller must do the work
    inline so it isn't dropped. ``defer`` delays execution by N seconds, giving
    the enqueuing request time to commit before the worker picks the job up.
    """
    if not settings.REDIS_URL:
        return False
    try:
        pool = await _get_pool()
        kwargs = {"_defer_by": timedelta(seconds=defer)} if defer else {}
        await pool.enqueue_job(task, *args, **kwargs)
        return True
    except Exception:
        # A broker hiccup must not fail (or block) the request — fall back inline.
        logger.exception("Failed to enqueue task %s; caller will run it inline", task)
        return False


async def close_pool() -> None:
    """Close the shared pool on app shutdown (no-op if never opened)."""
    global _pool
    if _pool is not None:
        await _pool.aclose()
        _pool = None
