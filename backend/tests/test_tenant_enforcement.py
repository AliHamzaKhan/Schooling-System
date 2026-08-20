"""Multi-tenant security enforcement tests.

Every school-scoped endpoint is gated by `enforce_school_context`, which enforces
three invariants for non-super-admins: tenant isolation (own school only),
account status (active), and subscription/school status (active + non-expired).
These tests exercise a representative gated endpoint (`/reports/overview`).
"""
from datetime import date
from uuid import uuid4

from app.core.config import settings

API = settings.API_V1_PREFIX


async def _premium_plan_id(client, sa) -> str:
    r = await client.get(f"{API}/subscription-plans", headers=sa)
    assert r.status_code == 200, r.text
    premium = next(p for p in r.json() if p["code"] == "premium")
    return premium["id"]


async def _assign(client, sa, school_id, plan_id, *, start_date=None):
    body = {"school_id": school_id, "plan_id": plan_id}
    if start_date is not None:
        body["start_date"] = start_date
    r = await client.post(f"{API}/subscriptions", headers=sa, json=body)
    assert r.status_code == 201, r.text
    return r.json()


# ─────────────────────────── tenant isolation ─────────────────────────── #


async def test_cross_tenant_access_blocked(client, school):
    """A school's Headmaster cannot read another school's data."""
    r = await client.get(
        f"{API}/schools/{uuid4()}/reports/overview", headers=school["hm"]
    )
    assert r.status_code == 403, r.text
    assert r.json()["error"]["code"] == "tenant_mismatch", r.text


async def test_own_school_allowed(client, school):
    """The grandfathered (legacy plan, active) school still works."""
    r = await client.get(
        f"{API}/schools/{school['id']}/reports/overview", headers=school["hm"]
    )
    assert r.status_code == 200, r.text


# ─────────────────────────── subscription status ──────────────────────── #


async def test_expired_subscription_blocks_with_402(client, sa_headers, school):
    plan_id = await _premium_plan_id(client, sa_headers)
    # Backdated start → end_date is in the past → expired.
    await _assign(client, sa_headers, school["id"], plan_id, start_date="2020-01-01")

    r = await client.get(
        f"{API}/schools/{school['id']}/reports/overview", headers=school["hm"]
    )
    assert r.status_code == 402, r.text
    assert r.json()["error"]["code"] == "subscription_inactive", r.text


async def test_active_subscription_allows(client, sa_headers, school):
    plan_id = await _premium_plan_id(client, sa_headers)
    await _assign(
        client, sa_headers, school["id"], plan_id, start_date=date.today().isoformat()
    )
    r = await client.get(
        f"{API}/schools/{school['id']}/reports/overview", headers=school["hm"]
    )
    assert r.status_code == 200, r.text


async def test_status_endpoint_readable_when_expired(client, sa_headers, school):
    """The subscription-status route stays open when expired so the Headmaster
    can still see the renewal alert."""
    plan_id = await _premium_plan_id(client, sa_headers)
    await _assign(client, sa_headers, school["id"], plan_id, start_date="2020-01-01")
    r = await client.get(
        f"{API}/schools/{school['id']}/subscription/status", headers=school["hm"]
    )
    assert r.status_code == 200, r.text
    assert r.json()["is_expiring_soon"] is True


async def test_super_admin_bypasses_expiry(client, sa_headers, school):
    plan_id = await _premium_plan_id(client, sa_headers)
    await _assign(client, sa_headers, school["id"], plan_id, start_date="2020-01-01")
    # Super Admin is never subject to the tenant/subscription gate.
    r = await client.get(
        f"{API}/schools/{school['id']}/reports/overview", headers=sa_headers
    )
    assert r.status_code != 402, r.text


# ─────────────────────────── school status ────────────────────────────── #


async def test_suspended_school_blocks(client, sa_headers, school):
    await client.post(
        f"{API}/schools/{school['id']}/status",
        headers=sa_headers,
        json={"status": "suspended"},
    )
    r = await client.get(
        f"{API}/schools/{school['id']}/reports/overview", headers=school["hm"]
    )
    assert r.status_code == 403, r.text
    assert r.json()["error"]["code"] == "tenant_disabled", r.text
