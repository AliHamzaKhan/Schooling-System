"""Leave: subject-student resolution, guardian-for-child, class-teacher review."""
from app.core.config import settings

from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def _set_class_teacher(client, sid, hm, section_id, teacher_id):
    r = await client.patch(
        f"{API}/schools/{sid}/academic/sections/{section_id}",
        headers=hm,
        json={"class_teacher_id": teacher_id},
    )
    assert r.status_code == 200, r.text


async def _submit(client, sid, headers, **body):
    body.setdefault("start_date", "2026-09-01")
    body.setdefault("end_date", "2026-09-02")
    return await client.post(
        f"{API}/schools/{sid}/leave/requests", headers=headers, json=body
    )


async def test_student_request_targets_self(client, school):
    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    sh = await login(client, student["email"], student["password"])
    r = await _submit(client, sid, sh, leave_type="sick", reason="Flu")
    assert r.status_code == 201, r.text
    assert r.json()["student_id"] == student["id"]


async def test_guardian_must_pick_own_child(client, school):
    sid, hm = school["id"], school["hm"]
    child = await create_user(client, sid, hm, "student")
    stranger = await create_user(client, sid, hm, "student")
    guardian = await create_user(client, sid, hm, "guardian")
    # Link guardian -> child.
    await client.post(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children",
        headers=hm,
        json={"student_id": child["id"], "relationship": "father"},
    )
    gh = await login(client, guardian["email"], guardian["password"])

    # No child id -> 400.
    r0 = await _submit(client, sid, gh, leave_type="family")
    assert r0.status_code == 400

    # Someone else's child -> 403.
    r1 = await _submit(client, sid, gh, student_id=stranger["id"])
    assert r1.status_code == 403

    # Own child -> 201, subject is the child.
    r2 = await _submit(client, sid, gh, student_id=child["id"], reason="Trip")
    assert r2.status_code == 201, r2.text
    assert r2.json()["student_id"] == child["id"]


async def test_class_teacher_review_scope_and_approve(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    teacher = await create_user(client, sid, hm, "teacher")
    await _set_class_teacher(client, sid, hm, ac["section_id"], teacher["id"])
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])

    sh = await login(client, student["email"], student["password"])
    sub = await _submit(client, sid, sh, leave_type="sick")
    leave_id = sub.json()["id"]

    th = await login(client, teacher["email"], teacher["password"])
    q = await client.get(f"{API}/schools/{sid}/leave/requests/for-review", headers=th)
    assert q.status_code == 200
    assert any(x["id"] == leave_id for x in q.json())
    assert q.json()[0]["student_name"]  # name composed

    ap = await client.post(
        f"{API}/schools/{sid}/leave/requests/{leave_id}/approve",
        headers=th,
        json={"note": "ok"},
    )
    assert ap.status_code == 200, ap.text
    assert ap.json()["status"] == "approved"


async def test_unrelated_teacher_sees_nothing(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    sh = await login(client, student["email"], student["password"])
    await _submit(client, sid, sh, leave_type="sick")

    # A teacher who is not the class teacher of any section.
    other = await create_user(client, sid, hm, "teacher")
    oh = await login(client, other["email"], other["password"])
    q = await client.get(f"{API}/schools/{sid}/leave/requests/for-review", headers=oh)
    assert q.status_code == 200
    assert q.json() == []


async def test_headmaster_sees_all(client, school):
    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    sh = await login(client, student["email"], student["password"])
    await _submit(client, sid, sh, leave_type="sick")
    q = await client.get(f"{API}/schools/{sid}/leave/requests/for-review", headers=hm)
    assert q.status_code == 200
    assert len(q.json()) >= 1


async def test_own_leave_pagination_scopes_before_page_window(client, school):
    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    stranger = await create_user(client, sid, hm, "student")
    sh = await login(client, student["email"], student["password"])
    stranger_headers = await login(client, stranger["email"], stranger["password"])

    first = await _submit(client, sid, sh, leave_type="sick", reason="first")
    second = await _submit(client, sid, sh, leave_type="sick", reason="second")
    hidden = await _submit(client, sid, stranger_headers, leave_type="sick", reason="hidden")
    assert first.status_code == second.status_code == hidden.status_code == 201

    all_visible = await client.get(f"{API}/schools/{sid}/leave/requests/mine", headers=sh)
    page_one = await client.get(
        f"{API}/schools/{sid}/leave/requests/mine?limit=1&offset=0", headers=sh
    )
    page_two = await client.get(
        f"{API}/schools/{sid}/leave/requests/mine?limit=1&offset=1", headers=sh
    )
    assert all_visible.status_code == page_one.status_code == page_two.status_code == 200
    visible_ids = [item["id"] for item in all_visible.json()]
    assert visible_ids == [item["id"] for item in page_one.json() + page_two.json()]
    assert hidden.json()["id"] not in visible_ids

    invalid_limit = await client.get(f"{API}/schools/{sid}/leave/requests/mine?limit=101", headers=sh)
    invalid_offset = await client.get(f"{API}/schools/{sid}/leave/requests/mine?offset=-1", headers=sh)
    assert invalid_limit.status_code == invalid_offset.status_code == 422
