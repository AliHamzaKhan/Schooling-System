"""Student documents, lesson planning/progress, and assignment approve/reject."""
from app.core.config import settings

from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


# ------------------------------ documents ------------------------------- #


async def test_student_document_add_list_delete(client, school):
    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    add = await client.post(
        f"{API}/schools/{sid}/students/{student['id']}/documents", headers=hm,
        json={"title": "Birth Certificate", "doc_type": "certificate",
              "file_url": "https://files.example/bc.pdf"})
    assert add.status_code == 201, add.text

    listing = await client.get(
        f"{API}/schools/{sid}/students/{student['id']}/documents", headers=hm)
    assert listing.status_code == 200
    assert len(listing.json()) == 1

    doc_id = add.json()["id"]
    d = await client.delete(
        f"{API}/schools/{sid}/students/{student['id']}/documents/{doc_id}", headers=hm)
    assert d.status_code == 204


# ------------------------------- lessons -------------------------------- #


async def test_lesson_plan_and_progress(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)

    l1 = await client.post(f"{API}/schools/{sid}/lessons", headers=hm, json={
        "section_id": ac["section_id"], "subject_id": ac["subject_id"],
        "title": "Intro to Algebra", "progress_percent": 50})
    assert l1.status_code == 201, l1.text
    l2 = (await client.post(f"{API}/schools/{sid}/lessons", headers=hm, json={
        "section_id": ac["section_id"], "subject_id": ac["subject_id"],
        "title": "Equations"})).json()

    # Mark the second lesson completed -> progress forced to 100.
    up = await client.patch(f"{API}/schools/{sid}/lessons/{l2['id']}", headers=hm,
                            json={"status": "completed"})
    assert up.json()["progress_percent"] == 100

    prog = await client.get(f"{API}/schools/{sid}/lessons/progress", headers=hm,
                            params={"section_id": ac["section_id"], "subject_id": ac["subject_id"]})
    assert prog.status_code == 200, prog.text
    body = prog.json()
    assert body["total_lessons"] == 2
    assert body["completed_lessons"] == 1
    assert body["average_progress"] == 75.0  # (50 + 100) / 2


# --------------------------- assignment review -------------------------- #


async def test_assignment_approve_reject(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    assignment = (await client.post(f"{API}/schools/{sid}/homework/assignments", headers=hm, json={
        "section_id": ac["section_id"], "subject_id": ac["subject_id"],
        "title": "Essay", "due_date": "2026-06-20", "max_marks": 10})).json()

    sh = await login(client, student["email"], student["password"])
    sub = (await client.post(
        f"{API}/schools/{sid}/homework/assignments/{assignment['id']}/submissions",
        headers=sh, json={"content": "my essay", "submitted_on": "2026-06-18"})).json()

    r = await client.patch(f"{API}/schools/{sid}/homework/submissions/{sub['id']}/review",
                           headers=hm, json={"approved": False, "feedback": "Redo section 2"})
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "rejected"
    assert r.json()["feedback"] == "Redo section 2"

    r = await client.patch(f"{API}/schools/{sid}/homework/submissions/{sub['id']}/review",
                           headers=hm, json={"approved": True})
    assert r.json()["status"] == "approved"
