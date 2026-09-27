"""F01.8 nested-object and no-partial-write regressions."""

from app.core.config import settings

from tests.test_broadcast_isolation import another_school
from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def test_calendar_and_lessons_reject_foreign_nested_ids(client, school):
    sid, hm = school["id"], school["hm"]
    own = await make_academics(client, sid, hm)
    other_sid = await another_school(client, school["sa"])
    foreign = await make_academics(client, other_sid, school["sa"])

    calendar = await client.post(
        f"{API}/schools/{sid}/calendar/events", headers=hm,
        json={"title": "Foreign session", "start_date": "2026-10-01", "session_id": foreign["class_id"]},
    )
    assert calendar.status_code == 404

    foreign_section = await client.post(
        f"{API}/schools/{sid}/lessons", headers=hm,
        json={"section_id": foreign["section_id"], "subject_id": own["subject_id"], "title": "No leak", "due_date": "2026-12-01"},
    )
    assert foreign_section.status_code == 404, foreign_section.text
    foreign_subject = await client.post(
        f"{API}/schools/{sid}/lessons", headers=hm,
        json={"section_id": own["section_id"], "subject_id": foreign["subject_id"], "title": "No leak", "due_date": "2026-12-01"},
    )
    assert foreign_subject.status_code == 404


async def test_promotion_preflights_foreign_target_without_mutation(client, school):
    sid, hm = school["id"], school["hm"]
    own = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, own["section_id"], student["id"])

    other_sid = await another_school(client, school["sa"])
    foreign = await make_academics(client, other_sid, school["sa"])
    before = await client.get(
        f"{API}/schools/{sid}/sections/{own['section_id']}/students", headers=hm
    )
    assert before.status_code == 200
    assert any(row["student_id"] == student["id"] and row["status"] == "active" for row in before.json())

    response = await client.post(
        f"{API}/schools/{sid}/promotions", headers=hm,
        json={"items": [{
            "student_id": student["id"],
            "to_section_id": foreign["section_id"],
            "outcome": "promoted",
        }]},
    )
    assert response.status_code == 404
    after = await client.get(
        f"{API}/schools/{sid}/sections/{own['section_id']}/students", headers=hm
    )
    assert any(row["student_id"] == student["id"] and row["status"] == "active" for row in after.json())


async def test_promotion_foreign_exam_rejected_before_write(client, school):
    sid, hm = school["id"], school["hm"]
    own = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, own["section_id"], student["id"])
    other_sid = await another_school(client, school["sa"])
    foreign = await make_academics(client, other_sid, school["sa"])
    foreign_exam = await client.post(
        f"{API}/schools/{other_sid}/exams", headers=school["sa"],
        json={"class_id": foreign["class_id"], "name": "Foreign"},
    )
    assert foreign_exam.status_code == 201

    response = await client.post(
        f"{API}/schools/{sid}/promotions", headers=hm,
        json={"exam_id": foreign_exam.json()["id"], "items": [{"student_id": student["id"], "outcome": "retained"}]},
    )
    assert response.status_code == 404
    report = await client.get(f"{API}/schools/{sid}/promotions", headers=hm)
    assert report.status_code == 200 and report.json() == []


async def test_homework_rejects_foreign_links_and_hides_unenrolled_detail(client, school):
    sid, hm = school["id"], school["hm"]
    own = await make_academics(client, sid, hm)
    outsider = await create_user(client, sid, hm, "student")
    other_sid = await another_school(client, school["sa"])
    foreign = await make_academics(client, other_sid, school["sa"])

    foreign_section = await client.post(
        f"{API}/schools/{sid}/homework/assignments", headers=hm,
        json={"section_id": foreign["section_id"], "subject_id": own["subject_id"], "title": "No leak", "due_date": "2026-12-01"},
    )
    assert foreign_section.status_code == 404
    foreign_subject = await client.post(
        f"{API}/schools/{sid}/homework/assignments", headers=hm,
        json={"section_id": own["section_id"], "subject_id": foreign["subject_id"], "title": "No leak", "due_date": "2026-12-01"},
    )
    assert foreign_subject.status_code == 404

    assignment = await client.post(
        f"{API}/schools/{sid}/homework/assignments", headers=hm,
        json={"section_id": own["section_id"], "subject_id": own["subject_id"], "title": "Private work", "due_date": "2026-12-01"},
    )
    assert assignment.status_code == 201
    outsider_headers = await login(client, outsider["email"], outsider["password"])
    detail = await client.get(
        f"{API}/schools/{sid}/homework/assignments/{assignment.json()['id']}", headers=outsider_headers
    )
    assert detail.status_code == 404


async def test_transport_route_filter_rejects_foreign_route(client, school):
    sid, hm = school["id"], school["hm"]
    other_sid = await another_school(client, school["sa"])
    foreign_route = await client.post(
        f"{API}/schools/{other_sid}/transport/routes", headers=school["sa"], json={"name": "Foreign route"}
    )
    assert foreign_route.status_code == 201
    response = await client.get(
        f"{API}/schools/{sid}/transport/assignments",
        headers=hm,
        params={"route_id": foreign_route.json()["id"]},
    )
    assert response.status_code == 404
