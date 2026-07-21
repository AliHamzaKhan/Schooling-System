"""Subject/period attendance, class-teacher gating, room numbers, AI quiz drafts."""
from app.core.config import settings

from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def test_daily_and_subject_attendance_coexist(client, school):
    """A student can have both a daily register row and a per-subject row."""
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])

    daily = {
        "section_id": ac["section_id"], "attendance_date": "2026-07-20",
        "entries": [{"student_id": student["id"], "status": "present"}],
    }
    assert (await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json=daily)).status_code == 201

    subject = {
        **daily,
        "subject_id": ac["subject_id"],
        "period_label": "Period 3",
        "entries": [{"student_id": student["id"], "status": "absent"}],
    }
    r = await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json=subject)
    assert r.status_code == 201, r.text
    assert r.json()[0]["subject_id"] == ac["subject_id"]
    assert r.json()[0]["period_label"] == "Period 3"

    # Both rows exist for the day; neither overwrote the other.
    everything = await client.get(
        f"{API}/schools/{sid}/attendance", headers=hm,
        params={"section_id": ac["section_id"], "attendance_date": "2026-07-20"},
    )
    assert len(everything.json()) == 2

    # The default summary still reports only the daily register, so totals stay
    # comparable to the pre-subject-attendance behaviour.
    summary = await client.get(
        f"{API}/schools/{sid}/attendance/summary", headers=hm,
        params={"section_id": ac["section_id"], "attendance_date": "2026-07-20"},
    )
    assert summary.json()["total"] == 1
    assert summary.json()["counts"]["present"] == 1

    # Scoped to the subject, the same day reports the absence.
    subj_summary = await client.get(
        f"{API}/schools/{sid}/attendance/summary", headers=hm,
        params={
            "section_id": ac["section_id"], "attendance_date": "2026-07-20",
            "subject_id": ac["subject_id"],
        },
    )
    assert subj_summary.json()["counts"]["absent"] == 1


async def test_subject_attendance_upserts_within_its_own_subject(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])

    mark = {
        "section_id": ac["section_id"], "attendance_date": "2026-07-21",
        "subject_id": ac["subject_id"],
        "entries": [{"student_id": student["id"], "status": "absent"}],
    }
    await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json=mark)
    mark["entries"] = [{"student_id": student["id"], "status": "present"}]
    await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json=mark)

    rows = await client.get(
        f"{API}/schools/{sid}/attendance", headers=hm,
        params={
            "section_id": ac["section_id"], "attendance_date": "2026-07-21",
            "subject_id": ac["subject_id"],
        },
    )
    assert len(rows.json()) == 1
    assert rows.json()[0]["status"] == "present"


async def test_only_class_teacher_marks_the_daily_register(client, school):
    """A subject teacher can mark their period but not the daily register."""
    sid, hm = school["id"], school["hm"]
    rc = await client.post(f"{API}/schools/{sid}/academic/classes", headers=hm,
                           json={"name": "Grade 4", "level": 4, "room_no": "B-12"})
    cid = rc.json()["id"]
    assert rc.json()["room_no"] == "B-12"

    class_teacher = await create_user(client, sid, hm, "teacher")
    subject_teacher = await create_user(client, sid, hm, "teacher")

    rs = await client.post(
        f"{API}/schools/{sid}/academic/classes/{cid}/sections", headers=hm,
        json={"name": "A", "room_no": "B-12a", "class_teacher_id": class_teacher["id"]},
    )
    assert rs.json()["room_no"] == "B-12a"
    section_id = rs.json()["id"]

    rsub = await client.post(f"{API}/schools/{sid}/academic/subjects", headers=hm,
                             json={"code": "SCI", "name": "Science"})
    subject_id = rsub.json()["id"]

    # The subject teacher is timetabled for Science in this section.
    await client.post(f"{API}/schools/{sid}/academic/timetable", headers=hm, json={
        "section_id": section_id, "subject_id": subject_id,
        "teacher_id": subject_teacher["id"], "day_of_week": 0,
        "start_time": "09:00", "end_time": "10:00",
    })

    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, section_id, student["id"])

    ct = await login(client, class_teacher["email"], class_teacher["password"])
    st = await login(client, subject_teacher["email"], subject_teacher["password"])
    entries = [{"student_id": student["id"], "status": "present"}]
    daily = {"section_id": section_id, "attendance_date": "2026-07-22", "entries": entries}

    # Class teacher: daily register allowed.
    assert (await client.post(f"{API}/schools/{sid}/attendance", headers=ct, json=daily)).status_code == 201

    # Subject teacher: daily register refused...
    refused = await client.post(f"{API}/schools/{sid}/attendance", headers=st, json=daily)
    assert refused.status_code == 403

    # ...but their own subject's period is allowed.
    allowed = await client.post(f"{API}/schools/{sid}/attendance", headers=st,
                                json={**daily, "subject_id": subject_id})
    assert allowed.status_code == 201, allowed.text

    # A subject they do not teach is refused.
    other = await client.post(f"{API}/schools/{sid}/academic/subjects", headers=hm,
                              json={"code": "ART", "name": "Art"})
    denied = await client.post(f"{API}/schools/{sid}/attendance", headers=st,
                               json={**daily, "subject_id": other.json()["id"]})
    assert denied.status_code == 403

    # The headmaster bypasses both rules.
    assert (await client.post(f"{API}/schools/{sid}/attendance", headers=hm,
                              json={**daily, "subject_id": other.json()["id"]})).status_code == 201


