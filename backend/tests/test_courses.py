"""Course content: headmaster authoring, member reads, reading progress, gating."""
from app.core.config import settings

from tests.utils import create_user, login

API = settings.API_V1_PREFIX


async def _course(client, sid, hm, title="Science"):
    r = await client.post(
        f"{API}/schools/{sid}/courses",
        headers=hm,
        json={"title": title, "subject": "Sci", "description": "About"},
    )
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def test_headmaster_authors_and_member_reads(client, school):
    sid, hm = school["id"], school["hm"]
    cid = await _course(client, sid, hm)

    rb = await client.post(
        f"{API}/schools/{sid}/courses/{cid}/books", headers=hm, json={"title": "Book 1"}
    )
    assert rb.status_code == 201, rb.text
    bid = rb.json()["id"]
    rc = await client.post(
        f"{API}/schools/{sid}/courses/books/{bid}/chapters",
        headers=hm,
        json={"title": "Ch 1", "content": "Hello chapter"},
    )
    assert rc.status_code == 201, rc.text
    chid = rc.json()["id"]
    rn = await client.post(
        f"{API}/schools/{sid}/courses/{cid}/notes",
        headers=hm,
        json={"title": "Note 1", "content": "Note body"},
    )
    assert rn.status_code == 201, rn.text

    # Any active member (a student) can read the material.
    student = await create_user(client, sid, hm, "student")
    sh = await login(client, student["email"], student["password"])

    rl = await client.get(f"{API}/schools/{sid}/courses", headers=sh)
    assert rl.status_code == 200
    row = next(c for c in rl.json() if c["id"] == cid)
    assert row["book_count"] == 1 and row["note_count"] == 1

    rch = await client.get(f"{API}/schools/{sid}/courses/chapters/{chid}", headers=sh)
    assert rch.status_code == 200
    assert rch.json()["content"] == "Hello chapter"


async def test_student_cannot_author(client, school):
    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    sh = await login(client, student["email"], student["password"])
    r = await client.post(
        f"{API}/schools/{sid}/courses", headers=sh, json={"title": "Nope"}
    )
    assert r.status_code == 403


async def test_reading_progress_roundtrip(client, school):
    sid, hm = school["id"], school["hm"]
    cid = await _course(client, sid, hm)
    rb = await client.post(
        f"{API}/schools/{sid}/courses/{cid}/books", headers=hm, json={"title": "Book"}
    )
    bid = rb.json()["id"]
    student = await create_user(client, sid, hm, "student")
    sh = await login(client, student["email"], student["password"])

    # No progress yet -> page 0.
    r0 = await client.get(
        f"{API}/schools/{sid}/courses/progress/lookup",
        headers=sh,
        params={"resource_type": "book", "resource_id": bid},
    )
    assert r0.status_code == 200 and r0.json()["page"] == 0

    r1 = await client.put(
        f"{API}/schools/{sid}/courses/progress",
        headers=sh,
        json={"resource_type": "book", "resource_id": bid, "page": 42},
    )
    assert r1.status_code == 200 and r1.json()["page"] == 42

    r2 = await client.get(
        f"{API}/schools/{sid}/courses/progress/lookup",
        headers=sh,
        params={"resource_type": "book", "resource_id": bid},
    )
    assert r2.json()["page"] == 42


async def test_progress_is_per_user(client, school):
    sid, hm = school["id"], school["hm"]
    cid = await _course(client, sid, hm)
    bid = (await client.post(
        f"{API}/schools/{sid}/courses/{cid}/books", headers=hm, json={"title": "Book"}
    )).json()["id"]
    a = await create_user(client, sid, hm, "student")
    b = await create_user(client, sid, hm, "student")
    ah = await login(client, a["email"], a["password"])
    bh = await login(client, b["email"], b["password"])
    await client.put(
        f"{API}/schools/{sid}/courses/progress", headers=ah,
        json={"resource_type": "book", "resource_id": bid, "page": 10},
    )
    r = await client.get(
        f"{API}/schools/{sid}/courses/progress/lookup", headers=bh,
        params={"resource_type": "book", "resource_id": bid},
    )
    assert r.json()["page"] == 0  # b has their own (empty) progress
