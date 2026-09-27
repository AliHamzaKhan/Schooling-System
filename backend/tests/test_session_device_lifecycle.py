from app.core.security import decode_token
from tests.conftest import API


async def _tokens(client, school):
    response = await client.post(f"{API}/auth/login", data={"username": school["hm_email"], "password": "HeadPass123"})
    assert response.status_code == 200
    return response.json()


def _headers(pair):
    return {"Authorization": f"Bearer {pair['access_token']}"}


async def test_session_list_is_self_only_and_single_revoke_is_immediate(client, school):
    first, second = await _tokens(client, school), await _tokens(client, school)
    listed = await client.get(f"{API}/auth/sessions", headers=_headers(first))
    assert listed.status_code == 200
    rows = listed.json()
    first_id = decode_token(first["access_token"])["sid"]
    second_id = decode_token(second["access_token"])["sid"]
    assert {first_id, second_id}.issubset({row["id"] for row in rows})
    assert next(row for row in rows if row["id"] == first_id)["is_current"] is True
    assert all({"id", "created_at", "last_used_at", "expires_at", "is_current"} == set(row) for row in rows)
    assert all("ip_address" not in row and "user_agent" not in row and "token" not in row for row in rows)
    assert (await client.delete(f"{API}/auth/sessions/{second_id}", headers=_headers(first))).status_code == 204
    assert (await client.get(f"{API}/auth/me", headers=_headers(second))).status_code == 401
    assert (await client.get(f"{API}/auth/me", headers=_headers(first))).status_code == 200
