"""Happy-path + one guard per remaining module."""
from app.core.config import settings

from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def test_homework_submit_and_grade(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], student["id"])
    assignment = (await client.post(f"{API}/schools/{sid}/homework/assignments", headers=hm, json={
        "section_id": ac["section_id"], "subject_id": ac["subject_id"], "title": "HW1",
        "due_date": "2026-06-20", "max_marks": 10,
    })).json()
    sh = await login(client, student["email"], student["password"])
    sub = await client.post(f"{API}/schools/{sid}/homework/assignments/{assignment['id']}/submissions",
                            headers=sh, json={"content": "done", "submitted_on": "2026-06-18"})
    assert sub.status_code == 201 and sub.json()["status"] == "submitted"
    graded = await client.patch(f"{API}/schools/{sid}/homework/submissions/{sub.json()['id']}/grade",
                                headers=hm, json={"marks_obtained": 9})
    assert graded.json()["status"] == "graded"


async def test_communication_broadcast(client, school):
    sid, hm = school["id"], school["hm"]
    g = await create_user(client, sid, hm, "guardian")
    await client.patch(f"{API}/schools/{sid}/users/{g['id']}", headers=hm, json={"phone": "+15551112222"})
    msg = await client.post(f"{API}/schools/{sid}/communication/broadcasts", headers=hm, json={
        "channel": "whatsapp", "audience_type": "guardians", "body": "Hello",
    })
    assert msg.status_code == 201
    summary = await client.get(f"{API}/schools/{sid}/communication/broadcasts/{msg.json()['id']}/summary", headers=hm)
    assert summary.json()["total"] >= 1


async def test_reports_overview(client, school):
    sid, hm = school["id"], school["hm"]
    await create_user(client, sid, hm, "teacher")
    r = await client.get(f"{API}/schools/{sid}/reports/overview", headers=hm)
    assert r.status_code == 200
    assert r.json()["teachers"] >= 1


async def test_transport_capacity(client, school):
    sid, hm = school["id"], school["hm"]
    vehicle = (await client.post(f"{API}/schools/{sid}/transport/vehicles", headers=hm,
               json={"registration_no": "BUS-1", "capacity": 1})).json()
    route = (await client.post(f"{API}/schools/{sid}/transport/routes", headers=hm,
             json={"name": "R1", "vehicle_id": vehicle["id"]})).json()
    s1 = await create_user(client, sid, hm, "student")
    s2 = await create_user(client, sid, hm, "student")
    ok = await client.post(f"{API}/schools/{sid}/transport/assignments", headers=hm,
                           json={"student_id": s1["id"], "route_id": route["id"]})
    assert ok.status_code == 201
    full = await client.post(f"{API}/schools/{sid}/transport/assignments", headers=hm,
                             json={"student_id": s2["id"], "route_id": route["id"]})
    assert full.status_code == 400


async def test_hr_payslip(client, school):
    sid, hm = school["id"], school["hm"]
    teacher = await create_user(client, sid, hm, "teacher")
    profile = (await client.post(f"{API}/schools/{sid}/hr/staff", headers=hm,
               json={"user_id": teacher["id"], "designation": "Teacher", "base_salary": 1000})).json()
    slip = await client.post(f"{API}/schools/{sid}/hr/staff/{profile['id']}/payslips", headers=hm,
                             json={"period_month": 6, "period_year": 2026, "allowances": 200, "deductions": 100})
    assert slip.status_code == 201
    assert slip.json()["net"] == 1100


async def test_inventory_stock(client, school):
    sid, hm = school["id"], school["hm"]
    item = (await client.post(f"{API}/schools/{sid}/inventory/items", headers=hm,
            json={"name": "Chalk", "reorder_level": 5})).json()
    await client.post(f"{API}/schools/{sid}/inventory/items/{item['id']}/movements", headers=hm,
                      json={"type": "in", "quantity": 3})
    out = await client.post(f"{API}/schools/{sid}/inventory/items/{item['id']}/movements", headers=hm,
                            json={"type": "out", "quantity": 5})
    assert out.status_code == 400  # only 3 available


async def test_ai_generate_stub(client, school):
    sid, hm = school["id"], school["hm"]
    r = await client.post(f"{API}/schools/{sid}/ai/generate", headers=hm,
                          json={"feature": "summary", "prompt": "Summarize term 1"})
    assert r.status_code == 201
    assert r.json()["provider"] == "stub"


async def test_leave_submit_and_approve(client, school):
    sid, hm = school["id"], school["hm"]
    teacher = await create_user(client, sid, hm, "teacher")
    th = await login(client, teacher["email"], teacher["password"])
    leave = await client.post(f"{API}/schools/{sid}/leave/requests", headers=th,
                              json={"start_date": "2026-06-20", "end_date": "2026-06-21", "reason": "x"})
    assert leave.status_code == 201
    # Teacher cannot list all leave.
    assert (await client.get(f"{API}/schools/{sid}/leave/requests", headers=th)).status_code == 403
    approved = await client.post(f"{API}/schools/{sid}/leave/requests/{leave.json()['id']}/approve",
                                 headers=hm, json={"note": "ok"})
    assert approved.json()["status"] == "approved"


async def test_meeting_schedule(client, school):
    sid, hm = school["id"], school["hm"]
    teacher = await create_user(client, sid, hm, "teacher")
    guardian = await create_user(client, sid, hm, "guardian")
    r = await client.post(f"{API}/schools/{sid}/meetings", headers=hm, json={
        "title": "PT Meeting", "teacher_id": teacher["id"], "guardian_id": guardian["id"],
        "scheduled_at": "2026-06-25T10:00:00Z",
    })
    assert r.status_code == 201 and r.json()["status"] == "scheduled"
