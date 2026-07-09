"""Shared rate limiter.

A single [Limiter] instance is imported by both the app (to register the
exception handler + middleware) and the routers that decorate sensitive
endpoints (e.g. login). Keyed by client IP.

Storage: when `REDIS_URL` is set the counters live in Redis, so the limit is
enforced across every worker process and replica. Without it the limiter falls
back to per-process in-memory counters (fine for local dev / a single worker,
but the config layer refuses to boot production without Redis for this reason).
"""
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.core.config import settings

# Disabled under the test environment so the suite (which logs in many times)
# isn't throttled; the rate-limit test re-enables it explicitly.
limiter = Limiter(
    key_func=get_remote_address,
    enabled=settings.ENVIRONMENT.lower() != "test",
    storage_uri=settings.REDIS_URL or "memory://",
)
