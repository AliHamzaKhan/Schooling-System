"""F01.7 lifecycle boundaries for exams, results, quizzes and attempts."""

from app.core.config import settings

from tests.test_broadcast_isolation import another_school
from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def test_exam_and_quiz_nested_ids_cannot_cross_schools(client, school):
    sid, hm = school["id"], school["hm"]
    own = await make_academics(client, sid, hm)
    other_sid = await another_school(client, school["sa"])
    foreign = await make_academics(client, other_sid, school["sa"])

    exam = await client.post(
        f"{API}/schools/{sid}/exams", headers=hm,
        json={"class_id": own["class_id"], "name": "Boundaries"},
    )
    assert exam.status_code == 201, exam.text
    exam_id = exam.json()["id"]
    paper = await client.post(
        f"{API}/schools/{sid}/exams/{exam_id}/papers", headers=hm,
        json={"subject_id": foreign["subject_id"], "max_marks": 10, "pass_marks": 4},
    )
    assert paper.status_code == 404

    quiz = await client.post(
        f"{API}/schools/{sid}/quizzes", headers=hm,
        json={"section_id": foreign["section_id"], "subject_id": own["subject_id"], "title": "No leak"},
    )
    assert quiz.status_code == 404


async def test_student_cannot_read_draft_quiz_or_other_attempts(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    quiz = await client.post(
        f"{API}/schools/{sid}/quizzes", headers=hm,
        json={"section_id": ac["section_id"], "subject_id": ac["subject_id"], "title": "Draft"},
    )
    assert quiz.status_code == 201
    sh = await login(client, student["email"], student["password"])
    detail = await client.get(f"{API}/schools/{sid}/quizzes/{quiz.json()['id']}", headers=sh)
    assert detail.status_code == 404
    attempts = await client.get(f"{API}/schools/{sid}/quizzes/{quiz.json()['id']}/attempts", headers=sh)
    assert attempts.status_code == 403


async def test_quiz_rejects_answers_from_another_quiz(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])

    async def make_quiz(title):
        response = await client.post(
            f"{API}/schools/{sid}/quizzes", headers=hm,
            json={"section_id": ac["section_id"], "subject_id": ac["subject_id"], "title": title},
        )
        assert response.status_code == 201
        question = await client.post(
            f"{API}/schools/{sid}/quizzes/{response.json()['id']}/questions", headers=hm,
            json={"prompt": "1+1", "question_type": "mcq", "options": ["1", "2"], "correct_answer": "2"},
        )
        assert question.status_code == 201
        await client.post(f"{API}/schools/{sid}/quizzes/{response.json()['id']}/publish", headers=hm)
        return response.json(), question.json()

    first, _ = await make_quiz("First")
    _, foreign_question = await make_quiz("Second")
    sh = await login(client, student["email"], student["password"])
    response = await client.post(
        f"{API}/schools/{sid}/quizzes/{first['id']}/attempts/submit", headers=sh,
        json={"answers": [{"question_id": foreign_question["id"], "response": "2"}]},
    )
    assert response.status_code == 400
