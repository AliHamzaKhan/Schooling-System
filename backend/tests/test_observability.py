"""Security headers, correlation IDs, readiness probe, and metrics exposition."""
from .conftest import API


async def test_security_headers_present(client):
    r = await client.get("/health")
    assert r.headers.get("x-content-type-options") == "nosniff"
    assert r.headers.get("x-frame-options") == "DENY"
    assert r.headers.get("referrer-policy") == "no-referrer"
    assert "content-security-policy" in r.headers


async def test_correlation_id_generated_and_echoed(client):
    r = await client.get("/health")
    assert r.headers.get("x-request-id")  # generated when none supplied


async def test_correlation_id_honours_inbound(client):
    r = await client.get("/health", headers={"X-Request-ID": "trace-abc-123"})
    assert r.headers.get("x-request-id") == "trace-abc-123"


async def test_readiness_reports_dependency_checks(client):
    r = await client.get("/health/ready")
    # DB is up in tests → ready; Redis is unset → reported as not_configured.
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["status"] == "ready"
    assert body["checks"]["database"] == "ok"
    assert body["checks"]["redis"] == "not_configured"


async def test_metrics_endpoint_exposes_prometheus(client):
    await client.get(f"{API}/auth/login", headers={})  # generate some traffic
    r = await client.get("/metrics")
    assert r.status_code == 200
    assert "http_requests_total" in r.text
