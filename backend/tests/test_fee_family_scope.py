"""Guardians and students read only their own family's fee records."""
from app.core.config import settings
from tests.utils import create_user, login

API = settings.API_V1_PREFIX


async def _invoice(client, sid, hm, student_id, title):
    r = await client.post(f"{API}/schools/{sid}/fees/invoices", headers=hm, json={
        "student_id": student_id, "title": title, "amount": 100, "due_date": "2030-01-10",
    })
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def test_guardian_fee_reads_are_limited_to_linked_children(client, school):
    sid, hm = school["id"], school["hm"]
    child = await create_user(client, sid, hm, "student")
    other = await create_user(client, sid, hm, "student")
    guardian = await create_user(client, sid, hm, "guardian")
    link = f"{API}/schools/{sid}/guardians/{guardian['id']}/children"
    assert (await client.post(link, headers=hm, json={"student_id": child["id"]})).status_code == 201
    own = await _invoice(client, sid, hm, child["id"], "Own family")
    foreign = await _invoice(client, sid, hm, other["id"], "Other family")
    gh = await login(client, guardian["email"], guardian["password"])
    base = f"{API}/schools/{sid}/fees"

    listed = (await client.get(f"{base}/invoices", headers=gh)).json()
    assert [i["id"] for i in listed] == [own]
    filtered = await client.get(f"{base}/invoices", headers=gh, params={"student_id": other["id"]})
    assert filtered.status_code == 200 and filtered.json() == []
    assert (await client.get(f"{base}/invoices/{foreign}", headers=gh)).status_code == 404
    assert (await client.get(f"{base}/invoices/{foreign}/receipt", headers=gh)).status_code == 404
    assert (await client.get(f"{base}/invoices/{own}", headers=gh)).status_code == 200
    assert (await client.get(f"{base}/students", headers=gh)).status_code == 403

    # Unlinking revokes access immediately.
    assert (await client.delete(f"{link}/{child['id']}", headers=hm)).status_code == 204
    assert (await client.get(f"{base}/invoices", headers=gh)).json() == []
    assert (await client.get(f"{base}/invoices/{own}", headers=gh)).status_code == 404

    # Staff keep school-wide visibility.
    assert len((await client.get(f"{base}/invoices", headers=hm)).json()) == 2
