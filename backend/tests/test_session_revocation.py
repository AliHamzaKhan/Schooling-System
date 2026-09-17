"""Access and download credentials follow committed server session state."""
import asyncio
from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

import pytest
from sqlalchemy import select, text, update
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core.security import _create_token, create_access_token, decode_token
from app.models.session import RefreshSession
from tests.conftest import API, TEST_URL
from tests.test_private_downloads import document, ticket_endpoint
from tests.utils import create_user


async def tokens(client, school, password="HeadPass123"):
    response = await client.post(f"{API}/auth/login", data={"username": school["hm_email"], "password": password})
    assert response.status_code == 200, response.text
    return response.json()


def headers(pair):
    return {"Authorization": f"Bearer {pair['access_token']}"}


async def test_logout_revokes_access_and_download_but_not_other_session(client, school):
    _, doc, _ = await document(client, school)
    one, two = await tokens(client, school), await tokens(client, school)
    link = await client.post(ticket_endpoint(school, doc), headers=headers(one))
    assert link.status_code == 200, link.text
    assert (await client.get(link.json()["path"])).status_code == 200
    out = await client.post(f"{API}/auth/logout", json={"refresh_token": one["refresh_token"]})
    assert out.status_code == 204
    assert (await client.get(f"{API}/auth/me", headers=headers(one))).status_code == 401
    assert (await client.get(link.json()["path"])).status_code == 401
    assert (await client.get(f"{API}/auth/me", headers=headers(two))).status_code == 200


@pytest.mark.parametrize("action", ["logout-all", "change-password"])
async def test_every_access_token_is_revoked_after_global_action(client, school, action):
    one, two = await tokens(client, school), await tokens(client, school)
    body = {"current_password": "HeadPass123", "new_password": "ChangedPass123"} if action == "change-password" else None
    response = await client.post(f"{API}/auth/{action}", headers=headers(one), json=body)
    assert response.status_code in (200, 204), response.text
    for pair in (one, two):
        assert (await client.get(f"{API}/auth/me", headers=headers(pair))).status_code == 401
        assert (await client.post(f"{API}/auth/refresh", json={"refresh_token": pair["refresh_token"]})).status_code == 401
    fresh = await tokens(client, school, "ChangedPass123" if action == "change-password" else "HeadPass123")
    assert (await client.get(f"{API}/auth/me", headers=headers(fresh))).status_code == 200


@pytest.mark.parametrize("kind", ["legacy", "foreign_session", "expired_session"])
async def test_access_requires_matching_live_session(client, school, kind):
    pair = await tokens(client, school)
    payload = decode_token(pair["access_token"])
    token = pair["access_token"]
    if kind == "legacy":
        token = create_access_token(payload["sub"])
    elif kind == "foreign_session":
        token = create_access_token(str(uuid4()), payload["sid"])
    else:
        engine = create_async_engine(TEST_URL)
        try:
            async with engine.begin() as db:
                await db.execute(update(RefreshSession).where(RefreshSession.id == UUID(payload["sid"]))
                                 .values(expires_at=datetime.now(timezone.utc) - timedelta(seconds=1)))
        finally:
            await engine.dispose()
    assert (await client.get(f"{API}/auth/me", headers={"Authorization": f"Bearer {token}"})).status_code == 401
    if kind == "legacy":
        refreshed = await client.post(f"{API}/auth/refresh", json={"refresh_token": pair["refresh_token"]})
        assert refreshed.status_code == 200
        assert "sid" in decode_token(refreshed.json()["access_token"])


async def test_other_token_purpose_cannot_rotate_or_revoke_session(client, school):
    pair = await tokens(client, school)
    payload = decode_token(pair["access_token"])
    ticket = _create_token(payload["sub"], "file_download", timedelta(seconds=60), sid=payload["sid"])
    assert (await client.post(f"{API}/auth/refresh", json={"refresh_token": ticket})).status_code == 401
    assert (await client.post(f"{API}/auth/logout", json={"refresh_token": ticket})).status_code == 204
    assert (await client.get(f"{API}/auth/me", headers=headers(pair))).status_code == 200


async def test_concurrent_refresh_replay_revokes_the_winning_access_token(client, school):
    pair = await tokens(client, school)
    sid = UUID(decode_token(pair["refresh_token"])["sid"])
    engine = create_async_engine(TEST_URL)
    tasks = []
    try:
        async with async_sessionmaker(engine)() as blocker:
            await blocker.execute(select(RefreshSession).where(RefreshSession.id == sid).with_for_update())
            tasks = [asyncio.create_task(client.post(f"{API}/auth/refresh", json={"refresh_token": pair["refresh_token"]})) for _ in range(2)]
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
        assert sorted(r.status_code for r in responses) == [200, 401]
        winner = next(r.json() for r in responses if r.status_code == 200)
        assert (await client.get(f"{API}/auth/me", headers=headers(winner))).status_code == 401
        assert (await client.get(f"{API}/auth/me", headers=headers(pair))).status_code == 401
    finally:
        for task in tasks:
            if not task.done():
                task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        await engine.dispose()


async def test_reactivation_does_not_restore_old_sessions(client, school):
    student = await create_user(client, school["id"], school["hm"], "student")
    pair = (await client.post(f"{API}/auth/login", data={"username": student["email"], "password": student["password"]})).json()
    path = f"{API}/schools/{school['id']}/users/{student['id']}"
    for active in (False, True):
        response = await client.patch(path, headers=school["hm"], json={"is_active": active})
        assert response.status_code == 200, response.text
        assert (await client.get(f"{API}/auth/me", headers=headers(pair))).status_code == 401
