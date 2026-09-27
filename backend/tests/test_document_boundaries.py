from uuid import uuid4
from unittest.mock import AsyncMock, patch

from .conftest import API
from .utils import create_user, login


async def test_document_creation_rejects_foreign_student_and_non_student(client, school):
    sid, hm, sa = school["id"], school["hm"], school["sa"]
    other = await client.post(f"{API}/schools", headers=sa,
                              json={"name": "Other", "code": uuid4().hex[:10]})
    oid = other.json()["id"]
    await client.post(f"{API}/schools/{oid}/provision-roles", headers=sa)
    foreign = await create_user(client, oid, sa, "student")
    teacher = await create_user(client, sid, hm, "teacher")
    for student_id in (foreign["id"], teacher["id"], str(uuid4())):
        response = await client.post(f"{API}/schools/{sid}/students/{student_id}/documents",
                                     headers=hm, json={
            "title": "Identity document", "doc_type": "certificate", "file_url": "/media/documents/test.pdf",
        })
        assert response.status_code == 404, response.text
    # The rejected foreign reference created no record under either school.
    response = await client.get(f"{API}/schools/{oid}/students/{foreign['id']}/documents", headers=sa)
    assert response.status_code == 200, response.text
    assert response.json() == []


async def test_document_delete_must_match_student_in_url(client, school):
    sid, hm = school["id"], school["hm"]
    owner = await create_user(client, sid, hm, "student")
    sibling = await create_user(client, sid, hm, "student")
    base = f"{API}/schools/{sid}/students"
    upload = await client.post(f"{API}/schools/{sid}/uploads", headers=hm,
                              data={"folder": "documents"},
                              files={"file": ("certificate.pdf", b"%PDF-test", "application/pdf")})
    assert upload.status_code == 201, upload.text
    created = await client.post(f"{base}/{owner['id']}/documents", headers=hm, json={
        "title": "Certificate", "doc_type": "certificate", "file_url": upload.json()["url"],
    })
    assert created.status_code == 201, created.text
    document_id = created.json()["id"]
    denied = await client.delete(f"{base}/{sibling['id']}/documents/{document_id}", headers=hm)
    assert denied.status_code == 404, denied.text
    listing = await client.get(f"{base}/{owner['id']}/documents", headers=hm)
    assert [row["id"] for row in listing.json()] == [document_id]
    deleted = await client.delete(f"{base}/{owner['id']}/documents/{document_id}", headers=hm)
    assert deleted.status_code == 204, deleted.text


async def test_guardian_document_history_is_paginated_after_child_access(client, school):
    """A guardian's child-scoped document page is bounded only after access succeeds."""
    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    guardian = await create_user(client, sid, hm, "guardian")
    guardian_headers = await login(client, guardian["email"], guardian["password"])
    linked = await client.post(
        f"{API}/schools/{sid}/guardians/{guardian['id']}/children",
        headers=hm,
        json={"student_id": student["id"]},
    )
    assert linked.status_code == 201, linked.text

    base = f"{API}/schools/{sid}/students/{student['id']}/documents"
    for title in ("Birth certificate", "Transfer certificate"):
        created = await client.post(
            base,
            headers=hm,
            json={
                "title": title,
                "doc_type": "certificate",
                "file_url": f"https://files.example/{title.replace(' ', '-')}.pdf",
            },
        )
        assert created.status_code == 201, created.text

    full = await client.get(base, headers=guardian_headers)
    assert full.status_code == 200, full.text
    expected_ids = [row["id"] for row in full.json()]
    assert len(expected_ids) == 2

    first = await client.get(base, headers=guardian_headers, params={"limit": 1})
    second = await client.get(
        base, headers=guardian_headers, params={"limit": 1, "offset": 1},
    )
    assert first.status_code == second.status_code == 200
    assert [row["id"] for row in first.json()] == expected_ids[:1]
    assert [row["id"] for row in second.json()] == expected_ids[1:]
    assert (await client.get(base, headers=guardian_headers, params={"limit": 101})).status_code == 422
    assert (await client.get(base, headers=guardian_headers, params={"offset": -1})).status_code == 422


async def test_upload_rejects_empty_or_oversized_before_storage(client, school, monkeypatch):
    from app.modules.uploads.router import settings
    monkeypatch.setattr(settings, "MAX_UPLOAD_MB", 1)
    save = AsyncMock()
    with patch("app.modules.uploads.router.get_storage") as storage:
        storage.return_value.save = save
        for content in (b"", b"x" * (1024 * 1024 + 1)):
            response = await client.post(f"{API}/schools/{school['id']}/uploads", headers=school["hm"],
                                         files={"file": ("test.pdf", content, "application/pdf")})
            assert response.status_code == 400, response.text
        save.assert_not_awaited()
