"""F01.5 attendance/enrollment boundaries and malformed legacy data."""
from datetime import date, time, timedelta
from uuid import UUID, uuid4

import pytest
from sqlalchemy import delete, func, select, update

from app.models.academic import Section, StudentEnrollment, TimetableSlot
from app.models.associations import guardian_students
from app.models.attendance import AttendanceRecord
from app.models.communication import Message, NotificationOutbox
from app.models.school import AcademicSession
from app.models.user import User
from tests.conftest import API
from tests.test_broadcast_isolation import another_school
from tests.test_direct_message_boundaries import family as _family_fixture
from tests.utils import create_user, enroll, login, make_academics

family = _family_fixture
DAY = '2026-09-22'


def root(school):
    return f"{API}/schools/{school['id']}"


def mark(family, **extra):
    return {'section_id': family['academic']['section_id'], 'attendance_date': DAY,
            'entries': [{'student_id': family['student']['id'], 'status': 'absent'}], **extra}


async def snapshot(family):
    async with family['sessions']() as db:
        return [await db.scalar(select(func.count()).select_from(model))
                for model in [AttendanceRecord, Message, NotificationOutbox]]


async def opt_in(client, school):
    r = await client.put(root(school) + '/communication/configs', headers=school['hm'],
                         json={'event': 'attendance_absent', 'enabled': True, 'channels': ['sms']})
    assert r.status_code == 200, r.text


async def test_register_summary_and_individual_role_boundaries(client, school, family):
    body = mark(family, entries=[{'student_id': family['student']['id'], 'status': 'present'}])
    assert (await client.post(root(school) + '/attendance', headers=school['hm'], json=body)).status_code == 201
    teacher = await create_user(client, school['id'], school['hm'], 'teacher')
    unrelated = await login(client, teacher['email'], teacher['password'])
    params = {'section_id': body['section_id'], 'attendance_date': DAY}
    for suffix in ['/attendance', '/attendance/summary']:
        for headers in [school['hm'], school['sa'], family['teacher']['headers']]:
            r = await client.get(root(school) + suffix, headers=headers, params=params)
            assert r.status_code == 200, r.text
            assert 'no-store' in r.headers['cache-control']
        for headers in [unrelated, family['student']['headers'], family['guardian']['headers']]:
            r = await client.get(root(school) + suffix, headers=headers, params=params)
            assert r.status_code == 403, r.text
            assert 'no-store' in r.headers['cache-control']
    path = root(school) + f"/students/{family['student']['id']}/attendance"
    for headers in [school['hm'], school['sa']] + [family[k]['headers'] for k in ['teacher', 'student', 'guardian']]:
        r = await client.get(path, headers=headers)
        assert r.status_code == 200 and len(r.json()) == 1, r.text
    assert (await client.get(path, headers=unrelated)).status_code == 403


@pytest.mark.parametrize('viewer', ['teacher', 'guardian'])
async def test_read_relationship_revocation_with_same_token(client, school, family, viewer):
    path = root(school) + f"/students/{family['student']['id']}/attendance"
    assert (await client.get(path, headers=family[viewer]['headers'])).status_code == 200
    async with family['sessions']() as db, db.begin():
        if viewer == 'teacher':
            await db.execute(update(Section).where(Section.id == UUID(family['academic']['section_id'])).values(class_teacher_id=None))
        else:
            await db.execute(delete(guardian_students).where(guardian_students.c.guardian_id == UUID(family['guardian']['id'])))
    assert (await client.get(path, headers=family[viewer]['headers'])).status_code == 403


async def test_missing_foreign_nonstudent_and_malformed_read_targets(client, school, family):
    foreign = await another_school(client, school['sa'])
    student = await create_user(client, foreign, school['sa'], 'student')
    for target in [str(uuid4()), student['id'], family['teacher']['id']]:
        r = await client.get(root(school) + f'/students/{target}/attendance', headers=school['hm'])
        assert r.status_code == 404, r.text
    for suffix in ['/attendance', '/attendance/summary']:
        r = await client.get(root(school) + suffix, headers=school['hm'],
                             params={'section_id': str(uuid4()), 'attendance_date': DAY})
        assert r.status_code == 404
    path = root(school) + f"/students/{family['student']['id']}/attendance"
    assert (await client.get(path, headers=school['hm'], params={'date_from': DAY, 'date_to': '2026-09-01'})).status_code == 400
    assert (await client.get(root(school) + '/students/not-a-uuid/attendance', headers=school['hm'])).status_code == 422