async def test_absence_notifies_guardians_only_when_school_opted_in(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    guardian = await create_user(client, sid, hm, "guardian")
    await client.post(f"{API}/schools/{sid}/guardians/{guardian['id']}/students",
                      headers=hm, json={"student_id": student["id"]})

    mark = {
        "section_id": ac["section_id"], "attendance_date": "2026-07-23",
        "entries": [{"student_id": student["id"], "status": "absent"}],
    }
    # No NotificationConfig yet -> no message is sent.
    await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json=mark)
    before = await client.get(f"{API}/schools/{sid}/communication/broadcasts", headers=hm)
    assert len(before.json()) == 0

    # Opt in, then mark a different student-day so the status actually changes.
    await client.put(f"{API}/schools/{sid}/communication/configs", headers=hm,
                     json={"event": "attendance_absent", "enabled": True, "channels": ["sms"]})
    mark["attendance_date"] = "2026-07-24"
    await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json=mark)

    after = await client.get(f"{API}/schools/{sid}/communication/broadcasts", headers=hm)
    assert len(after.json()) == 1
    assert after.json()[0]["audience_type"] == "student_guardians"

    # Re-saving the same mark must not re-notify.
    await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json=mark)
    assert len((await client.get(f"{API}/schools/{sid}/communication/broadcasts", headers=hm)).json()) == 1

    # "present" never notifies.
    mark["attendance_date"] = "2026-07-25"
    mark["entries"] = [{"student_id": student["id"], "status": "present"}]
    await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json=mark)
    assert len((await client.get(f"{API}/schools/{sid}/communication/broadcasts", headers=hm)).json()) == 1


async def test_ai_quiz_questions_return_reviewable_drafts(client, school):
    """Without an API key the provider stubs, but the shape must still hold."""
    sid, hm = school["id"], school["hm"]
    r = await client.post(f"{API}/schools/{sid}/ai/quiz-questions", headers=hm, json={
        "topic": "Photosynthesis", "question_count": 3, "difficulty": "easy",
    })
    assert r.status_code == 200, r.text
    body = r.json()
    assert len(body["questions"]) == 3
    assert all(len(q["options"]) == 4 for q in body["questions"])
    assert all(q["question_type"] == "mcq" for q in body["questions"])

    # Generation is logged for audit, but no quiz rows were created.
    interactions = await client.get(f"{API}/schools/{sid}/ai/interactions", headers=hm)
    assert any(i["feature"] == "quiz_generation" for i in interactions.json())


