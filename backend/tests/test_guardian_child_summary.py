"""Guardian child summaries reflect live fees, homework and attendance."""
from datetime import date, timedelta
from uuid import UUID

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core.config import settings
from app.models.attendance import AttendanceRecord
from tests.conftest import TEST_URL
from tests.test_broadcast_isolation import another_school
from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def test_child_summary_reports_live_family_state(client, school):
    sid, hm = school["id"], school["hm"]
    academic = await make_academics(client, sid, hm)
    student = await create_user(client, sid, hm, "student")
    guardian = await create_user(client, sid, hm, "guardian")
    await enroll(client, sid, hm, academic["section_id"], student["id"])
    linked = await client.post(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children", headers=hm,
        json={"student_id": student["id"]},
    )
    assert linked.status_code == 201, linked.text
    gh = await login(client, guardian["email"], guardian["password"])
    children_url = f"{API}/schools/{sid}/me/children"

    (child,) = (await client.get(children_url, headers=gh)).json()
    assert child["fees_due"] is False
    assert child["pending_homework"] == 0
    assert child["attendance_percent"] is None  # no register yet: not "0 %"

    today = date.today()
    for title, due in (("Open work", today + timedelta(days=3)), ("Past work", today - timedelta(days=3))):
        r = await client.post(f"{API}/schools/{sid}/homework/assignments", headers=hm, json={
            "section_id": academic["section_id"], "subject_id": academic["subject_id"],
            "title": title, "due_date": due.isoformat(),
        })
        assert r.status_code == 201, r.text
    invoice = await client.post(f"{API}/schools/{sid}/fees/invoices", headers=hm, json={
        "student_id": student["id"], "title": "Tuition", "amount": 100, "due_date": today.isoformat(),
    })
    assert invoice.status_code == 201, invoice.text
    # Another school's unpaid invoice/homework can never leak into this child.
    await another_school(client, school["sa"])

    engine = create_async_engine(TEST_URL)
    try:
        async with async_sessionmaker(engine)() as db, db.begin():
            for offset, status in ((0, "present"), (1, "absent"), (2, "late"), (3, "present")):
                day = today.replace(day=1) + timedelta(days=offset)
                if day > today:
                    continue
                db.add(AttendanceRecord(
                    school_id=UUID(sid), section_id=UUID(academic["section_id"]),
                    student_id=UUID(student["id"]), attendance_date=day, status=status,
                ))
    finally:
        await engine.dispose()

    (child,) = (await client.get(children_url, headers=gh)).json()
    assert child["fees_due"] is True
    assert child["pending_homework"] == 1
    days = min(4, today.day)
    attended = sum(1 for i, s in enumerate(("present", "absent", "late", "present")) if i < days and s != "absent")
    assert child["attendance_percent"] == round(100 * attended / days)

    paid = await client.post(
        f"{API}/schools/{sid}/fees/invoices/{invoice.json()['id']}/payments", headers=hm,
        json={"amount": 100, "method": "cash", "paid_on": date.today().isoformat(), "idempotency_key": "guardian-summary-paid"},
    )
    assert paid.status_code in (200, 201), paid.text
    (child,) = (await client.get(children_url, headers=gh)).json()
    assert child["fees_due"] is False
