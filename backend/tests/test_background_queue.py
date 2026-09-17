"""Real PostgreSQL outbox tests; providers mocked, no Redis/external sends."""
import asyncio
from datetime import timedelta
from uuid import UUID, uuid4
from unittest.mock import AsyncMock

import pytest
import pytest_asyncio
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core import queue
from app.core.security import decode_token
from app.models.communication import Message, MessageDelivery, NotificationOutbox
from app.modules.communication import outbox
from app.modules.communication.outbox import OutboxWorker, now, MAX_JOB_ATTEMPTS
from app.modules.communication.providers import DeliveryResult
from app.modules.communication.schemas import BroadcastCreate
from app.modules.communication.service import CommunicationService
from tests.conftest import API, TEST_URL
from tests.utils import create_user


@pytest_asyncio.fixture
async def worker():
    engine = create_async_engine(TEST_URL)
    result = OutboxWorker(async_sessionmaker(engine, expire_on_commit=False))
    yield result
    await engine.dispose()


@pytest.fixture
def provider(monkeypatch):
    mock = AsyncMock(return_value=DeliveryResult(status="accepted", provider="test"))
    monkeypatch.setattr(outbox.notifier, "dispatch", mock)
    return mock


async def create_message(client, school, scheduled=False, recipients=1):
    for _ in range(recipients):
        await create_user(client, school["id"], school["hm"], "guardian")
    body = {"channel": "email", "audience_type": "guardians", "body": "Test message"}
    if scheduled:
        body["scheduled_at"] = (now() + timedelta(days=1)).isoformat()
    response = await client.post(f"{API}/schools/{school['id']}/communication/broadcasts", headers=school["hm"], json=body)
    assert response.status_code == 201, response.text
    assert response.json()["status"] == ("scheduled" if scheduled else "pending")
    return UUID(response.json()["id"])


async def state(worker, message_id):
    async with worker.sessions() as db:
        message = await db.get(Message, message_id)
        job = await db.get(NotificationOutbox, message_id)
        deliveries = list((await db.scalars(select(MessageDelivery).where(MessageDelivery.message_id == message_id))).all())
        return message, job, deliveries


async def make_due(worker, message_id):
    async with worker.sessions() as db, db.begin():
        await db.execute(update(NotificationOutbox).where(NotificationOutbox.message_id == message_id).values(
            available_at=now() - timedelta(seconds=1), lease_until=now() - timedelta(seconds=1)))


async def test_api_persists_work_without_broker_or_provider_calls(client, school, worker, provider, monkeypatch):
    broker = AsyncMock(side_effect=ConnectionError("broker unavailable"))
    monkeypatch.setattr(queue, "enqueue", broker)
    message_id = await create_message(client, school)
    _, job, deliveries = await state(worker, message_id)
    assert job.state == "pending" and deliveries == []
    broker.assert_not_awaited()
    provider.assert_not_awaited()
    await worker.run_due()
    message, job, deliveries = await state(worker, message_id)
    assert message.status == "accepted" and job.state == "complete"
    assert len(deliveries) == provider.await_count == 1


@pytest.mark.parametrize("commit", [False, True])
async def test_worker_cannot_observe_uncommitted_or_rolled_back_work(client, school, worker, provider, commit):
    await create_user(client, school["id"], school["hm"], "guardian")
    user_id = UUID(decode_token(school["hm"]["Authorization"].removeprefix("Bearer "))["sub"])
    async with worker.sessions() as db:
        message = await CommunicationService(db).create_broadcast(UUID(school["id"]),
            BroadcastCreate(channel="email", audience_type="guardians", body="Atomic"), user_id)
        message_id = message.id
        await worker.process(message_id)
        provider.assert_not_awaited()
        if commit:
            await db.commit()
        else:
            await db.rollback()
    await worker.process(message_id)
    assert provider.await_count == int(commit)


async def test_concurrent_and_repeated_jobs_send_each_recipient_once(client, school, worker, provider):
    message_id = await create_message(client, school)
    entered, release = asyncio.Event(), asyncio.Event()

    async def send(*args):
        entered.set()
        await release.wait()
        return DeliveryResult(status="accepted", provider="test")

    provider.side_effect = send
    first = asyncio.create_task(worker.process(message_id))
    try:
        await asyncio.wait_for(entered.wait(), 10)
        await asyncio.wait_for(worker.process(message_id), 10)
        _, _, rows = await state(worker, message_id)
        assert rows[0].status == "sending"  # durable before provider completion
    finally:
        release.set()
        await first
    await worker.process(message_id)
    assert provider.await_count == 1
    assert len((await state(worker, message_id))[2]) == 1


