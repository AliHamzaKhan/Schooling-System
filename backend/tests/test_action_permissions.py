"""Per-action permission depth.

The cascade tests prove which *modules* a role can reach; these prove the
*action* split within a reachable module — a role that can view a module must
not necessarily create in it.
"""
from app.core.config import settings

from tests.utils import create_user, login, make_academics

API = settings.API_V1_PREFIX


async def test_teacher_views_but_cannot_create_classes(client, school):
    """Teacher has TIMETABLE view (→ academic read) but no create."""
    sid, hm = school["id"], school["hm"]
    teacher = await create_user(client, sid, hm, "teacher")
    th = await login(client, teacher["email"], teacher["password"])

    assert (await client.get(f"{API}/schools/{sid}/academic/classes", headers=th)).status_code == 200
    created = await client.post(
        f"{API}/schools/{sid}/academic/classes", headers=th, json={"name": "G2", "level": 2}
    )
    assert created.status_code == 403


async def test_student_views_but_cannot_create_assignments(client, school):
    """Student has HOMEWORK view but no create."""
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    sh = await login(client, student["email"], student["password"])

    assert (await client.get(f"{API}/schools/{sid}/homework/assignments", headers=sh)).status_code == 200
    created = await client.post(
        f"{API}/schools/{sid}/homework/assignments", headers=sh,
        json={"section_id": ac["section_id"], "subject_id": ac["subject_id"],
              "title": "X", "due_date": "2026-12-01"},
    )
    assert created.status_code == 403
