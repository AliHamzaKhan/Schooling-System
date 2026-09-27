"""Admission/enrollment session consistency and safe retries."""

from app.core.config import settings
from tests.utils import create_user

API = settings.API_V1_PREFIX


async def _session(client, school, name: str) -> dict:
    response = await client.post(
        f"{API}/schools/{school['id']}/sessions",
        headers=school["sa"],
        json={"name": name},
    )
    assert response.status_code == 201, response.text
    return response.json()


async def _session_section(client, school, session_id: str | None) -> dict:
    payload = {"name": "Grade 6"}
    if session_id is not None:
        payload["session_id"] = session_id
    school_class = await client.post(
        f"{API}/schools/{school['id']}/academic/classes",
        headers=school["hm"],
        json=payload,
    )
    assert school_class.status_code == 201, school_class.text
    section = await client.post(
        f"{API}/schools/{school['id']}/academic/classes/{school_class.json()['id']}/sections",
        headers=school["hm"],
        json={"name": "A"},
    )
    assert section.status_code == 201, section.text
    return section.json()


async def test_session_scoped_section_infers_session_and_retries_without_duplicate(client, school):
    session = await _session(client, school, "2026-27")
    section = await _session_section(client, school, session["id"])
    student = await create_user(client, school["id"], school["hm"], "student")
    path = f"{API}/schools/{school['id']}/sections/{section['id']}/students"

    created = await client.post(path, headers=school["hm"], json={"student_id": student["id"]})
    retried = await client.post(path, headers=school["hm"], json={"student_id": student["id"]})

    assert created.status_code == retried.status_code == 201
    assert created.json()["id"] == retried.json()["id"]
    assert created.json()["session_id"] == retried.json()["session_id"] == session["id"]
    assert created.json()["roll_number"] == retried.json()["roll_number"] == 1

    roster = await client.get(path, headers=school["hm"])
    assert roster.status_code == 200, roster.text
    assert [row["id"] for row in roster.json()] == [created.json()["id"]]


async def test_active_admission_rejects_conflicting_session_without_rewriting_placement(client, school):
    first = await _session(client, school, "2026-27")
    second = await _session(client, school, "2027-28")
    section = await _session_section(client, school, None)
    student = await create_user(client, school["id"], school["hm"], "student")
    path = f"{API}/schools/{school['id']}/sections/{section['id']}/students"

    created = await client.post(
        path,
        headers=school["hm"],
        json={"student_id": student["id"], "session_id": first["id"]},
    )
    assert created.status_code == 201, created.text

    conflicting = await client.post(
        path,
        headers=school["hm"],
        json={"student_id": student["id"], "session_id": second["id"]},
    )
    assert conflicting.status_code == 400

    roster = await client.get(path, headers=school["hm"])
    assert roster.status_code == 200, roster.text
    assert roster.json()[0]["id"] == created.json()["id"]
    assert roster.json()[0]["session_id"] == first["id"]


async def test_session_scoped_section_rejects_another_local_session_before_creating_enrollment(client, school):
    first = await _session(client, school, "2026-27")
    second = await _session(client, school, "2027-28")
    section = await _session_section(client, school, first["id"])
    student = await create_user(client, school["id"], school["hm"], "student")
    path = f"{API}/schools/{school['id']}/sections/{section['id']}/students"

    response = await client.post(
        path,
        headers=school["hm"],
        json={"student_id": student["id"], "session_id": second["id"]},
    )
    assert response.status_code == 400

    roster = await client.get(path, headers=school["hm"])
    assert roster.status_code == 200, roster.text
    assert roster.json() == []
