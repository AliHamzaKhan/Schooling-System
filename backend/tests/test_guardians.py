"""Guardian ↔ student linkage + per-student access scoping."""
from uuid import uuid4

import pytest
from httpx import AsyncClient

from app.core.config import settings

API = settings.API_V1_PREFIX


async def _login(client: AsyncClient, email: str, password: str) -> dict[str, str]:
    r = await client.post(
        f"{API}/auth/login", data={"username": email, "password": password}
    )
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


async def _make_user(client, school, role: str) -> dict:
    """Create a school user with the given role and return id + auth headers."""
    email = f"{role}-{uuid4().hex[:8]}@test.edu"
    r = await client.post(
        f"{API}/schools/{school['id']}/users",
        headers=school["hm"],
        json={
            "email": email,
            "password": "UserPass123",
            "full_name": f"{role.title()} User",
            "role_codes": [role],
        },
    )
    assert r.status_code == 201, r.text
    return {
        "id": r.json()["id"],
        "email": email,
        "headers": await _login(client, email, "UserPass123"),
    }


@pytest.mark.asyncio
async def test_link_list_and_unlink_child(client: AsyncClient, school: dict):
    sid = school["id"]
    guardian = await _make_user(client, school, "guardian")
    student = await _make_user(client, school, "student")

    # Headmaster links the student to the guardian.
    r = await client.post(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children",
        headers=school["hm"],
        json={"student_id": student["id"], "relationship": "father"},
    )
    assert r.status_code == 201, r.text
    assert r.json()["student_id"] == student["id"]
    assert r.json()["relationship"] == "father"

    # Guardian sees the child via self-service.
    r = await client.get(f"{API}/schools/{sid}/me/children", headers=guardian["headers"])
    assert r.status_code == 200, r.text
    assert [c["student_id"] for c in r.json()] == [student["id"]]

    # Headmaster sees it too.
    r = await client.get(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children",
        headers=school["hm"],
    )
    assert r.status_code == 200 and len(r.json()) == 1

    # Re-linking is idempotent (no duplicate, still 201).
    r = await client.post(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children",
        headers=school["hm"],
        json={"student_id": student["id"]},
    )
    assert r.status_code == 201

    # Unlink.
    r = await client.delete(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children/{student['id']}",
        headers=school["hm"],
    )
    assert r.status_code == 204
    r = await client.get(f"{API}/schools/{sid}/me/children", headers=guardian["headers"])
    assert r.json() == []


@pytest.mark.asyncio
async def test_cannot_link_non_student(client: AsyncClient, school: dict):
    sid = school["id"]
    guardian = await _make_user(client, school, "guardian")
    other_guardian = await _make_user(client, school, "guardian")
    r = await client.post(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children",
        headers=school["hm"],
        json={"student_id": other_guardian["id"]},
    )
    assert r.status_code == 400, r.text


@pytest.mark.asyncio
async def test_guardian_cannot_manage_links(client: AsyncClient, school: dict):
    sid = school["id"]
    guardian = await _make_user(client, school, "guardian")
    student = await _make_user(client, school, "student")
    # A guardian has no GUARDIAN_MANAGEMENT permission → cannot link.
    r = await client.post(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children",
        headers=guardian["headers"],
        json={"student_id": student["id"]},
    )
    assert r.status_code == 403, r.text


@pytest.mark.asyncio
async def test_per_student_access_scoping(client: AsyncClient, school: dict):
    sid = school["id"]
    guardian = await _make_user(client, school, "guardian")
    stranger = await _make_user(client, school, "guardian")
    student = await _make_user(client, school, "student")

    await client.post(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children",
        headers=school["hm"],
        json={"student_id": student["id"]},
    )

    url = f"{API}/schools/{sid}/students/{student['id']}/attendance"
    # Linked guardian: allowed (empty list, but 200).
    assert (await client.get(url, headers=guardian["headers"])).status_code == 200
    # The student themselves: allowed.
    assert (await client.get(url, headers=student["headers"])).status_code == 200
    # Unlinked guardian: forbidden.
    assert (await client.get(url, headers=stranger["headers"])).status_code == 403
    # Headmaster (student management): allowed.
    assert (await client.get(url, headers=school["hm"])).status_code == 200
