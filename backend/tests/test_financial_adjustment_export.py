"""Headmaster CSV exports retain audit detail without spreadsheet formulas."""

import csv
import io
from datetime import date

from app.core.config import settings
from tests.test_broadcast_isolation import another_school
from tests.utils import create_user, login

API = settings.API_V1_PREFIX


async def _invoice(client, school, *, title: str = "Term fee") -> dict:
    student = await create_user(client, school["id"], school["hm"], "student")
    response = await client.post(
        f"{API}/schools/{school['id']}/fees/invoices",
        headers=school["hm"],
        json={
            "student_id": student["id"],
            "title": title,
            "amount": 100,
            "due_date": date.today().isoformat(),
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


async def _adjustment(client, school, invoice, *, reason: str) -> dict:
    response = await client.post(
        f"{API}/schools/{school['id']}/fees/adjustments",
        headers=school["hm"],
        json={
            "kind": "refund",
            "target_id": invoice["id"],
            "proposed_amount": "25.50",
            "currency_code": "PKR",
            "reason": reason,
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


async def test_headmaster_csv_export_is_tenant_scoped_formula_safe_and_auditable(
    client, school
):
    invoice = await _invoice(client, school)
    adjustment = await _adjustment(client, school, invoice, reason=" \t=SUM(1,1)")
    decided = await client.post(
        f"{API}/schools/{school['id']}/fees/adjustments/{adjustment['id']}/decision",
        headers=school["hm"],
        json={"decision": "approved", "reason": "\t@audit-review"},
    )
    assert decided.status_code == 200, decided.text

    # The JSON review queue exposes the decision actor and timestamp as part
    # of the audit record, before the same data is exported.
    listed = await client.get(
        f"{API}/schools/{school['id']}/fees/adjustments", headers=school["hm"]
    )
    assert listed.status_code == 200, listed.text
    api_row = next(row for row in listed.json() if row["id"] == adjustment["id"])
    assert api_row["decided_by"] == adjustment["requested_by"]
    assert api_row["decided_at"]

    exported = await client.get(
        f"{API}/schools/{school['id']}/fees/adjustments/export", headers=school["hm"]
    )
    assert exported.status_code == 200, exported.text
    assert exported.headers["content-type"].startswith("text/csv")
    assert "attachment; filename=financial_adjustments.csv" in exported.headers[
        "content-disposition"
    ]
    rows = list(csv.DictReader(io.StringIO(exported.text)))
    assert len(rows) == 1
    row = rows[0]
    assert row["adjustment_id"] == adjustment["id"]
    assert row["reason"] == "' \t=SUM(1,1)"
    assert row["decision_reason"] == "'\t@audit-review"
    assert row["requested_by"] == adjustment["requested_by"]
    assert row["decided_by"] == adjustment["requested_by"]
    assert row["requested_at"]
    assert row["decided_at"]


async def test_adjustment_export_never_includes_a_foreign_school_row(client, school):
    local_invoice = await _invoice(client, school)
    local_adjustment = await _adjustment(
        client, school, local_invoice, reason="Local export record."
    )

    foreign_school = await another_school(client, school["sa"])
    foreign_student = await create_user(client, foreign_school, school["sa"], "student")
    foreign_invoice = await client.post(
        f"{API}/schools/{foreign_school}/fees/invoices",
        headers=school["sa"],
        json={
            "student_id": foreign_student["id"],
            "title": "Foreign fee",
            "amount": 100,
            "due_date": date.today().isoformat(),
        },
    )
    assert foreign_invoice.status_code == 201, foreign_invoice.text
    foreign_adjustment = await client.post(
        f"{API}/schools/{foreign_school}/fees/adjustments",
        headers=school["sa"],
        json={
            "kind": "credit",
            "target_id": foreign_invoice.json()["id"],
            "proposed_amount": "10",
            "currency_code": "PKR",
            "reason": "Foreign export record.",
        },
    )
    assert foreign_adjustment.status_code == 201, foreign_adjustment.text

    exported = await client.get(
        f"{API}/schools/{school['id']}/fees/adjustments/export", headers=school["hm"]
    )
    assert exported.status_code == 200, exported.text
    ids = {row["adjustment_id"] for row in csv.DictReader(io.StringIO(exported.text))}
    assert ids == {local_adjustment["id"]}
    assert foreign_adjustment.json()["id"] not in ids


async def test_adjustment_export_requires_headmaster_or_super_admin(client, school):
    guardian = await create_user(client, school["id"], school["hm"], "guardian")
    guardian_headers = await login(client, guardian["email"], guardian["password"])
    response = await client.get(
        f"{API}/schools/{school['id']}/fees/adjustments/export", headers=guardian_headers
    )
    assert response.status_code == 403, response.text
