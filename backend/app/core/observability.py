"""Observability: request correlation IDs, access logging, and Prometheus metrics.

Three things wired together here:

* **Correlation ID** — every request gets an id (an inbound ``X-Request-ID`` is
  honoured, else one is generated), stashed in a `ContextVar` so *every* log line
  emitted while handling the request carries it, and echoed back on the response.
  Across multiple API instances behind the load balancer this is what lets one
  logical request be traced through the logs (and forwarded to the worker later).
* **Access log + latency** — one structured line per request with method, route,
  status, and duration.
* **Prometheus metrics** — request counts + latency histogram (labelled by the
  route *template*, not the raw path, to keep cardinality bounded), plus the
  default process collectors (CPU, memory, open FDs). Exposed at ``/metrics``.
"""
from __future__ import annotations

import logging
import time
import uuid
from contextvars import ContextVar

from prometheus_client import (
    CONTENT_TYPE_LATEST,
    CollectorRegistry,
    Counter,
    Histogram,
    generate_latest,
    process_collector,
)
from starlette.requests import Request
from starlette.responses import Response
from starlette.types import ASGIApp, Message, Receive, Scope, Send

logger = logging.getLogger("app.access")

REQUEST_ID_HEADER = "x-request-id"

# Correlation id for the in-flight request; "-" when outside a request (startup,
# worker, etc.). Read by `RequestIdLogFilter` so it lands on every log record.
request_id_ctx: ContextVar[str] = ContextVar("request_id", default="-")


class RequestIdLogFilter(logging.Filter):
    """Attaches the current request id to every log record so the format string
    can include it. Added to the root handler in `configure_logging`."""

    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = request_id_ctx.get()
        return True


# ── Metrics ───────────────────────────────────────────────────────────────────
# A dedicated registry (rather than the global default) keeps test imports
# idempotent and the exposition self-contained.
registry = CollectorRegistry()
registry.register(process_collector.ProcessCollector())

_REQUESTS = Counter(
    "http_requests_total",
    "Total HTTP requests.",
    ["method", "route", "status"],
    registry=registry,
)
_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency (seconds).",
    ["method", "route"],
    registry=registry,
)


def _route_template(scope: Scope, fallback: str) -> str:
    """The matched route's path template (e.g. ``/schools/{school_id}/users``)
    rather than the concrete path, so metric label cardinality stays bounded and
    UUIDs don't explode the series count."""
    route = scope.get("route")
    return getattr(route, "path", None) or fallback


class RequestContextMiddleware:
    """Assigns a correlation id, times the request, records metrics, and writes
    one access-log line. Pure ASGI so it sees the final status and the matched
    route regardless of downstream error handling."""

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        headers = dict(scope.get("headers") or [])
        inbound = headers.get(REQUEST_ID_HEADER.encode())
        request_id = inbound.decode()[:64] if inbound else uuid.uuid4().hex
        token = request_id_ctx.set(request_id)
        start = time.perf_counter()
        status_code = 500

        async def _send(message: Message) -> None:
            nonlocal status_code
            if message["type"] == "http.response.start":
                status_code = message["status"]
                message.setdefault("headers", []).append(
                    (REQUEST_ID_HEADER.encode(), request_id.encode())
                )
            await send(message)

        try:
            await self.app(scope, receive, _send)
        finally:
            duration = time.perf_counter() - start
            method = scope.get("method", "-")
            route = _route_template(scope, scope.get("path", "-"))
            # /metrics scrapes shouldn't inflate their own series or the log.
            if route != "/metrics":
                _REQUESTS.labels(method, route, str(status_code)).inc()
                _LATENCY.labels(method, route).observe(duration)
                logger.info(
                    "%s %s -> %s (%.1fms)",
                    method,
                    scope.get("path", "-"),
                    status_code,
                    duration * 1000,
                )
            request_id_ctx.reset(token)


async def metrics_endpoint(_request: Request) -> Response:
    """Prometheus exposition endpoint."""
    return Response(generate_latest(registry), media_type=CONTENT_TYPE_LATEST)
