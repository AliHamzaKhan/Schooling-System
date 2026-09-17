"""Cross-school audience references must never create or dispatch messages."""
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock
from uuid import uuid4

import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.models.communication import Message, MessageDelivery
from app.modules.communication import outbox as communication

from .conftest import API, TEST_URL
from .utils import create_user, enroll, make_academics


async def another_school(client, sa):
    response = await client.post(f"{API}/schools", headers=sa,
                                 json={"name": "Other school", "code": uuid4().hex[:10]})
    assert response.status_code == 201, response.text
    sid = response.json()["id"]
    roles = await client.post(f"{API}/schools/{sid}/provision-roles", headers=sa)
    assert roles.status_code == 200, roles.text
    return sid


async def message_counts():
    engine = create_async_engine(TEST_URL)
    try:
        async with async_sessionmaker(engine)() as db:
            return tuple([await db.scalar(select(func.count()).select_from(model))
                          for model in (Message, MessageDelivery)])
    finally:
        await engine.dispose()


@pytest.mark.parametrize("audience_type", ["class", "section", "student_guardians"])
@pytest.mark.parametrize("scheduled", [False, True])
async def test_foreign_audience_rejected_before_write_or_dispatch(client, school, monkeypatch,
                                                               audience_type, scheduled):
    other = await another_school(client, school["sa"])
    academic = await make_academics(client, other, school["sa"])
    student = await create_user(client, other, school["sa"], "student")
    reference = {"class": academic["class_id"], "section": academic["section_id"],
                 "student_guardians": student["id"]}[audience_type]
    dispatch = AsyncMock()
    enqueue = AsyncMock()
    monkeypatch.setattr(communication.notifier, "dispatch", dispatch)
    from app.core import queue
    monkeypatch.setattr(queue, "enqueue", enqueue)
    before = await message_counts()
    body = {"channel": "whatsapp", "audience_type": audience_type,
            "audience_ref": reference, "body": "Do not send"}
    if scheduled:
        body["scheduled_at"] = (datetime.now(timezone.utc) + timedelta(days=1)).isoformat()
    response = await client.post(f"{API}/schools/{school['id']}/communication/broadcasts",
                                 headers=school["hm"], json=body)
    assert response.status_code == 404, response.text
    assert await message_counts() == before
    dispatch.assert_not_awaited()
    enqueue.assert_not_awaited()


@pytest.mark.parametrize("audience_type", ["class", "section"])
async def test_own_audience_selects_only_active_enrolled_users(client, school, audience_type):
    sid, hm = school["id"], school["hm"]
    academic = await make_academics(client, sid, hm)
    active = await create_user(client, sid, hm, "student")
    inactive = await create_user(client, sid, hm, "student")
    unenrolled = await create_user(client, sid, hm, "student")
    for student in (active, inactive):
        await enroll(client, sid, hm, academic["section_id"], student["id"])
    response = await client.post(f"{API}/schools/{sid}/users/{inactive['id']}/deactivate", headers=hm)
    assert response.status_code == 200, response.text
    response = await client.post(f"{API}/schools/{sid}/communication/broadcasts", headers=hm, json={
        "channel": "whatsapp", "audience_type": audience_type,
        "audience_ref": academic[f"{audience_type}_id"], "body": "Class update",
    })
    assert response.status_code == 201, response.text
    from tests.utils import run_notification
    await run_notification(response.json()["id"])
    deliveries = await client.get(
        f"{API}/schools/{sid}/communication/broadcasts/{response.json()['id']}/deliveries", headers=hm)
    assert deliveries.status_code == 200, deliveries.text
    assert {row["user_id"] for row in deliveries.json()} == {active["id"]}
    assert inactive["id"] != unenrolled["id"]


@pytest.mark.parametrize("audience_ref", [None, str(uuid4())])
async def test_missing_or_unknown_reference_does_not_persist(client, school, audience_ref):
    before = await message_counts()
    response = await client.post(f"{API}/schools/{school['id']}/communication/broadcasts",
                                 headers=school["hm"], json={
        "channel": "push", "audience_type": "section", "audience_ref": audience_ref,
        "body": "Invalid audience",
    })
    assert response.status_code == (400 if audience_ref is None else 404), response.text
    assert await message_counts() == before
