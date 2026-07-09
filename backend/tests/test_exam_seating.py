"""Admit card and seating-plan generation."""
from app.core.config import settings

from tests.utils import create_user, enroll, make_academics

API = settings.API_V1_PREFIX


async def _exam_with_paper(client, sid, hm, ac):
    exam = (await client.post(f"{API}/schools/{sid}/exams", headers=hm, json={
        "class_id": ac["class_id"], "name": "Finals",
        "start_date": "2026-11-01", "end_date": "2026-11-10"})).json()
    await client.post(f"{API}/schools/{sid}/exams/{exam['id']}/papers", headers=hm,
                      json={"subject_id": ac["subject_id"], "max_marks": 100,
                            "pass_marks": 40, "exam_date": "2026-11-02"})
    return exam


async def test_seating_generation_and_admit_card(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    students = [await create_user(client, sid, hm, "student") for _ in range(3)]
    for s in students:
        await enroll(client, sid, hm, ac["section_id"], s["id"])
    exam = await _exam_with_paper(client, sid, hm, ac)

    # Two rooms, capacity 2 each -> 3 students seated across them.
    r = await client.post(f"{API}/schools/{sid}/exams/{exam['id']}/seating/generate", headers=hm,
                          json={"rooms": [{"name": "Room A", "capacity": 2},
                                          {"name": "Room B", "capacity": 2}]})
    assert r.status_code == 201, r.text
    seats = r.json()
    assert len(seats) == 3
    # Seats are unique per (room, seat_no).
    keys = {(s["room"], s["seat_no"]) for s in seats}
    assert len(keys) == 3
    assert {s["room"] for s in seats} == {"Room A", "Room B"}

    # Admit card for a seated student includes the seat + papers.
    seated = seats[0]["student_id"]
    ac_resp = await client.get(
        f"{API}/schools/{sid}/exams/{exam['id']}/students/{seated}/admit-card", headers=hm)
    assert ac_resp.status_code == 200, ac_resp.text
    card = ac_resp.json()
    assert card["exam_name"] == "Finals"
    assert card["room"] is not None
    assert len(card["papers"]) == 1
    assert card["papers"][0]["subject_id"] == ac["subject_id"]


async def test_seating_capacity_too_small(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    for _ in range(3):
        s = await create_user(client, sid, hm, "student")
        await enroll(client, sid, hm, ac["section_id"], s["id"])
    exam = await _exam_with_paper(client, sid, hm, ac)
    r = await client.post(f"{API}/schools/{sid}/exams/{exam['id']}/seating/generate", headers=hm,
                          json={"rooms": [{"name": "Room A", "capacity": 2}]})
    assert r.status_code == 400


async def test_admit_card_for_unenrolled_student(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    exam = await _exam_with_paper(client, sid, hm, ac)
    outsider = await create_user(client, sid, hm, "student")  # not enrolled
    r = await client.get(
        f"{API}/schools/{sid}/exams/{exam['id']}/students/{outsider['id']}/admit-card", headers=hm)
    assert r.status_code == 404
