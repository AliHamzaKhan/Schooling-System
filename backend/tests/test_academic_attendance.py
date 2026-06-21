"""Academic structure and attendance tests."""
from app.core.config import settings

from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def test_timetable_clash_detection(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    base = {"section_id": ac["section_id"], "subject_id": ac["subject_id"], "day_of_week": 0}
    r1 = await client.post(f"{API}/schools/{sid}/academic/timetable", headers=hm,
                           json={**base, "start_time": "09:00", "end_time": "10:00"})
    assert r1.status_code == 201
    # Overlapping slot for the same section -> clash.
    r2 = await client.post(f"{API}/schools/{sid}/academic/timetable", headers=hm,
                           json={**base, "start_time": "09:30", "end_time": "10:30"})
    assert r2.status_code == 400
    # Adjacent (non-overlapping) slot is fine.
    r3 = await client.post(f"{API}/schools/{sid}/academic/timetable", headers=hm,
                           json={**base, "start_time": "10:00", "end_time": "11:00"})
    assert r3.status_code == 201


async def test_attendance_upsert_and_enrollment_guard(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    s1 = await create_user(client, sid, hm, "student")
    s2 = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], s1["id"])
    # s2 is NOT enrolled.

    mark = {
        "section_id": ac["section_id"], "attendance_date": "2026-06-18",
        "entries": [{"student_id": s1["id"], "status": "present"}],
    }
    r = await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json=mark)
    assert r.status_code == 201

    # Re-mark same student/date -> upsert (no duplicate).
    mark["entries"] = [{"student_id": s1["id"], "status": "late"}]
    await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json=mark)
    summary = await client.get(
        f"{API}/schools/{sid}/attendance/summary",
        headers=hm, params={"section_id": ac["section_id"], "attendance_date": "2026-06-18"},
    )
    assert summary.json()["total"] == 1
    assert summary.json()["counts"]["late"] == 1

    # Marking a non-enrolled student -> 400.
    bad = await client.post(f"{API}/schools/{sid}/attendance", headers=hm, json={
        "section_id": ac["section_id"], "attendance_date": "2026-06-18",
        "entries": [{"student_id": s2["id"], "status": "present"}],
    })
    assert bad.status_code == 400


async def test_guardian_cannot_mark_attendance(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    s1 = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], s1["id"])
    guardian = await create_user(client, sid, hm, "guardian")
    gh = await login(client, guardian["email"], guardian["password"])
    r = await client.post(f"{API}/schools/{sid}/attendance", headers=gh, json={
        "section_id": ac["section_id"], "attendance_date": "2026-06-18",
        "entries": [{"student_id": s1["id"], "status": "present"}],
    })
    assert r.status_code == 403
