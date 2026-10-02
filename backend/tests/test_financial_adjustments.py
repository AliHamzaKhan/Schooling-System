"""Finance adjustment requests, decisions and tenant scope.

Accountant requests wait for a Headmaster decision; see
test_adjustment_approval.py for how decisions post to balances.
"""

from datetime import date
from uuid import uuid4

from app.core.config import settings
from tests.test_broadcast_isolation import another_school
from tests.utils import create_user, login

API = settings.API_V1_PREFIX


async def _invoice(client, school, *, amount: int = 100) -> dict:
    student = await create_user(client, school["id"], school["hm"], "student")
    response = await client.post(
        f"{API}/schools/{school['id']}/fees/invoices",
        headers=school["hm"],
        json={
            "student_id": student["id"],
            "title": "Term fee",
            "amount": amount,
            "due_date": date.today().isoformat(),
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


async def _accountant(client, school_id: str, creator: dict) -> dict:
    user = await create_user(client, school_id, creator, "accountant")
    return await login(client, user["email"], user["password"])


async def _payslip(client, school) -> dict:
    teacher = await create_user(client, school["id"], school["hm"], "teacher")
    profile = await client.post(
        f"{API}/schools/{school['id']}/hr/staff",
        headers=school["hm"],
        json={
            "user_id": teacher["id"],
            "designation": "Teacher",
            "base_salary": 30_000,
        },
    )
    assert profile.status_code == 201, profile.text
    payslip = await client.post(
        f"{API}/schools/{school['id']}/hr/staff/{profile.json()['id']}/payslips",
        headers=school["hm"],
        json={"period_month": 9, "period_year": 2026},
    )
    assert payslip.status_code == 201, payslip.text
    return payslip.json()


async def test_headmaster_can_record_one_immutable_fee_adjustment_decision(
    client, school
):
    school_id, headmaster = school["id"], school["hm"]
    invoice = await _invoice(client, school)
    accountant = await _accountant(client, school_id, headmaster)

    created = await client.post(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=accountant,
        json={
            "kind": "waiver",
            "target_id": invoice["id"],
            "proposed_amount": "25.500",
            "currency_code": "pkr",
            "reason": "Approved hardship waiver request.",
        },
    )
    assert created.status_code == 201, created.text
    adjustment = created.json()
    assert adjustment["target_type"] == "invoice"
    assert adjustment["proposed_amount"] == "25.500"
    assert adjustment["currency_code"] == "PKR"
    assert adjustment["decision"] is None

    approved = await client.post(
        f"{API}/schools/{school_id}/fees/adjustments/{adjustment['id']}/decision",
        headers=headmaster,
        json={"decision": "approved", "reason": "Verified against school policy."},
    )
    assert approved.status_code == 200, approved.text
    assert approved.json()["decision"] == "approved"

    duplicate = await client.post(
        f"{API}/schools/{school_id}/fees/adjustments/{adjustment['id']}/decision",
        headers=headmaster,
        json={"decision": "rejected", "reason": "Cannot change a recorded decision."},
    )
    assert duplicate.status_code == 400

    waived = await client.get(
        f"{API}/schools/{school_id}/fees/invoices/{invoice['id']}",
        headers=headmaster,
    )
    assert waived.json()["amount"] == 74.5
    assert waived.json()["amount_paid"] == 0
    assert waived.json()["status"] == "unpaid"


async def test_guardian_cannot_read_or_create_financial_adjustments(client, school):
    school_id, headmaster = school["id"], school["hm"]
    guardian = await create_user(client, school_id, headmaster, "guardian")
    guardian_headers = await login(client, guardian["email"], guardian["password"])
    assert (
        await client.get(
            f"{API}/schools/{school_id}/fees/adjustments", headers=guardian_headers
        )
    ).status_code == 403
    assert (
        await client.post(
            f"{API}/schools/{school_id}/fees/adjustments",
            headers=guardian_headers,
            json={
                "kind": "credit",
                "target_id": guardian["id"],
                "proposed_amount": "1",
                "currency_code": "PKR",
                "reason": "Not authorized.",
            },
        )
    ).status_code == 403


async def test_payroll_correction_targets_only_a_payslip(client, school):
    school_id, headmaster = school["id"], school["hm"]
    payslip = await _payslip(client, school)
    accountant = await _accountant(client, school_id, headmaster)

    created = await client.post(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=accountant,
        json={
            "kind": "payroll_correction",
            "target_id": payslip["id"],
            "proposed_amount": "1500.00",
            "currency_code": "PKR",
            "reason": "Correct a verified attendance deduction.",
        },
    )
    assert created.status_code == 201, created.text
    assert created.json()["target_type"] == "payslip"

    # A pending request does not rewrite the payroll record.
    listed = await client.get(
        f"{API}/schools/{school_id}/hr/payslips", headers=headmaster
    )
    assert listed.status_code == 200, listed.text
    unchanged = next(row for row in listed.json() if row["id"] == payslip["id"])
    assert unchanged["net"] == payslip["net"]
    assert unchanged["status"] == payslip["status"]


async def test_adjustments_reject_the_wrong_target_type(client, school):
    school_id, headmaster = school["id"], school["hm"]
    invoice = await _invoice(client, school)
    payslip = await _payslip(client, school)

    payroll_on_invoice = await client.post(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        json={
            "kind": "payroll_correction",
            "target_id": invoice["id"],
            "proposed_amount": "1",
            "currency_code": "PKR",
            "reason": "This must be rejected because it is not a payslip.",
        },
    )
    assert payroll_on_invoice.status_code == 404
    assert "Payslip" in payroll_on_invoice.json()["detail"]

    credit_on_payslip = await client.post(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        json={
            "kind": "credit",
            "target_id": payslip["id"],
            "proposed_amount": "1",
            "currency_code": "PKR",
            "reason": "This must be rejected because it is not an invoice.",
        },
    )
    assert credit_on_payslip.status_code == 404
    assert "Invoice" in credit_on_payslip.json()["detail"]


async def test_adjustments_reject_invalid_kind_and_currency_before_persisting(
    client, school
):
    school_id, headmaster = school["id"], school["hm"]
    payload = {
        "target_id": str(uuid4()),
        "proposed_amount": "1",
        "currency_code": "PKR",
        "reason": "Validation must reject malformed ledger values.",
    }

    invalid_kind = await client.post(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        json={**payload, "kind": "discount"},
    )
    assert invalid_kind.status_code == 422
    assert any(issue["loc"][-1] == "kind" for issue in invalid_kind.json()["detail"])

    invalid_currency = await client.post(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        json={**payload, "kind": "credit", "currency_code": "P1K"},
    )
    assert invalid_currency.status_code == 422
    assert any(
        issue["loc"][-1] == "currency_code"
        for issue in invalid_currency.json()["detail"]
    )


async def test_adjustment_review_queue_filters_and_paginates_after_school_scope(
    client, school
):
    school_id, headmaster = school["id"], school["hm"]
    invoices = [await _invoice(client, school) for _ in range(3)]
    payslip = await _payslip(client, school)
    accountant = await _accountant(client, school_id, headmaster)
    paid = await client.post(
        f"{API}/schools/{school_id}/fees/invoices/{invoices[0]['id']}/payments",
        headers=headmaster,
        json={"amount": 10, "method": "cash", "paid_on": date.today().isoformat()},
    )
    assert paid.status_code == 201, paid.text

    async def create(kind: str, target_id: str, amount: str) -> dict:
        response = await client.post(
            f"{API}/schools/{school_id}/fees/adjustments",
            headers=accountant,
            json={
                "kind": kind,
                "target_id": target_id,
                "proposed_amount": amount,
                "currency_code": "PKR",
                "reason": f"Queue review for {kind}.",
            },
        )
        assert response.status_code == 201, response.text
        return response.json()

    approved = await create("refund", invoices[0]["id"], "1")
    rejected = await create("credit", invoices[1]["id"], "2")
    pending_invoice = await create("waiver", invoices[2]["id"], "3")
    pending_payslip = await create("payroll_correction", payslip["id"], "4")

    for adjustment, decision in ((approved, "approved"), (rejected, "rejected")):
        response = await client.post(
            f"{API}/schools/{school_id}/fees/adjustments/{adjustment['id']}/decision",
            headers=headmaster,
            json={"decision": decision, "reason": f"Recorded {decision} decision."},
        )
        assert response.status_code == 200, response.text

    pending = await client.get(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        params={"decision": "pending"},
    )
    assert {row["id"] for row in pending.json()} == {
        pending_invoice["id"],
        pending_payslip["id"],
    }

    invoice_pending = await client.get(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        params={"target_type": "invoice", "decision": "pending"},
    )
    assert [row["id"] for row in invoice_pending.json()] == [pending_invoice["id"]]

    refunds = await client.get(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        params={"kind": "refund", "decision": "approved"},
    )
    assert [row["id"] for row in refunds.json()] == [approved["id"]]

    all_local = await client.get(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        params={"target_type": "invoice"},
    )
    assert all_local.status_code == 200, all_local.text
    first_page = await client.get(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        params={"target_type": "invoice", "limit": 1, "offset": 0},
    )
    second_page = await client.get(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        params={"target_type": "invoice", "limit": 1, "offset": 1},
    )
    assert [row["id"] for row in first_page.json()] == [all_local.json()[0]["id"]]
    assert [row["id"] for row in second_page.json()] == [all_local.json()[1]["id"]]

    foreign_school = await another_school(client, school["sa"])
    foreign_student = await create_user(client, foreign_school, school["sa"], "student")
    foreign_invoice = await client.post(
        f"{API}/schools/{foreign_school}/fees/invoices",
        headers=school["sa"],
        json={
            "student_id": foreign_student["id"],
            "title": "Foreign term fee",
            "amount": 99,
            "due_date": date.today().isoformat(),
        },
    )
    assert foreign_invoice.status_code == 201, foreign_invoice.text
    foreign_adjustment = await client.post(
        f"{API}/schools/{foreign_school}/fees/adjustments",
        headers=school["sa"],
        json={
            "kind": "waiver",
            "target_id": foreign_invoice.json()["id"],
            "proposed_amount": "5",
            "currency_code": "PKR",
            "reason": "Foreign school adjustment.",
        },
    )
    assert foreign_adjustment.status_code == 201, foreign_adjustment.text

    # A row in another school's review queue cannot consume a local page slot.
    local_again = await client.get(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        params={"target_type": "invoice"},
    )
    assert [row["id"] for row in local_again.json()] == [
        row["id"] for row in all_local.json()
    ]
    for params in ({"limit": 101}, {"offset": -1}, {"decision": "unknown"}):
        response = await client.get(
            f"{API}/schools/{school_id}/fees/adjustments",
            headers=headmaster,
            params=params,
        )
        assert response.status_code == 422, response.text


async def test_adjustment_routes_require_headmaster_and_keep_targets_tenant_scoped(
    client, school
):
    school_id, headmaster = school["id"], school["hm"]
    invoice = await _invoice(client, school)
    adjustment = await client.post(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        json={
            "kind": "credit",
            "target_id": invoice["id"],
            "proposed_amount": "7",
            "currency_code": "PKR",
            "reason": "A local request for access checks.",
        },
    )
    assert adjustment.status_code == 201, adjustment.text

    teacher = await create_user(client, school_id, headmaster, "teacher")
    teacher_headers = await login(client, teacher["email"], teacher["password"])
    for method, path, body in (
        ("get", "/adjustments", None),
        (
            "post",
            "/adjustments",
            {
                "kind": "waiver",
                "target_id": invoice["id"],
                "proposed_amount": "1",
                "currency_code": "PKR",
                "reason": "A teacher cannot propose this.",
            },
        ),
        (
            "post",
            f"/adjustments/{adjustment.json()['id']}/decision",
            {
                "decision": "approved",
                "reason": "A teacher cannot decide this.",
            },
        ),
    ):
        request = getattr(client, method)
        request_args = {"headers": teacher_headers}
        if body is not None:
            request_args["json"] = body
        response = await request(
            f"{API}/schools/{school_id}/fees{path}", **request_args
        )
        assert response.status_code == 403, response.text

    foreign_school = await another_school(client, school["sa"])
    foreign_student = await create_user(client, foreign_school, school["sa"], "student")
    foreign_invoice = await client.post(
        f"{API}/schools/{foreign_school}/fees/invoices",
        headers=school["sa"],
        json={
            "student_id": foreign_student["id"],
            "title": "Foreign invoice",
            "amount": 10,
            "due_date": date.today().isoformat(),
        },
    )
    assert foreign_invoice.status_code == 201, foreign_invoice.text

    # Local Headmasters cannot even name a foreign target or review queue.
    foreign_target = await client.post(
        f"{API}/schools/{school_id}/fees/adjustments",
        headers=headmaster,
        json={
            "kind": "refund",
            "target_id": foreign_invoice.json()["id"],
            "proposed_amount": "1",
            "currency_code": "PKR",
            "reason": "Cross-school targets are forbidden.",
        },
    )
    assert foreign_target.status_code == 404
    assert (
        await client.get(
            f"{API}/schools/{foreign_school}/fees/adjustments", headers=headmaster
        )
    ).status_code == 403

    # Finance staff need an active plan with fee management.
    await client.post(f"{API}/schools/{foreign_school}/subscription", headers=school["sa"], json={"plan_code": "premium"})
    await client.post(f"{API}/schools/{foreign_school}/status", headers=school["sa"], json={"status": "active"})
    foreign_accountant = await _accountant(client, foreign_school, school["sa"])
    foreign_adjustment = await client.post(
        f"{API}/schools/{foreign_school}/fees/adjustments",
        headers=foreign_accountant,
        json={
            "kind": "waiver",
            "target_id": foreign_invoice.json()["id"],
            "proposed_amount": "1",
            "currency_code": "PKR",
            "reason": "Foreign decision target.",
        },
    )
    assert foreign_adjustment.status_code == 201, foreign_adjustment.text

    # The platform Super Admin retains the documented cross-school oversight
    # path, while a Headmaster remains bound to their own school above.
    super_admin_queue = await client.get(
        f"{API}/schools/{foreign_school}/fees/adjustments", headers=school["sa"]
    )
    assert super_admin_queue.status_code == 200, super_admin_queue.text
    assert [row["id"] for row in super_admin_queue.json()] == [
        foreign_adjustment.json()["id"]
    ]

    foreign_decision = await client.post(
        f"{API}/schools/{school_id}/fees/adjustments/{foreign_adjustment.json()['id']}/decision",
        headers=headmaster,
        json={"decision": "approved", "reason": "Must not reach another school."},
    )
    assert foreign_decision.status_code == 404

    super_admin_decision = await client.post(
        f"{API}/schools/{foreign_school}/fees/adjustments/{foreign_adjustment.json()['id']}/decision",
        headers=school["sa"],
        json={"decision": "approved", "reason": "Platform audit approved it."},
    )
    assert super_admin_decision.status_code == 200, super_admin_decision.text
    assert super_admin_decision.json()["decision"] == "approved"


async def test_adjustment_without_currency_code_stores_no_currency(client, school):
    """Amounts are plain numbers; an omitted currency is stored as ISO 'XXX'."""
    from tests.utils import create_user

    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    invoice = await client.post(f"{API}/schools/{sid}/fees/invoices", headers=hm, json={
        "student_id": student["id"], "title": "Plain number fee", "amount": 500, "due_date": "2030-01-10",
    })
    assert invoice.status_code == 201, invoice.text
    r = await client.post(f"{API}/schools/{sid}/fees/adjustments", headers=hm, json={
        "kind": "waiver", "target_id": invoice.json()["id"], "proposed_amount": "50",
        "reason": "Sibling waiver",
    })
    assert r.status_code == 201, r.text
    assert r.json()["currency_code"] == "XXX"
