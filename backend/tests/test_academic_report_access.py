"""HTTP regression tests for current academic relationships and nested tenants."""
from datetime import datetime, timezone
from uuid import UUID, uuid4

import pytest
from sqlalchemy import delete, select, update

from app.models.academic import Section, StudentEnrollment, TimetableSlot
from app.models.associations import guardian_students, user_roles
from app.models.examination import Exam, ExamResult, ExamSubject, Mark
from app.models.user import User
from app.models.role import RolePermission
from tests.conftest import API
from tests.test_broadcast_isolation import another_school
from tests.test_direct_message_boundaries import family as _family_fixture
from tests.utils import create_user, enroll, login, make_academics

family = _family_fixture


def student_paths(school, student_id):
    base = f"{API}/schools/{school['id']}"
    return [f"{base}/reports/students/{student_id}",
            f"{base}/academic/students/{student_id}/performance",
            f"{base}/academic/students/{student_id}/timetable"]


@pytest.mark.parametrize('viewer', ['teacher', 'guardian', 'student'])
async def test_current_relationships_and_unrelated_student_denial(client, school, family, viewer):
    for path in student_paths(school, family['student']['id']):
        response = await client.get(path, headers=family[viewer]['headers'])
        assert response.status_code == 200, response.text
        assert 'no-store' in response.headers['cache-control']
    for path in student_paths(school, family['other']['id']):
        response = await client.get(path, headers=family[viewer]['headers'])
        assert response.status_code == 403, response.text
        assert 'no-store' in response.headers['cache-control']


@pytest.mark.parametrize('viewer', ['teacher', 'guardian'])
async def test_revoked_relationship_takes_effect_with_same_token(client, school, family, viewer):
    async with family['sessions']() as db, db.begin():
        if viewer == 'teacher':
            await db.execute(update(Section).where(Section.id == UUID(family['academic']['section_id'])).values(class_teacher_id=None))
        else:
            await db.execute(delete(guardian_students).where(guardian_students.c.guardian_id == UUID(family['guardian']['id'])))
    for path in student_paths(school, family['student']['id']):
        assert (await client.get(path, headers=family[viewer]['headers'])).status_code == 403


async def test_rosters_and_rankings_are_staff_relationship_scoped(client, school, family):
    sid, hm, ac = school['id'], school['hm'], family['academic']
    root = f'{API}/schools/{sid}'
    second = await client.post(f"{root}/academic/classes/{ac['class_id']}/sections", headers=hm, json={'name': 'B'})
    other_section = second.json()['id']
    await enroll(client, sid, hm, other_section, family['other']['id'])
    for section in [ac['section_id'], other_section]:
        paths = [f'{root}/sections/{section}/students', f'{root}/academic/sections/{section}/performance', f'{root}/quizzes/sections/{section}/students']
        for path in paths:
            assert (await client.get(path, headers=hm)).status_code == 200
            expected = 200 if section == ac['section_id'] else 403
            assert (await client.get(path, headers=family['teacher']['headers'])).status_code == expected
            for viewer in ['student', 'guardian']:
                assert (await client.get(path, headers=family[viewer]['headers'])).status_code == 403
    roster = await client.get(f'{root}/academic/students', headers=family['teacher']['headers'])
    assert {s['id'] for s in roster.json()} == {family['student']['id']}
    roster = await client.get(f'{root}/academic/students', headers=hm)
    assert {s['id'] for s in roster.json()} == {family['student']['id'], family['other']['id']}


async def test_timetabled_teacher_and_enrollment_revocation(client, school, family):
    sid, hm, ac = school['id'], school['hm'], family['academic']
    async with family['sessions']() as db, db.begin():
        await db.execute(update(Section).where(Section.id == UUID(ac['section_id'])).values(class_teacher_id=None))
    response = await client.post(f'{API}/schools/{sid}/academic/timetable', headers=hm, json={
        'section_id': ac['section_id'], 'subject_id': ac['subject_id'], 'teacher_id': family['teacher']['id'],
        'day_of_week': 0, 'start_time': '09:00', 'end_time': '10:00',
    })
    assert response.status_code == 201, response.text
    for path in student_paths(school, family['student']['id']):
        assert (await client.get(path, headers=family['teacher']['headers'])).status_code == 200
    async with family['sessions']() as db, db.begin():
        await db.execute(update(StudentEnrollment).where(StudentEnrollment.id == UUID(family['enrollment'])).values(status='inactive'))
    for path in student_paths(school, family['student']['id']):
        assert (await client.get(path, headers=family['teacher']['headers'])).status_code == 403
        assert (await client.get(path, headers=hm)).status_code == 200


