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
