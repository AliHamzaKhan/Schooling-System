"""Fee aging is ledger-derived, scoped and read-only."""

from datetime import date, timedelta
from uuid import UUID

from app.core.config import settings
from app.models.fees import Invoice
from sqlalchemy import update
from sqlalchemy.ext.asyncio import create_async_engine
from tests.conftest import TEST_URL
from tests.utils import create_user, login

API = settings.API_V1_PREFIX


async def _invoice(client, school_id, headers, student_id, due_date):
    response = await client.post(
        f"{API}/schools/{school_id}/fees/invoices",
        headers=headers,
        json={
            "student_id": student_id,
            "title": f"Fee due {due_date.isoformat()}",
            "amount": 100,
            "due_date": due_date.isoformat(),
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


async def test_fee_aging_uses_payment_ledger_and_due_age_buckets(client, school):
    school_id, headmaster = school["id"], school["hm"]
    student = await create_user(client, school_id, headmaster, "student")
    as_of = date.today()
    await _invoice(client, school_id, headmaster, student["id"], as_of)
    await _invoice(
        client, school_id, headmaster, student["id"], as_of - timedelta(days=1)
    )
    thirty_one_to_sixty = await _invoice(
        client, school_id, headmaster, student["id"], as_of - timedelta(days=31)
    )
    await _invoice(
        client, school_id, headmaster, student["id"], as_of - timedelta(days=61)
    )
    await _invoice(
        client, school_id, headmaster, student["id"], as_of - timedelta(days=91)
    )

    partial = await client.post(
        f"{API}/schools/{school_id}/fees/invoices/{thirty_one_to_sixty['id']}/payments",
        headers=headmaster,
        json={"amount": 40, "method": "cash", "paid_on": as_of.isoformat()},
    )
    assert partial.status_code == 201, partial.text

    report = await client.get(
        f"{API}/schools/{school_id}/fees/aging",
        headers=headmaster,
        params={"as_of": as_of.isoformat()},
    )
    assert report.status_code == 200, report.text
    body = report.json()
    assert body["as_of_date"] == as_of.isoformat()
    assert body["total_outstanding"] == 460
    assert body["buckets"] == [
        {"label": "Current", "invoice_count": 1, "outstanding_total": 100},
        {"label": "1–30 days", "invoice_count": 1, "outstanding_total": 100},
        {"label": "31–60 days", "invoice_count": 1, "outstanding_total": 60},
        {"label": "61–90 days", "invoice_count": 1, "outstanding_total": 100},
        {"label": "91+ days", "invoice_count": 1, "outstanding_total": 100},
    ]


async def test_fee_aging_requires_fee_view_permission(client, school):
    school_id, headmaster = school["id"], school["hm"]
    guardian = await create_user(client, school_id, headmaster, "guardian")
    guardian_headers = await login(client, guardian["email"], guardian["password"])
    response = await client.get(
        f"{API}/schools/{school_id}/fees/aging", headers=guardian_headers
    )
    assert response.status_code == 403
    reconciliation = await client.get(
        f"{API}/schools/{school_id}/fees/reconciliation", headers=guardian_headers
    )
    assert reconciliation.status_code == 403


async def test_fee_reconciliation_reports_drift_without_repairing_it(client, school):
    school_id, headmaster = school["id"], school["hm"]
    student = await create_user(client, school_id, headmaster, "student")
    invoice = await _invoice(client, school_id, headmaster, student["id"], date.today())
    recorded = await client.post(
        f"{API}/schools/{school_id}/fees/invoices/{invoice['id']}/payments",
        headers=headmaster,
        json={"amount": 40, "method": "cash", "paid_on": date.today().isoformat()},
    )
    assert recorded.status_code == 201, recorded.text

    engine = create_async_engine(TEST_URL)
    try:
        async with engine.begin() as db:
            await db.execute(
                update(Invoice)
                .where(Invoice.id == UUID(invoice["id"]))
                .values(amount_paid=0, status="unpaid")
            )
    finally:
        await engine.dispose()

    report = await client.get(
        f"{API}/schools/{school_id}/fees/reconciliation", headers=headmaster
    )
    assert report.status_code == 200, report.text
    body = report.json()
    assert body["invoices_scanned"] == 1
    assert body["reconciled_count"] == 0
    assert body["mismatch_count"] == 1
    assert body["issues"] == [
        {
            "invoice_id": invoice["id"],
            "cached_amount_paid": 0,
            "ledger_amount_paid": 40,
            "cached_status": "unpaid",
            "ledger_status": "partial",
            "issue_codes": ["cached_total_mismatch", "cached_status_mismatch"],
        }
    ]

    unchanged = await client.get(
        f"{API}/schools/{school_id}/fees/invoices/{invoice['id']}", headers=headmaster
    )
    assert unchanged.json()["amount_paid"] == 0
    assert unchanged.json()["status"] == "unpaid"