async def test_foreign_missing_nonstudent_targets_and_bad_uuid(client, school, family):
    other_sid = await another_school(client, school['sa'])
    other = await create_user(client, other_sid, school['sa'], 'student')
    for student_id in [other['id'], str(uuid4()), family['teacher']['id']]:
        for path in student_paths(school, student_id):
            assert (await client.get(path, headers=school['hm'])).status_code == 404
            assert (await client.get(path, headers=school['sa'])).status_code == 404
    for path in student_paths(school, 'not-a-uuid'):
        assert (await client.get(path, headers=school['hm'])).status_code == 422


async def test_draft_marks_hidden_until_result_publication(client, school, family):
    sid, ac, student = UUID(school['id']), family['academic'], UUID(family['student']['id'])
    async with family['sessions']() as db, db.begin():
        exam = Exam(school_id=sid, class_id=UUID(ac['class_id']), name='Private draft exam')
        db.add(exam)
        await db.flush()
        paper = ExamSubject(school_id=sid, exam_id=exam.id, subject_id=UUID(ac['subject_id']), max_marks=100, pass_marks=40)
        db.add(paper)
        await db.flush()
        db.add(Mark(school_id=sid, student_id=student, exam_subject_id=paper.id, marks_obtained=88))
        result = ExamResult(school_id=sid, exam_id=exam.id, student_id=student, total_marks=88, max_total=100, percentage=88, grade='A', status='pass', published=False)
        db.add(result)
        await db.flush()
        result_id = result.id
    path = student_paths(school, student)[1]
    for headers in [school['hm'], family['teacher']['headers']]:
        response = await client.get(path, headers=headers)
        assert response.status_code == 200, response.text
        assert response.json()['trend_labels'] == ['Private draft exam']
    for viewer in ['student', 'guardian']:
        response = await client.get(path, headers=family[viewer]['headers'])
        assert response.json()['recent'] == []
        assert response.json()['trend_labels'] == []
    async with family['sessions']() as db, db.begin():
        await db.execute(update(ExamResult).where(ExamResult.id == result_id).values(published=True, published_at=datetime.now(timezone.utc)))
    for viewer in ['student', 'guardian']:
        response = await client.get(path, headers=family[viewer]['headers'])
        assert response.json()['trend_scores'] == [88.0]
    async with family['sessions']() as db, db.begin():
        await db.execute(update(ExamResult).where(ExamResult.id == result_id).values(published=False))
    assert (await client.get(path, headers=family['student']['headers'])).json()['recent'] == []


