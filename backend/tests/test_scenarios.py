"""End-to-end scenarios that connect modules together.

Where the per-module tests prove each surface in isolation, these walk a piece
of data across many modules the way a real school would, so a regression that
breaks an *integration* (not just one endpoint) is caught. Each scenario is one
coherent story with cross-module assertions.
"""
from app.core.config import settings

from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def _next_class_section(client, sid, hm, name="Grade 2", level=2):
    cid = (await client.post(f"{API}/schools/{sid}/academic/classes", headers=hm,
                             json={"name": name, "level": level})).json()["id"]
    sec = (await client.post(f"{API}/schools/{sid}/academic/classes/{cid}/sections",
                             headers=hm, json={"name": "A"})).json()["id"]
    return cid, sec


async def test_scenario_full_student_lifecycle(client, school):
    """Admission → enroll → attendance → homework → quiz → exam → result →
    report card → merit → promotion, asserting the links between each module."""
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)

    # 1) Admission + enrollment (Student Management ↔ Academic).
    student = await create_user(client, sid, hm, "student")
    peer = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    await enroll(client, sid, hm, ac["section_id"], peer["id"])
    roster = (await client.get(
        f"{API}/schools/{sid}/sections/{ac['section_id']}/students", headers=hm)).json()
    assert {student["id"], peer["id"]} <= {e["student_id"] for e in roster}

    # 2) Attendance (Attendance ↔ Academic/Student).
    r = await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json={
        "section_id": ac["section_id"], "attendance_date": "2026-07-01",
        "entries": [{"student_id": student["id"], "status": "present"},
                    {"student_id": peer["id"], "status": "absent"}]})
    assert r.status_code == 201, r.text
    att = (await client.get(f"{API}/schools/{sid}/students/{student['id']}/attendance",
                            headers=hm)).json()
    assert any(a["status"] == "present" for a in att)

    # 3) Homework (Homework ↔ Academic/Student).
    assignment = (await client.post(f"{API}/schools/{sid}/homework/assignments", headers=hm, json={
        "section_id": ac["section_id"], "subject_id": ac["subject_id"],
        "title": "Worksheet 1", "due_date": "2026-07-10", "max_marks": 10})).json()
    sh = await login(client, student["email"], student["password"])
    sub = (await client.post(
        f"{API}/schools/{sid}/homework/assignments/{assignment['id']}/submissions",
        headers=sh, json={"content": "done", "submitted_on": "2026-07-05"})).json()
    graded = (await client.patch(
        f"{API}/schools/{sid}/homework/submissions/{sub['id']}/grade",
        headers=hm, json={"marks_obtained": 9, "feedback": "Great"})).json()
    assert graded["status"] == "graded" and graded["marks_obtained"] == 9

    # 4) Quiz (Quiz ↔ Academic/Student, auto-grading).
    quiz = (await client.post(f"{API}/schools/{sid}/quizzes", headers=hm, json={
        "section_id": ac["section_id"], "subject_id": ac["subject_id"], "title": "Q1"})).json()
    q = (await client.post(f"{API}/schools/{sid}/quizzes/{quiz['id']}/questions", headers=hm,
                           json={"prompt": "2+2?", "question_type": "mcq",
                                 "options": ["3", "4"], "correct_answer": "4", "marks": 5})).json()
    await client.post(f"{API}/schools/{sid}/quizzes/{quiz['id']}/publish", headers=hm)
    attempt = (await client.post(f"{API}/schools/{sid}/quizzes/{quiz['id']}/attempts/submit",
                                 headers=sh,
                                 json={"answers": [{"question_id": q["id"], "response": "4"}]})).json()
    assert attempt["status"] == "graded" and attempt["score"] == 5
    report = (await client.get(f"{API}/schools/{sid}/quizzes/{quiz['id']}/report", headers=hm)).json()
    assert report["graded_count"] == 1 and report["average_score"] == 5

    # 5) Exam → marks → results → report card (Exams ↔ Results ↔ Student).
    exam = (await client.post(f"{API}/schools/{sid}/exams", headers=hm, json={
        "class_id": ac["class_id"], "name": "Final", "start_date": "2026-07-20",
        "end_date": "2026-07-25"})).json()
    paper = (await client.post(f"{API}/schools/{sid}/exams/{exam['id']}/papers", headers=hm,
             json={"subject_id": ac["subject_id"], "max_marks": 100, "pass_marks": 40,
                   "exam_date": "2026-07-21"})).json()
    await client.post(f"{API}/schools/{sid}/exams/papers/{paper['id']}/marks", headers=hm, json={
        "entries": [{"student_id": student["id"], "marks_obtained": 90},
                    {"student_id": peer["id"], "marks_obtained": 30}]})
    results = (await client.post(f"{API}/schools/{sid}/exams/{exam['id']}/results/publish",
                                 headers=hm)).json()
    by_student = {r["student_id"]: r for r in results}
    assert by_student[student["id"]]["status"] == "pass"
    assert by_student[peer["id"]]["status"] == "fail"

    card = (await client.get(
        f"{API}/schools/{sid}/exams/{exam['id']}/students/{student['id']}/report-card",
        headers=hm)).json()
    assert card["percentage"] == 90

    # 6) Merit list ranks the passer first (Promotion/Reports ↔ Results).
    merit = (await client.get(f"{API}/schools/{sid}/exams/{exam['id']}/merit-list",
                              headers=hm)).json()
    assert merit[0]["student_id"] == student["id"] and merit[0]["rank"] == 1

    # 7) Admit card + seating reference the same exam (Exams integration).
    await client.post(f"{API}/schools/{sid}/exams/{exam['id']}/seating/generate", headers=hm,
                      json={"rooms": [{"name": "Hall 1", "capacity": 5}]})
    admit = (await client.get(
        f"{API}/schools/{sid}/exams/{exam['id']}/students/{student['id']}/admit-card",
        headers=hm)).json()
    assert admit["exam_name"] == "Final" and admit["room"] == "Hall 1"

    # 8) Promotion from the exam result (Promotion ↔ Exams ↔ Academic/Student).
    prev = (await client.get(f"{API}/schools/{sid}/promotions/preview", headers=hm,
                             params={"exam_id": exam["id"]})).json()
    suggested = {r["student_id"]: r["suggested_outcome"] for r in prev}
    assert suggested[student["id"]] == "promoted"
    assert suggested[peer["id"]] == "retained"

    _, next_section = await _next_class_section(client, sid, hm)
    await client.post(f"{API}/schools/{sid}/promotions", headers=hm, json={
        "exam_id": exam["id"],
        "items": [{"student_id": student["id"], "to_section_id": next_section, "outcome": "promoted"},
                  {"student_id": peer["id"], "outcome": "retained"}]})
    new_roster = (await client.get(
        f"{API}/schools/{sid}/sections/{next_section}/students", headers=hm)).json()
    assert any(e["student_id"] == student["id"] for e in new_roster)
    # Promotion report captures the decision.
    promo_report = (await client.get(f"{API}/schools/{sid}/promotions", headers=hm)).json()
    assert {p["student_id"]: p["outcome"] for p in promo_report}[peer["id"]] == "retained"


