"""F01.10 remaining registered-router ownership regressions."""

from app.core.config import settings

from tests.test_broadcast_isolation import another_school
from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def test_course_rejects_foreign_academic_links_before_mutation(client, school):
    sid, hm = school["id"], school["hm"]
    own = await make_academics(client, sid, hm)
    other_sid = await another_school(client, school["sa"])
    foreign = await make_academics(client, other_sid, school["sa"])

    foreign_section = await client.post(
        f"{API}/schools/{sid}/courses",
        headers=hm,
        json={
            "title": "No foreign section",
            "section_id": foreign["section_id"],
            "subject_id": own["subject_id"],
        },
    )
    assert foreign_section.status_code == 404

    foreign_subject = await client.post(
        f"{API}/schools/{sid}/courses",
        headers=hm,
        json={
            "title": "No foreign subject",
            "section_id": own["section_id"],
            "subject_id": foreign["subject_id"],
        },
    )
    assert foreign_subject.status_code == 404

    course = await client.post(
        f"{API}/schools/{sid}/courses",
        headers=hm,
        json={
            "title": "Local course",
            "section_id": own["section_id"],
            "subject_id": own["subject_id"],
        },
    )
    assert course.status_code == 201, course.text

    update = await client.patch(
        f"{API}/schools/{sid}/courses/{course.json()['id']}",
        headers=hm,
        json={"section_id": foreign["section_id"]},
    )
    assert update.status_code == 404
    unchanged = await client.get(
        f"{API}/schools/{sid}/courses/{course.json()['id']}", headers=hm
    )
    assert unchanged.status_code == 200
    assert unchanged.json()["section_id"] == own["section_id"]


async def test_student_cannot_read_or_track_another_sections_course(client, school):
    sid, hm = school["id"], school["hm"]
    academic = await make_academics(client, sid, hm)
    course = await client.post(
        f"{API}/schools/{sid}/courses",
        headers=hm,
        json={
            "title": "Section course",
            "section_id": academic["section_id"],
            "subject_id": academic["subject_id"],
        },
    )
    assert course.status_code == 201, course.text
    course_id = course.json()["id"]
    book = await client.post(
        f"{API}/schools/{sid}/courses/{course_id}/books",
        headers=hm,
        json={"title": "Private book"},
    )
    assert book.status_code == 201, book.text
    chapter = await client.post(
        f"{API}/schools/{sid}/courses/books/{book.json()['id']}/chapters",
        headers=hm,
        json={"title": "Private chapter", "content": "Only this section"},
    )
    assert chapter.status_code == 201, chapter.text
    note = await client.post(
        f"{API}/schools/{sid}/courses/{course_id}/notes",
        headers=hm,
        json={"title": "Private note", "content": "Only this section"},
    )
    assert note.status_code == 201, note.text

    student = await create_user(client, sid, hm, "student")
    student_headers = await login(client, student["email"], student["password"])
    protected_paths = (
        f"/courses/{course_id}",
        f"/courses/{course_id}/books",
        f"/courses/books/{book.json()['id']}/chapters",
        f"/courses/chapters/{chapter.json()['id']}",
        f"/courses/{course_id}/notes",
        f"/courses/notes/{note.json()['id']}",
    )
    for path in protected_paths:
        response = await client.get(f"{API}/schools/{sid}{path}", headers=student_headers)
        assert response.status_code == 404, response.text

    lookup = await client.get(
        f"{API}/schools/{sid}/courses/progress/lookup",
        headers=student_headers,
        params={"resource_type": "book", "resource_id": book.json()["id"]},
    )
    assert lookup.status_code == 404
    update = await client.put(
        f"{API}/schools/{sid}/courses/progress",
        headers=student_headers,
        json={"resource_type": "book", "resource_id": book.json()["id"], "page": 1},
    )
    assert update.status_code == 404

    await enroll(client, sid, hm, academic["section_id"], student["id"])
    readable = await client.get(
        f"{API}/schools/{sid}/courses/chapters/{chapter.json()['id']}",
        headers=student_headers,
    )
    assert readable.status_code == 200
    progress = await client.put(
        f"{API}/schools/{sid}/courses/progress",
        headers=student_headers,
        json={"resource_type": "book", "resource_id": book.json()["id"], "page": 1},
    )
    assert progress.status_code == 200
