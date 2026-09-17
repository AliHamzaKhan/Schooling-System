"""No targeted broadcast body may escape through feeds, URLs or due listings."""
from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

import pytest
import pytest_asyncio
from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.models.academic import Section, StudentEnrollment
from app.models.associations import guardian_students, user_roles
from app.models.communication import Message, MessageDelivery, NotificationOutbox
from app.models.role import Role
from app.models.user import User
from app.modules.communication.service import CommunicationService
from tests.conftest import API, TEST_URL
from tests.test_broadcast_isolation import another_school
from tests.utils import create_user, enroll, login, make_academics


@pytest_asyncio.fixture
async def sessions(school):
    engine = create_async_engine(TEST_URL)
    factory = async_sessionmaker(engine, expire_on_commit=False)
    yield factory
    # Only this disposable test school's work; don't leak jobs to global poll tests.
    async with factory() as db, db.begin():
        await db.execute(delete(NotificationOutbox).where(NotificationOutbox.message_id.in_(
            select(Message.id).where(Message.school_id == UUID(school["id"]))
        )))
    await engine.dispose()


def path(school):
    return f"{API}/schools/{school['id']}/communication/broadcasts"


async def person(client, school, role):
    user = await create_user(client, school["id"], school["hm"], role)
    user["headers"] = await login(client, user["email"], user["password"])
    return user


async def post(client, school, audience, ref=None, *, headers=None, scheduled=None):
    payload = {"channel": "email", "audience_type": audience, "audience_ref": ref,
               "body": f"PRIVATE-{uuid4()}", "title": f"Title-{uuid4()}"}
    if scheduled is not None:
        payload["scheduled_at"] = scheduled.isoformat()
    response = await client.post(path(school), headers=headers or school["hm"], json=payload)
    assert response.status_code == 201, response.text
    return response.json()


async def assert_visible(client, school, headers, messages, expected):
    result = await client.get(path(school), headers=headers)
    assert result.status_code == 200, result.text
    assert result.headers['cache-control'] == 'private, no-store'
    assert {m["id"] for m in result.json()} == {messages[i]["id"] for i in expected}
    for i, message in enumerate(messages):
        detail = await client.get(f"{path(school)}/{message['id']}", headers=headers)
        assert detail.status_code == (200 if i in expected else 404), detail.text
        assert detail.headers['cache-control'] == 'private, no-store'
        if i not in expected:
            assert message["body"] not in result.text and message["title"] not in result.text
            assert message["body"] not in detail.text and message["title"] not in detail.text


@pytest.mark.parametrize("role,index", [("teacher", 1), ("student", 2), ("guardian", 3)])
async def test_role_feeds_and_direct_urls_match(client, school, sessions, role, index):
    user = await person(client, school, role)
    messages = [await post(client, school, audience)
                for audience in ["entire_school", "teachers", "students", "guardians"]]
    await assert_visible(client, school, user["headers"], messages, {0, index})
    for headers in [school["hm"], school["sa"]]:
        await assert_visible(client, school, headers, messages, {0, 1, 2, 3})


