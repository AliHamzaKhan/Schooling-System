"""Exercise the real upload → record → authorization → byte-download boundary."""
from datetime import timedelta
from urllib.parse import parse_qs, urlsplit
from uuid import UUID, uuid4

import pytest
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core.security import _create_token, decode_token
from app.core.storage import get_storage
from app.models.document import StudentDocument
from tests.conftest import API, TEST_URL
from tests.test_homework_grading import _setup_submission
from tests.utils import create_user, login


async def upload(client, school, headers, folder="documents", data=b"%PDF-private"):
    response = await client.post(f"{API}/schools/{school['id']}/uploads", headers=headers,
                                 data={"folder": folder},
                                 files={"file": ("record.pdf", data, "application/pdf")})
    assert response.status_code == 201, response.text
    return response.json()["url"]


async def document(client, school):
    student = await create_user(client, school["id"], school["hm"], "student")
    student["headers"] = await login(client, student["email"], student["password"])
    url = await upload(client, school, school["hm"])
    base = f"{API}/schools/{school['id']}/students/{student['id']}/documents"
    response = await client.post(base, headers=school["hm"], json={"title": "Certificate", "file_url": url})
    assert response.status_code == 201, response.text
    return student, response.json(), base


def ticket_endpoint(school, record, kind="documents"):
    return f"{API}/schools/{school['id']}/files/{kind}/{record['id']}/ticket"


async def test_private_bytes_need_record_access_and_download_headers(client, school):
    student, doc, _ = await document(client, school)
    assert (await client.get(doc["file_url"])).status_code == 404
    endpoint = ticket_endpoint(school, doc)
    assert (await client.post(endpoint)).status_code == 401
    peer = await create_user(client, school["id"], school["hm"], "student")
    peer_headers = await login(client, peer["email"], peer["password"])
    assert (await client.post(endpoint, headers=peer_headers)).status_code == 403
    for headers in (student["headers"], school["hm"], school["sa"]):
        issued = await client.post(endpoint, headers=headers)
        assert issued.status_code == 200, issued.text
        assert issued.json()["expires_in"] == 60
        assert "no-store" in issued.headers["cache-control"]
        download = await client.get(issued.json()["path"])
        assert download.status_code == 200, download.text
        assert download.content == b"%PDF-private"
        assert "no-store" in download.headers["cache-control"]
        assert download.headers["content-disposition"].startswith("attachment;")
        assert download.headers["x-content-type-options"] == "nosniff"
        assert download.headers["referrer-policy"] == "no-referrer"
    wrong_school = endpoint.replace(school["id"], str(uuid4()))
    assert (await client.post(wrong_school, headers=student["headers"])).status_code == 403
    assert (await client.post(wrong_school, headers=school["sa"])).status_code == 404


async def test_ticket_rechecks_guardian_link_and_deleted_record(client, school):
    student, doc, base = await document(client, school)
    guardian = await create_user(client, school["id"], school["hm"], "guardian")
    headers = await login(client, guardian["email"], guardian["password"])
    endpoint = ticket_endpoint(school, doc)
    assert (await client.post(endpoint, headers=headers)).status_code == 403
    link = f"{API}/schools/{school['id']}/guardians/{guardian['id']}/children"
    assert (await client.post(link, headers=school["hm"], json={"student_id": student["id"]})).status_code == 201
    issued = await client.post(endpoint, headers=headers)
    assert issued.status_code == 200, issued.text
    assert (await client.get(issued.json()["path"])).status_code == 200
    await client.delete(f"{link}/{student['id']}", headers=school["hm"])
    assert (await client.get(issued.json()["path"])).status_code == 403
    own = await client.post(endpoint, headers=student["headers"])
    await client.delete(f"{base}/{doc['id']}", headers=school["hm"])
    assert (await client.get(own.json()["path"])).status_code == 404


