"""Families read only their own exam results, seats and never raw marks."""
from app.core.config import settings
from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def test_exam_reads_are_limited_to_the_callers_family(client, school):
    sid, hm = school["id"], school["hm"]
    academic = await make_academics(client, sid, hm)
    child = await create_user(client, sid, hm, "student")
    other = await create_user(client, sid, hm, "student")
    for s in (child, other):
        await enroll(client, sid, hm, academic["section_id"], s["id"])
    guardian = await create_user(client, sid, hm, "guardian")
    link = await client.post(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children", headers=hm, json={"student_id": child["id"]},
    )
    assert link.status_code == 201, link.text
    exams = f"{API}/schools/{sid}/exams"
    exam = (await client.post(exams, headers=hm, json={
        "class_id": academic["class_id"], "name": "Midterm", "start_date": "2030-01-01", "end_date": "2030-01-30",
    })).json()["id"]
    paper = (await client.post(f"{exams}/{exam}/papers", headers=hm, json={
        "subject_id": academic["subject_id"], "max_marks": 100, "pass_marks": 40, "exam_date": "2030-01-10",
    })).json()["id"]
    marks = await client.post(f"{exams}/papers/{paper}/marks", headers=hm, json={"entries": [
        {"student_id": child["id"], "marks_obtained": 80}, {"student_id": other["id"], "marks_obtained": 30},
    ]})
    assert marks.status_code == 200, marks.text

    family = [await login(client, guardian["email"], guardian["password"]),
              await login(client, child["email"], child["password"])]
    for headers in family:
        assert (await client.get(f"{exams}/papers/{paper}/marks", headers=headers)).status_code == 403
        assert (await client.get(f"{exams}/papers/{paper}/gradebook", headers=headers)).status_code == 403

    assert (await client.post(f"{exams}/{exam}/results/publish", headers=hm)).status_code == 200
    for headers in family:
        rows = (await client.get(f"{exams}/{exam}/results", headers=headers)).json()
        assert [r["student_id"] for r in rows] == [child["id"]]
        merit = await client.get(f"{API}/schools/{sid}/exams/{exam}/merit-list", headers=headers)
        assert merit.status_code == 403
    # Staff still see the whole exam.
    assert len((await client.get(f"{exams}/{exam}/results", headers=hm)).json()) == 2
    assert (await client.get(f"{exams}/papers/{paper}/marks", headers=hm)).status_code == 200
