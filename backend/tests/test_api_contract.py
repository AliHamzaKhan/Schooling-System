"""Small, stable OpenAPI contract gate for the authentication/session surface."""

from tests.conftest import API


REQUIRED_OPERATIONS = {
    f"{API}/auth/login": {"post"},
    f"{API}/auth/refresh": {"post"},
    f"{API}/auth/logout": {"post"},
    f"{API}/auth/logout-all": {"post"},
    f"{API}/auth/sessions": {"get"},
    f"{API}/auth/sessions/{{session_id}}": {"delete"},
}


async def test_openapi_keeps_required_auth_and_session_operations(client):
    response = await client.get(f"{API}/openapi.json")

    assert response.status_code == 200
    paths = response.json()["paths"]
    for path, methods in REQUIRED_OPERATIONS.items():
        assert path in paths
        assert methods <= set(paths[path])


async def test_openapi_session_list_does_not_publish_sensitive_metadata(client):
    document = (await client.get(f"{API}/openapi.json")).json()
    schema = document["components"]["schemas"]["SessionOut"]

    assert set(schema["properties"]) == {
        "id",
        "created_at",
        "last_used_at",
        "expires_at",
        "is_current",
    }
