"""F01.11 regressions for malformed tenant links outside normal API writes."""

from uuid import UUID

from sqlalchemy import func, select, update

from app.models.academic import StudentEnrollment
from app.models.associations import guardian_students
from app.models.leave import LeaveRequest
from tests.conftest import API
from tests.test_broadcast_isolation import another_school
from tests.test_direct_message_boundaries import family as _family_fixture
from tests.utils import create_user, make_academics

family = _family_fixture


async def test_guardian_placement_ignores_foreign_enrollment_links(client, school, family):
    """A bad enrollment row must not expose another school's class metadata."""
    foreign_school = await another_school(client, school["sa"])
    foreign_academic = await make_academics(client, foreign_school, school["sa"])
    async with family["sessions"]() as db, db.begin():
        await db.execute(
            update(StudentEnrollment)
            .where(StudentEnrollment.id == UUID(family["enrollment"]))
            .values(
                school_id=UUID(foreign_school),
                section_id=UUID(foreign_academic["section_id"]),
            )
        )

    response = await client.get(
        f"{API}/schools/{school['id']}/guardians/{family['guardian']['id']}/children",
        headers=school["hm"],
    )
    assert response.status_code == 200, response.text
    child = response.json()[0]
    assert child["student_id"] == family["student"]["id"]
    assert child["section_id"] is None
    assert child["class_name"] is None


async def test_guardian_leave_rejects_corrupt_foreign_child_link(client, school, family):
    """A malformed guardian association cannot create a local leave for a foreign child."""
    foreign_school = await another_school(client, school["sa"])
    foreign_student = await create_user(
        client, foreign_school, school["sa"], "student"
    )
    async with family["sessions"]() as db, db.begin():
        await db.execute(
            guardian_students.insert().values(
                guardian_id=UUID(family["guardian"]["id"]),
                student_id=UUID(foreign_student["id"]),
                school_id=UUID(school["id"]),
            )
        )

    before = await _leave_count(family, school["id"])
    response = await client.post(
        f"{API}/schools/{school['id']}/leave/requests",
        headers=family["guardian"]["headers"],
        json={
            "student_id": foreign_student["id"],
            "start_date": "2026-10-01",
            "end_date": "2026-10-02",
        },
    )
    assert response.status_code == 403, response.text
    assert await _leave_count(family, school["id"]) == before


async def test_guardian_relink_rejects_corrupt_link_tenant(client, school, family):
    """A successful relink can never acknowledge a link owned by another tenant."""
    foreign_school = await another_school(client, school["sa"])
    guardian_id = UUID(family["guardian"]["id"])
    student_id = UUID(family["student"]["id"])
    async with family["sessions"]() as db, db.begin():
        await db.execute(
            update(guardian_students)
            .where(
                guardian_students.c.guardian_id == guardian_id,
                guardian_students.c.student_id == student_id,
            )
            .values(school_id=UUID(foreign_school))
        )

    response = await client.post(
        f"{API}/schools/{school['id']}/guardians/{guardian_id}/children",
        headers=school["hm"],
        json={"student_id": str(student_id), "relationship": "guardian"},
    )
    assert response.status_code == 400, response.text


async def _leave_count(family, school_id: str) -> int:
    async with family["sessions"]() as db:
        return await db.scalar(
            select(func.count())
            .select_from(LeaveRequest)
            .where(LeaveRequest.school_id == UUID(school_id))
        ) or 0
