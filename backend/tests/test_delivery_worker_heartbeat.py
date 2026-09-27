"""The Redis-independent worker exposes the same liveness signal as ARQ."""
from unittest.mock import AsyncMock

from app import delivery_worker


async def test_standalone_worker_records_heartbeat_before_and_after_poll(monkeypatch):
    heartbeat = AsyncMock()
    poll = AsyncMock()
    dispose = AsyncMock()
    monkeypatch.setattr(delivery_worker, "record_worker_heartbeat", heartbeat)
    monkeypatch.setattr(delivery_worker, "OutboxWorker", lambda _: type("Worker", (), {"run_due": poll})())
    monkeypatch.setattr(
        delivery_worker,
        "engine",
        type("Engine", (), {"dispose": dispose})(),
    )

    await delivery_worker.run(once=True)

    assert heartbeat.await_count == 2
    poll.assert_awaited_once()
    dispose.assert_awaited_once()