@pytest.mark.parametrize("change", ["expired", "wrong_type", "tampered", "changed_blob"])
async def test_invalid_tickets_cannot_download(client, school, change):
    student, doc, _ = await document(client, school)
    issued = await client.post(ticket_endpoint(school, doc), headers=student["headers"])
    token = parse_qs(urlsplit(issued.json()["path"]).query)["ticket"][0]
    payload = decode_token(token)
    extra = {key: payload[key] for key in ("school", "kind", "record", "blob", "sid")}
    if change == "expired":
        token = _create_token(payload["sub"], "file_download", timedelta(seconds=-5), **extra)
    elif change == "wrong_type":
        token = _create_token(payload["sub"], "access", timedelta(seconds=60), **extra)
    elif change == "changed_blob":
        extra["blob"] = "wrong"
        token = _create_token(payload["sub"], "file_download", timedelta(seconds=60), **extra)
    else:
        token = "x" + token[1:]
    response = await client.get(f"{API}/file-download", params={"ticket": token})
    assert response.status_code == 401, response.text
    assert "no-store" in response.headers["cache-control"]


@pytest.mark.parametrize("revocation", ["account", "school"])
async def test_ticket_rechecks_account_and_school_status(client, school, revocation):
    student, doc, _ = await document(client, school)
    issued = await client.post(ticket_endpoint(school, doc), headers=student["headers"])
    if revocation == "account":
        updated = await client.patch(f"{API}/schools/{school['id']}/users/{student['id']}",
                                     headers=school["hm"], json={"is_active": False})
        assert updated.status_code == 200, updated.text
    else:
        updated = await client.post(f"{API}/schools/{school['id']}/status", headers=school["sa"],
                                     json={"status": "suspended"})
        assert updated.status_code == 200, updated.text
    assert (await client.get(issued.json()["path"])).status_code in (401, 403)


async def test_legacy_files_only_resolve_from_existing_school_records(client, school):
    student = await create_user(client, school["id"], school["hm"], "student")
    headers = await login(client, student["email"], student["password"])
    key = f"documents/{school['id']}/{uuid4().hex}_legacy.pdf"
    url = await get_storage().save(key=key, data=b"legacy-private")
    # Simulate already persisted pre-upgrade metadata, never rewrite real data.
    engine = create_async_engine(TEST_URL)
    try:
        async with async_sessionmaker(engine, expire_on_commit=False)() as db:
            doc = StudentDocument(school_id=UUID(school["id"]), student_id=UUID(student["id"]),
                                  title="Legacy", file_url=url)
            db.add(doc)
            await db.commit()
            record_id = str(doc.id)
    finally:
        await engine.dispose()
    assert (await client.get(url, headers=headers)).status_code == 404
    response = await client.post(ticket_endpoint(school, {"id": record_id}), headers=headers)
    assert response.status_code == 200, response.text
    assert (await client.get(response.json()["path"])).content == b"legacy-private"
    base = f"{API}/schools/{school['id']}/students/{student['id']}/documents"
    rejected = await client.post(base, headers=school["hm"], json={"title": "Claim", "file_url": url})
    assert rejected.status_code == 400


async def test_submission_private_access_and_peer_claim_rejected(client, school):
    sid, hm = school["id"], school["hm"]
    setup = await _setup_submission(client, sid, hm)
    url = await upload(client, school, setup["sh"], "submissions")
    base = f"{API}/schools/{sid}/homework/assignments/{setup['assignment_id']}/submissions"
    submitted = await client.post(base, headers=setup["sh"], json={"attachment_url": url})
    assert submitted.status_code == 201, submitted.text
    doc = submitted.json()
    endpoint = ticket_endpoint(school, doc, "submissions")
    for headers in (hm, setup["sh"]):
        issued = await client.post(endpoint, headers=headers)
        assert issued.status_code == 200, issued.text
        assert (await client.get(issued.json()["path"])).content == b"%PDF-private"
    guardian = await create_user(client, sid, hm, "guardian")
    gh = await login(client, guardian["email"], guardian["password"])
    child_link = f"{API}/schools/{sid}/guardians/{guardian['id']}/children"
    await client.post(child_link, headers=hm, json={"student_id": setup["student"]["id"]})
    guardian_ticket = await client.post(endpoint, headers=gh)
    assert guardian_ticket.status_code == 200, guardian_ticket.text
    assert (await client.get(guardian_ticket.json()["path"])).status_code == 200
    await client.delete(f"{child_link}/{setup['student']['id']}", headers=hm)
    assert (await client.get(guardian_ticket.json()["path"])).status_code == 403
    teacher = await create_user(client, sid, hm, "teacher")
    th = await login(client, teacher["email"], teacher["password"])
    for headers in (setup["sh"], th):
        assert (await client.get(base, headers=headers)).status_code == 403
    assert (await client.post(endpoint, headers=th)).status_code == 403
    student_records = f"{API}/schools/{sid}/homework/students/{setup['student']['id']}/submissions"
    assert (await client.get(student_records, headers=th)).json() == []
    parent = f"{API}/schools/{sid}/homework/assignments/{setup['assignment_id']}"
    assert (await client.patch(parent, headers=th, json={"title": "Hijacked"})).status_code == 403
    assert (await client.delete(parent, headers=th)).status_code == 403
    grade = f"{API}/schools/{sid}/homework/submissions/{doc['id']}/grade"
    assert (await client.patch(grade, headers=th, json={"marks_obtained": 5})).status_code == 403
    foreign_url = await upload(client, school, hm, "submissions")
    rejected = await client.post(base, headers=setup["sh"], json={"attachment_url": foreign_url})
    assert rejected.status_code == 400
    # Assigning the teacher to this section enables the established work flow.
    assignment = (await client.get(f"{API}/schools/{sid}/homework/assignments/{setup['assignment_id']}", headers=hm)).json()
    engine = create_async_engine(TEST_URL)
    from app.models.academic import Section
    try:
        async with async_sessionmaker(engine)() as db:
            section = await db.get(Section, UUID(assignment["section_id"]))
            section.class_teacher_id = UUID(teacher["id"])
            await db.commit()
    finally:
        await engine.dispose()
    assert (await client.get(base, headers=th)).status_code == 200
    assert (await client.post(endpoint, headers=th)).status_code == 200
    assert len((await client.get(student_records, headers=th)).json()) == 1


