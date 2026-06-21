"""Examination result computation and fee payment tests."""
from app.core.config import settings

from tests.utils import create_user, enroll, make_academics

API = settings.API_V1_PREFIX


async def test_exam_pass_fail_and_grades(client, school):
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)
    s_pass = await create_user(client, sid, hm, "student")
    s_fail = await create_user(client, sid, hm, "student")
    await enroll(client, sid, hm, ac["section_id"], s_pass["id"])
    await enroll(client, sid, hm, ac["section_id"], s_fail["id"])

    exam = (await client.post(f"{API}/schools/{sid}/exams", headers=hm,
            json={"class_id": ac["class_id"], "name": "Midterm"})).json()
    paper = (await client.post(f"{API}/schools/{sid}/exams/{exam['id']}/papers", headers=hm,
             json={"subject_id": ac["subject_id"], "max_marks": 100, "pass_marks": 40})).json()

    # marks > max rejected
    bad = await client.post(f"{API}/schools/{sid}/exams/papers/{paper['id']}/marks", headers=hm,
                            json={"entries": [{"student_id": s_pass["id"], "marks_obtained": 120}]})
    assert bad.status_code == 400

    await client.post(f"{API}/schools/{sid}/exams/papers/{paper['id']}/marks", headers=hm, json={"entries": [
        {"student_id": s_pass["id"], "marks_obtained": 85},
        {"student_id": s_fail["id"], "marks_obtained": 30},
    ]})

    results = (await client.post(f"{API}/schools/{sid}/exams/{exam['id']}/results/publish", headers=hm)).json()
    by_student = {r["student_id"]: r for r in results}
    assert by_student[s_pass["id"]]["status"] == "pass"
    assert by_student[s_pass["id"]]["grade"] == "A"  # 85%
    assert by_student[s_fail["id"]]["status"] == "fail"  # below pass_marks


async def test_fee_payment_and_overpayment(client, school):
    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    inv = (await client.post(f"{API}/schools/{sid}/fees/invoices", headers=hm, json={
        "student_id": student["id"], "title": "Term Fee", "amount": 5000, "due_date": "2026-06-10",
    })).json()
    assert inv["status"] == "unpaid"
    assert inv["is_overdue"] is True  # due date in the past

    # Partial payment.
    await client.post(f"{API}/schools/{sid}/fees/invoices/{inv['id']}/payments", headers=hm,
                      json={"amount": 2000, "method": "cash", "paid_on": "2026-06-18"})
    got = (await client.get(f"{API}/schools/{sid}/fees/invoices/{inv['id']}", headers=hm)).json()
    assert got["status"] == "partial"
    assert got["balance"] == 3000

    # Overpayment rejected.
    over = await client.post(f"{API}/schools/{sid}/fees/invoices/{inv['id']}/payments", headers=hm,
                             json={"amount": 9999, "method": "cash", "paid_on": "2026-06-18"})
    assert over.status_code == 400

    # Pay remainder -> paid.
    await client.post(f"{API}/schools/{sid}/fees/invoices/{inv['id']}/payments", headers=hm,
                      json={"amount": 3000, "method": "card", "paid_on": "2026-06-18"})
    paid = (await client.get(f"{API}/schools/{sid}/fees/invoices/{inv['id']}", headers=hm)).json()
    assert paid["status"] == "paid"
    assert paid["balance"] == 0


async def test_fee_receipt_and_report(client, school):
    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    inv = (await client.post(f"{API}/schools/{sid}/fees/invoices", headers=hm, json={
        "student_id": student["id"], "title": "Lab Fee", "amount": 1000, "due_date": "2026-12-01",
    })).json()
    await client.post(f"{API}/schools/{sid}/fees/invoices/{inv['id']}/payments", headers=hm,
                      json={"amount": 400, "method": "cash", "paid_on": "2026-06-18"})

    # Receipt aggregates the invoice with its payments.
    rec = await client.get(f"{API}/schools/{sid}/fees/invoices/{inv['id']}/receipt", headers=hm)
    assert rec.status_code == 200
    body = rec.json()
    assert body["invoice"]["id"] == inv["id"]
    assert body["total_paid"] == 400
    assert len(body["payments"]) == 1

    # School-wide report reflects billed/collected/outstanding for this invoice.
    rep = await client.get(f"{API}/schools/{sid}/fees/report", headers=hm)
    assert rep.status_code == 200
    r = rep.json()
    assert r["total_billed"] >= 1000
    assert r["total_collected"] >= 400
    assert r["total_outstanding"] >= 600
