"""Shared rate limiter.

A single [Limiter] instance is imported by both the app (to register the
exception handler + middleware) and the routers that decorate sensitive
endpoints (e.g. login). Keyed by client IP; defaults to in-memory storage —
point `storage_uri` at Redis for multi-process deployments.
"""
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.core.config import settings

# Disabled under the test environment so the suite (which logs in many times)
# isn't throttled; the rate-limit test re-enables it explicitly.
limiter = Limiter(
    key_func=get_remote_address,
    enabled=settings.ENVIRONMENT.lower() != "test",
)
