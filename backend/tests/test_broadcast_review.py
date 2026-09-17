"""Request replay and privacy-safe read-only delivery inspection."""
import asyncio
import hashlib
from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

import pytest
import pytest_asyncio
from sqlalchemy import delete, func, select, text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.models.communication import Message, MessageDelivery, NotificationOutbox
from tests.conftest import API, TEST_URL
from tests.utils import create_user, login, run_notification

PAYLOAD = {"channel": "email", "audience_type": "guardians", "body": "School update"}


@pytest_asyncio.fixture(autouse=True)
async def clear_test_school_work(school):
    """Don't leave this fixture's queued work for later global worker tests."""
    yield
    engine = create_async_engine(TEST_URL)
    try:
        async with engine.begin() as conn:
            await conn.execute(delete(NotificationOutbox).where(NotificationOutbox.message_id.in_(
                select(Message.id).where(Message.school_id == UUID(school["id"]))
            )))
    finally:
        await engine.dispose()


def endpoint(school):
    return f"{API}/schools/{school['id']}/communication/broadcasts"


@pytest.mark.parametrize("change", [{"body": "Changed"}, {"title": "New"},
    {"channel": "sms"}, {"audience_type": "teachers"}, {"audience_ref": str(uuid4())},
    {"scheduled_at": "2030-01-01T10:00:00Z"}])
async def test_changed_payload_conflicts(client, school, change):
    headers = school["hm"] | {"Idempotency-Key": str(uuid4())}
    assert (await client.post(endpoint(school), headers=headers, json=PAYLOAD)).status_code == 201
    result = await client.post(endpoint(school), headers=headers, json=PAYLOAD | change)
    assert result.status_code == 409, result.text


async def test_replay_preserves_current_status_and_single_outbox(client, school):
    await create_user(client, school["id"], school["hm"], "guardian")
    key = str(uuid4())
    headers = school["hm"] | {"Idempotency-Key": key}
    first = await client.post(endpoint(school), headers=headers, json=PAYLOAD)
    assert first.status_code == 201 and first.json()["id"] == key
    await run_notification(key)
    replay = await client.post(endpoint(school), headers=headers, json=PAYLOAD)
    assert replay.status_code == 201 and replay.json()["status"] == "simulated"
    engine = create_async_engine(TEST_URL)
    try:
        async with async_sessionmaker(engine)() as db:
            for model, column in [(Message, Message.id), (NotificationOutbox, NotificationOutbox.message_id),
                                  (MessageDelivery, MessageDelivery.message_id)]:
                assert await db.scalar(select(func.count()).select_from(model).where(column == UUID(key))) == 1
    finally:
        await engine.dispose()


@pytest.mark.parametrize("same", [True, False])
async def test_overlapping_requests_serialize(client, school, same):
    key = uuid4()
    headers = school["hm"] | {"Idempotency-Key": str(key)}
    lock_key = int.from_bytes(hashlib.sha256(b"broadcast:" + key.bytes).digest()[:8], "big", signed=True)
    engine = create_async_engine(TEST_URL)
    tasks = []
    try:
        async with engine.connect() as blocker:
            await blocker.execute(text("SELECT pg_advisory_xact_lock(:key)"), {"key": lock_key})
            tasks = [asyncio.create_task(client.post(endpoint(school), headers=headers, json=body))
                     for body in [PAYLOAD, PAYLOAD if same else PAYLOAD | {"body": "Other"}]]

            async def wait_for_locks():
                async with engine.connect() as observer:
                    while True:
                        count = await observer.scalar(text("""SELECT count(*) FROM pg_stat_activity
                            WHERE datname=current_database() AND usename=current_user
                            AND wait_event_type='Lock' AND wait_event='advisory'"""))
                        await observer.commit()
                        if count >= 2:
                            return
                        await asyncio.sleep(.02)
            await asyncio.wait_for(wait_for_locks(), 10)
            await blocker.commit()
        results = await asyncio.gather(*tasks)
        assert sorted(r.status_code for r in results) == ([201, 201] if same else [201, 409])
        assert {r.json()["id"] for r in results if r.status_code == 201} == {str(key)}
    finally:
        for task in tasks:
            if not task.done():
                task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        await engine.dispose()


