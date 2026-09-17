"""Forgot-password / reset-password OTP flow.

The OTP is delivered by email (stubbed in tests), so each test intercepts the
notifier to read the code out of the message body, then drives
forgot-password → verify-otp → reset-password and checks the new password works.
"""
import asyncio
import re
from uuid import UUID

import pytest
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core.security import decode_token
from app.models.password_reset import PasswordReset
from app.modules.auth import router as auth_router

from .conftest import API, TEST_URL


@pytest.fixture
def captured_otp(monkeypatch):
    """Intercept the reset email and expose the 6-digit code it carries."""
    box: dict[str, str] = {}

    async def fake_dispatch(channel, address, subject, body):
        m = re.search(r"\b(\d{6})\b", body or "")
        if m:
            box["code"] = m.group(1)
            box["address"] = address
        return None

    monkeypatch.setattr(auth_router.notifier, "dispatch", fake_dispatch)
    return box


async def test_full_reset_flow(client, school, captured_otp):
    email = school["hm_email"]

    # 1. Request a code — neutral ack, and the email carries the OTP.
    r = await client.post(f"{API}/auth/forgot-password", json={"email": email})
    assert r.status_code == 200, r.text
    assert "code" in captured_otp, "no OTP was emailed"

    # 2. Verify the OTP → short-lived reset token.
    r = await client.post(
        f"{API}/auth/verify-otp", json={"email": email, "code": captured_otp["code"]}
    )
    assert r.status_code == 200, r.text
    reset_token = r.json()["reset_token"]

    # 3. Reset the password.
    r = await client.post(
        f"{API}/auth/reset-password",
        json={"token": reset_token, "new_password": "BrandNewPass9"},
    )
    assert r.status_code == 200, r.text

    # 4. Old password rejected, new password works.
    old = await client.post(
        f"{API}/auth/login", data={"username": email, "password": "HeadPass123"}
    )
    assert old.status_code == 401, old.text
    new = await client.post(
        f"{API}/auth/login", data={"username": email, "password": "BrandNewPass9"}
    )
    assert new.status_code == 200, new.text


async def test_unknown_email_is_neutral_and_sends_nothing(client, captured_otp):
    r = await client.post(
        f"{API}/auth/forgot-password", json={"email": "nobody-unregistered@nowhere.edu"}
    )
    assert r.status_code == 200, r.text  # same ack as a real address
    assert "code" not in captured_otp  # but no email actually sent


async def test_wrong_otp_is_rejected(client, school, captured_otp):
    email = school["hm_email"]
    await client.post(f"{API}/auth/forgot-password", json={"email": email})
    r = await client.post(
        f"{API}/auth/verify-otp", json={"email": email, "code": "000000"}
    )
    assert r.status_code == 400, r.text
    assert r.json()["error"]["code"] == "bad_request"


async def test_reset_token_cannot_be_reused(client, school, captured_otp):
    email = school["hm_email"]
    await client.post(f"{API}/auth/forgot-password", json={"email": email})
    v = await client.post(
        f"{API}/auth/verify-otp", json={"email": email, "code": captured_otp["code"]}
    )
    token = v.json()["reset_token"]
    first = await client.post(
        f"{API}/auth/reset-password", json={"token": token, "new_password": "FirstReset1"}
    )
    assert first.status_code == 200, first.text
    assert (await client.get(f"{API}/auth/me", headers=school["hm"])).status_code == 401
    # The challenge is consumed — the same token must not reset again.
    second = await client.post(
        f"{API}/auth/reset-password", json={"token": token, "new_password": "SecondReset2"}
    )
    assert second.status_code == 401, second.text


async def test_change_password_requires_current(client, school):
    email = school["hm_email"]
    login = await client.post(
        f"{API}/auth/login", data={"username": email, "password": "HeadPass123"}
    )
    hdr = {"Authorization": f"Bearer {login.json()['access_token']}"}

    # Wrong current password is rejected.
    bad = await client.post(
        f"{API}/auth/change-password", headers=hdr,
        json={"current_password": "WrongOne1", "new_password": "ChangedPass1"},
    )
    assert bad.status_code == 400, bad.text

    # Correct current password changes it; the new one then works to log in.
    ok = await client.post(
        f"{API}/auth/change-password", headers=hdr,
        json={"current_password": "HeadPass123", "new_password": "ChangedPass1"},
    )
    assert ok.status_code == 200, ok.text
    relog = await client.post(
        f"{API}/auth/login", data={"username": email, "password": "ChangedPass1"}
    )
    assert relog.status_code == 200, relog.text


@pytest.mark.parametrize("stage", ["verify-otp", "reset-password"])
async def test_reset_challenge_is_single_use_under_concurrent_requests(
    client, school, captured_otp, stage
):
    email = school["hm_email"]
    await client.post(f"{API}/auth/forgot-password", json={"email": email})
    body = {"email": email, "code": captured_otp["code"]}
    if stage == "reset-password":
        verified = await client.post(f"{API}/auth/verify-otp", json=body)
        assert verified.status_code == 200, verified.text
        body = {"token": verified.json()["reset_token"], "new_password": "ConcurrentReset9"}

    engine = create_async_engine(TEST_URL)
    tasks = []
    try:
        async with async_sessionmaker(engine)() as blocker:
            if stage == "reset-password":
                condition = PasswordReset.id == UUID(decode_token(body["token"])["rid"])
            else:
                access = school["hm"]["Authorization"].removeprefix("Bearer ")
                condition = PasswordReset.user_id == UUID(decode_token(access)["sub"])
            await blocker.execute(select(PasswordReset).where(condition).with_for_update())
            tasks = [asyncio.create_task(client.post(f"{API}/auth/{stage}", json=body)) for _ in range(2)]

            async def wait_for_locks():
                async with engine.connect() as observer:
                    while True:
                        count = await observer.scalar(text("""SELECT count(*) FROM pg_stat_activity
                            WHERE datname=current_database() AND usename=current_user AND wait_event_type='Lock'"""))
                        await observer.commit()
                        if count >= 2:
                            return
                        await asyncio.sleep(0.02)

            await asyncio.wait_for(wait_for_locks(), 10)
            await blocker.commit()
        responses = await asyncio.gather(*tasks)
        assert sorted(r.status_code for r in responses) == [200, 400 if stage == "verify-otp" else 401]
        if stage == "reset-password":
            assert (await client.get(f"{API}/auth/me", headers=school["hm"])).status_code == 401
            login = await client.post(f"{API}/auth/login", data={
                "username": email, "password": body["new_password"],
            })
            assert login.status_code == 200, login.text
    finally:
        for task in tasks:
            if not task.done():
                task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        await engine.dispose()
