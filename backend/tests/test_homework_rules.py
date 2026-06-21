"""Homework submission rules.

The smoke test covers the enrolled happy path + grading. These cover the rules
that bit us in integration: only an enrolled student can submit, and a
submission past the due date is flagged "late".
"""
from app.core.config import settings

from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def _assignment(client, sid, hm, section_id, subject_id, due_date):
    r = await client.post(
        f"{API}/schools/{sid}/homework/assignments",
        headers=hm,
        json={
            "section_id": section_id,
            "subject_id": subject_id,
            "title": "HW",
            "due_date": due_date,
            "max_marks": 10,
        },
    )
    assert r.status_code == 201, r.text
    return r.json()


async def test_unenrolled_student_cannot_submit(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")  # NOT enrolled
    assignment = await _assignment(
        client, sid, hm, ac["section_id"], ac["subject_id"], "2026-06-20"
    )
    sh = await login(client, student["email"], student["password"])
    r = await client.post(
        f"{API}/schools/{sid}/homework/assignments/{assignment['id']}/submissions",
        headers=sh,
        json={"content": "done"},
    )
    assert r.status_code == 403


async def test_enrolled_student_can_submit(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    assignment = await _assignment(
        client, sid, hm, ac["section_id"], ac["subject_id"], "2026-06-20"
    )
    sh = await login(client, student["email"], student["password"])
    r = await client.post(
        f"{API}/schools/{sid}/homework/assignments/{assignment['id']}/submissions",
        headers=sh,
        json={"content": "done", "submitted_on": "2026-06-18"},
    )
    assert r.status_code == 201
    assert r.json()["status"] == "submitted"


async def test_submission_after_due_date_is_late(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    assignment = await _assignment(
        client, sid, hm, ac["section_id"], ac["subject_id"], "2026-06-10"
    )
    sh = await login(client, student["email"], student["password"])
    r = await client.post(
        f"{API}/schools/{sid}/homework/assignments/{assignment['id']}/submissions",
        headers=sh,
        json={"content": "late work", "submitted_on": "2026-06-20"},
    )
    assert r.status_code == 201
    assert r.json()["status"] == "late"