async def test_key_is_bound_to_actor_and_school(client, school):
    key = str(uuid4())
    headers = school["hm"] | {"Idempotency-Key": key}
    assert (await client.post(endpoint(school), headers=headers, json=PAYLOAD)).status_code == 201
    teacher = await create_user(client, school["id"], school["hm"], "teacher")
    other = await login(client, teacher["email"], teacher["password"])
    assert (await client.post(endpoint(school), headers=other | {"Idempotency-Key": key}, json=PAYLOAD)).status_code == 409
    # A privileged actor still cannot adopt a request from another tenant.
    engine = create_async_engine(TEST_URL)
    try:
        async with async_sessionmaker(engine)() as db:
            from app.modules.communication.service import CommunicationService
            from app.modules.communication.schemas import BroadcastCreate
            from fastapi import HTTPException
            msg = await db.get(Message, UUID(key))
            with pytest.raises(HTTPException) as exc:
                await CommunicationService(db).create_broadcast(uuid4(), BroadcastCreate(**PAYLOAD), msg.created_by, idempotency_key=UUID(key))
            assert exc.value.status_code == 409
    finally:
        await engine.dispose()


async def test_uuid_validation_timezone_equivalence_and_keyless_compatibility(client, school):
    path = endpoint(school)
    assert (await client.post(path, headers=school["hm"] | {"Idempotency-Key": "invalid"}, json=PAYLOAD)).status_code == 422
    assert (await client.post(path, headers=school["hm"], json=PAYLOAD | {"scheduled_at": "2030-01-01T10:00:00"})).status_code == 422
    headers = school["hm"] | {"Idempotency-Key": str(uuid4())}
    for time in ["2030-01-01T10:00:00Z", "2030-01-01T15:00:00+05:00"]:
        result = await client.post(path, headers=headers, json=PAYLOAD | {"scheduled_at": time})
        assert result.status_code == 201, result.text
    first = await client.post(path, headers=school["hm"], json=PAYLOAD)
    second = await client.post(path, headers=school["hm"], json=PAYLOAD)
    assert first.json()["id"] != second.json()["id"]


async def test_review_access_is_sender_or_administrator(client, school):
    teacher = await create_user(client, school["id"], school["hm"], "teacher")
    sender = await login(client, teacher["email"], teacher["password"])
    result = await client.post(endpoint(school), headers=sender, json=PAYLOAD)
    assert result.status_code == 201, result.text
    path = endpoint(school) + "/" + result.json()["id"]
    for headers in [sender, school["hm"], school["sa"]]:
        for suffix in ["review", "deliveries", "summary"]:
            response = await client.get(f"{path}/{suffix}", headers=headers)
            assert response.status_code == 200, response.text
    for role in ["teacher", "guardian", "student"]:
        user = await create_user(client, school["id"], school["hm"], role)
        headers = await login(client, user["email"], user["password"])
        for suffix in ["review", "deliveries", "summary"]:
            assert (await client.get(f"{path}/{suffix}", headers=headers)).status_code == 403
    assert (await client.get(endpoint(school) + f"/{uuid4()}/review", headers=school["hm"])).status_code == 404


async def test_review_paginates_masks_and_never_mutates(client, school):
    response = await client.post(endpoint(school), headers=school["hm"], json=PAYLOAD)
    mid = UUID(response.json()["id"])
    path = endpoint(school) + f"/{mid}/review"
    engine = create_async_engine(TEST_URL)
    try:
        async with async_sessionmaker(engine)() as db, db.begin():
            job = await db.get(NotificationOutbox, mid)
            job.state = "processing"
            job.lease_until = datetime.now(timezone.utc) - timedelta(seconds=10)
            job.last_error = "PRIVATE historical provider payload"
            for channel, address in [("push", "SECRET_DEVICE_TOKEN"), ("email", "private@example.test"), ("sms", "+15551112222")]:
                db.add(MessageDelivery(school_id=UUID(school["id"]), message_id=mid,
                    channel=channel, address=address, status="uncertain", provider="PRIVATE provider",
                    error="PRIVATE historical provider payload"))
        pages = []
        for offset in range(3):
            result = await client.get(path, headers=school["hm"], params={"limit": 1, "offset": offset})
            assert result.status_code == 200, result.text
            data = result.json()
            assert data["total"] == data["counts"]["uncertain"] == 3
            assert data["has_more"] == (offset < 2)
            assert data["lease_expired"] is True and data["outbox_state"] == "processing"
            assert len(data["items"]) == 1
            assert all(secret not in result.text for secret in ["SECRET", "PRIVATE", "private@example", "+1555", "lease_token", "recipient_key"])
            pages += data["items"]
        assert len({row["id"] for row in pages}) == 3
        assert {row["address_label"] for row in pages} == {"Registered device", "Email address on file", "Phone ending 22"}
        for query in [{"limit": 101}, {"limit": 0}, {"offset": -1}]:
            assert (await client.get(path, headers=school["hm"], params=query)).status_code == 422
        async with async_sessionmaker(engine)() as db:
            assert (await db.get(NotificationOutbox, mid)).state == "processing"
        legacy = await client.get(endpoint(school) + f"/{mid}/deliveries", headers=school["hm"])
        assert next(d for d in legacy.json() if d["channel"] == "push")["address"] is None
    finally:
        await engine.dispose()