async def test_class_section_and_child_audiences_match_worker_recipients(client, school, sessions):
    academic = await make_academics(client, school["id"], school["hm"])
    same_class_section = await client.post(
        f"{API}/schools/{school['id']}/academic/classes/{academic['class_id']}/sections",
        headers=school["hm"], json={"name": "B"})
    first, second, outsider = [await person(client, school, "student") for _ in range(3)]
    guardian, unrelated = [await person(client, school, "guardian") for _ in range(2)]
    teacher = await person(client, school, "teacher")
    await enroll(client, school["id"], school["hm"], academic["section_id"], first["id"])
    await enroll(client, school["id"], school["hm"], same_class_section.json()["id"], second["id"])
    async with sessions() as db, db.begin():
        await db.execute(guardian_students.insert().values(
            school_id=UUID(school["id"]), guardian_id=UUID(guardian["id"]), student_id=UUID(first["id"])))
        # Corrupt historical links must not turn a teacher into a student/guardian.
        db.add(StudentEnrollment(school_id=UUID(school['id']), section_id=UUID(academic['section_id']),
                                 student_id=UUID(teacher['id']), status='active'))
        await db.execute(guardian_students.insert().values(
            school_id=UUID(school["id"]), guardian_id=UUID(teacher["id"]), student_id=UUID(first["id"])))
    targets = [("class", academic["class_id"]), ("section", academic["section_id"]),
               ("student_guardians", first["id"])]
    messages = [await post(client, school, audience, ref) for audience, ref in targets]
    for user, expected in [(first, {0, 1}), (second, {0}), (outsider, set()),
                           (guardian, {2}), (unrelated, set()), (teacher, set())]:
        await assert_visible(client, school, user["headers"], messages, expected)
    async with sessions() as db:
        for (audience, ref), expected in zip(targets, [{first['id'], second['id']}, {first['id']}, {guardian['id']}], strict=True):
            recipients = await CommunicationService(db)._resolve_audience(UUID(school["id"]), audience, UUID(ref))
            assert {str(user.id) for user in recipients} == expected
    # A recipient's content access does not expose operational recipient details.
    response = await client.get(f"{path(school)}/{messages[0]['id']}/review", headers=first["headers"])
    assert response.status_code == 403


async def test_withdrawal_revokes_access_despite_historical_delivery(client, school, sessions):
    academic = await make_academics(client, school["id"], school["hm"])
    student = await person(client, school, "student")
    enrollment = await enroll(client, school["id"], school["hm"], academic["section_id"], student["id"])
    message = await post(client, school, "section", academic["section_id"])
    await assert_visible(client, school, student["headers"], [message], {0})
    async with sessions() as db, db.begin():
        db.add(MessageDelivery(message_id=UUID(message["id"]), school_id=UUID(school["id"]),
                               user_id=UUID(student["id"]), channel="email", status="accepted"))
        await db.execute(update(StudentEnrollment).where(StudentEnrollment.id == UUID(enrollment)).values(status="withdrawn"))
    await assert_visible(client, school, student["headers"], [message], set())
    async with sessions() as db:
        recipients = await CommunicationService(db)._resolve_audience(UUID(school["id"]), "section", UUID(academic["section_id"]))
        assert recipients == []


@pytest.mark.parametrize("change", ["unlink", "deactivate_child", "wrong_link_school", "child_role"])
async def test_child_relationship_is_rechecked_on_every_read(client, school, sessions, change):
    student = await person(client, school, "student")
    guardian = await person(client, school, "guardian")
    async with sessions() as db, db.begin():
        await db.execute(guardian_students.insert().values(school_id=UUID(school["id"]),
            guardian_id=UUID(guardian["id"]), student_id=UUID(student["id"])))
    message = await post(client, school, "student_guardians", student["id"])
    await assert_visible(client, school, guardian["headers"], [message], {0})
    other = await another_school(client, school["sa"]) if change == "wrong_link_school" else None
    async with sessions() as db, db.begin():
        link = guardian_students.c.guardian_id == UUID(guardian["id"])
        if change == "unlink":
            await db.execute(delete(guardian_students).where(link))
        elif change == "wrong_link_school":
            await db.execute(update(guardian_students).where(link).values(school_id=UUID(other)))
        elif change == "deactivate_child":
            await db.execute(update(User).where(User.id == UUID(student["id"])).values(is_active=False))
        else:
            await db.execute(delete(user_roles).where(user_roles.c.user_id == UUID(student["id"])))
    await assert_visible(client, school, guardian["headers"], [message], set())


async def test_role_changes_revoke_audience_access(client, school, sessions):
    teacher = await person(client, school, "teacher")
    messages = [await post(client, school, audience) for audience in ["teachers", "students"]]
    await assert_visible(client, school, teacher["headers"], messages, {0})
    async with sessions() as db, db.begin():
        role = await db.scalar(select(Role).where(Role.code == "student", Role.school_id == UUID(school["id"])))
        await db.execute(delete(user_roles).where(user_roles.c.user_id == UUID(teacher["id"])))
        await db.execute(user_roles.insert().values(user_id=UUID(teacher["id"]), role_id=role.id))
    await assert_visible(client, school, teacher["headers"], messages, {1})


