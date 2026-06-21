"""School Service (Super Admin) tests.

Covers the school lifecycle the admin portal drives — create/list/get/update,
status + subscription, module toggles — plus the two access rules that bit us in
integration: the schools API is Super-Admin-only, and a school's resources stay
blocked for its Headmaster until the school is activated (the effective-modules
cascade returns nothing for a non-active school).
"""
from uuid import uuid4

from app.core.config import settings
from tests.utils import login

API = settings.API_V1_PREFIX


async def _create_school(client, sa, **overrides) -> dict:
    payload = {"name": "Acme School", "code": "S-" + uuid4().hex[:8]}
    payload.update(overrides)
    r = await client.post(f"{API}/schools", headers=sa, json=payload)
    assert r.status_code == 201, r.text
    return r.json()


async def test_create_school_defaults_to_pending(client, sa_headers):
    s = await _create_school(client, sa_headers)
    assert s["status"] == "pending"
    assert s["code"]
    assert s["subscription_plan"] is None


async def test_list_and_get_school(client, sa_headers):
    s = await _create_school(client, sa_headers)
    lst = await client.get(f"{API}/schools", headers=sa_headers)
    assert lst.status_code == 200
    assert any(x["id"] == s["id"] for x in lst.json())

    one = await client.get(f"{API}/schools/{s['id']}", headers=sa_headers)
    assert one.status_code == 200 and one.json()["id"] == s["id"]


async def test_get_unknown_school_returns_404(client, sa_headers):
    r = await client.get(f"{API}/schools/{uuid4()}", headers=sa_headers)
    assert r.status_code == 404


async def test_update_school_fields(client, sa_headers):
    s = await _create_school(client, sa_headers)
    r = await client.patch(
        f"{API}/schools/{s['id']}",
        headers=sa_headers,
        json={"name": "Renamed", "contact_email": "x@acme.edu", "address": "1 Main St"},
    )
    assert r.status_code == 200
    body = r.json()
    assert body["name"] == "Renamed"
    assert body["contact_email"] == "x@acme.edu"
    assert body["address"] == "1 Main St"


async def test_set_status_and_assign_subscription(client, sa_headers):
    s = await _create_school(client, sa_headers)

    act = await client.post(
        f"{API}/schools/{s['id']}/status", headers=sa_headers, json={"status": "active"}
    )
    assert act.status_code == 200 and act.json()["status"] == "active"

    sub = await client.post(
        f"{API}/schools/{s['id']}/subscription", headers=sa_headers, json={"plan_code": "premium"}
    )
    assert sub.status_code == 200
    assert sub.json()["subscription_plan"]["code"] == "premium"


async def test_module_toggle_disables_effective_module(client, sa_headers):
    s = await _create_school(client, sa_headers)
    await client.post(
        f"{API}/schools/{s['id']}/subscription", headers=sa_headers, json={"plan_code": "premium"}
    )

    put = await client.put(
        f"{API}/schools/{s['id']}/modules",
        headers=sa_headers,
        json={"toggles": [{"module": "exams", "enabled": False}]},
    )
    assert put.status_code == 200
    assert "exams" not in put.json()["effective_modules"]

    view = await client.get(f"{API}/schools/{s['id']}/modules", headers=sa_headers)
    assert view.status_code == 200
    exams = next(m for m in view.json()["modules"] if m["module"] == "exams")
    assert exams["in_plan"] is True
    assert exams["toggle_enabled"] is False
    assert exams["effective"] is False


async def test_schools_api_is_super_admin_only(client, school):
    """A Headmaster token must not reach the Super-Admin schools API."""
    hm = school["hm"]
    assert (await client.get(f"{API}/schools", headers=hm)).status_code == 403
    created = await client.post(
        f"{API}/schools", headers=hm, json={"name": "Nope", "code": "N-" + uuid4().hex[:6]}
    )
    assert created.status_code == 403


async def test_inactive_school_blocks_headmaster_until_activated(client, sa_headers):
    s = await _create_school(client, sa_headers)
    await client.post(
        f"{API}/schools/{s['id']}/subscription", headers=sa_headers, json={"plan_code": "premium"}
    )
    email = f"head-{uuid4().hex[:8]}@test.edu"
    rh = await client.post(
        f"{API}/schools/{s['id']}/headmaster",
        headers=sa_headers,
        json={"email": email, "password": "HeadPass123", "full_name": "Head"},
    )
    assert rh.status_code == 201
    hm = await login(client, email, "HeadPass123")

    # Pending school → effective modules empty → school resources are forbidden.
    blocked = await client.get(f"{API}/schools/{s['id']}/users", headers=hm)
    assert blocked.status_code == 403

    # After activation the same call succeeds.
    await client.post(
        f"{API}/schools/{s['id']}/status", headers=sa_headers, json={"status": "active"}
    )
    ok = await client.get(f"{API}/schools/{s['id']}/users", headers=hm)
    assert ok.status_code == 200
