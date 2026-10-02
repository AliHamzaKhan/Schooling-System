"""User management and role/permission bounding tests."""
from app.core.config import settings

from tests.utils import create_user, login

API = settings.API_V1_PREFIX


async def test_headmaster_creates_users(client, school):
    sid, hm = school["id"], school["hm"]
    for role in ("teacher", "student", "guardian"):
        u = await create_user(client, sid, hm, role)
        detail = await client.get(f"{API}/schools/{sid}/users/{u['id']}", headers=hm)
        assert detail.status_code == 200
        assert role in [r["code"] for r in detail.json()["roles"]]


async def test_teacher_cannot_create_users(client, school):
    sid, hm = school["id"], school["hm"]
    teacher = await create_user(client, sid, hm, "teacher")
    th = await login(client, teacher["email"], teacher["password"])
    r = await client.post(
        f"{API}/schools/{sid}/users", headers=th,
        json={"email": "x@test.edu", "password": "Passw0rd1", "full_name": "X Y", "role_codes": ["student"]},
    )
    assert r.status_code == 403


async def test_headmaster_creates_custom_role(client, school):
    sid, hm = school["id"], school["hm"]
    r = await client.post(
        f"{API}/schools/{sid}/roles", headers=hm,
        json={"name": "Librarian", "permissions": [{"module": "fee_management", "actions": ["view", "create"]}]},
    )
    assert r.status_code == 201
    assert r.json()["code"] == "librarian"


async def test_role_grant_bounded_by_school_modules(client, sa_headers):
    # On a standard school, granting a premium-only module must fail.
    from uuid import uuid4
    code = "R-" + uuid4().hex[:8]
    sid = (await client.post(f"{API}/schools", headers=sa_headers, json={"name": "School", "code": code})).json()["id"]
    await client.post(f"{API}/schools/{sid}/subscription", headers=sa_headers, json={"plan_code": "standard"})
    await client.post(f"{API}/schools/{sid}/status", headers=sa_headers, json={"status": "active"})
    r = await client.post(
        f"{API}/schools/{sid}/roles", headers=sa_headers,
        json={"name": "Transport Staff", "permissions": [{"module": "transport", "actions": ["view"]}]},
    )
    assert r.status_code == 400


async def test_default_role_cannot_be_deleted(client, school):
    sid, hm = school["id"], school["hm"]
    roles = (await client.get(f"{API}/schools/{sid}/roles", headers=hm)).json()
    teacher_role = next(r["id"] for r in roles if r["code"] == "teacher")
    r = await client.delete(f"{API}/schools/{sid}/roles/{teacher_role}", headers=hm)
    assert r.status_code == 400


async def test_cross_school_user_access_denied(client, school, sa_headers):
    from uuid import uuid4
    other = (await client.post(f"{API}/schools", headers=sa_headers, json={"name": "Other", "code": "O-" + uuid4().hex[:8]})).json()["id"]
    # Headmaster of `school` cannot list users of another school.
    r = await client.get(f"{API}/schools/{other}/users", headers=school["hm"])
    assert r.status_code == 403


async def test_cannot_assign_headmaster_via_users_endpoint(client, school):
    """The Headmaster role must be assigned via /headmaster, not /users."""
    sid, hm = school["id"], school["hm"]
    r = await client.post(
        f"{API}/schools/{sid}/users", headers=hm,
        json={"email": "h2@test.edu", "password": "Passw0rd1", "full_name": "H Two", "role_codes": ["headmaster"]},
    )
    assert r.status_code == 400


async def test_cannot_assign_super_admin_via_users_endpoint(client, school):
    sid, hm = school["id"], school["hm"]
    r = await client.post(
        f"{API}/schools/{sid}/users", headers=hm,
        json={"email": "sa2@test.edu", "password": "Passw0rd1", "full_name": "SA Two", "role_codes": ["super_admin"]},
    )
    assert r.status_code == 400
