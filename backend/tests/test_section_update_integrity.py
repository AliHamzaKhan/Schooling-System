"""Regression coverage for section setup updates."""

from app.core.config import settings

API = settings.API_V1_PREFIX


async def test_section_rename_cannot_duplicate_another_section(client, school):
    school_class = await client.post(
        f"{API}/schools/{school['id']}/academic/classes",
        headers=school["hm"],
        json={"name": "Grade 6"},
    )
    assert school_class.status_code == 201, school_class.text

    first = await client.post(
        f"{API}/schools/{school['id']}/academic/classes/{school_class.json()['id']}/sections",
        headers=school["hm"],
        json={"name": "A"},
    )
    second = await client.post(
        f"{API}/schools/{school['id']}/academic/classes/{school_class.json()['id']}/sections",
        headers=school["hm"],
        json={"name": "B"},
    )
    assert first.status_code == second.status_code == 201

    rejected = await client.patch(
        f"{API}/schools/{school['id']}/academic/sections/{second.json()['id']}",
        headers=school["hm"],
        json={"name": "A"},
    )
    assert rejected.status_code == 400, rejected.text
    assert "already exists" in rejected.json()["detail"].lower()

    sections = await client.get(
        f"{API}/schools/{school['id']}/academic/classes/{school_class.json()['id']}/sections",
        headers=school["hm"],
    )
    assert sections.status_code == 200, sections.text
    assert [(section["id"], section["name"]) for section in sections.json()] == [
        (first.json()["id"], "A"),
        (second.json()["id"], "B"),
    ]


async def test_class_rename_cannot_duplicate_another_class_in_its_session(client, school):
    classes_url = f"{API}/schools/{school['id']}/academic/classes"
    first = await client.post(classes_url, headers=school["hm"], json={"name": "Grade 6"})
    second = await client.post(classes_url, headers=school["hm"], json={"name": "Grade 7"})
    assert first.status_code == second.status_code == 201

    rejected = await client.patch(
        f"{classes_url}/{second.json()['id']}",
        headers=school["hm"],
        json={"name": "Grade 6"},
    )
    assert rejected.status_code == 400, rejected.text
    assert "already exists" in rejected.json()["detail"].lower()

    classes = await client.get(classes_url, headers=school["hm"])
    assert classes.status_code == 200, classes.text
    assert [(row["id"], row["name"]) for row in classes.json()] == [
        (first.json()["id"], "Grade 6"),
        (second.json()["id"], "Grade 7"),
    ]


async def test_subject_code_update_cannot_duplicate_another_subject(client, school):
    subjects_url = f"{API}/schools/{school['id']}/academic/subjects"
    first = await client.post(
        subjects_url, headers=school["hm"], json={"code": "MATH", "name": "Mathematics"}
    )
    second = await client.post(
        subjects_url, headers=school["hm"], json={"code": "SCI", "name": "Science"}
    )
    assert first.status_code == second.status_code == 201

    rejected = await client.patch(
        f"{subjects_url}/{second.json()['id']}",
        headers=school["hm"],
        json={"code": "MATH"},
    )
    assert rejected.status_code == 400, rejected.text
    assert "already exists" in rejected.json()["detail"].lower()

    subjects = await client.get(subjects_url, headers=school["hm"])
    assert subjects.status_code == 200, subjects.text
    assert {row["code"] for row in subjects.json()} == {"MATH", "SCI"}
