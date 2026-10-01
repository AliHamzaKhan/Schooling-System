"""A homeroom teacher's dashboard counts their section without timetable slots."""
from app.core.config import settings
from tests.utils import create_user, login, make_academics

API = settings.API_V1_PREFIX


async def test_homeroom_section_counts_without_timetable(client, school):
    sid, hm = school["id"], school["hm"]
    academic = await make_academics(client, sid, hm)
    teacher = await create_user(client, sid, hm, "teacher")
    th = await login(client, teacher["email"], teacher["password"])
    url = f"{API}/schools/{sid}/academic/me/dashboard"

    before = await client.get(url, headers=th)
    assert before.status_code == 200, before.text
    assert before.json()["sections_taught"] == 0

    r = await client.patch(
        f"{API}/schools/{sid}/academic/sections/{academic['section_id']}", headers=hm,
        json={"class_teacher_id": teacher["id"]},
    )
    assert r.status_code == 200, r.text
    after = await client.get(url, headers=th)
    assert after.json()["sections_taught"] == 1


async def test_my_sections_lists_homeroom_and_taught_sections(client, school):
    sid, hm = school["id"], school["hm"]
    academic = await make_academics(client, sid, hm)
    teacher = await create_user(client, sid, hm, "teacher")
    other = await create_user(client, sid, hm, "teacher")
    th = await login(client, teacher["email"], teacher["password"])
    url = f"{API}/schools/{sid}/academic/me/sections"
    assert (await client.get(url, headers=th)).json() == []

    second = await client.post(
        f"{API}/schools/{sid}/academic/classes/{academic['class_id']}/sections", headers=hm, json={"name": "B"},
    )
    assert second.status_code == 201, second.text
    await client.patch(
        f"{API}/schools/{sid}/academic/sections/{academic['section_id']}", headers=hm,
        json={"class_teacher_id": teacher["id"]},
    )
    # Another teacher's homeroom must not appear.
    await client.patch(
        f"{API}/schools/{sid}/academic/sections/{second.json()['id']}", headers=hm,
        json={"class_teacher_id": other["id"]},
    )
    rows = (await client.get(url, headers=th)).json()
    assert [(r["section_id"], r["is_homeroom"]) for r in rows] == [(academic["section_id"], True)]
    assert rows[0]["class_name"] == "Grade 1" and rows[0]["section_name"] == "A"