async def test_scenario_guardian_360_view(client, school):
    """A guardian linked to a child can read that child's data across modules,
    but only their own child's — the cross-module access scoping."""
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)

    child = await create_user(client, sid, hm, "student")
    other = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], child["id"])
    await enroll(client, sid, hm, ac["section_id"], other["id"])

    guardian = await create_user(client, sid, hm, "guardian")
    gh = await login(client, guardian["email"], guardian["password"])
    link = await client.post(f"{API}/schools/{sid}/guardians/{guardian['id']}/children",
                             headers=hm, json={"student_id": child["id"], "relationship": "mother"})
    assert link.status_code == 201, link.text

    # Guardian self-service sees exactly their child.
    mine = (await client.get(f"{API}/schools/{sid}/me/children", headers=gh)).json()
    assert [c["student_id"] for c in mine] == [child["id"]]

    # Attendance recorded for the child is readable by the guardian...
    await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json={
        "section_id": ac["section_id"], "attendance_date": "2026-07-02",
        "entries": [{"student_id": child["id"], "status": "present"}]})
    ok = await client.get(f"{API}/schools/{sid}/students/{child['id']}/attendance", headers=gh)
    assert ok.status_code == 200 and len(ok.json()) == 1

    # ...but the guardian cannot read a child that isn't theirs (scoping).
    denied = await client.get(f"{API}/schools/{sid}/students/{other['id']}/attendance", headers=gh)
    assert denied.status_code == 403

    # A document attached to the child is visible to the guardian.
    await client.post(f"{API}/schools/{sid}/students/{child['id']}/documents", headers=hm,
                      json={"title": "Report", "file_url": "https://f/r.pdf"})
    docs = await client.get(f"{API}/schools/{sid}/students/{child['id']}/documents", headers=gh)
    assert docs.status_code == 200 and len(docs.json()) == 1


