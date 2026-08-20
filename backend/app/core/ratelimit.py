"""Centralized, distributed API rate limiting.

A single [Limiter] instance is imported by both the app (to register the
middleware + the 429 handler) and by routers that put a stricter limit on a
sensitive endpoint (e.g. login). It provides two layers of protection:

1. **A global default limit** ([DEFAULT_LIMITS]) applied to *every* endpoint, so
   no route is unprotected — a generous catch-all that only trips on abuse.
2. **Per-endpoint strict limits** for abuse-prone actions, applied with the
   ``@limiter.limit(AUTH_LIMIT)`` / ``SENSITIVE_LIMIT`` decorators.

**Keying.** Authenticated requests are keyed per *user* (from the bearer token's
subject), so one user on a shared/NAT'd IP can't exhaust everyone else's budget,
and a user can't dodge their limit by rotating IPs. Requests without a usable
token fall back to per-IP.

**Distribution.** When ``REDIS_URL`` is set the counters live in Redis, so a
limit is enforced across every worker process and replica behind the load
balancer. Without it the limiter falls back to per-process in-memory counters
(fine for local dev / a single worker); the config layer refuses to boot
production without Redis for exactly this reason.
"""
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from starlette.requests import Request
from starlette.responses import JSONResponse

from app.core.config import settings
from app.core.exceptions import ErrorCode
from app.core.security import ACCESS_TOKEN, JWTError, decode_token

# ── Limit tiers (named + centralized so they're tuned in one place) ────────────
# Generous global catch-all applied to every route. Sized so normal bursty UI
# usage (a dashboard firing a handful of parallel calls) never trips it, while a
# runaway client / scraper does.
DEFAULT_LIMITS = ["300/minute"]
# Credential-checking endpoints (login) — blunts brute-force / stuffing.
AUTH_LIMIT = "10/minute"
# Highest-risk unauthenticated actions: OTP request/verify, password reset,
# registration. Apply with `@limiter.limit(SENSITIVE_LIMIT)` on those endpoints
# as they are added (they don't exist on the backend yet).
SENSITIVE_LIMIT = "5/minute"


def _rate_limit_key(request: Request) -> str:
    """Per-user when a valid access token is present, else per-IP."""
    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        try:
            payload = decode_token(auth[len("Bearer ") :])
            sub = payload.get("sub")
            if payload.get("type") == ACCESS_TOKEN and sub:
                return f"user:{sub}"
        except JWTError:
            pass  # malformed/expired token → fall through to IP keying
    return f"ip:{get_remote_address(request)}"


# Disabled under the test environment so the suite (which logs in many times)
# isn't throttled; the rate-limit test re-enables it explicitly.
limiter = Limiter(
    key_func=_rate_limit_key,
    default_limits=DEFAULT_LIMITS,
    enabled=settings.ENVIRONMENT.lower() != "test",
    storage_uri=settings.REDIS_URL or "memory://",
    headers_enabled=True,  # emit X-RateLimit-* headers on every response
)


def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    """429 in the app's standard envelope (``error.code == "rate_limited"``), with
    ``Retry-After`` + ``X-RateLimit-*`` headers. The code lets the client back off
    without treating it as a session failure (it is deliberately *not* in the
    frontend's session-fatal set, so it never triggers a logout)."""
    response = JSONResponse(
        status_code=429,
        content={
            "detail": "Too many requests. Please slow down and try again shortly.",
            "error": {
                "code": ErrorCode.RATE_LIMITED.value,
                "message": f"Rate limit exceeded: {exc.detail}",
            },
        },
    )
    # Attach Retry-After / X-RateLimit-* exactly as slowapi's own handler does.
    return request.app.state.limiter._inject_headers(
        response, request.state.view_rate_limit
    )
