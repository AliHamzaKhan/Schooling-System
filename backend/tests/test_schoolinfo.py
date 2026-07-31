"""School info: headmaster edits, any member reads the composed profile."""
from app.core.config import settings

from tests.utils import create_user, login

API = settings.API_V1_PREFIX


async def test_headmaster_edits_and_member_reads(client, school):
    sid, hm = school["id"], school["hm"]

    r = await client.put(
        f"{API}/schools/{sid}/info",
        headers=hm,
        json={
            "about": "We are great.",
            "achievements": [{"title": "Champions", "year": "2025"}],
            "uniform_image_url": "/media/uniform/x.png",
        },
    )
    assert r.status_code == 200, r.text
    assert r.json()["about"] == "We are great."
    assert r.json()["achievements"][0]["title"] == "Champions"
    # Composed from the core school row.
    assert r.json()["name"] == "Test School"

    student = await create_user(client, sid, hm, "student")
    sh = await login(client, student["email"], student["password"])
    rg = await client.get(f"{API}/schools/{sid}/info", headers=sh)
    assert rg.status_code == 200
    assert rg.json()["about"] == "We are great."
    assert rg.json()["uniform_image_url"] == "/media/uniform/x.png"


async def test_student_cannot_edit_info(client, school):
    sid, hm = school["id"], school["hm"]
    student = await create_user(client, sid, hm, "student")
    sh = await login(client, student["email"], student["password"])
    r = await client.put(
        f"{API}/schools/{sid}/info", headers=sh, json={"about": "hacked"}
    )
    assert r.status_code == 403


async def test_info_defaults_before_any_edit(client, school):
    sid, hm = school["id"], school["hm"]
    r = await client.get(f"{API}/schools/{sid}/info", headers=hm)
    assert r.status_code == 200
    body = r.json()
    assert body["name"] == "Test School"
    assert body["about"] is None
    assert body["achievements"] == []
