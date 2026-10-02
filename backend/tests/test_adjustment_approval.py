"""Accountant proposes, Headmaster decides; approved adjustments move money."""
from datetime import date
from uuid import uuid4

from app.core.config import settings
from tests.test_financial_adjustments import _invoice, _payslip
from tests.utils import create_user, login

API = settings.API_V1_PREFIX


async def _accountant(client, school) -> dict:
    user = await create_user(client, school["id"], school["hm"], "accountant")
    return await login(client, user["email"], user["password"])


async def _invoice_state(client, school, invoice_id) -> dict:
    receipt = await client.get(f"{API}/schools/{school['id']}/fees/invoices/{invoice_id}/receipt", headers=school["hm"])
    assert receipt.status_code == 200, receipt.text
    return receipt.json()


async def _pay(client, school, invoice_id, amount, headers=None) -> None:
    response = await client.post(
        f"{API}/schools/{school['id']}/fees/invoices/{invoice_id}/payments", headers=headers or school["hm"],
        json={"amount": amount, "method": "cash", "paid_on": date.today().isoformat()},
    )
    assert response.status_code == 201, response.text


async def _adjust(client, school, headers, kind, target_id, amount):
    return await client.post(
        f"{API}/schools/{school['id']}/fees/adjustments", headers=headers,
        json={"kind": kind, "target_id": target_id, "proposed_amount": str(amount), "reason": "Checked by finance"},
    )


async def test_accountant_role_exists_with_finance_permissions(client, school):
    accountant = await _accountant(client, school)
    base = f"{API}/schools/{school['id']}"
    assert (await client.get(f"{base}/fees/invoices", headers=accountant)).status_code == 200
    assert (await client.get(f"{base}/hr/payslips", headers=accountant)).status_code == 200
    # Not an approver and not a school administrator.
    assert (await client.post(f"{base}/academic/subjects", headers=accountant,
                              json={"code": "X1", "name": "Nope"})).status_code == 403


async def test_accountant_waiver_waits_for_headmaster_then_lowers_the_charge(client, school):
    accountant = await _accountant(client, school)
    invoice = await _invoice(client, school, amount=100)

    created = await _adjust(client, school, accountant, "waiver", invoice["id"], 30)
    assert created.status_code == 201, created.text
    assert created.json()["decision"] is None
    assert (await _invoice_state(client, school, invoice["id"]))["invoice"]["amount"] == 100

    # The accountant cannot approve their own request.
    url = f"{API}/schools/{school['id']}/fees/adjustments/{created.json()['id']}/decision"
    denied = await client.post(url, headers=accountant, json={"decision": "approved", "reason": "Self approval"})
    assert denied.status_code == 403
    queue = await client.get(f"{API}/schools/{school['id']}/fees/adjustments", headers=accountant)
    assert queue.status_code == 200 and queue.json()[0]["id"] == created.json()["id"]

    approved = await client.post(url, headers=school["hm"], json={"decision": "approved", "reason": "Hardship case"})
    assert approved.status_code == 200, approved.text
    state = await _invoice_state(client, school, invoice["id"])
    assert state["invoice"]["amount"] == 70
    assert state["invoice"]["balance"] == 70


async def test_rejected_request_changes_nothing(client, school):
    accountant = await _accountant(client, school)
    invoice = await _invoice(client, school, amount=100)
    created = await _adjust(client, school, accountant, "credit", invoice["id"], 40)
    url = f"{API}/schools/{school['id']}/fees/adjustments/{created.json()['id']}/decision"
    rejected = await client.post(url, headers=school["hm"], json={"decision": "rejected", "reason": "Not eligible"})
    assert rejected.status_code == 200
    assert (await _invoice_state(client, school, invoice["id"]))["invoice"]["amount"] == 100


async def test_headmaster_adjustment_applies_immediately(client, school):
    invoice = await _invoice(client, school, amount=100)
    created = await _adjust(client, school, school["hm"], "credit", invoice["id"], 25)
    assert created.status_code == 201, created.text
    assert created.json()["decision"] == "approved"
    assert (await _invoice_state(client, school, invoice["id"]))["invoice"]["balance"] == 75


