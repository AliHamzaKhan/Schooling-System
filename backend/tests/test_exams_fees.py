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

    future = await client.post(
        f"{API}/schools/{sid}/fees/invoices/{inv['id']}/payments",
        headers=hm,
        json={"amount": 2000, "method": "cash", "paid_on": "2099-01-01"},
    )
    assert future.status_code == 422
    unchanged = await client.get(f"{API}/schools/{sid}/fees/invoices/{inv['id']}", headers=hm)
    assert unchanged.json()["amount_paid"] == 0

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


async def test_student_fee_search_and_class_filter(client, school):
    """The Record Payment / Overdue screens depend on:
      * /fees/students — search by name/father/class with a fee snapshot,
      * /fees/invoices?class_id=&status=overdue — paginated overdue filter.
    """
    sid, hm = school["id"], school["hm"]
    ac = await make_academics(client, sid, hm)

    # Two students in the same class; one has an overdue invoice + a father name.
    with_meta = await create_user(
        client, sid, hm, "student",
        full_name="Aisha Khan",
        profile_metadata={"father_name": "Rehan Khan"},
    )
    plain = await create_user(client, sid, hm, "student", full_name="Bilal Ahmed")
    await enroll(client, sid, hm, ac["section_id"], with_meta["id"])
    await enroll(client, sid, hm, ac["section_id"], plain["id"])

    # One overdue invoice (past due, unpaid) + one future invoice (unpaid).
    overdue = (await client.post(f"{API}/schools/{sid}/fees/invoices", headers=hm, json={
        "student_id": with_meta["id"], "title": "Term 1 Fee",
        "amount": 4000, "due_date": "2025-01-01",
    })).json()
    assert overdue["is_overdue"] is True
    future = (await client.post(f"{API}/schools/{sid}/fees/invoices", headers=hm, json={
        "student_id": plain["id"], "title": "Term 1 Fee",
        "amount": 4000, "due_date": "2099-12-31",
    })).json()
    assert future["is_overdue"] is False

    # -- Search by name --
    r = await client.get(f"{API}/schools/{sid}/fees/students?q=aisha", headers=hm)
    assert r.status_code == 200, r.text
    page = r.json()
    assert page["total"] == 1
    hit = page["items"][0]
    assert hit["full_name"] == "Aisha Khan"
    assert hit["father_name"] == "Rehan Khan"
    assert hit["class_name"] == "Grade 1"
    assert hit["outstanding_total"] == 4000
    assert hit["has_overdue"] is True
    assert len(hit["invoices"]) == 1

    # -- Search by father name --
    r2 = await client.get(f"{API}/schools/{sid}/fees/students?q=rehan", headers=hm)
    assert r2.json()["total"] == 1

    # -- Search by class name matches both students --
    r3 = await client.get(f"{API}/schools/{sid}/fees/students?q=grade 1", headers=hm)
    assert r3.json()["total"] == 2

    # -- Pagination --
    r4 = await client.get(
        f"{API}/schools/{sid}/fees/students?q=grade 1&limit=1&offset=0", headers=hm,
    )
    p1 = r4.json()
    assert p1["total"] == 2 and len(p1["items"]) == 1

    # -- Invoice list filtered by overdue + class --
    r5 = await client.get(
        f"{API}/schools/{sid}/fees/invoices?status=overdue&class_id={ac['class_id']}",
        headers=hm,
    )
    assert r5.status_code == 200
    invs = r5.json()
    assert len(invs) == 1
    assert invs[0]["id"] == overdue["id"]

    # -- Student search filtered by class + fee_status=overdue --
    r6 = await client.get(
        f"{API}/schools/{sid}/fees/students"
        f"?class_id={ac['class_id']}&fee_status=overdue",
        headers=hm,
    )
    assert r6.status_code == 200, r6.text
    p6 = r6.json()
    assert p6["total"] == 1
    assert p6["items"][0]["full_name"] == "Aisha Khan"

    # -- fee_status=pending only lists Bilal (unpaid, not overdue) --
    r7 = await client.get(
        f"{API}/schools/{sid}/fees/students?fee_status=pending", headers=hm,
    )
    p7 = r7.json()
    names = [i["full_name"] for i in p7["items"]]
    assert "Bilal Ahmed" in names
    assert "Aisha Khan" not in names
