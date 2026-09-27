"""Direct messages enforce the same current relationship rules as contacts."""
import asyncio
from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

import pytest
import pytest_asyncio
from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.models.academic import Section, StudentEnrollment, TimetableSlot
from app.models.associations import guardian_students, user_roles
from app.models.direct_message import DirectMessage
from app.models.user import User
from tests.conftest import API, TEST_URL
from tests.test_broadcast_isolation import another_school
from tests.utils import create_user, enroll, login, make_academics


@pytest_asyncio.fixture
async def family(client, school):
    people = {}
    for name, role in [('teacher', 'teacher'), ('guardian', 'guardian'), ('student', 'student'),
                       ('other', 'student')]:
        user = await create_user(client, school['id'], school['hm'], role)
        user['headers'] = await login(client, user['email'], user['password'])
        people[name] = user
    academic = await make_academics(client, school['id'], school['hm'])
    enrollment = await enroll(client, school['id'], school['hm'], academic['section_id'], people['student']['id'])
    engine = create_async_engine(TEST_URL)
    sessions = async_sessionmaker(engine, expire_on_commit=False)
    async with sessions() as db, db.begin():
        await db.execute(update(Section).where(Section.id == UUID(academic['section_id'])).values(
            class_teacher_id=UUID(people['teacher']['id'])))
        await db.execute(guardian_students.insert().values(school_id=UUID(school['id']),
            guardian_id=UUID(people['guardian']['id']), student_id=UUID(people['student']['id'])))
        hm_id = str(await db.scalar(select(User.id).where(User.email == school['hm_email'])))
    yield people | {'sessions': sessions, 'academic': academic, 'enrollment': enrollment, 'hm_id': hm_id}
    await engine.dispose()


def base(school):
    return f"{API}/schools/{school['id']}/messages"


async def send(client, school, sender, recipient, student=None, **extra):
    return await client.post(base(school), headers=sender, json={
        'recipient_id': recipient, 'student_id': student, 'body': 'Private family note', **extra})


async def count(family, school):
    async with family['sessions']() as db:
        return await db.scalar(select(func.count()).select_from(DirectMessage).where(DirectMessage.school_id == UUID(school['id'])))


async def test_contact_send_parity_and_bidirectional_family_conversations(client, school, family):
    t, g, s = (family[key] for key in ['teacher', 'guardian', 'student'])
    for sender, recipient in [(t, g), (g, t), (t, s), (s, t)]:
        contacts = await client.get(base(school) + '/contacts', headers=sender['headers'])
        assert recipient['id'] in {row['id'] for row in contacts.json()}
        response = await send(client, school, sender['headers'], recipient['id'], s['id'])
        assert response.status_code == 201, response.text
    denied = await send(client, school, t['headers'], family['other']['id'])
    assert denied.status_code == 403
    assert await count(family, school) == 4


@pytest.mark.parametrize('change', ['withdrawn', 'unlinked', 'teacher_role_removed', 'inactive_recipient', 'wrong_link_school'])
async def test_current_relationship_changes_block_new_sends_but_preserve_mailbox(client, school, family, change):
    t, g, s = (family[key] for key in ['teacher', 'guardian', 'student'])
    first = await send(client, school, t['headers'], g['id'])
    assert first.status_code == 201
    other = await another_school(client, school['sa']) if change == 'wrong_link_school' else None
    async with family['sessions']() as db, db.begin():
        if change == 'withdrawn':
            await db.execute(update(StudentEnrollment).where(StudentEnrollment.id == UUID(family['enrollment'])).values(status='withdrawn'))
        elif change == 'unlinked':
            await db.execute(delete(guardian_students).where(guardian_students.c.guardian_id == UUID(g['id'])))
        elif change == 'teacher_role_removed':
            await db.execute(delete(user_roles).where(user_roles.c.user_id == UUID(t['id'])))
        elif change == 'inactive_recipient':
            await db.execute(update(User).where(User.id == UUID(g['id'])).values(is_active=False))
        else:
            await db.execute(update(guardian_students).where(guardian_students.c.guardian_id == UUID(g['id'])).values(school_id=UUID(other)))
    response = await send(client, school, t['headers'], g['id'])
    assert response.status_code == (404 if change == 'inactive_recipient' else 403), response.text
    inbox = await client.get(base(school) + '?box=all', headers=t['headers'])
    assert [row['id'] for row in inbox.json()] == [first.json()['id']]
    assert await count(family, school) == 1


