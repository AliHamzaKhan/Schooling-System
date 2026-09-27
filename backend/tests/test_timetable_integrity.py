"""Timetable consistency safeguards."""

from app.core.config import settings

from tests.utils import make_academics

API = settings.API_V1_PREFIX


async def test_timetable_rejects_subject_from_a_different_class_on_create_and_update(
    client, school
):
    sid, hm = school["id"], school["hm"]
    first = await make_academics(client, sid, hm)

    second_class = await client.post(
        f"{API}/schools/{sid}/academic/classes",
        headers=hm,
        json={"name": "Grade 2", "level": 2},
    )
    assert second_class.status_code == 201
    second_class_id = second_class.json()["id"]
    second_section = await client.post(
        f"{API}/schools/{sid}/academic/classes/{second_class_id}/sections",
        headers=hm,
        json={"name": "A"},
    )
    assert second_section.status_code == 201
    subject = await client.post(
        f"{API}/schools/{sid}/academic/subjects",
        headers=hm,
        json={"code": "SCI2", "name": "Science", "class_id": second_class_id},
    )
    assert subject.status_code == 201

    invalid = await client.post(
        f"{API}/schools/{sid}/academic/timetable",
        headers=hm,
        json={
            "section_id": first["section_id"],
            "subject_id": subject.json()["id"],
            "day_of_week": 0,
            "start_time": "09:00",
            "end_time": "10:00",
        },
    )
    assert invalid.status_code == 400
    assert invalid.json()["detail"] == "Timetable subject must belong to the slot section's class"

    slot = await client.post(
        f"{API}/schools/{sid}/academic/timetable",
        headers=hm,
        json={
            "section_id": first["section_id"],
            "subject_id": first["subject_id"],
            "day_of_week": 0,
            "start_time": "09:00",
            "end_time": "10:00",
        },
    )
    assert slot.status_code == 201

    invalid_update = await client.patch(
        f"{API}/schools/{sid}/academic/timetable/{slot.json()['id']}",
        headers=hm,
        json={"subject_id": subject.json()["id"]},
    )
    assert invalid_update.status_code == 400
    assert invalid_update.json()["detail"] == "Timetable subject must belong to the slot section's class"


async def test_subject_cannot_be_restricted_away_from_an_existing_timetable_slot(
    client, school
):
    sid, hm = school["id"], school["hm"]
    first = await make_academics(client, sid, hm)

    slot = await client.post(
        f"{API}/schools/{sid}/academic/timetable",
        headers=hm,
        json={
            "section_id": first["section_id"],
            "subject_id": first["subject_id"],
            "day_of_week": 0,
            "start_time": "09:00",
            "end_time": "10:00",
        },
    )
    assert slot.status_code == 201, slot.text

    other_class = await client.post(
        f"{API}/schools/{sid}/academic/classes",
        headers=hm,
        json={"name": "Grade 2", "level": 2},
    )
    assert other_class.status_code == 201, other_class.text

    invalid = await client.patch(
        f"{API}/schools/{sid}/academic/subjects/{first['subject_id']}",
        headers=hm,
        json={"class_id": other_class.json()["id"]},
    )
    assert invalid.status_code == 400
    assert invalid.json()["detail"] == (
        "Cannot restrict a subject to a class while it is timetabled for another class"
    )

    subjects = await client.get(f"{API}/schools/{sid}/academic/subjects", headers=hm)
    assert subjects.status_code == 200, subjects.text
    unchanged = next(row for row in subjects.json() if row["id"] == first["subject_id"])
    assert unchanged["class_id"] is None