async def test_scenario_fees_calendar_and_lessons(client, school):
    """Finance + planning surfaces interconnect with the academic core."""
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])

    # Fee lifecycle (Fees ↔ Student): invoice → payment → receipt.
    inv = (await client.post(f"{API}/schools/{sid}/fees/invoices", headers=hm, json={
        "student_id": student["id"], "title": "Term Fee", "amount": 5000,
        "due_date": "2026-08-01"})).json()
    await client.post(f"{API}/schools/{sid}/fees/invoices/{inv['id']}/payments", headers=hm,
                      json={"amount": 5000, "method": "cash", "paid_on": "2026-07-15"})
    paid = (await client.get(f"{API}/schools/{sid}/fees/invoices/{inv['id']}", headers=hm)).json()
    assert paid["status"] == "paid" and paid["balance"] == 0
    receipt = await client.get(f"{API}/schools/{sid}/fees/invoices/{inv['id']}/receipt", headers=hm)
    assert receipt.status_code == 200

    # Calendar exam-schedule feed reflects a scheduled exam (Calendar ↔ Exams).
    await client.post(f"{API}/schools/{sid}/exams", headers=hm, json={
        "class_id": ac["class_id"], "name": "Monthly Test",
        "start_date": "2026-08-05", "end_date": "2026-08-06"})
    feed = (await client.get(f"{API}/schools/{sid}/calendar/exam-schedule", headers=hm)).json()
    assert any(e["title"] == "Monthly Test" and e["event_type"] == "exam" for e in feed)

    # A holiday and the exam window can both be listed for the term (Calendar).
    await client.post(f"{API}/schools/{sid}/calendar/events", headers=hm, json={
        "title": "Summer Break", "event_type": "holiday", "start_date": "2026-08-10",
        "end_date": "2026-08-20"})
    events = (await client.get(f"{API}/schools/{sid}/calendar/events", headers=hm,
                               params={"event_type": "holiday"})).json()
    assert [e["title"] for e in events] == ["Summer Break"]

    # Lesson planning progresses for the same section+subject (Lessons ↔ Academic).
    await client.post(f"{API}/schools/{sid}/lessons", headers=hm, json={
        "section_id": ac["section_id"], "subject_id": ac["subject_id"],
        "title": "Chapter 1", "status": "completed", "progress_percent": 100})
    await client.post(f"{API}/schools/{sid}/lessons", headers=hm, json={
        "section_id": ac["section_id"], "subject_id": ac["subject_id"],
        "title": "Chapter 2", "progress_percent": 40})
    prog = (await client.get(f"{API}/schools/{sid}/lessons/progress", headers=hm,
                             params={"section_id": ac["section_id"],
                                     "subject_id": ac["subject_id"]})).json()
    assert prog["total_lessons"] == 2 and prog["completed_lessons"] == 1
    assert prog["average_progress"] == 70.0
