"""Homework grading: student names, the seen_at read receipt, and grade flow."""
from app.core.config import settings

from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def _setup_submission(client, sid, hm):
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student", full_name="Ada Lovelace")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    r = await client.post(
        f"{API}/schools/{sid}/homework/assignments",
        headers=hm,
        json={
            "section_id": ac["section_id"],
            "subject_id": ac["subject_id"],
            "title": "Essay",
            "due_date": "2026-12-01",
            "max_marks": 10,
        },
    )
    aid = r.json()["id"]
    sh = await login(client, student["email"], student["password"])
    await client.post(
        f"{API}/schools/{sid}/homework/assignments/{aid}/submissions",
        headers=sh,
        json={"content": "my work", "submitted_on": "2026-11-20"},
    )
    return {"assignment_id": aid, "student": student, "sh": sh}


async def _my_submission(client, sid, sh, aid):
    r = await client.get(f"{API}/schools/{sid}/homework/assignments", headers=sh)
    row = next(a for a in r.json() if a["id"] == aid)
    return row["my_submission"]


async def test_seen_receipt_and_student_name(client, school):
    sid, hm = school["id"], school["hm"]
    s = await _setup_submission(client, sid, hm)
    aid, sh = s["assignment_id"], s["sh"]

    # Before a teacher opens it, the student's receipt is unset.
    assert (await _my_submission(client, sid, sh, aid))["seen_at"] is None

    # Teacher (here the headmaster, who holds homework view) opens the list:
    # names are composed and every submission is stamped seen.
    r = await client.get(
        f"{API}/schools/{sid}/homework/assignments/{aid}/submissions", headers=hm
    )
    assert r.status_code == 200
    assert r.json()[0]["student_name"] == "Ada Lovelace"
    assert r.json()[0]["seen_at"] is not None

    # The student now has a read receipt.
    assert (await _my_submission(client, sid, sh, aid))["seen_at"] is not None


async def test_resubmission_clears_read_receipt_but_identical_retry_keeps_it(client, school):
    sid, hm = school["id"], school["hm"]
    setup = await _setup_submission(client, sid, hm)
    aid, sh = setup["assignment_id"], setup["sh"]

    # Staff has read the original version.
    opened = await client.get(
        f"{API}/schools/{sid}/homework/assignments/{aid}/submissions", headers=hm
    )
    assert opened.status_code == 200
    assert (await _my_submission(client, sid, sh, aid))["seen_at"] is not None

    # A changed submission is a new revision and must be visibly unread.
    revised = await client.post(
        f"{API}/schools/{sid}/homework/assignments/{aid}/submissions",
        headers=sh,
        json={"content": "revised work", "submitted_on": "2026-11-20"},
    )
    assert revised.status_code == 201, revised.text
    assert revised.json()["seen_at"] is None
    assert (await _my_submission(client, sid, sh, aid))["seen_at"] is None

    # Once read, a response-loss retry with the same payload must not erase
    # the receipt again.
    opened = await client.get(
        f"{API}/schools/{sid}/homework/assignments/{aid}/submissions", headers=hm
    )
    assert opened.status_code == 200
    retried = await client.post(
        f"{API}/schools/{sid}/homework/assignments/{aid}/submissions",
        headers=sh,
        json={"content": "revised work", "submitted_on": "2026-11-20"},
    )
    assert retried.status_code == 201, retried.text
    assert retried.json()["seen_at"] is not None


async def test_grade_visible_to_student(client, school):
    sid, hm = school["id"], school["hm"]
    s = await _setup_submission(client, sid, hm)
    aid, sh = s["assignment_id"], s["sh"]
    subs = await client.get(
        f"{API}/schools/{sid}/homework/assignments/{aid}/submissions", headers=hm
    )
    sub_id = subs.json()[0]["id"]

    g = await client.patch(
        f"{API}/schools/{sid}/homework/submissions/{sub_id}/grade",
        headers=hm,
        json={"marks_obtained": 9, "feedback": "Great"},
    )
    assert g.status_code == 200, g.text

    mine = await _my_submission(client, sid, sh, aid)
    assert mine["status"] == "graded"
    assert mine["marks_obtained"] == 9
    assert mine["feedback"] == "Great"


async def test_marks_cannot_exceed_max(client, school):
    sid, hm = school["id"], school["hm"]
    s = await _setup_submission(client, sid, hm)
    subs = await client.get(
        f"{API}/schools/{sid}/homework/assignments/{s['assignment_id']}/submissions",
        headers=hm,
    )
    sub_id = subs.json()[0]["id"]
    g = await client.patch(
        f"{API}/schools/{sid}/homework/submissions/{sub_id}/grade",
        headers=hm,
        json={"marks_obtained": 99},
    )
    assert g.status_code == 400
