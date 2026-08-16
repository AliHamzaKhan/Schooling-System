"""Application-wide error handling.

Two problems this module exists to solve:

1. **The client saw a network failure instead of an error response.** An
   exception that no handler claimed used to travel all the way out to
   Starlette's ``ServerErrorMiddleware``, which sits *outside* ``CORSMiddleware``
   and replies with a bare ``500 Internal Server Error`` carrying no CORS
   headers. A browser refuses to hand such a response to the page, so the app
   sees an opaque ``Failed to fetch`` — indistinguishable from the whole server
   being down, even though it is still serving. :class:`CatchAllErrorMiddleware`
   is installed *inside* the CORS layer, so every error reply travels back out
   through CORS and reaches the client as a readable JSON 500.

2. **The traceback went nowhere useful.** Every failure is logged with the
   request method and path, so a failing endpoint can be found from the logs
   rather than guessed at.

Neither piece changes how deliberate errors behave: ``HTTPException`` (and the
``bad_request`` / ``not_found`` / ``forbidden`` helpers built on it) and request
validation errors are still handled by FastAPI's own inner handlers, which
already return JSON through the CORS layer.
"""
from __future__ import annotations

import logging
import uuid

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError
from starlette.types import ASGIApp, Message, Receive, Scope, Send

logger = logging.getLogger("app.errors")


def _failure_body(error_id: str, detail: str) -> dict[str, str]:
    """The shape every unexpected failure returns.

    ``error_id`` is echoed to the client and printed alongside the traceback, so
    a user's screenshot can be matched to a specific log line without asking
    them to reproduce it.
    """
    return {"detail": detail, "error_id": error_id}


class CatchAllErrorMiddleware:
    """Turns any unhandled exception into a JSON 500 instead of letting it
    escape the middleware stack.

    Pure ASGI (rather than ``BaseHTTPMiddleware``) so it can tell whether the
    response has already begun: once bytes are on the wire there is no way to
    replace them with an error body, and the exception must be re-raised for the
    server to log and close the connection.
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        response_started = False

        async def _send(message: Message) -> None:
            nonlocal response_started
            if message["type"] == "http.response.start":
                response_started = True
            await send(message)

        try:
            await self.app(scope, receive, _send)
        except Exception:
            error_id = uuid.uuid4().hex[:12]
            logger.exception(
                "Unhandled error [%s] on %s %s",
                error_id,
                scope.get("method", "?"),
                scope.get("path", "?"),
            )
            if response_started:
                # Too late to send an error body — let the server tear the
                # connection down.
                raise
            response = JSONResponse(
                status_code=500,
                content=_failure_body(
                    error_id, "Something went wrong on the server. Please try again."
                ),
            )
            await response(scope, receive, send)


async def _sqlalchemy_error_handler(request: Request, exc: Exception) -> JSONResponse:
    """Database failures (connection dropped, constraint violation, …).

    Registered as a handler rather than left to the catch-all so the client gets
    503 — "try again", the request itself was fine — instead of a flat 500.
    """
    error_id = uuid.uuid4().hex[:12]
    logger.exception(
        "Database error [%s] on %s %s", error_id, request.method, request.url.path
    )
    return JSONResponse(
        status_code=503,
        content=_failure_body(
            error_id, "The service is temporarily unavailable. Please try again."
        ),
    )


def configure_logging() -> None:
    """Give the root logger a handler when the host process hasn't.

    Uvicorn configures only its own loggers, so without this an application
    ``logger.exception`` falls back to Python's last-resort handler and loses
    its timestamp and logger name.
    """
    if not logging.getLogger().handlers:
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s %(levelname)-8s %(name)s: %(message)s",
        )


def install_error_handling(app: FastAPI) -> None:
    """Wire up logging, the DB-error handler, and the catch-all middleware.

    Call this **before** adding CORS (and any other middleware that must see
    error responses): ``add_middleware`` prepends, so the first-added middleware
    ends up innermost.
    """
    configure_logging()
    app.add_exception_handler(SQLAlchemyError, _sqlalchemy_error_handler)
    app.add_middleware(CatchAllErrorMiddleware)