async def test_student_context_requires_both_participants_and_active_same_school_student(client, school, family):
    t, g, s, other = (family[key] for key in ['teacher', 'guardian', 'student', 'other'])
    # Sender/admin access to a child is not permission to disclose it to any guardian.
    for headers, recipient, child, status in [
        (school['hm'], g['id'], other['id'], 403),
        (t['headers'], g['id'], other['id'], 403),
        (s['headers'], t['id'], other['id'], 403),
        (school['hm'], g['id'], t['id'], 404),
        (school['hm'], g['id'], str(uuid4()), 404),
    ]:
        result = await send(client, school, headers, recipient, child)
        assert result.status_code == status, result.text
    foreign_school = await another_school(client, school['sa'])
    foreign_student = await create_user(client, foreign_school, school['sa'], 'student')
    result = await send(client, school, school['hm'], g['id'], foreign_student['id'])
    assert result.status_code == 404
    result = await send(client, school, school['hm'], foreign_student['id'])
    assert result.status_code == 404
    async with family['sessions']() as db, db.begin():
        await db.execute(update(User).where(User.id == UUID(s['id'])).values(is_active=False))
    assert (await send(client, school, school['hm'], g['id'], s['id'])).status_code == 404
    assert await count(family, school) == 0


async def test_history_thread_filter_and_read_mutations_are_participant_only(client, school, family):
    t, g, s = (family[key] for key in ['teacher', 'guardian', 'student'])
    first = await send(client, school, t['headers'], g['id'], s['id'])
    second = await send(client, school, t['headers'], s['id'], s['id'])
    assert first.status_code == second.status_code == 201
    mid = first.json()['id']
    for headers in [school['hm'], school['sa'], family['other']['headers']]:
        result = await client.get(base(school), headers=headers, params={'box': 'all', 'counterpart_id': t['id']})
        assert result.status_code == 200 and result.json() == []
        result = await client.patch(f'{base(school)}/{mid}/read', headers=headers)
        assert result.status_code == 404
        assert 'Private family note' not in result.text
        assert result.headers['cache-control'] == 'private, no-store'
    result = await client.get(base(school), headers=t['headers'], params={'box': 'all', 'counterpart_id': g['id']})
    assert [row['id'] for row in result.json()] == [mid]
    assert result.headers['cache-control'] == 'private, no-store'
    results = await asyncio.gather(*[client.patch(f'{base(school)}/{mid}/read', headers=g['headers']) for _ in range(2)])
    assert all(row.status_code == 200 for row in results)
    assert results[0].json()['read_at'] == results[1].json()['read_at'] is not None
    assert (await client.patch(f'{base(school)}/{mid}/read', headers=t['headers'])).status_code == 403
    assert (await client.get(base(school), headers=t['headers'], params={'counterpart_id': 'bad-id'})).status_code == 422


async def test_message_history_uses_bounded_stable_pages(client, school, family):
    """A representative history stays bounded without changing list payloads."""
    teacher, guardian = family['teacher'], family['guardian']
    count = 105
    started = datetime(2026, 1, 1, tzinfo=timezone.utc)
    expected_ids: list[str] = []
    async with family['sessions']() as db, db.begin():
        for index in range(count):
            message = DirectMessage(
                school_id=UUID(school['id']),
                sender_id=UUID(teacher['id']),
                recipient_id=UUID(guardian['id']),
                body=f'Representative history message {index}',
                created_at=started + timedelta(seconds=index),
            )
            db.add(message)
            await db.flush()
            expected_ids.append(str(message.id))

    first = await client.get(base(school), headers=guardian['headers'])
    assert first.status_code == 200, first.text
    assert len(first.json()) == 50
    assert [row['id'] for row in first.json()] == list(reversed(expected_ids[-50:]))

    second = await client.get(base(school), headers=guardian['headers'], params={'limit': 50, 'offset': 50})
    assert second.status_code == 200, second.text
    assert len(second.json()) == 50
    assert [row['id'] for row in second.json()] == list(reversed(expected_ids[5:55]))
    assert not set(row['id'] for row in first.json()) & set(row['id'] for row in second.json())

    tail = await client.get(base(school), headers=guardian['headers'], params={'limit': 50, 'offset': 100})
    assert tail.status_code == 200, tail.text
    assert [row['id'] for row in tail.json()] == list(reversed(expected_ids[:5]))
    assert (await client.get(base(school), headers=guardian['headers'], params={'limit': 101})).status_code == 422


