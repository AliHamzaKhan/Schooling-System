"""Quiz authoring, attempts, and grading rules.

Covers the risky logic: publishing requires questions, objective questions are
auto-graded on submission, short answers stay pending until manual grading, and
only enrolled students can attempt.
"""
from app.core.config import settings

from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def _quiz(client, sid, hm, section_id, subject_id):
    r = await client.post(
        f"{API}/schools/{sid}/quizzes",
        headers=hm,
        json={"section_id": section_id, "subject_id": subject_id, "title": "Pop Quiz"},
    )
    assert r.status_code == 201, r.text
    return r.json()


async def _question(client, sid, hm, quiz_id, **body):
    r = await client.post(
        f"{API}/schools/{sid}/quizzes/{quiz_id}/questions", headers=hm, json=body
    )
    assert r.status_code == 201, r.text
    return r.json()


async def test_cannot_publish_without_questions(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    quiz = await _quiz(client, sid, hm, ac["section_id"], ac["subject_id"])
    r = await client.post(f"{API}/schools/{sid}/quizzes/{quiz['id']}/publish", headers=hm)
    assert r.status_code == 400


async def test_objective_questions_autograded(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    quiz = await _quiz(client, sid, hm, ac["section_id"], ac["subject_id"])
    q1 = await _question(
        client, sid, hm, quiz["id"],
        prompt="2+2?", question_type="mcq",
        options=["3", "4", "5"], correct_answer="4", marks=2,
    )
    q2 = await _question(
        client, sid, hm, quiz["id"],
        prompt="Sky is blue?", question_type="true_false",
        correct_answer="true", marks=1,
    )
    r = await client.post(f"{API}/schools/{sid}/quizzes/{quiz['id']}/publish", headers=hm)
    assert r.status_code == 200

    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    sh = await login(client, student["email"], student["password"])

    r = await client.post(
        f"{API}/schools/{sid}/quizzes/{quiz['id']}/attempts/submit",
        headers=sh,
        json={"answers": [
            {"question_id": q1["id"], "response": "4"},
            {"question_id": q2["id"], "response": "false"},
        ]},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    # 2 marks for the correct MCQ, 0 for the wrong true/false; fully auto-graded.
    assert body["status"] == "graded"
    assert body["score"] == 2


async def test_submit_retry_returns_saved_attempt_without_replacing_answers(client, school):
    """A lost successful response must be safely retryable by the student."""
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    quiz = await _quiz(client, sid, hm, ac["section_id"], ac["subject_id"])
    question = await _question(
        client, sid, hm, quiz["id"],
        prompt="2+2?", question_type="mcq", options=["3", "4"], correct_answer="4", marks=2,
    )
    await client.post(f"{API}/schools/{sid}/quizzes/{quiz['id']}/publish", headers=hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    sh = await login(client, student["email"], student["password"])

    first = await client.post(
        f"{API}/schools/{sid}/quizzes/{quiz['id']}/attempts/submit",
        headers=sh,
        json={"answers": [{"question_id": question["id"], "response": "4"}]},
    )
    assert first.status_code == 200, first.text
    saved = first.json()

    retry = await client.post(
        f"{API}/schools/{sid}/quizzes/{quiz['id']}/attempts/submit",
        headers=sh,
        # A changed retry payload cannot alter a completed attempt.
        json={"answers": [{"question_id": question["id"], "response": "3"}]},
    )
    assert retry.status_code == 200, retry.text
    replayed = retry.json()
    assert replayed["id"] == saved["id"]
    assert replayed["status"] == "graded"
    assert replayed["score"] == 2
    assert replayed["answers"][0]["response"] == "4"


async def test_short_answer_pending_then_manual_grade(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    quiz = await _quiz(client, sid, hm, ac["section_id"], ac["subject_id"])
    q1 = await _question(
        client, sid, hm, quiz["id"],
        prompt="Explain gravity", question_type="short", marks=5,
    )
    await client.post(f"{API}/schools/{sid}/quizzes/{quiz['id']}/publish", headers=hm)

    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    sh = await login(client, student["email"], student["password"])

    r = await client.post(
        f"{API}/schools/{sid}/quizzes/{quiz['id']}/attempts/submit",
        headers=sh,
        json={"answers": [{"question_id": q1["id"], "response": "mass attracts mass"}]},
    )
    assert r.status_code == 200, r.text
    attempt = r.json()
    assert attempt["status"] == "submitted"  # awaiting manual grade
    answer_id = attempt["answers"][0]["id"]

    r = await client.patch(
        f"{API}/schools/{sid}/quizzes/attempts/{attempt['id']}/grade",
        headers=hm,
        json={"grades": [{"answer_id": answer_id, "marks_awarded": 4, "is_correct": True}]},
    )
    assert r.status_code == 200, r.text
    graded = r.json()
    assert graded["status"] == "graded"
    assert graded["score"] == 4


async def test_unenrolled_student_cannot_attempt(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    quiz = await _quiz(client, sid, hm, ac["section_id"], ac["subject_id"])
    q1 = await _question(
        client, sid, hm, quiz["id"],
        prompt="1+1?", question_type="mcq", options=["1", "2"], correct_answer="2",
    )
    await client.post(f"{API}/schools/{sid}/quizzes/{quiz['id']}/publish", headers=hm)

    student = await create_user(client, sid, hm, "student")  # NOT enrolled
    sh = await login(client, student["email"], student["password"])
    r = await client.post(
        f"{API}/schools/{sid}/quizzes/{quiz['id']}/attempts/submit",
        headers=sh,
        json={"answers": [{"question_id": q1["id"], "response": "2"}]},
    )
    assert r.status_code == 403


async def test_answer_key_hidden_from_students(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    quiz = await _quiz(client, sid, hm, ac["section_id"], ac["subject_id"])
    await _question(
        client, sid, hm, quiz["id"],
        prompt="2+2?", question_type="mcq", options=["3", "4"], correct_answer="4", marks=1,
    )
    await client.post(f"{API}/schools/{sid}/quizzes/{quiz['id']}/publish", headers=hm)

    # The author (HOMEWORK edit) sees the answer key.
    r = await client.get(f"{API}/schools/{sid}/quizzes/{quiz['id']}", headers=hm)
    assert r.status_code == 200
    assert r.json()["questions"][0]["correct_answer"] == "4"

    # A student sees the question but never the answer.
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    sh = await login(client, student["email"], student["password"])
    r = await client.get(f"{API}/schools/{sid}/quizzes/{quiz['id']}", headers=sh)
    assert r.status_code == 200, r.text
    q = r.json()["questions"][0]
    assert q["prompt"] == "2+2?"
    assert q["correct_answer"] is None


async def test_targeted_assignment_scoped_and_performance(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    s1 = await create_user(client, sid, hm, "student")
    s2 = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], s1["id"])
    await enroll(client, sid, hm, ac["section_id"], s2["id"])

    # Quiz targeted at s1 only.
    r = await client.post(
        f"{API}/schools/{sid}/quizzes",
        headers=hm,
        json={
            "section_id": ac["section_id"],
            "subject_id": ac["subject_id"],
            "title": "Targeted",
            "assignee_ids": [s1["id"]],
        },
    )
    assert r.status_code == 201, r.text
    quiz = r.json()
    q1 = await _question(
        client, sid, hm, quiz["id"],
        prompt="2+2?", question_type="mcq", options=["3", "4"], correct_answer="4", marks=1,
    )
    await client.post(f"{API}/schools/{sid}/quizzes/{quiz['id']}/publish", headers=hm)

    h1 = await login(client, s1["email"], s1["password"])
    h2 = await login(client, s2["email"], s2["password"])

    # s1 sees the targeted quiz; s2 (same section, not targeted) does not.
    r1 = await client.get(f"{API}/schools/{sid}/quizzes/assigned", headers=h1)
    r2 = await client.get(f"{API}/schools/{sid}/quizzes/assigned", headers=h2)
    assert quiz["id"] in [q["id"] for q in r1.json()]
    assert quiz["id"] not in [q["id"] for q in r2.json()]

    # s2 cannot attempt a quiz not assigned to them.
    r = await client.post(
        f"{API}/schools/{sid}/quizzes/{quiz['id']}/attempts/submit",
        headers=h2,
        json={"answers": [{"question_id": q1["id"], "response": "4"}]},
    )
    assert r.status_code == 403

    # s1 attempts and is auto-scored.
    r = await client.post(
        f"{API}/schools/{sid}/quizzes/{quiz['id']}/attempts/submit",
        headers=h1,
        json={"answers": [{"question_id": q1["id"], "response": "4"}]},
    )
    assert r.status_code == 200, r.text

    # Performance roster = the assignee only, with the score.
    r = await client.get(f"{API}/schools/{sid}/quizzes/{quiz['id']}/performance", headers=hm)
    assert r.status_code == 200, r.text
    rows = r.json()["rows"]
    assert len(rows) == 1
    assert rows[0]["score"] == 1
    assert rows[0]["submitted"] is True
