"""Content-free structured logging contract for production aggregation."""
import json
import logging

from app.core.errors import StructuredJsonFormatter, _safe_route


def test_structured_json_log_has_only_safe_indexed_fields():
    record = logging.LogRecord(
        name="app.access",
        level=logging.WARNING,
        pathname=__file__,
        lineno=1,
        msg="GET /schools/{school_id}/reports -> 503",
        args=(),
        exc_info=None,
    )
    record.request_id = "request-123"

    body = json.loads(StructuredJsonFormatter().format(record))
    assert set(body) == {"timestamp", "level", "logger", "request_id", "message"}
    assert body["request_id"] == "request-123"
    assert body["message"] == "GET /schools/{school_id}/reports -> 503"


def test_safe_route_rejects_unmatched_raw_paths():
    class Route:
        path = "/schools/{school_id}/reports"

    assert _safe_route({"route": Route()}) == "/schools/{school_id}/reports"
    assert _safe_route({"path": "/schools/private-id"}) == "unmatched"
