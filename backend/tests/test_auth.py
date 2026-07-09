"""Authentication tests."""
from app.core.config import settings

API = settings.API_V1_PREFIX


async def test_login_success_and_me(client, sa_headers):
    r = await client.get(f"{API}/auth/me", headers=sa_headers)
    assert r.status_code == 200
    body = r.json()
    assert body["email"] == settings.FIRST_SUPERADMIN_EMAIL
    assert any(role["code"] == "super_admin" for role in body["roles"])


async def test_login_bad_credentials(client):
    r = await client.post(f"{API}/auth/login", data={"username": settings.FIRST_SUPERADMIN_EMAIL, "password": "wrong"})
    assert r.status_code == 401


async def test_me_requires_auth(client):
    r = await client.get(f"{API}/auth/me")
    assert r.status_code == 401


async def test_refresh_token(client, sa_headers):
    login = await client.post(
        f"{API}/auth/login",
        data={"username": settings.FIRST_SUPERADMIN_EMAIL, "password": settings.FIRST_SUPERADMIN_PASSWORD},
    )
    refresh = login.json()["refresh_token"]
    r = await client.post(f"{API}/auth/refresh", json={"refresh_token": refresh})
    assert r.status_code == 200
    assert "access_token" in r.json()

    # An access token cannot be used to refresh.
    access = login.json()["access_token"]
    bad = await client.post(f"{API}/auth/refresh", json={"refresh_token": access})
    assert bad.status_code == 401


async def _login_tokens(client) -> dict:
    r = await client.post(
        f"{API}/auth/login",
        data={"username": settings.FIRST_SUPERADMIN_EMAIL, "password": settings.FIRST_SUPERADMIN_PASSWORD},
    )
    assert r.status_code == 200, r.text
    return r.json()


async def test_refresh_rotation_and_reuse_detection(client):
    """Rotating a refresh token kills the old one, and replaying a rotated
    token revokes the whole session (reuse == suspected theft)."""
    r0 = (await _login_tokens(client))["refresh_token"]

    # First rotation succeeds and yields a new refresh token.
    first = await client.post(f"{API}/auth/refresh", json={"refresh_token": r0})
    assert first.status_code == 200, first.text
    r1 = first.json()["refresh_token"]
    assert r1 != r0

    # Replaying the now-rotated r0 is rejected...
    reuse = await client.post(f"{API}/auth/refresh", json={"refresh_token": r0})
    assert reuse.status_code == 401

    # ...and the reuse revoked the session, so even the valid r1 is now dead.
    after = await client.post(f"{API}/auth/refresh", json={"refresh_token": r1})
    assert after.status_code == 401


async def test_logout_revokes_session(client):
    tokens = await _login_tokens(client)
    refresh = tokens["refresh_token"]

    out = await client.post(f"{API}/auth/logout", json={"refresh_token": refresh})
    assert out.status_code == 204

    # The refresh token no longer works after logout.
    r = await client.post(f"{API}/auth/refresh", json={"refresh_token": refresh})
    assert r.status_code == 401

    # Logout is idempotent (no error on an already-revoked / unknown token).
    again = await client.post(f"{API}/auth/logout", json={"refresh_token": refresh})
    assert again.status_code == 204


async def test_logout_all_revokes_every_session(client):
    session_a = await _login_tokens(client)
    session_b = await _login_tokens(client)

    out = await client.post(
        f"{API}/auth/logout-all",
        headers={"Authorization": f"Bearer {session_a['access_token']}"},
    )
    assert out.status_code == 204

    for tokens in (session_a, session_b):
        r = await client.post(f"{API}/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
        assert r.status_code == 401


async def test_logout_all_requires_auth(client):
    r = await client.post(f"{API}/auth/logout-all")
    assert r.status_code == 401


async def test_login_is_rate_limited(client):
    """The login endpoint throttles per-IP (disabled in the test env by default,
    so we enable it just for this case)."""
    from app.core.ratelimit import limiter

    limiter.enabled = True
    limiter.reset()
    try:
        codes = []
        for _ in range(12):  # limit is 10/minute
            r = await client.post(
                f"{API}/auth/login", data={"username": "nobody@x.com", "password": "bad"}
            )
            codes.append(r.status_code)
        assert 429 in codes, codes
        # Pre-limit attempts get the normal 401 (bad credentials), not 429.
        assert codes[0] == 401
    finally:
        limiter.reset()
        limiter.enabled = False
