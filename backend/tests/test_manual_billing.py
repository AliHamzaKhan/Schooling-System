"""Manual fee evidence and Headmaster-managed billing contact regressions."""
from datetime import date

from app.core.config import settings
from tests.test_payment_concurrency import make_invoice
from tests.utils import create_user, login

API = settings.API_V1_PREFIX


async def test_manual_payment_accepts_only_recorder_owned_private_proof(client, school):
    invoice_id = await make_invoice(client, school)
    me = await client.get(f"{API}/auth/me", headers=school["hm"])
    assert me.status_code == 200, me.text
    owner_id = me.json()["id"]
    proof_url = (
        f"/media/private/payment_proofs/{school['id']}/{owner_id}/bank-receipt.png"
    )
    payload = {
        "amount": 30,
        "method": "bank_transfer",
        "paid_on": date.today().isoformat(),
        "reference": "BANK-123",
        "proof_url": proof_url,
    }
    recorded = await client.post(
        f"{API}/schools/{school['id']}/fees/invoices/{invoice_id}/payments",
        headers=school["hm"],
        json=payload,
    )
    assert recorded.status_code == 201, recorded.text
    assert recorded.json()["proof_url"] == proof_url

    guardian = await create_user(client, school["id"], school["hm"], "guardian")
    guardian_headers = await login(client, guardian["email"], guardian["password"])
    ticket_path = (
        f"{API}/schools/{school['id']}/files/payment_proofs/"
        f"{recorded.json()['id']}/ticket"
    )
    assert (await client.post(ticket_path, headers=school["hm"])).status_code == 200
    assert (await client.post(ticket_path, headers=guardian_headers)).status_code == 403

    foreign = await client.post(
        f"{API}/schools/{school['id']}/fees/invoices/{invoice_id}/payments",
        headers=school["hm"],
        json=payload | {"amount": 10, "proof_url": "https://bank.example/receipt.png"},
    )
    assert foreign.status_code == 400, foreign.text


async def test_headmaster_manages_linked_guardian_billing_contact(client, school):
    student = await create_user(client, school["id"], school["hm"], "student")
    guardian = await create_user(client, school["id"], school["hm"], "guardian")
    linked = await client.post(
        f"{API}/schools/{school['id']}/guardians/{guardian['id']}/children",
        headers=school["hm"],
        json={"student_id": student["id"], "relationship": "mother"},
    )
    assert linked.status_code == 201, linked.text

    path = (
        f"{API}/schools/{school['id']}/fees/students/{student['id']}"
        f"/billing-contacts/{guardian['id']}"
    )
    saved = await client.put(
        path,
        headers=school["hm"],
        json={
            "billing_email": "billing@example.test",
            "billing_phone": "+15550001111",
            "payer_reference": "FAMILY-001",
            "is_primary": True,
            "note": "Bank transfers use the student reference.",
        },
    )
    assert saved.status_code == 200, saved.text
    assert saved.json()["is_primary"] is True
    assert saved.json()["payer_reference"] == "FAMILY-001"

    candidates = await client.get(
        f"{API}/schools/{school['id']}/fees/students/{student['id']}"
        "/billing-contacts/candidates",
        headers=school["hm"],
    )
    assert candidates.status_code == 200, candidates.text
    assert candidates.json() == [
        {
            "guardian_id": guardian["id"],
            "full_name": "Guardian User",
            "email": guardian["email"],
            "phone": None,
            "relationship": "mother",
        }
    ]

    listed = await client.get(
        f"{API}/schools/{school['id']}/fees/students/{student['id']}/billing-contacts",
        headers=school["hm"],
    )
    assert listed.status_code == 200, listed.text
    assert [row["guardian_id"] for row in listed.json()] == [guardian["id"]]

    guardian_headers = await login(client, guardian["email"], guardian["password"])
    denied = await client.get(
        f"{API}/schools/{school['id']}/fees/students/{student['id']}/billing-contacts",
        headers=guardian_headers,
    )
    assert denied.status_code == 403


async def test_billing_contact_requires_existing_guardian_link(client, school):
    student = await create_user(client, school["id"], school["hm"], "student")
    guardian = await create_user(client, school["id"], school["hm"], "guardian")
    response = await client.put(
        f"{API}/schools/{school['id']}/fees/students/{student['id']}"
        f"/billing-contacts/{guardian['id']}",
        headers=school["hm"],
        json={"is_primary": True},
    )
    assert response.status_code == 400, response.text