async def test_enrollment_session_validation_and_unchanged_reactivation(client, school, family):
    foreign = await another_school(client, school['sa'])
    async with family['sessions']() as db, db.begin():
        local = AcademicSession(school_id=UUID(school['id']), name='Local')
        other = AcademicSession(school_id=UUID(foreign), name='Foreign')
        db.add_all([local, other])
        await db.flush()
        local_id, foreign_id = local.id, other.id
        await db.execute(update(StudentEnrollment).where(StudentEnrollment.id == UUID(family['enrollment'])).values(status='withdrawn', session_id=local_id))
    path = root(school) + f"/sections/{family['academic']['section_id']}/students"
    for student in [family['student'], family['other']]:
        for session in [foreign_id, uuid4()]:
            r = await client.post(path, headers=school['hm'], json={'student_id': student['id'], 'session_id': str(session)})
            assert r.status_code == 404, r.text
    async with family['sessions']() as db:
        row = await db.get(StudentEnrollment, UUID(family['enrollment']))
        assert row.status == 'withdrawn' and row.session_id == local_id
        assert await db.scalar(select(func.count()).select_from(StudentEnrollment).where(StudentEnrollment.student_id == UUID(family['other']['id']))) == 0
    r = await client.post(path, headers=school['hm'], json={'student_id': family['student']['id'], 'session_id': str(local_id)})
    assert r.status_code == 201 and r.json()['status'] == 'active'


@pytest.mark.parametrize('corruption', ['enrollment_school', 'student_inactive', 'student_school', 'section_parent', 'session_school'])
async def test_corrupt_enrollment_cannot_mark_or_notify(client, school, family, corruption):
    foreign = await another_school(client, school['sa'])
    foreign_ac = await make_academics(client, foreign, school['sa'])
    await opt_in(client, school)
    async with family['sessions']() as db, db.begin():
        if corruption == 'enrollment_school':
            await db.execute(update(StudentEnrollment).where(StudentEnrollment.id == UUID(family['enrollment'])).values(school_id=UUID(foreign)))
        elif corruption.startswith('student_'):
            values = {'is_active': False} if corruption == 'student_inactive' else {'school_id': UUID(foreign)}
            await db.execute(update(User).where(User.id == UUID(family['student']['id'])).values(**values))
        elif corruption == 'section_parent':
            await db.execute(update(Section).where(Section.id == UUID(family['academic']['section_id'])).values(class_id=UUID(foreign_ac['class_id']), name='Corrupt parent fixture'))
        else:
            session = AcademicSession(school_id=UUID(foreign), name='Foreign')
            db.add(session)
            await db.flush()
            await db.execute(update(StudentEnrollment).where(StudentEnrollment.id == UUID(family['enrollment'])).values(session_id=session.id))
    before = await snapshot(family)
    r = await client.post(root(school) + '/attendance', headers=school['hm'], json=mark(family))
    assert r.status_code in [400, 404], r.text
    assert await snapshot(family) == before


async def test_invalid_subject_slot_duplicate_and_mixed_batch_have_zero_side_effects(client, school, family):
    foreign = await another_school(client, school['sa'])
    foreign_ac = await make_academics(client, foreign, school['sa'])
    await opt_in(client, school)
    ac = family['academic']
    async with family['sessions']() as db, db.begin():
        slot = TimetableSlot(school_id=UUID(foreign), section_id=UUID(foreign_ac['section_id']), subject_id=UUID(foreign_ac['subject_id']), day_of_week=0, start_time=time(9), end_time=time(10))
        db.add(slot)
        await db.flush()
        slot_id = str(slot.id)
    invalid = [mark(family, subject_id=foreign_ac['subject_id']), mark(family, subject_id=str(uuid4())),
               mark(family, timetable_slot_id=slot_id),
               mark(family, subject_id=ac['subject_id'], timetable_slot_id=slot_id),
               mark(family, subject_id=ac['subject_id'], timetable_slot_id=str(uuid4())),
               mark(family, entries=mark(family)['entries'] * 2),
               mark(family, entries=mark(family)['entries'] + [{'student_id': family['other']['id'], 'status': 'absent'}]),
               mark(family, subject_id='bad-uuid')]
    before = await snapshot(family)
    for body in invalid:
        r = await client.post(root(school) + '/attendance', headers=school['hm'], json=body)
        assert r.status_code in [400, 404, 422], r.text
        assert await snapshot(family) == before


