"""Permission cascade tests: subscription ∩ toggles ∩ role."""
from uuid import uuid4

from app.core.config import settings

API = settings.API_V1_PREFIX


async def _make_school(client, sa, plan):
    code = "P-" + uuid4().hex[:8]
    resp = await client.post(f"{API}/schools", headers=sa, json={"name": "School", "code": code})
    assert resp.status_code == 201, f"{resp.status_code}: {resp.text}"
    sid = resp.json()["id"]
    await client.post(f"{API}/schools/{sid}/subscription", headers=sa, json={"plan_code": plan})
    await client.post(f"{API}/schools/{sid}/status", headers=sa, json={"status": "active"})
    return sid


async def test_super_admin_has_all_modules(client, sa_headers):
    r = await client.get(f"{API}/permissions/me", headers=sa_headers)
    body = r.json()
    assert body["is_super_admin"] is True
    assert len(body["modules"]) >= 20


async def test_standard_plan_excludes_premium_modules(client, sa_headers):
    sid = await _make_school(client, sa_headers, "standard")
    r = await client.get(f"{API}/schools/{sid}/modules", headers=sa_headers)
    effective = set(r.json()["effective_modules"])
    assert "exams" in effective
    assert "library" not in effective  # premium-only
    assert "hr_payroll" not in effective


async def test_disabling_toggle_removes_module(client, sa_headers):
    sid = await _make_school(client, sa_headers, "premium")
    # Disable exams via toggle even though the premium plan includes it.
    r = await client.put(
        f"{API}/schools/{sid}/modules", headers=sa_headers,
        json={"toggles": [{"module": "exams", "enabled": False}]},
    )
    effective = set(r.json()["effective_modules"])
    assert "exams" not in effective
    assert "results" in effective  # untouched


async def test_enabling_out_of_plan_module_stays_unavailable(client, sa_headers):
    sid = await _make_school(client, sa_headers, "standard")
    # Try to enable library (not in standard plan) — must stay unavailable.
    r = await client.put(
        f"{API}/schools/{sid}/modules", headers=sa_headers,
        json={"toggles": [{"module": "library", "enabled": True}]},
    )
    modules = {m["module"]: m for m in r.json()["modules"]}
    assert modules["library"]["in_plan"] is False
    assert modules["library"]["effective"] is False


async def test_headmaster_permissions_bounded_and_present(client, school):
    r = await client.get(f"{API}/permissions/me", headers=school["hm"])
    body = r.json()
    assert body["is_super_admin"] is False
    # Premium school -> headmaster sees all operational modules.
    assert "exams" in body["modules"]
    assert body["matrix"]["exams"]["create"] is True