async def test_legacy_cross_school_reference_and_external_url_fail_closed(client, school):
    _, doc, _ = await document(client, school)
    engine = create_async_engine(TEST_URL)
    try:
        for url in (f"/media/documents/{uuid4()}/foreign.pdf", "https://untrusted.example/file.pdf",
                    "/media/documents/../../secret.txt"):
            async with async_sessionmaker(engine)() as db:
                record = await db.get(StudentDocument, UUID(doc["id"]))
                record.file_url = url
                await db.commit()
            denied = await client.post(ticket_endpoint(school, doc), headers=school["hm"])
            assert denied.status_code in (400, 403), denied.text
    finally:
        await engine.dispose()


def test_download_access_log_redacts_ticket_query():
    import logging
    from app.modules.uploads.downloads import DownloadLogFilter
    record = logging.LogRecord("uvicorn.access", logging.INFO, "", 0, '%s - "%s %s HTTP/%s" %d',
                               ("client", "GET", f"{API}/file-download?ticket=secret", "1.1", 200), None)
    assert DownloadLogFilter().filter(record)
    assert "secret" not in record.getMessage()
    assert "file-download" in record.getMessage()


def test_download_access_log_redacts_every_query_value():
    import logging
    from app.modules.uploads.downloads import DownloadLogFilter

    record = logging.LogRecord("uvicorn.access", logging.INFO, "", 0, '%s - "%s %s HTTP/%s" %d',
                               ("client", "GET", f"{API}/auth/verify?email=student@example.test&token=secret", "1.1", 200), None)
    assert DownloadLogFilter().filter(record)
    assert "student@example.test" not in record.getMessage()
    assert "secret" not in record.getMessage()
    assert "/auth/verify" in record.getMessage()


async def test_school_photos_are_for_school_members_only(client, school):
    from tests.test_broadcast_isolation import another_school
    from tests.utils import create_user, login

    png = b"\x89PNG\r\n\x1a\nfixture"
    url = await upload(client, school, school["hm"], "avatars", png)
    assert (await client.get(url)).status_code == 401
    student = await create_user(client, school["id"], school["hm"], "student")
    member = await client.get(url, headers=await login(client, student["email"], student["password"]))
    assert member.status_code == 200
    assert member.headers["content-type"] == "image/png"
    assert member.content == png
    assert (await client.get(url, headers=school["sa"])).status_code == 200

    other = await another_school(client, school["sa"])
    outsider = await create_user(client, other, school["sa"], "teacher")
    denied = await client.get(url, headers=await login(client, outsider["email"], outsider["password"]))
    assert denied.status_code == 404
    for folder in ("avatars", "uniform"):
        response = await client.post(f"{API}/schools/{school['id']}/uploads", headers=school["hm"],
                                     data={"folder": folder}, files={"file": ("x.svg", b"<svg/>", "image/svg+xml")})
        assert response.status_code == 400
