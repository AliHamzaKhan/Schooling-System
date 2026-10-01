"""Assignment lists carry real placement, roster and grading counts."""
from datetime import date, timedelta

from app.core.config import settings
from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def test_assignment_list_reports_roster_submissions_and_grading(client, school):
    sid, hm = school["id"], school["hm"]
    academic = await make_academics(client, sid, hm)
    students = []
    for _ in range(3):
        student = await create_user(client, sid, hm, "student")
        await enroll(client, sid, hm, academic["section_id"], student["id"])
        students.append(student)
    created = await client.post(f"{API}/schools/{sid}/homework/assignments", headers=hm, json={
        "section_id": academic["section_id"], "subject_id": academic["subject_id"],
        "title": "Counts", "due_date": (date.today() + timedelta(days=2)).isoformat(), "max_marks": 10,
    })
    assert created.status_code == 201, created.text
    aid = created.json()["id"]
    submission_ids = []
    for student in students[:2]:
        sh = await login(client, student["email"], student["password"])
        r = await client.post(f"{API}/schools/{sid}/homework/assignments/{aid}/submissions", headers=sh, json={"content": "answer"})
        assert r.status_code == 201, r.text
        submission_ids.append(r.json()["id"])
    graded = await client.patch(
        f"{API}/schools/{sid}/homework/submissions/{submission_ids[0]}/grade", headers=hm,
        json={"marks_obtained": 8},
    )
    assert graded.status_code == 200, graded.text

    (row,) = (await client.get(f"{API}/schools/{sid}/homework/assignments", headers=hm)).json()
    assert (row["class_name"], row["section_name"]) == ("Grade 1", "A")
    assert row["roster_size"] == 3
    assert row["submission_count"] == 2
    assert row["graded_count"] == 1