async def test_teacher_timetable_is_scoped_to_the_caller(client, school):
    """/me/timetable returns only the caller's periods, with names resolved."""
    sid, hm = school["id"], school["hm"]
    rc = await client.post(f"{API}/schools/{sid}/academic/classes", headers=hm,
                           json={"name": "Grade 7", "level": 7})
    cid = rc.json()["id"]
    mine = await create_user(client, sid, hm, "teacher")
    other = await create_user(client, sid, hm, "teacher")
    rs = await client.post(f"{API}/schools/{sid}/academic/classes/{cid}/sections", headers=hm,
                           json={"name": "B", "room_no": "C-3", "class_teacher_id": mine["id"]})
    section_id = rs.json()["id"]
    rsub = await client.post(f"{API}/schools/{sid}/academic/subjects", headers=hm,
                             json={"code": "GEO", "name": "Geography"})
    subject_id = rsub.json()["id"]

    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, section_id, student["id"])

    slot = await client.post(f"{API}/schools/{sid}/academic/timetable", headers=hm, json={
        "section_id": section_id, "subject_id": subject_id, "teacher_id": mine["id"],
        "day_of_week": 2, "start_time": "11:00", "end_time": "12:00",
    })
    slot_id = slot.json()["id"]
    # A period belonging to the other teacher must not leak into my timetable.
    await client.post(f"{API}/schools/{sid}/academic/timetable", headers=hm, json={
        "section_id": section_id, "subject_id": subject_id, "teacher_id": other["id"],
        "day_of_week": 3, "start_time": "09:00", "end_time": "10:00",
    })

    th = await login(client, mine["email"], mine["password"])
    r = await client.get(f"{API}/schools/{sid}/academic/me/timetable", headers=th)
    assert r.status_code == 200, r.text
    rows = r.json()
    assert len(rows) == 1
    row = rows[0]
    assert row["subject"] == "Geography"
    assert row["class_name"] == "Grade 7"
    assert row["section_name"] == "B"
    assert row["room"] == "C-3"          # falls back to the section's room
    assert row["student_count"] == 1
    assert row["is_class_teacher"] is True
    assert row["attendance_marked"] is False

    # Marking this period's attendance flips attendance_marked for that date.
    await client.post(f"{API}/schools/{sid}/attendance", headers=th, json={
        "section_id": section_id, "attendance_date": "2026-07-29",
        "subject_id": subject_id, "timetable_slot_id": slot_id,
        "entries": [{"student_id": student["id"], "status": "present"}],
    })
    marked = await client.get(f"{API}/schools/{sid}/academic/me/timetable",
                              headers=th, params={"on_date": "2026-07-29"})
    assert marked.json()[0]["attendance_marked"] is True
    # A different day is still unmarked.
    unmarked = await client.get(f"{API}/schools/{sid}/academic/me/timetable",
                                headers=th, params={"on_date": "2026-07-30"})
    assert unmarked.json()[0]["attendance_marked"] is False

    # The other teacher sees only their own period.
    oh = await login(client, other["email"], other["password"])
    ro = await client.get(f"{API}/schools/{sid}/academic/me/timetable", headers=oh)
    assert len(ro.json()) == 1
    assert ro.json()[0]["day_of_week"] == 3


async def test_section_performance_ranks_students(client, school):
    """Attendance + marks aggregate into a ranked roster for the teacher view."""
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)

    strong = await create_user(client, sid, hm, "student", full_name="Strong Student")
    weak = await create_user(client, sid, hm, "student", full_name="Weak Student")
    for s in (strong, weak):
        await enroll(client, sid, hm, ac["section_id"], s["id"])

    # Two days of daily register: strong present twice, weak absent twice.
    for day in ("2026-08-03", "2026-08-04"):
        await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json={
            "section_id": ac["section_id"], "attendance_date": day,
            "entries": [
                {"student_id": strong["id"], "status": "present"},
                {"student_id": weak["id"], "status": "absent"},
            ],
        })

    # An exam paper worth 100, marked 90 vs 40.
    rex = await client.post(f"{API}/schools/{sid}/exams", headers=hm, json={
        "class_id": ac["class_id"], "name": "Term 1",
        "start_date": "2026-08-10", "end_date": "2026-08-12",
    })
    assert rex.status_code == 201, rex.text
    exam_id = rex.json()["id"]
    rp = await client.post(f"{API}/schools/{sid}/exams/{exam_id}/papers", headers=hm,
                           json={"subject_id": ac["subject_id"], "max_marks": 100,
                                 "pass_marks": 40})
    assert rp.status_code == 201, rp.text
    paper_id = rp.json()["id"]
    await client.post(
        f"{API}/schools/{sid}/exams/papers/{paper_id}/marks", headers=hm,
        json={"entries": [
            {"student_id": strong["id"], "marks_obtained": 90},
            {"student_id": weak["id"], "marks_obtained": 40},
        ]},
    )

    r = await client.get(
        f"{API}/schools/{sid}/academic/sections/{ac['section_id']}/performance",
        headers=hm,
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["section_name"] == "A"
    names = [s["full_name"] for s in body["students"]]
    assert names == ["Strong Student", "Weak Student"], "best performer must rank first"

    top = body["students"][0]
    assert top["attendance_rate"] == 1.0
    assert top["present_days"] == 2 and top["total_days"] == 2
    assert top["average_percentage"] == 90.0
    assert top["grade"] == "A+"

    bottom = body["students"][1]
    assert bottom["attendance_rate"] == 0.0
    assert bottom["average_percentage"] == 40.0

    # A student with no attendance and no marks still appears, ranked last.
    fresh = await create_user(client, sid, hm, "student", full_name="Aaa New")
    await enroll(client, sid, hm, ac["section_id"], fresh["id"])
    r2 = await client.get(
        f"{API}/schools/{sid}/academic/sections/{ac['section_id']}/performance",
        headers=hm,
    )
    students = r2.json()["students"]
    assert len(students) == 3
    assert students[-1]["full_name"] == "Aaa New"
    assert students[-1]["grade"] == "—"
