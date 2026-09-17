"""Notification persistence distinguishes simulation, acceptance and failure."""
import pytest

from app.modules.communication import outbox as communication
from app.modules.communication.providers import DeliveryResult
from tests.conftest import API
from tests.utils import create_user, login, run_notification


async def guardian(client, school):
    user = await create_user(client, school["id"], school["hm"], "guardian")
    response = await client.patch(f"{API}/schools/{school['id']}/users/{user['id']}",
                                  headers=school["hm"], json={"phone": "+15551112222"})
    assert response.status_code == 200, response.text
    return user


async def broadcast(client, school, channel="email"):
    base = f"{API}/schools/{school['id']}/communication/broadcasts"
    response = await client.post(base, headers=school["hm"], json={
        "channel": channel, "audience_type": "guardians", "body": "Test message",
    })
    assert response.status_code == 201, response.text
    message = response.json()
    assert message["status"] == "pending"
    await run_notification(message["id"])
    message = (await client.get(f"{base}/{message['id']}", headers=school["hm"])).json()
    deliveries = await client.get(f"{base}/{message['id']}/deliveries", headers=school["hm"])
    summary = await client.get(f"{base}/{message['id']}/summary", headers=school["hm"])
    assert deliveries.status_code == summary.status_code == 200
    return message, deliveries.json(), summary.json()


@pytest.mark.parametrize("channel", ["email", "sms", "whatsapp", "push"])
async def test_unconfigured_channel_is_simulated_not_sent(client, school, channel):
    user = await guardian(client, school)
    if channel == "push":
        headers = await login(client, user["email"], user["password"])
        response = await client.post(f"{API}/schools/{school['id']}/communication/device-tokens",
                                     headers=headers, json={"token": "fake-push-device", "platform": "android"})
        assert response.status_code == 201, response.text
    message, deliveries, summary = await broadcast(client, school, channel)
    assert message["status"] == "simulated"
    assert message["sent_at"] is None
    assert len(deliveries) == 1
    assert deliveries[0]["status"] == "simulated"
    assert deliveries[0]["provider"] == "stub"
    assert "no delivery attempted" in deliveries[0]["error"]
    assert summary["counts"]["simulated"] == 1
    assert summary["counts"]["sent"] == summary["counts"]["delivered"] == 0


async def test_push_without_device_records_failure(client, school):
    user = await guardian(client, school)
    message, deliveries, summary = await broadcast(client, school, "push")
    assert message["status"] == "failed" and message["sent_at"] is None
    assert deliveries[0]["user_id"] == user["id"]
    assert deliveries[0]["status"] == "failed"
    assert deliveries[0]["error"] == "No address for this channel"
    assert summary["total"] == summary["counts"]["failed"] == 1


@pytest.mark.parametrize("kind", ["accepted", "failed", "legacy_stub", "mixed"])
async def test_provider_outcomes_are_not_overstated(client, school, monkeypatch, kind):
    await guardian(client, school)
    if kind == "mixed":
        await guardian(client, school)
    calls = 0

    async def dispatch(*args):
        nonlocal calls
        calls += 1
        if kind == "legacy_stub":
            return DeliveryResult(status="sent", provider="stub", stub=True)
        if kind == "failed" or (kind == "mixed" and calls == 2):
            return DeliveryResult(status="failed", provider="test", error="HTTP 503")
        return DeliveryResult(status="accepted", provider="test")

    monkeypatch.setattr(communication.notifier, "dispatch", dispatch)
    message, deliveries, summary = await broadcast(client, school)
    expected = {"legacy_stub": "simulated", "mixed": "partial"}.get(kind, kind)
    assert message["status"] == expected
    assert (message["sent_at"] is not None) == (kind in {"accepted", "mixed"})
    assert summary["counts"]["delivered"] == summary["counts"]["sent"] == 0
    assert all(d["status"] in {"accepted", "failed", "simulated"} for d in deliveries)
    if kind == "mixed":
        assert summary["counts"]["accepted"] == summary["counts"]["failed"] == 1
