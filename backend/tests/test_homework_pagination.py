"""Homework assignment list pagination and visibility boundaries."""

from app.core.config import settings

from tests.test_broadcast_isolation import another_school
from tests.utils import create_user, enroll, login, make_academics

API = settings.API_V1_PREFIX


async def _assignment(client, school_id, headers, section_id, subject_id, title, due_date):
    response = await client.post(
        f"{API}/schools/{school_id}/homework/assignments",
        headers=headers,
        json={
            "section_id": section_id,
            "subject_id": subject_id,
            "title": title,
            "due_date": due_date,
        },
    )
    assert response.status_code == 201, response.text


async def test_assignment_list_paginates_only_after_student_visibility_scope(client, school):
    school_id, headmaster = school["id"], school["hm"]
    academic = await make_academics(client, school_id, headmaster)
    student = await create_user(client, school_id, headmaster, "student")
    await enroll(client, school_id, headmaster, academic["section_id"], student["id"])
    student_headers = await login(client, student["email"], student["password"])

    # Three assignments in the student's active section, ordered by due date.
    await _assignment(client, school_id, headmaster, academic["section_id"], academic["subject_id"], "Visible newest", "2030-01-03")
    await _assignment(client, school_id, headmaster, academic["section_id"], academic["subject_id"], "Visible middle", "2030-01-02")
    await _assignment(client, school_id, headmaster, academic["section_id"], academic["subject_id"], "Visible oldest", "2030-01-01")

    # A local assignment in another section must be filtered before offset and
    # limit are applied, otherwise it could consume a student's page slot.
    other_section = await client.post(
        f"{API}/schools/{school_id}/academic/classes/{academic['class_id']}/sections",
        headers=headmaster,
        json={"name": "B"},
    )
    assert other_section.status_code == 201, other_section.text
    await _assignment(client, school_id, headmaster, other_section.json()["id"], academic["subject_id"], "Invisible local", "2031-01-01")

    # A separate school's assignment is also excluded by the tenant scope.
    foreign_school_id = await another_school(client, school["sa"])
    foreign_academic = await make_academics(client, foreign_school_id, school["sa"])
    await _assignment(client, foreign_school_id, school["sa"], foreign_academic["section_id"], foreign_academic["subject_id"], "Foreign", "2032-01-01")

    first_page = await client.get(
        f"{API}/schools/{school_id}/homework/assignments",
        headers=student_headers,
        params={"limit": 2, "offset": 0},
    )
    assert first_page.status_code == 200, first_page.text
    assert [row["title"] for row in first_page.json()] == ["Visible newest", "Visible middle"]

    second_page = await client.get(
        f"{API}/schools/{school_id}/homework/assignments",
        headers=student_headers,
        params={"limit": 2, "offset": 2},
    )
    assert second_page.status_code == 200, second_page.text
    assert [row["title"] for row in second_page.json()] == ["Visible oldest"]

    # The shared pagination contract enforces its maximum before reaching the
    # list query, so a caller cannot ask for an unbounded assignment page.
    invalid_limit = await client.get(
        f"{API}/schools/{school_id}/homework/assignments",
        headers=student_headers,
        params={"limit": 101},
    )
    assert invalid_limit.status_code == 422