@pytest.mark.parametrize('foreign_school', [True, False])
async def test_upsert_never_adopts_foreign_school_or_other_section_record(client, school, family, foreign_school):
    foreign = await another_school(client, school['sa'])
    other_ac = await make_academics(client, foreign, school['sa'])
    if foreign_school:
        target_school, target_section = foreign, other_ac['section_id']
    else:
        response = await client.post(root(school) + f"/academic/classes/{family['academic']['class_id']}/sections", headers=school['hm'], json={'name': 'B'})
        target_school, target_section = school['id'], response.json()['id']
        await enroll(client, school['id'], school['hm'], target_section, family['student']['id'])
    async with family['sessions']() as db, db.begin():
        record = AttendanceRecord(school_id=UUID(target_school), section_id=UUID(target_section), student_id=UUID(family['student']['id']), attendance_date=date.fromisoformat(DAY), status='present')
        db.add(record)
        await db.flush()
        record_id = record.id
    await opt_in(client, school)
    before = await snapshot(family)
    r = await client.post(root(school) + '/attendance', headers=school['hm'], json=mark(family))
    assert r.status_code == 400, r.text
    assert await snapshot(family) == before
    async with family['sessions']() as db:
        row = await db.get(AttendanceRecord, record_id)
        assert row.status == 'present' and str(row.section_id) == target_section and str(row.school_id) == target_school


async def test_corrupt_attendance_rows_filtered_from_list_summary_and_history(client, school, family):
    foreign = await another_school(client, school['sa'])
    foreign_ac = await make_academics(client, foreign, school['sa'])
    student = await create_user(client, foreign, school['sa'], 'student')
    ac = family['academic']
    async with family['sessions']() as db, db.begin():
        common = {'school_id': UUID(school['id']), 'section_id': UUID(ac['section_id']),
                  'student_id': UUID(family['student']['id']), 'attendance_date': date.fromisoformat(DAY), 'status': 'absent'}
        db.add(AttendanceRecord(**(common | {'school_id': UUID(foreign)})))
        db.add(AttendanceRecord(**(common | {'subject_id': UUID(foreign_ac['subject_id'])})))
        db.add(AttendanceRecord(**(common | {'student_id': UUID(student['id'])})))
    params = {'section_id': ac['section_id'], 'attendance_date': DAY}
    r = await client.get(root(school) + '/attendance', headers=school['hm'], params=params)
    assert r.status_code == 200 and r.json() == [], r.text
    r = await client.get(root(school) + '/attendance/summary', headers=school['hm'], params=params)
    assert r.status_code == 200 and r.json()['total'] == 0, r.text
    r = await client.get(root(school) + f"/students/{family['student']['id']}/attendance", headers=family['student']['headers'])
    assert r.status_code == 200 and r.json() == [], r.text


async def test_student_history_is_bounded_after_tenant_visibility_filters(client, school, family):
    """A foreign earliest row cannot consume an otherwise valid local page."""
    foreign = await another_school(client, school['sa'])
    foreign_ac = await make_academics(client, foreign, school['sa'])
    local_school_id = UUID(school['id'])
    student_id = UUID(family['student']['id'])
    section_id = UUID(family['academic']['section_id'])
    first_local_day = date(2026, 1, 1)

    async with family['sessions']() as db, db.begin():
        # This row structurally points at the local student, but belongs to a
        # foreign tenant and predates every valid row. It must be filtered
        # before limit/offset are applied.
        db.add(AttendanceRecord(
            school_id=UUID(foreign), section_id=UUID(foreign_ac['section_id']),
            student_id=student_id, attendance_date=date(2025, 1, 1), status='absent',
        ))
        db.add_all([
            AttendanceRecord(
                school_id=local_school_id, section_id=section_id,
                student_id=student_id,
                attendance_date=first_local_day + timedelta(days=index),
                status='present',
            )
            for index in range(105)
        ])

    path = root(school) + f"/students/{family['student']['id']}/attendance"
    first_page = await client.get(path, headers=family['student']['headers'])
    assert first_page.status_code == 200, first_page.text
    assert len(first_page.json()) == 50
    assert first_page.json()[0]['attendance_date'] == first_local_day.isoformat()

    final_page = await client.get(
        path, headers=family['student']['headers'], params={'limit': 10, 'offset': 100},
    )
    assert final_page.status_code == 200, final_page.text
    assert [row['attendance_date'] for row in final_page.json()] == [
        (first_local_day + timedelta(days=index)).isoformat() for index in range(100, 105)
    ]


async def test_corrupt_enrollment_cannot_be_reactivated_or_deleted(client, school, family):
    foreign = await another_school(client, school['sa'])
    async with family['sessions']() as db, db.begin():
        await db.execute(update(StudentEnrollment).where(StudentEnrollment.id == UUID(family['enrollment'])).values(school_id=UUID(foreign), status='withdrawn'))
    path = root(school) + f"/sections/{family['academic']['section_id']}/students"
    assert (await client.post(path, headers=school['hm'], json={'student_id': family['student']['id']})).status_code == 400
    assert (await client.delete(path + '/' + family['student']['id'], headers=school['hm'])).status_code == 404
    async with family['sessions']() as db:
        row = await db.get(StudentEnrollment, UUID(family['enrollment']))
        assert row is not None and row.status == 'withdrawn' and str(row.school_id) == foreign


