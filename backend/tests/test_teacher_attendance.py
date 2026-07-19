"""HR — teacher attendance marking + daily roster."""
from app.core.config import settings

from tests.utils import create_user

API = settings.API_V1_PREFIX


async def test_teacher_attendance_mark_and_roster(client, school):
    """Upsert per teacher+date, aggregate day view with status filter."""
    sid, hm = school["id"], school["hm"]

    t1 = await create_user(client, sid, hm, "teacher", full_name="Ana Silva")
    t2 = await create_user(client, sid, hm, "teacher", full_name="Ben Osei")
    t3 = await create_user(client, sid, hm, "teacher", full_name="Chi Wong")

    day = "2026-07-19"

    # First mark: t1 present, t2 late with arrival, t3 absent.
    r = await client.post(f"{API}/schools/{sid}/hr/attendance", headers=hm, json={
        "entries": [
            {"teacher_id": t1["id"], "attendance_date": day, "status": "present",
             "arrival_time": "08:00"},
            {"teacher_id": t2["id"], "attendance_date": day, "status": "late",
             "arrival_time": "09:15"},
            {"teacher_id": t3["id"], "attendance_date": day, "status": "absent"},
        ]
    })
    assert r.status_code == 200, r.text
    out = r.json()
    assert len(out) == 3
    assert {row["status"] for row in out} == {"present", "late", "absent"}

    # Day roster reflects the marks + counts.
    q = await client.get(
        f"{API}/schools/{sid}/hr/attendance?date={day}", headers=hm,
    )
    assert q.status_code == 200
    day_view = q.json()
    assert day_view["total_teachers"] == 3
    assert day_view["present"] == 1
    assert day_view["late"] == 1
    assert day_view["absent"] == 1
    assert day_view["unmarked"] == 0
    names = {e["teacher_name"]: e for e in day_view["entries"]}
    assert names["Ana Silva"]["status"] == "present"
    assert names["Ben Osei"]["arrival_time"].startswith("09:15")

    # Upsert: re-mark t3 as present — old record replaced, not duplicated.
    r2 = await client.post(f"{API}/schools/{sid}/hr/attendance", headers=hm, json={
        "entries": [
            {"teacher_id": t3["id"], "attendance_date": day, "status": "present",
             "arrival_time": "08:20"},
        ]
    })
    assert r2.status_code == 200
    updated = await client.get(
        f"{API}/schools/{sid}/hr/attendance?date={day}", headers=hm,
    )
    du = updated.json()
    assert du["present"] == 2
    assert du["absent"] == 0

    # Status filter (late only).
    q_late = await client.get(
        f"{API}/schools/{sid}/hr/attendance?date={day}&status=late",
        headers=hm,
    )
    entries = q_late.json()["entries"]
    assert len(entries) == 1
    assert entries[0]["teacher_name"] == "Ben Osei"


async def test_payslip_absence_deduction(client, school):
    """Payslip snapshots the month's attendance and only deducts when asked.

    Deduction basis is base_salary / 30 per absent day.
    """
    sid, hm = school["id"], school["hm"]
    teacher = await create_user(client, sid, hm, "teacher", full_name="Dee Rao")

    # 30,000/mo -> 1,000 per absent day.
    profile = (await client.post(f"{API}/schools/{sid}/hr/staff", headers=hm, json={
        "user_id": teacher["id"], "designation": "Teacher", "base_salary": 30000,
    })).json()

    # 2 absences + 1 late + 1 present in Mar 2026.
    await client.post(f"{API}/schools/{sid}/hr/attendance", headers=hm, json={
        "entries": [
            {"teacher_id": teacher["id"], "attendance_date": "2026-03-02", "status": "absent"},
            {"teacher_id": teacher["id"], "attendance_date": "2026-03-03", "status": "absent"},
            {"teacher_id": teacher["id"], "attendance_date": "2026-03-04", "status": "late",
             "arrival_time": "09:30"},
            {"teacher_id": teacher["id"], "attendance_date": "2026-03-05", "status": "present"},
        ]
    })

    # Summary endpoint projects the deduction without applying it.
    s = await client.get(
        f"{API}/schools/{sid}/hr/teachers/{teacher['id']}/attendance-summary"
        f"?month=3&year=2026",
        headers=hm,
    )
    assert s.status_code == 200, s.text
    summary = s.json()
    assert summary["absent_days"] == 2
    assert summary["late_days"] == 1
    assert summary["present_days"] == 1
    assert summary["marked_days"] == 4
    assert summary["projected_absence_deduction"] == 2000

    # deduct_absences=False -> counts snapshotted, nothing deducted.
    no_deduct = (await client.post(
        f"{API}/schools/{sid}/hr/staff/{profile['id']}/payslips", headers=hm,
        json={"period_month": 3, "period_year": 2026, "deduct_absences": False},
    )).json()
    assert no_deduct["absent_days"] == 2
    assert no_deduct["late_days"] == 1
    assert no_deduct["absence_deduction"] == 0
    assert no_deduct["net"] == 30000

    # Same teacher, different month, with the toggle on.
    await client.post(f"{API}/schools/{sid}/hr/attendance", headers=hm, json={
        "entries": [
            {"teacher_id": teacher["id"], "attendance_date": "2026-04-02", "status": "absent"},
            {"teacher_id": teacher["id"], "attendance_date": "2026-04-03", "status": "absent"},
            {"teacher_id": teacher["id"], "attendance_date": "2026-04-06", "status": "absent"},
        ]
    })
    deducted = (await client.post(
        f"{API}/schools/{sid}/hr/staff/{profile['id']}/payslips", headers=hm,
        json={"period_month": 4, "period_year": 2026, "deduct_absences": True,
              "allowances": 2000, "deductions": 500},
    )).json()
    assert deducted["absent_days"] == 3
    assert deducted["absence_deduction"] == 3000       # 30000/30 * 3
    assert deducted["gross"] == 32000                  # base + allowances
    assert deducted["deductions"] == 3500              # manual 500 + absence 3000
    assert deducted["net"] == 28500


async def test_teacher_attendance_rejects_non_teacher(client, school):
    """Marking someone who isn't a teacher of the school is a 400."""
    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    r = await client.post(f"{API}/schools/{sid}/hr/attendance", headers=hm, json={
        "entries": [
            {"teacher_id": student["id"], "attendance_date": "2026-07-19",
             "status": "present"},
        ]
    })
    assert r.status_code == 400, r.text
