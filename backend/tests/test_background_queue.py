"""Background-queue offload for notification delivery.

When a broker is configured the broadcast fan-out is handed to the worker rather
than run inside the request; the worker later delivers it via
`CommunicationService.deliver_by_id`. These tests stand in for Redis + a live
worker by stubbing `enqueue` and driving `deliver_by_id` directly.
"""
import uuid

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.modules.communication import service as comm_service
from app.modules.communication.service import CommunicationService

from .conftest import API, TEST_URL
from .utils import create_user


async def test_broadcast_is_offloaded_then_delivered_by_worker(client, school, monkeypatch):
    sid, hm = school["id"], school["hm"]
    g = await create_user(client, sid, hm, "guardian")
    await client.patch(
        f"{API}/schools/{sid}/users/{g['id']}", headers=hm, json={"phone": "+15551112222"}
    )

    # Pretend a broker is configured, and capture what would be enqueued instead
    # of really dialing Redis. Returning True => the service must NOT send inline.
    enqueued: list[tuple] = []

    async def fake_enqueue(task, *args, defer=0):
        enqueued.append((task, args))
        return True

    monkeypatch.setattr(comm_service.settings, "TASK_QUEUE_ENABLED", True)
    monkeypatch.setattr(comm_service, "enqueue", fake_enqueue)

    msg = await client.post(
        f"{API}/schools/{sid}/communication/broadcasts",
        headers=hm,
        json={"channel": "whatsapp", "audience_type": "guardians", "body": "Hello"},
    )
    assert msg.status_code == 201, msg.text
    message_id = msg.json()["id"]

    # Offloaded: the delivery task was enqueued and nothing was sent inline yet.
    assert enqueued == [("deliver_message", (message_id,))]
    assert msg.json()["status"] == "pending"
    summary = await client.get(
        f"{API}/schools/{sid}/communication/broadcasts/{message_id}/summary", headers=hm
    )
    assert summary.json()["total"] == 0  # no MessageDelivery rows recorded yet

    # Now stand in for the worker: a fresh session (as the worker would open) runs
    # the actual delivery, which records the MessageDelivery rows.
    engine = create_async_engine(TEST_URL)
    try:
        async with async_sessionmaker(engine, expire_on_commit=False)() as session:
            delivered = await CommunicationService(session).deliver_by_id(
                uuid.UUID(message_id)
            )
            await session.commit()
            assert delivered is not None
    finally:
        await engine.dispose()

    summary = await client.get(
        f"{API}/schools/{sid}/communication/broadcasts/{message_id}/summary", headers=hm
    )
    assert summary.json()["total"] >= 1  # worker delivered it


async def test_deliver_by_id_missing_row_returns_none(client, school):
    """The worker relies on a ``None`` return to detect the enqueue-before-commit
    race (row not visible yet) and retry."""
    engine = create_async_engine(TEST_URL)
    try:
        async with async_sessionmaker(engine, expire_on_commit=False)() as session:
            result = await CommunicationService(session).deliver_by_id(uuid.uuid4())
            assert result is None
    finally:
        await engine.dispose()
