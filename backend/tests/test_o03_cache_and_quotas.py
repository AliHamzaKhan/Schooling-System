"""O03 HTTP cache policy and bulk-job quotas."""
from datetime import date
from uuid import uuid4

from app.core import quotas
from app.core.config import settings
from tests.utils import create_user, enroll, make_academics

API = settings.API_V1_PREFIX


async def test_credentialed_and_token_responses_are_not_http_cacheable(client, school):
    for path in ("fees/invoices", "homework/assignments", "exams"):
        response = await client.get(f"{API}/schools/{school['id']}/{path}", headers=school["hm"])
        assert response.status_code == 200, response.text
        assert response.headers["cache-control"] == "private, no-store", path

    login = await client.post(
        f"{API}/auth/login", data={"username": school["hm_email"], "password": "HeadPass123"}
    )
    assert login.status_code == 200
    assert login.headers["cache-control"] == "private, no-store"

    # Unauthenticated public metadata keeps default HTTP caching semantics.
    assert "cache-control" not in (await client.get("/health")).headers


async def test_roster_bulk_writes_reject_oversized_requests_before_writing(client, school):
    academic = await make_academics(client, school["id"], school["hm"])
    oversized = [
        {"student_id": str(uuid4()), "status": "present"}
        for _ in range(quotas.BULK_ROSTER_MAX_ENTRIES + 1)
    ]
    response = await client.post(
        f"{API}/schools/{school['id']}/attendance",
        headers=school["hm"],
        json={"section_id": academic["section_id"], "attendance_date": "2030-01-02", "entries": oversized},
    )
    assert response.status_code == 422, response.text

    staff = [
        {"teacher_id": str(uuid4()), "attendance_date": "2030-01-02", "status": "present"}
        for _ in range(quotas.BULK_STAFF_MAX_ENTRIES + 1)
    ]
    response = await client.post(
        f"{API}/schools/{school['id']}/hr/attendance", headers=school["hm"], json={"entries": staff},
    )
    assert response.status_code == 422, response.text


async def test_bulk_invoice_issuance_enforces_student_quota_without_writes(client, school, monkeypatch):
    from app.modules.fees import service as fee_service

    academic = await make_academics(client, school["id"], school["hm"])
    for _ in range(3):
        student = await create_user(client, school["id"], school["hm"], "student")
        await enroll(client, school["id"], school["hm"], academic["section_id"], student["id"])
    monkeypatch.setattr(fee_service, "BULK_INVOICE_MAX_STUDENTS", 2)

    payload = {
        "class_id": academic["class_id"], "title": "Quota tuition", "amount": 1000,
        "due_date": date(2030, 2, 1).isoformat(),
    }
    url = f"{API}/schools/{school['id']}/fees/invoices"
    response = await client.post(f"{url}/bulk", headers=school["hm"], json=payload)
    assert response.status_code == 400, response.text
    assert "limited to 2 students" in response.text
    assert (await client.get(url, headers=school["hm"])).json() == []

    monkeypatch.setattr(fee_service, "BULK_INVOICE_MAX_STUDENTS", 3)
    response = await client.post(f"{url}/bulk", headers=school["hm"], json=payload)
    assert response.status_code == 201, response.text
    assert len(response.json()) == 3
