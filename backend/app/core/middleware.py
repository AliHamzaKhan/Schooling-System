"""Cross-cutting HTTP middleware (security response headers).

Kept separate from the observability middleware so the two concerns — hardening
the response vs. tracing/measuring the request — stay independently testable.
"""
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from app.core.config import settings

# Static hardening headers applied to every response. `Strict-Transport-Security`
# is added separately (only outside dev) since it's meaningful only over HTTPS.
_BASE_HEADERS: list[tuple[bytes, bytes]] = [
    (b"x-content-type-options", b"nosniff"),
    (b"x-frame-options", b"DENY"),
    (b"referrer-policy", b"no-referrer"),
    # Legacy XSS auditor off (modern guidance — CSP is the real control).
    (b"x-xss-protection", b"0"),
    # This is a JSON API; nothing should embed or execute its responses.
    (b"content-security-policy", b"default-src 'none'; frame-ancestors 'none'"),
]

# The interactive API docs (Swagger UI / ReDoc) are HTML that loads scripts,
# styles, and fonts, so the `default-src 'none'` CSP would blank them out. These
# prefixes get the other headers but not the restrictive CSP.
_CSP_EXEMPT_PREFIXES = ("/docs", "/redoc", f"{settings.API_V1_PREFIX}/openapi.json")


class SecurityHeadersMiddleware:
    """Pure-ASGI middleware that injects security headers on every response
    (including error responses, since it wraps the whole app)."""

    def __init__(self, app: ASGIApp) -> None:
        self.app = app
        self._hsts = (
            settings.ENVIRONMENT.lower() not in {"development", "dev", "local", "test"}
        )

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        path = scope.get("path", "")
        csp_exempt = path.startswith(_CSP_EXEMPT_PREFIXES)

        async def _send(message: Message) -> None:
            if message["type"] == "http.response.start":
                headers = message.setdefault("headers", [])
                existing = {k.lower() for k, _ in headers}
                private_communication = (
                    path.startswith(f"{settings.API_V1_PREFIX}/schools/")
                    and ("/communication/" in path or "/messages/" in path or path.endswith("/messages")
                         or "/academic/" in path or "/reports/" in path
                         or "/attendance/" in path or path.endswith("/attendance")
                         or path.endswith("/fees/report")
                         or ("/sections/" in path and path.endswith("/students")))
                )
                if (private_communication or path == f"{settings.API_V1_PREFIX}/file-download" or
                        ("/files/" in path and path.endswith("/ticket"))):
                    # Targeted communication, denials and expired tickets must
                    # not survive authorization changes in an HTTP cache.
                    if b"cache-control" not in existing:
                        headers.append((b"cache-control", b"private, no-store"))
                for key, value in _BASE_HEADERS:
                    if key == b"content-security-policy" and csp_exempt:
                        continue
                    if key not in existing:
                        headers.append((key, value))
                if self._hsts and b"strict-transport-security" not in existing:
                    headers.append(
                        (b"strict-transport-security", b"max-age=63072000; includeSubDomains")
                    )
            await send(message)

        await self.app(scope, receive, _send)