async def test_refund_returns_paid_money_and_keeps_the_balance(client, school):
    invoice = await _invoice(client, school, amount=100)
    await _pay(client, school, invoice["id"], 60)
    created = await _adjust(client, school, school["hm"], "refund", invoice["id"], 20)
    assert created.status_code == 201, created.text
    state = await _invoice_state(client, school, invoice["id"])
    assert state["total_paid"] == 40
    assert state["invoice"]["amount"] == 80
    assert state["invoice"]["balance"] == 40
    assert [p["method"] for p in state["payments"]].count("refund") == 1

    report = await client.get(f"{API}/schools/{school['id']}/fees/reconciliation", headers=school["hm"])
    assert invoice["id"] not in {issue["invoice_id"] for issue in report.json()["issues"]}


async def test_impossible_amounts_are_refused_before_anything_changes(client, school):
    accountant = await _accountant(client, school)
    invoice = await _invoice(client, school, amount=100)
    await _pay(client, school, invoice["id"], 30)
    assert (await _adjust(client, school, accountant, "refund", invoice["id"], 31)).status_code == 400
    assert (await _adjust(client, school, accountant, "waiver", invoice["id"], 71)).status_code == 400
    assert (await _invoice_state(client, school, invoice["id"]))["invoice"]["amount"] == 100

    # Approving a request that became impossible is refused; it stays pending.
    pending = await _adjust(client, school, accountant, "waiver", invoice["id"], 70)
    await _pay(client, school, invoice["id"], 50)
    url = f"{API}/schools/{school['id']}/fees/adjustments/{pending.json()['id']}/decision"
    blocked = await client.post(url, headers=school["hm"], json={"decision": "approved", "reason": "Too late"})
    assert blocked.status_code == 400
    assert (await client.post(url, headers=school["hm"], json={"decision": "rejected", "reason": "Paid since"})).status_code == 200


async def test_payroll_correction_sets_net_pay_of_unpaid_payslip(client, school):
    accountant = await _accountant(client, school)
    payslip = await _payslip(client, school)
    created = await _adjust(client, school, accountant, "payroll_correction", payslip["id"], 31_500)
    assert created.status_code == 201, created.text
    url = f"{API}/schools/{school['id']}/fees/adjustments/{created.json()['id']}/decision"
    assert (await client.post(url, headers=school["hm"], json={"decision": "approved", "reason": "Overtime"})).status_code == 200
    rows = (await client.get(f"{API}/schools/{school['id']}/hr/payslips", headers=school["hm"])).json()
    corrected = next(row for row in rows if row["id"] == payslip["id"])
    assert corrected["net"] == 31_500
    assert corrected["gross"] - corrected["deductions"] == 31_500

    lower = await _adjust(client, school, school["hm"], "payroll_correction", payslip["id"], 29_000)
    assert lower.status_code == 201
    rows = (await client.get(f"{API}/schools/{school['id']}/hr/payslips", headers=school["hm"])).json()
    corrected = next(row for row in rows if row["id"] == payslip["id"])
    assert corrected["net"] == 29_000 and corrected["gross"] - corrected["deductions"] == 29_000

    paid = await client.post(f"{API}/schools/{school['id']}/hr/payslips/{payslip['id']}/pay", headers=school["hm"])
    assert paid.status_code == 200
    late = await _adjust(client, school, school["hm"], "payroll_correction", payslip["id"], 30_000)
    assert late.status_code == 400


async def test_payslip_payment_retry_with_the_same_key_succeeds_once(client, school):
    payslip = await _payslip(client, school)
    url = f"{API}/schools/{school['id']}/hr/payslips/{payslip['id']}/pay"
    key = str(uuid4())
    first = await client.post(url, headers={**school["hm"], "Idempotency-Key": key})
    retry = await client.post(url, headers={**school["hm"], "Idempotency-Key": key})
    assert first.status_code == retry.status_code == 200, retry.text
    assert first.json()["paid_on"] == retry.json()["paid_on"]
    other = await client.post(url, headers={**school["hm"], "Idempotency-Key": str(uuid4())})
    assert other.status_code == 400
    second_payslip = await _payslip(client, school)
    reused = await client.post(
        f"{API}/schools/{school['id']}/hr/payslips/{second_payslip['id']}/pay",
        headers={**school["hm"], "Idempotency-Key": key},
    )
    assert reused.status_code == 409