async def test_student_can_reply_to_admin_but_cannot_initiate_or_read_others_threads(client, school, family):
    s = family['student']
    assert (await send(client, school, s['headers'], family['hm_id'])).status_code == 403
    first = await send(client, school, school['hm'], s['id'], s['id'])
    assert first.status_code == 201
    assert (await send(client, school, s['headers'], family['hm_id'], s['id'])).status_code == 201
    platform = await send(client, school, school['sa'], s['id'], s['id'])
    assert platform.status_code == 201
    platform_id = platform.json()['sender_id']
    reply = await send(client, school, s['headers'], platform_id, s['id'])
    assert reply.status_code == 201, reply.text
    own = await client.get(base(school), headers=school['sa'], params={'box': 'all'})
    assert len(own.json()) == 2


async def test_corrupt_historical_participants_and_student_references_are_hidden(client, school, family):
    other_school = await another_school(client, school['sa'])
    foreign = await create_user(client, other_school, school['sa'], 'student')
    t, g = family['teacher'], family['guardian']
    ids = []
    async with family['sessions']() as db, db.begin():
        for sender, student in [(foreign['id'], None), (t['id'], foreign['id']), (t['id'], t['id'])]:
            row = DirectMessage(school_id=UUID(school['id']), sender_id=UUID(sender), recipient_id=UUID(g['id']),
                student_id=UUID(student) if student else None, body='CORRUPT PRIVATE BODY')
            db.add(row)
            await db.flush()
            ids.append(str(row.id))
    result = await client.get(base(school), headers=g['headers'], params={'box': 'all'})
    assert result.status_code == 200 and result.json() == []
    for mid in ids:
        result = await client.patch(f'{base(school)}/{mid}/read', headers=g['headers'])
        assert result.status_code == 404 and 'CORRUPT' not in result.text
    async with family['sessions']() as db:
        assert await db.scalar(select(func.count()).select_from(DirectMessage).where(
            DirectMessage.id.in_([UUID(mid) for mid in ids]), DirectMessage.read_at.is_not(None))) == 0


async def test_corrupt_section_hierarchy_does_not_grant_contacts_or_sends(client, school, family):
    other_school = await another_school(client, school['sa'])
    academic = await make_academics(client, other_school, school['sa'])
    async with family['sessions']() as db, db.begin():
        await db.execute(update(Section).where(Section.id == UUID(family['academic']['section_id'])).values(
            class_id=UUID(academic['class_id']), name='Corrupt relationship'))
    for key in ['student', 'guardian']:
        result = await client.get(base(school) + '/contacts', headers=family[key]['headers'])
        assert family['teacher']['id'] not in {row['id'] for row in result.json()}
        assert (await send(client, school, family[key]['headers'], family['teacher']['id'])).status_code == 403
    assert await count(family, school) == 0


async def test_blank_body_rejected_before_persistence(client, school, family):
    result = await send(client, school, school['hm'], family['student']['id'], body=' \n\t ')
    assert result.status_code == 422
    assert await count(family, school) == 0


@pytest.mark.parametrize('corruption', ['enrollment_school', 'slot_subject_school', 'teacher_role'])
async def test_invalid_relationship_rows_do_not_grant_recipient_eligibility(client, school, family, corruption):
    from datetime import time
    foreign = await another_school(client, school['sa'])
    academic = await make_academics(client, foreign, school['sa'])
    async with family['sessions']() as db, db.begin():
        if corruption == 'enrollment_school':
            await db.execute(update(StudentEnrollment).where(StudentEnrollment.id == UUID(family['enrollment'])).values(school_id=UUID(foreign)))
        elif corruption == 'teacher_role':
            await db.execute(delete(user_roles).where(user_roles.c.user_id == UUID(family['teacher']['id'])))
        else:
            await db.execute(update(Section).where(Section.id == UUID(family['academic']['section_id'])).values(class_teacher_id=None))
            db.add(TimetableSlot(school_id=UUID(school['id']), section_id=UUID(family['academic']['section_id']),
                teacher_id=UUID(family['teacher']['id']), subject_id=UUID(academic['subject_id']),
                day_of_week=1, start_time=time(9), end_time=time(10)))
    for key in ['student', 'guardian']:
        contacts = await client.get(base(school) + '/contacts', headers=family[key]['headers'])
        assert family['teacher']['id'] not in {row['id'] for row in contacts.json()}
        denied = await send(client, school, family[key]['headers'], family['teacher']['id'])
        assert denied.status_code == 403
    assert await count(family, school) == 0