async def test_subject_teacher_authority_and_corrupt_timetable_denial(client, school, family):
    ac = family['academic']
    foreign = await another_school(client, school['sa'])
    await opt_in(client, school)
    async with family['sessions']() as db, db.begin():
        await db.execute(update(Section).where(Section.id == UUID(ac['section_id'])).values(class_teacher_id=None))
        slot = TimetableSlot(school_id=UUID(school['id']), section_id=UUID(ac['section_id']),
                             subject_id=UUID(ac['subject_id']), teacher_id=UUID(family['teacher']['id']),
                             day_of_week=0, start_time=time(9), end_time=time(10))
        db.add(slot)
        await db.flush()
        slot_id = slot.id
    before = await snapshot(family)
    # Subject teachers may read their section, but may not mark its daily register.
    params = {'section_id': ac['section_id'], 'attendance_date': DAY}
    assert (await client.get(root(school) + '/attendance', headers=family['teacher']['headers'], params=params)).status_code == 200
    r = await client.post(root(school) + '/attendance', headers=family['teacher']['headers'], json=mark(family))
    assert r.status_code == 403, r.text
    assert await snapshot(family) == before
    present = mark(family, subject_id=ac['subject_id'], timetable_slot_id=str(slot_id),
                   entries=[{'student_id': family['student']['id'], 'status': 'present'}])
    r = await client.post(root(school) + '/attendance', headers=family['teacher']['headers'], json=present)
    assert r.status_code == 201, r.text
    # A foreign-tenant slot must not grant subject marking or section reads.
    async with family['sessions']() as db, db.begin():
        await db.execute(update(TimetableSlot).where(TimetableSlot.id == slot_id).values(school_id=UUID(foreign)))
    before = await snapshot(family)
    r = await client.post(root(school) + '/attendance', headers=family['teacher']['headers'], json=mark(family, subject_id=ac['subject_id']))
    assert r.status_code == 403, r.text
    assert await snapshot(family) == before
    assert (await client.get(root(school) + '/attendance', headers=family['teacher']['headers'], params=params)).status_code == 403


async def test_same_school_slot_must_match_section_and_subject(client, school, family):
    ac = family['academic']
    response = await client.post(root(school) + f"/academic/classes/{ac['class_id']}/sections", headers=school['hm'], json={'name': 'B'})
    section_id = response.json()['id']
    async with family['sessions']() as db, db.begin():
        slot = TimetableSlot(school_id=UUID(school['id']), section_id=UUID(section_id),
                             subject_id=UUID(ac['subject_id']), day_of_week=0, start_time=time(9), end_time=time(10))
        db.add(slot)
        await db.flush()
        slot_id = slot.id
    await opt_in(client, school)
    before = await snapshot(family)
    body = mark(family, subject_id=ac['subject_id'], timetable_slot_id=str(slot_id))
    assert (await client.post(root(school) + '/attendance', headers=school['hm'], json=body)).status_code == 400
    other = await client.post(root(school) + '/academic/subjects', headers=school['hm'], json={'code': 'OTHER', 'name': 'Other'})
    async with family['sessions']() as db, db.begin():
        await db.execute(update(TimetableSlot).where(TimetableSlot.id == slot_id).values(section_id=UUID(ac['section_id']), subject_id=UUID(other.json()['id'])))
    assert (await client.post(root(school) + '/attendance', headers=school['hm'], json=body)).status_code == 400
    assert await snapshot(family) == before


async def test_withdrawal_retains_history_and_inactive_student_can_be_unenrolled(client, school, family):
    body = mark(family, entries=[{'student_id': family['student']['id'], 'status': 'present'}])
    assert (await client.post(root(school) + '/attendance', headers=school['hm'], json=body)).status_code == 201
    async with family['sessions']() as db, db.begin():
        await db.execute(update(StudentEnrollment).where(StudentEnrollment.id == UUID(family['enrollment'])).values(status='withdrawn'))
    path = root(school) + f"/students/{family['student']['id']}/attendance"
    assert (await client.get(path, headers=family['teacher']['headers'])).status_code == 403
    for headers in [school['hm'], family['student']['headers'], family['guardian']['headers']]:
        r = await client.get(path, headers=headers)
        assert r.status_code == 200 and len(r.json()) == 1, r.text
    async with family['sessions']() as db, db.begin():
        await db.execute(update(User).where(User.id == UUID(family['student']['id'])).values(is_active=False))
    enrollment_path = root(school) + f"/sections/{family['academic']['section_id']}/students"
    assert (await client.post(enrollment_path, headers=school['hm'], json={'student_id': family['student']['id']})).status_code == 400
    assert (await client.delete(enrollment_path + '/' + family['student']['id'], headers=school['hm'])).status_code == 204
