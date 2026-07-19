"""Shared async helpers for building test data via the API."""
from uuid import uuid4

from httpx import AsyncClient

from app.core.config import settings

API = settings.API_V1_PREFIX


async def login(client: AsyncClient, email: str, password: str) -> dict[str, str]:
    resp = await client.post(f"{API}/auth/login", data={"username": email, "password": password})
    assert resp.status_code == 200, resp.text
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


async def create_user(
    client: AsyncClient, sid: str, hm: dict, role: str,
    password: str = "Passw0rd1",
    full_name: str | None = None,
    profile_metadata: dict | None = None,
) -> dict:
    email = f"{role}-{uuid4().hex[:8]}@test.edu"
    payload = {
        "email": email,
        "password": password,
        "full_name": full_name or f"{role.title()} User",
        "role_codes": [role],
    }
    if profile_metadata is not None:
        payload["profile_metadata"] = profile_metadata
    r = await client.post(f"{API}/schools/{sid}/users", headers=hm, json=payload)
    assert r.status_code == 201, r.text
    return {"id": r.json()["id"], "email": email, "password": password}


async def make_academics(client: AsyncClient, sid: str, hm: dict) -> dict:
    """Create a class, section, and subject; return their ids."""
    rc = await client.post(f"{API}/schools/{sid}/academic/classes", headers=hm, json={"name": "Grade 1", "level": 1})
    cid = rc.json()["id"]
    rs = await client.post(f"{API}/schools/{sid}/academic/classes/{cid}/sections", headers=hm, json={"name": "A"})
    sec = rs.json()["id"]
    rsub = await client.post(f"{API}/schools/{sid}/academic/subjects", headers=hm, json={"code": "MATH", "name": "Mathematics"})
    subj = rsub.json()["id"]
    return {"class_id": cid, "section_id": sec, "subject_id": subj}


async def enroll(client: AsyncClient, sid: str, hm: dict, section_id: str, student_id: str) -> str:
    r = await client.post(
        f"{API}/schools/{sid}/sections/{section_id}/students", headers=hm, json={"student_id": student_id}
    )
    assert r.status_code == 201, r.text
    return r.json()["id"]
