"""Academic-session setup invariants for the L02 launch path."""
from uuid import uuid4

from app.core.config import settings
from tests.utils import create_user, enroll

API = settings.API_V1_PREFIX


async def _session(client, school, name: str, **dates) -> dict:
    response = await client.post(
        f"{API}/schools/{school['id']}/sessions",
        headers=school["sa"],
        json={"name": name, **dates},
    )
    assert response.status_code == 201, response.text
    return response.json()


async def test_sessions_reject_invalid_ranges_and_duplicate_renames(client, school):
    invalid = await client.post(
        f"{API}/schools/{school['id']}/sessions",
        headers=school["sa"],
        json={"name": "Broken year", "start_date": "2026-06-01", "end_date": "2026-05-31"},
    )
    assert invalid.status_code == 400

    first = await _session(
        client, school, "2026-27", start_date="2026-08-01", end_date="2027-06-30"
    )
    second = await _session(
        client, school, "2027-28", start_date="2027-08-01", end_date="2028-06-30"
    )

    invalid_patch = await client.patch(
        f"{API}/schools/sessions/{first['id']}",
        headers=school["sa"],
        json={"end_date": "2026-07-31"},
    )
    assert invalid_patch.status_code == 400

    duplicate = await client.patch(
        f"{API}/schools/sessions/{second['id']}",
        headers=school["sa"],
        json={"name": first["name"]},
    )
    assert duplicate.status_code == 400


async def test_classes_can_be_scoped_to_one_school_session(client, school):
    first = await _session(client, school, "2026-27")
    second = await _session(client, school, "2027-28")
    own = []
    for name, session in [("Grade 1", first), ("Grade 2", second), ("Nursery", None)]:
        payload = {"name": name}
        if session is not None:
            payload["session_id"] = session["id"]
        response = await client.post(
            f"{API}/schools/{school['id']}/academic/classes",
            headers=school["hm"], json=payload,
        )
        assert response.status_code == 201, response.text
        own.append(response.json())

    filtered = await client.get(
        f"{API}/schools/{school['id']}/academic/classes",
        headers=school["hm"], params={"session_id": first["id"]},
    )
    assert filtered.status_code == 200, filtered.text
    assert [row["id"] for row in filtered.json()] == [own[0]["id"]]

    foreign_school = await client.post(
        f"{API}/schools",
        headers=school["sa"],
        json={"name": "Foreign School", "code": "F-" + uuid4().hex[:8]},
    )
    assert foreign_school.status_code == 201, foreign_school.text
    foreign_session = await client.post(
        f"{API}/schools/{foreign_school.json()['id']}/sessions",
        headers=school["sa"], json={"name": "2026-27"},
    )
    assert foreign_session.status_code == 201, foreign_session.text

    foreign = await client.get(
        f"{API}/schools/{school['id']}/academic/classes",
        headers=school["hm"], params={"session_id": foreign_session.json()["id"]},
    )
    assert foreign.status_code == 404

    unknown = await client.get(
        f"{API}/schools/{school['id']}/academic/classes",
        headers=school["hm"], params={"session_id": uuid4()},
    )
    assert unknown.status_code == 404


async def test_enrolled_class_cannot_move_to_another_session(client, school):
    first = await _session(client, school, "2026-27")
    second = await _session(client, school, "2027-28")
    created = await client.post(
        f"{API}/schools/{school['id']}/academic/classes",
        headers=school["hm"], json={"name": "Grade 4", "session_id": first["id"]},
    )
    assert created.status_code == 201, created.text
    school_class = created.json()
    section = await client.post(
        f"{API}/schools/{school['id']}/academic/classes/{school_class['id']}/sections",
        headers=school["hm"], json={"name": "A"},
    )
    assert section.status_code == 201, section.text
    student = await create_user(client, school["id"], school["hm"], "student")
    await enroll(client, school["id"], school["hm"], section.json()["id"], student["id"])

    moved = await client.patch(
        f"{API}/schools/{school['id']}/academic/classes/{school_class['id']}",
        headers=school["hm"], json={"session_id": second["id"]},
    )
    assert moved.status_code == 400, moved.text

    still_original = await client.get(
        f"{API}/schools/{school['id']}/academic/classes",
        headers=school["hm"], params={"session_id": first["id"]},
    )
    assert [row["id"] for row in still_original.json()] == [school_class["id"]]
