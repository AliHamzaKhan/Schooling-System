"""Direct messages: staff ↔ guardian send, inbox scoping, read receipts."""
from app.core.config import settings

from tests.utils import create_user, enroll, login

API = settings.API_V1_PREFIX


async def test_send_inbox_and_read(client, school):
    sid, hm = school["id"], school["hm"]
    teacher = await create_user(client, sid, hm, "teacher")
    guardian = await create_user(client, sid, hm, "guardian")
    student = await create_user(client, sid, hm, "student")
    grade = (await client.post(f"{API}/schools/{sid}/academic/classes", headers=hm,
                               json={"name": "Family class"})).json()
    section = (await client.post(f"{API}/schools/{sid}/academic/classes/{grade['id']}/sections",
        headers=hm, json={"name": "A", "class_teacher_id": teacher['id']})).json()
    await enroll(client, sid, hm, section['id'], student['id'])
    linked = await client.post(f"{API}/schools/{sid}/guardians/{guardian['id']}/children",
                              headers=hm, json={"student_id": student['id']})
    assert linked.status_code == 201, linked.text
    th = await login(client, teacher["email"], teacher["password"])
    gh = await login(client, guardian["email"], guardian["password"])

    # Teacher sends a message and a complaint to the guardian.
    r = await client.post(
        f"{API}/schools/{sid}/messages",
        headers=th,
        json={"recipient_id": guardian["id"], "body": "Hello!", "kind": "message"},
    )
    assert r.status_code == 201, r.text
    r = await client.post(
        f"{API}/schools/{sid}/messages",
        headers=th,
        json={"recipient_id": guardian["id"], "body": "A concern.", "kind": "complaint"},
    )
    assert r.status_code == 201, r.text
    complaint_id = r.json()["id"]

    # Guardian inbox holds both, newest first, with the sender's name.
    r = await client.get(f"{API}/schools/{sid}/messages", headers=gh)
    assert r.status_code == 200
    inbox = r.json()
    assert [m["kind"] for m in inbox] == ["complaint", "message"]
    assert inbox[0]["sender_name"] == "Teacher User"  # create_user's full_name
    assert all(m["read_at"] is None for m in inbox)

    # The teacher's inbox is empty; their sent box holds both.
    r = await client.get(f"{API}/schools/{sid}/messages", headers=th)
    assert r.json() == []
    r = await client.get(f"{API}/schools/{sid}/messages?box=sent", headers=th)
    assert len(r.json()) == 2

    # Only the recipient can mark a message read.
    r = await client.patch(
        f"{API}/schools/{sid}/messages/{complaint_id}/read", headers=th
    )
    assert r.status_code == 403
    r = await client.patch(
        f"{API}/schools/{sid}/messages/{complaint_id}/read", headers=gh
    )
    assert r.status_code == 200
    assert r.json()["read_at"] is not None


async def _contacts(client, sid, headers):
    r = await client.get(f"{API}/schools/{sid}/messages/contacts", headers=headers)
    assert r.status_code == 200, r.text
    return {c["id"]: c["role"] for c in r.json()}


async def test_contacts_are_scoped_by_role(client, school):
    """student → own teachers only; guardian → child's teachers + headmaster;
    teacher → own students + headmaster; headmaster → everyone."""
    sid, hm = school["id"], school["hm"]

    teacher = await create_user(client, sid, hm, "teacher")  # class teacher
    subject_teacher = await create_user(client, sid, hm, "teacher")  # via timetable
    other_teacher = await create_user(client, sid, hm, "teacher")  # unrelated
    student = await create_user(client, sid, hm, "student")
    guardian = await create_user(client, sid, hm, "guardian")

    # A class + section whose class teacher is `teacher`, with `student` enrolled.
    rc = await client.post(
        f"{API}/schools/{sid}/academic/classes", headers=hm,
        json={"name": "Grade 5", "level": 5},
    )
    cid = rc.json()["id"]
    rs = await client.post(
        f"{API}/schools/{sid}/academic/classes/{cid}/sections", headers=hm,
        json={"name": "A", "class_teacher_id": teacher["id"]},
    )
    section_id = rs.json()["id"]
    await enroll(client, sid, hm, section_id, student["id"])

    # A subject teacher who takes this section via a timetable slot.
    rsub = await client.post(
        f"{API}/schools/{sid}/academic/subjects", headers=hm,
        json={"code": "SCI", "name": "Science"},
    )
    subject_id = rsub.json()["id"]
    r = await client.post(
        f"{API}/schools/{sid}/academic/timetable", headers=hm,
        json={
            "section_id": section_id,
            "subject_id": subject_id,
            "teacher_id": subject_teacher["id"],
            "day_of_week": 0,
            "start_time": "09:00:00",
            "end_time": "09:45:00",
        },
    )
    assert r.status_code == 201, r.text

    # Link the guardian to the student.
    r = await client.post(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children", headers=hm,
        json={"student_id": student["id"], "relationship": "father"},
    )
    assert r.status_code == 201, r.text

    th = await login(client, teacher["email"], teacher["password"])
    sh = await login(client, student["email"], student["password"])
    gh = await login(client, guardian["email"], guardian["password"])

    # Student: every teacher who actually teaches them (class teacher + subject
    # teacher) — no headmaster, no unrelated teacher, no self.
    student_contacts = await _contacts(client, sid, sh)
    assert student_contacts.get(teacher["id"]) == "teacher"
    assert student_contacts.get(subject_teacher["id"]) == "teacher"
    assert other_teacher["id"] not in student_contacts
    assert "headmaster" not in student_contacts.values()
    assert student["id"] not in student_contacts

    # Guardian: the child's teacher + the headmaster (not the unrelated teacher).
    guardian_contacts = await _contacts(client, sid, gh)
    assert guardian_contacts.get(teacher["id"]) == "teacher"
    assert "headmaster" in guardian_contacts.values()
    assert other_teacher["id"] not in guardian_contacts

    # Teacher: their student + the headmaster (not the unrelated teacher).
    teacher_contacts = await _contacts(client, sid, th)
    assert teacher_contacts.get(student["id"]) == "student"
    assert teacher_contacts.get(guardian["id"]) == "guardian"
    assert "headmaster" in teacher_contacts.values()
    assert other_teacher["id"] not in teacher_contacts

    # Headmaster: everyone in the school (all four created users).
    hm_contacts = await _contacts(client, sid, hm)
    for u in (teacher, other_teacher, student, guardian):
        assert u["id"] in hm_contacts


async def test_cannot_message_self(client, school):
    sid, hm = school["id"], school["hm"]
    teacher = await create_user(client, sid, hm, "teacher")
    th = await login(client, teacher["email"], teacher["password"])
    r = await client.post(
        f"{API}/schools/{sid}/messages",
        headers=th,
        json={"recipient_id": teacher["id"], "body": "hi me"},
    )
    assert r.status_code == 400
