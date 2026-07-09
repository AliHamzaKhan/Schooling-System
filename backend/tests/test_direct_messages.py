"""Direct messages: staff ↔ guardian send, inbox scoping, read receipts."""
from app.core.config import settings

from tests.utils import create_user, login

API = settings.API_V1_PREFIX


async def test_send_inbox_and_read(client, school):
    sid, hm = school["id"], school["hm"]
    teacher = await create_user(client, sid, hm, "teacher")
    guardian = await create_user(client, sid, hm, "guardian")
    th = await login(client, teacher["email"], teacher["password"])
    gh = await login(client, guardian["email"], guardian["password"])

    # Teacher sends a message and a complaint to the guardian.
    r = await client.post(
        f"{API}/schools/{sid}/messages",
        headers=th,
        json={"recipient_id": guardian["id"], "body": "Hello!", "kind": "message"},
    )
    assert r.status_code == 201, r.text
    r = await client.post(
        f"{API}/schools/{sid}/messages",
        headers=th,
        json={"recipient_id": guardian["id"], "body": "A concern.", "kind": "complaint"},
    )
    assert r.status_code == 201, r.text
    complaint_id = r.json()["id"]

    # Guardian inbox holds both, newest first, with the sender's name.
    r = await client.get(f"{API}/schools/{sid}/messages", headers=gh)
    assert r.status_code == 200
    inbox = r.json()
    assert [m["kind"] for m in inbox] == ["complaint", "message"]
    assert inbox[0]["sender_name"] == "Teacher User"  # create_user's full_name
    assert all(m["read_at"] is None for m in inbox)

    # The teacher's inbox is empty; their sent box holds both.
    r = await client.get(f"{API}/schools/{sid}/messages", headers=th)
    assert r.json() == []
    r = await client.get(f"{API}/schools/{sid}/messages?box=sent", headers=th)
    assert len(r.json()) == 2

    # Only the recipient can mark a message read.
    r = await client.patch(
        f"{API}/schools/{sid}/messages/{complaint_id}/read", headers=th
    )
    assert r.status_code == 403
    r = await client.patch(
        f"{API}/schools/{sid}/messages/{complaint_id}/read", headers=gh
    )
    assert r.status_code == 200
    assert r.json()["read_at"] is not None


async def test_cannot_message_self(client, school):
    sid, hm = school["id"], school["hm"]
    teacher = await create_user(client, sid, hm, "teacher")
    th = await login(client, teacher["email"], teacher["password"])
    r = await client.post(
        f"{API}/schools/{sid}/messages",
        headers=th,
        json={"recipient_id": teacher["id"], "body": "hi me"},
    )
    assert r.status_code == 400
