"""Fee structure scope must remain compatible with invoice issuance."""

from app.core.config import settings
from tests.utils import create_user, enroll

API = settings.API_V1_PREFIX


async def _session(client, school, name: str) -> dict:
    response = await client.post(
        f"{API}/schools/{school['id']}/sessions",
        headers=school["sa"],
        json={"name": name},
    )
    assert response.status_code == 201, response.text
    return response.json()


async def _class(client, school, name: str, session_id: str) -> dict:
    response = await client.post(
        f"{API}/schools/{school['id']}/academic/classes",
        headers=school["hm"],
        json={"name": name, "session_id": session_id},
    )
    assert response.status_code == 201, response.text
    return response.json()


async def test_fee_structure_session_scope_cannot_drift_into_an_invoice(client, school):
    first = await _session(client, school, "2026-27")
    second = await _session(client, school, "2027-28")
    school_class = await _class(client, school, "Grade 4", first["id"])
    student = await create_user(client, school["id"], school["hm"], "student")

    mismatched_structure = await client.post(
        f"{API}/schools/{school['id']}/fees/structures",
        headers=school["hm"],
        json={
            "name": "Wrong Term Fee",
            "amount": 5000,
            "class_id": school_class["id"],
            "session_id": second["id"],
        },
    )
    assert mismatched_structure.status_code == 400

    structure = await client.post(
        f"{API}/schools/{school['id']}/fees/structures",
        headers=school["hm"],
        json={
            "name": "Grade 4 Term Fee",
            "amount": 5000,
            "class_id": school_class["id"],
            "session_id": first["id"],
        },
    )
    assert structure.status_code == 201, structure.text

    mismatched_invoice = await client.post(
        f"{API}/schools/{school['id']}/fees/invoices",
        headers=school["hm"],
        json={
            "student_id": student["id"],
            "title": "Term Fee",
            "amount": 5000,
            "due_date": "2027-01-01",
            "fee_structure_id": structure.json()["id"],
            "session_id": second["id"],
        },
    )
    assert mismatched_invoice.status_code == 400

    inherited_scope = await client.post(
        f"{API}/schools/{school['id']}/fees/invoices",
        headers=school["hm"],
        json={
            "student_id": student["id"],
            "title": "Term Fee",
            "amount": 5000,
            "due_date": "2027-01-01",
            "fee_structure_id": structure.json()["id"],
        },
    )
    assert inherited_scope.status_code == 201, inherited_scope.text
    assert inherited_scope.json()["session_id"] == first["id"]


async def test_bulk_invoices_cannot_use_a_structure_for_another_class(client, school):
    session = await _session(client, school, "2026-27")
    class_a = await _class(client, school, "Grade 4", session["id"])
    class_b = await _class(client, school, "Grade 5", session["id"])
    section = await client.post(
        f"{API}/schools/{school['id']}/academic/classes/{class_b['id']}/sections",
        headers=school["hm"],
        json={"name": "A"},
    )
    assert section.status_code == 201, section.text
    student = await create_user(client, school["id"], school["hm"], "student")
    await enroll(client, school["id"], school["hm"], section.json()["id"], student["id"])

    structure = await client.post(
        f"{API}/schools/{school['id']}/fees/structures",
        headers=school["hm"],
        json={
            "name": "Grade 4 Term Fee",
            "amount": 5000,
            "class_id": class_a["id"],
            "session_id": session["id"],
        },
    )
    assert structure.status_code == 201, structure.text

    rejected = await client.post(
        f"{API}/schools/{school['id']}/fees/invoices/bulk",
        headers=school["hm"],
        json={
            "class_id": class_b["id"],
            "title": "Term Fee",
            "amount": 5000,
            "due_date": "2027-01-01",
            "fee_structure_id": structure.json()["id"],
            "session_id": session["id"],
        },
    )
    assert rejected.status_code == 400

    invoices = await client.get(
        f"{API}/schools/{school['id']}/fees/invoices",
        headers=school["hm"],
    )
    assert invoices.status_code == 200, invoices.text
    assert invoices.json() == []


async def test_duplicate_invoice_is_rejected_without_blocking_the_next_due_date(client, school):
    student = await create_user(client, school["id"], school["hm"], "student")
    invoices_url = f"{API}/schools/{school['id']}/fees/invoices"
    payload = {
        "student_id": student["id"],
        "title": "October tuition",
        "amount": 1000,
        "due_date": "2030-10-10",
    }
    created = await client.post(invoices_url, headers=school["hm"], json=payload)
    assert created.status_code == 201, created.text

    duplicate = await client.post(invoices_url, headers=school["hm"], json=payload)
    assert duplicate.status_code == 400, duplicate.text
    assert "already exists" in duplicate.json()["detail"]

    next_cycle = await client.post(
        invoices_url,
        headers=school["hm"],
        json={**payload, "due_date": "2030-11-10"},
    )
    assert next_cycle.status_code == 201, next_cycle.text

    invoices = await client.get(invoices_url, headers=school["hm"])
    assert [invoice["due_date"] for invoice in invoices.json()] == [
        "2030-10-10",
        "2030-11-10",
    ]


async def test_repeated_bulk_issue_is_rejected_without_duplicate_charges(client, school):
    session = await _session(client, school, "2030-31")
    school_class = await _class(client, school, "Grade 6", session["id"])
    section = await client.post(
        f"{API}/schools/{school['id']}/academic/classes/{school_class['id']}/sections",
        headers=school["hm"],
        json={"name": "A"},
    )
    assert section.status_code == 201, section.text
    for _ in range(2):
        student = await create_user(client, school["id"], school["hm"], "student")
        await enroll(client, school["id"], school["hm"], section.json()["id"], student["id"])

    payload = {
        "class_id": school_class["id"],
        "title": "November tuition",
        "amount": 1000,
        "due_date": "2030-11-10",
        "session_id": session["id"],
    }
    invoices_url = f"{API}/schools/{school['id']}/fees/invoices/bulk"
    first = await client.post(invoices_url, headers=school["hm"], json=payload)
    assert first.status_code == 201, first.text
    assert len(first.json()) == 2

    repeated = await client.post(invoices_url, headers=school["hm"], json=payload)
    assert repeated.status_code == 400, repeated.text
    assert "not applied" in repeated.json()["detail"]

    invoices = await client.get(
        f"{API}/schools/{school['id']}/fees/invoices", headers=school["hm"]
    )
    assert len(invoices.json()) == 2