@pytest.mark.parametrize("failure", [asyncio.CancelledError, RuntimeError])
async def test_crash_after_provider_acceptance_does_not_resend(client, school, worker, provider, monkeypatch, failure):
    message_id = await create_message(client, school, recipients=2)
    finish = worker._finish
    monkeypatch.setattr(worker, "_finish", AsyncMock(side_effect=failure()))
    if failure is asyncio.CancelledError:
        with pytest.raises(asyncio.CancelledError):
            await worker.process(message_id)
    else:
        await worker.process(message_id)
    assert provider.await_count == 1
    await make_due(worker, message_id)
    monkeypatch.setattr(worker, "_finish", finish)
    await worker.process(message_id)
    message, job, rows = await state(worker, message_id)
    assert provider.await_count == 2  # only the second, unattempted recipient
    assert {r.status for r in rows} == {"accepted", "uncertain"}
    assert message.status == "uncertain" and job.state == "needs_review"
    await worker.process(message_id)
    assert provider.await_count == 2


async def test_stale_worker_is_fenced_from_starting_more_attempts(client, school, worker, provider):
    message_id = await create_message(client, school)
    token = await worker._claim(message_id)
    assert await worker._prepare(message_id, token)
    await make_due(worker, message_id)
    await worker.process(message_id)
    assert await worker._take(message_id, token) is None
    assert provider.await_count == 1


async def test_preparation_failure_has_backoff_and_bounded_recovery(client, school, worker, provider, monkeypatch):
    message_id = await create_message(client, school)
    prepare = AsyncMock(side_effect=RuntimeError("secret connection details"))
    monkeypatch.setattr(worker, "_prepare", prepare)
    for attempt in range(MAX_JOB_ATTEMPTS):
        await worker.process(message_id)
        _, job, _ = await state(worker, message_id)
        assert job.attempts == attempt + 1
        assert job.available_at > now()
        assert "secret" not in job.last_error
        await worker.process(message_id)  # backoff has not elapsed
        assert prepare.await_count == attempt + 1
        await make_due(worker, message_id)
    await worker.process(message_id)
    message, job, _ = await state(worker, message_id)
    assert job.state == "needs_review" and message.status == "uncertain"
    provider.assert_not_awaited()


async def test_future_schedule_cannot_be_sent_by_an_early_broker_job(client, school, worker, provider):
    message_id = await create_message(client, school, scheduled=True)
    await worker.process(message_id)
    provider.assert_not_awaited()
    await make_due(worker, message_id)
    await worker.process(message_id)
    assert provider.await_count == 1


async def test_changed_recipient_address_is_not_retargeted_after_planning(client, school, worker, provider):
    message_id = await create_message(client, school)
    token = await worker._claim(message_id)
    await worker._prepare(message_id, token)
    _, _, rows = await state(worker, message_id)
    response = await client.patch(f"{API}/schools/{school['id']}/users/{rows[0].user_id}",
        headers=school["hm"], json={"is_active": False})
    assert response.status_code == 200
    await make_due(worker, message_id)
    await worker.process(message_id)
    assert (await state(worker, message_id))[2][0].status == "failed"
    provider.assert_not_awaited()


async def test_ambiguous_provider_exception_requires_review_without_retry(client, school, worker, provider):
    message_id = await create_message(client, school)
    provider.side_effect = TimeoutError("secret recipient")
    await worker.process(message_id)
    await worker.process(message_id)
    message, job, rows = await state(worker, message_id)
    assert message.status == "uncertain" and job.state == "needs_review"
    assert "secret" not in rows[0].error
    assert provider.await_count == 1


async def test_missing_and_legacy_jobs_are_not_adopted(client, school, worker, provider):
    await worker.process(uuid4())
    async with worker.sessions() as db, db.begin():
        message = Message(school_id=UUID(school["id"]), body="Legacy", channel="email",
                          audience_type="guardians", status="sent")
        db.add(message)
        await db.flush()
        message_id = message.id
    await worker.process(message_id)
    provider.assert_not_awaited()