async def test_cross_school_linked_metadata_is_filtered(client, school, family):
    sid, ac, student = UUID(school['id']), family['academic'], UUID(family['student']['id'])
    foreign_sid = await another_school(client, school['sa'])
    foreign_ac = await make_academics(client, foreign_sid, school['sa'])
    foreign_student = await create_user(client, foreign_sid, school['sa'], 'student', full_name='Foreign secret student')
    foreign_guardian = await create_user(client, foreign_sid, school['sa'], 'guardian', full_name='Foreign secret guardian')
    async with family['sessions']() as db, db.begin():
        # Deliberately inconsistent legacy rows: FK existence is not tenant ownership.
        db.add(StudentEnrollment(school_id=sid, student_id=UUID(foreign_student['id']), section_id=UUID(ac['section_id']), status='active'))
        db.add(StudentEnrollment(school_id=sid, student_id=student, section_id=UUID(foreign_ac['section_id']), status='active'))
        await db.execute(guardian_students.insert().values(school_id=sid, guardian_id=UUID(foreign_guardian['id']), student_id=student))
        exam = Exam(school_id=UUID(foreign_sid), class_id=UUID(foreign_ac['class_id']), name='Foreign secret exam')
        db.add(exam)
        await db.flush()
        paper = ExamSubject(school_id=sid, exam_id=exam.id, subject_id=UUID(foreign_ac['subject_id']), max_marks=100, pass_marks=40)
        db.add(paper)
        await db.flush()
        db.add(Mark(school_id=sid, exam_subject_id=paper.id, student_id=student, marks_obtained=91))
        db.add(ExamResult(school_id=sid, exam_id=exam.id, student_id=student, total_marks=91, max_total=100, percentage=91, grade='A', status='pass', published=True))
        from datetime import time
        db.add(TimetableSlot(school_id=sid, section_id=UUID(ac['section_id']), subject_id=UUID(foreign_ac['subject_id']), day_of_week=0, start_time=time(9), end_time=time(10)))
    root = f"{API}/schools/{sid}"
    for path in student_paths(school, student) + [f"{root}/academic/sections/{ac['section_id']}/performance", f"{root}/sections/{ac['section_id']}/students", f"{root}/quizzes/sections/{ac['section_id']}/students", f'{root}/academic/students']:
        response = await client.get(path, headers=school['hm'])
        assert response.status_code == 200, response.text
        assert 'Foreign secret' not in response.text
        assert foreign_student['id'] not in response.text
        assert foreign_guardian['id'] not in response.text
    assert (await client.get(student_paths(school, student)[0], headers=school['hm'])).json()['exams'] == []
    assert (await client.get(student_paths(school, student)[1], headers=school['hm'])).json()['recent'] == []
    assert (await client.get(student_paths(school, student)[2], headers=school['hm'])).json() == []


async def test_teacher_assignment_rejects_nonteacher_and_inactive_teacher(client, school, family):
    path = f"{API}/schools/{school['id']}/academic/sections/{family['academic']['section_id']}"
    assert (await client.patch(path, headers=school['hm'], json={'class_teacher_id': family['student']['id']})).status_code == 400
    async with family['sessions']() as db, db.begin():
        await db.execute(update(User).where(User.id == UUID(family['teacher']['id'])).values(is_active=False))
    assert (await client.patch(path, headers=school['hm'], json={'class_teacher_id': family['teacher']['id']})).status_code == 400


async def test_unassigned_teacher_cannot_gain_access_from_forged_enrollment_school(client, school, family):
    foreign_sid = await another_school(client, school['sa'])
    async with family['sessions']() as db, db.begin():
        await db.execute(update(StudentEnrollment).where(StudentEnrollment.id == UUID(family['enrollment'])).values(school_id=UUID(foreign_sid)))
    for path in student_paths(school, family['student']['id']):
        assert (await client.get(path, headers=family['teacher']['headers'])).status_code == 403


async def test_unrelated_teacher_not_allowed_by_module_permission_alone(client, school, family):
    teacher = await create_user(client, school['id'], school['hm'], 'teacher')
    headers = await login(client, teacher['email'], teacher['password'])
    for path in student_paths(school, family['student']['id']):
        assert (await client.get(path, headers=headers)).status_code == 403


async def test_guardian_keeps_child_access_when_additional_staff_permission_is_revoked(client, school, family):
    async with family['sessions']() as db, db.begin():
        teacher_role = await db.scalar(select(user_roles.c.role_id).where(user_roles.c.user_id == UUID(family['teacher']['id'])))
        await db.execute(user_roles.insert().values(user_id=UUID(family['guardian']['id']), role_id=teacher_role))
        await db.execute(update(RolePermission).where(
            RolePermission.role_id == teacher_role, RolePermission.module == 'student_management',
        ).values(can_view=False))
    for path in student_paths(school, family['student']['id']):
        assert (await client.get(path, headers=family['guardian']['headers'])).status_code == 200
        assert (await client.get(path, headers=family['teacher']['headers'])).status_code == 403