async def test_scheduling_sender_oversight_and_due_listing(client, school, sessions):
    teacher = await person(client, school, "teacher")
    peer = await person(client, school, "teacher")
    past = datetime.now(timezone.utc) - timedelta(minutes=5)
    future = datetime.now(timezone.utc) + timedelta(days=1)
    messages = [
        await post(client, school, "teachers", scheduled=future),
        await post(client, school, "teachers", scheduled=past),
        await post(client, school, "guardians", headers=teacher["headers"], scheduled=future),
        await post(client, school, "guardians", headers=teacher["headers"], scheduled=past),
        await post(client, school, "guardians", headers=peer["headers"], scheduled=past),
    ]
    await assert_visible(client, school, teacher["headers"], messages, {1, 2, 3})
    await assert_visible(client, school, peer["headers"], messages, {1, 4})
    due_path = f"{API}/schools/{school['id']}/communication/process-due"
    for headers, expected in [(teacher["headers"], {3}), (peer["headers"], {4}),
                              (school["hm"], {1, 3, 4}), (school["sa"], {1, 3, 4})]:
        result = await client.post(due_path, headers=headers)
        assert result.status_code == 200, result.text
        assert {row['id'] for row in result.json()} == {messages[i]['id'] for i in expected}
    # Elapsed schedule becomes visible without relying on provider success.
    async with sessions() as db, db.begin():
        await db.execute(update(Message).where(Message.id == UUID(messages[0]['id'])).values(scheduled_at=past))
    await assert_visible(client, school, peer["headers"], messages, {0, 1, 4})


async def test_historical_malformed_and_cross_school_targets_fail_closed(client, school, sessions):
    student = await person(client, school, "student")
    academic = await make_academics(client, school["id"], school["hm"])
    await enroll(client, school["id"], school["hm"], academic['section_id'], student['id'])
    other = await another_school(client, school["sa"])
    foreign = await make_academics(client, other, school["sa"])
    rows = []
    async with sessions() as db, db.begin():
        for audience, ref, sid, status in [
            ('unknown', None, school['id'], 'accepted'),
            ('section', None, school['id'], 'accepted'),
            ('entire_school', academic['class_id'], school['id'], 'accepted'),
            ('class', foreign['class_id'], school['id'], 'accepted'),
            ('section', foreign['section_id'], school['id'], 'accepted'),
            ('entire_school', None, other, 'accepted'),
            ('entire_school', None, school['id'], 'scheduled'),
        ]:
            row = Message(school_id=UUID(sid), channel='email', audience_type=audience,
                          audience_ref=UUID(ref) if ref else None, title='HIDDEN TITLE', body='HIDDEN BODY', status=status)
            db.add(row)
            rows.append(row)
        await db.flush()
        messages = [{'id': str(row.id), 'body': row.body, 'title': row.title} for row in rows]
    await assert_visible(client, school, student['headers'], messages, set())
    # Even a corrupt local section whose parent is foreign cannot grant reads/sends.
    local = await post(client, school, 'section', academic['section_id'])
    async with sessions() as db, db.begin():
        await db.execute(update(Section).where(Section.id == UUID(academic['section_id'])).values(
            class_id=UUID(foreign['class_id']), name='Corrupt historical section'))
    await assert_visible(client, school, student['headers'], messages + [local], set())
    async with sessions() as db:
        recipients = await CommunicationService(db)._resolve_audience(UUID(school['id']), 'section', UUID(academic['section_id']))
        assert recipients == []
    # Foreign-school URL is rejected by the outer tenant permission gate too.
    result = await client.get(f"{API}/schools/{other}/communication/broadcasts", headers=student['headers'])
    assert result.status_code == 403
