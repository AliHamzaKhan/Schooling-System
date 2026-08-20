"""Small Redis cache abstraction (transparent, best-effort).

Used to take repeated, hot, read-mostly lookups off Postgres — most importantly
the per-request tenant/subscription check that runs on *every* school-scoped
endpoint (see ``app/core/deps.enforce_school_context``).

Two design rules keep it safe to sprinkle in:

* **Transparent degradation.** With no ``REDIS_URL`` (dev/tests) — or if Redis
  is unreachable — every operation is a no-op: `get` returns ``None`` so the
  caller falls through to the database, and `set`/`invalidate` quietly do
  nothing. Correctness never depends on the cache being up.
* **Bounded staleness.** Entries carry a short TTL, and the known mutation points
  call [invalidate] explicitly, so a stale read is both rare and short-lived.
"""
from __future__ import annotations

import json
import logging
from typing import Any

from app.core.config import settings

logger = logging.getLogger("app.cache")

_client: Any = None
_unavailable = False  # latch after a connection failure to avoid per-call retries


def _get_client() -> Any:
    global _client, _unavailable
    if _unavailable or not settings.REDIS_URL:
        return None
    if _client is None:
        try:
            import redis.asyncio as aioredis

            _client = aioredis.from_url(settings.REDIS_URL, decode_responses=True)
        except Exception:
            logger.exception("Redis cache unavailable; continuing without cache")
            _unavailable = True
            return None
    return _client


async def get_json(key: str) -> Any | None:
    """Return the cached JSON value for `key`, or ``None`` on miss/no-cache."""
    client = _get_client()
    if client is None:
        return None
    try:
        raw = await client.get(key)
        return json.loads(raw) if raw is not None else None
    except Exception:
        logger.warning("cache get failed for %s", key, exc_info=True)
        return None


async def set_json(key: str, value: Any, ttl: int) -> None:
    """Cache `value` (JSON-serialisable) under `key` for `ttl` seconds."""
    client = _get_client()
    if client is None:
        return
    try:
        await client.set(key, json.dumps(value), ex=ttl)
    except Exception:
        logger.warning("cache set failed for %s", key, exc_info=True)


async def invalidate(*keys: str) -> None:
    """Best-effort delete of one or more keys (called from mutation paths)."""
    client = _get_client()
    if client is None or not keys:
        return
    try:
        await client.delete(*keys)
    except Exception:
        logger.warning("cache invalidate failed for %s", keys, exc_info=True)


async def close() -> None:
    """Release the cache client on shutdown (no-op if never opened)."""
    global _client
    if _client is not None:
        await _client.aclose()
        _client = None


def tenant_status_key(school_id: Any) -> str:
    """Cache key for a school's serviceability status (see enforce_school_context)."""
    return f"tenant:status:{school_id}"
