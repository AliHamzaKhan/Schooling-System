"""Direct message service: 1-to-1 messages/complaints between school members."""
import uuid
from datetime import datetime, timezone

from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import SystemRole
from app.core.exceptions import bad_request, forbidden, not_found
from app.models.academic import SchoolClass, Section, StudentEnrollment, Subject, TimetableSlot
from app.models.associations import guardian_students
from app.models.direct_message import DirectMessage
from app.models.role import Role
from app.models.user import User
from app.modules.messages import schemas

# Order of preference when a user has several roles — the first match is the
# label shown in the contact picker.
_ROLE_PRIORITY = (
    SystemRole.HEADMASTER.value,
    SystemRole.TEACHER.value,
    SystemRole.GUARDIAN.value,
    SystemRole.STUDENT.value,
)


def _primary_role(user: User) -> str:
    codes = {r.code for r in user.roles}
    for code in _ROLE_PRIORITY:
        if code in codes:
            return code
    return "staff"


class DirectMessageService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    @staticmethod
    def _school_party(school_id: uuid.UUID):
        return or_(User.school_id == school_id, and_(
            User.school_id.is_(None), User.roles.any(and_(
                Role.code == SystemRole.SUPER_ADMIN.value, Role.is_system.is_(True),
            )),
        ))

    @classmethod
    def _valid_history(cls, school_id: uuid.UUID):
        parties = select(User.id).where(cls._school_party(school_id))
        students = select(User.id).where(User.school_id == school_id,
            User.roles.any(Role.code == SystemRole.STUDENT.value))
        return and_(DirectMessage.school_id == school_id,
            DirectMessage.sender_id.in_(parties), DirectMessage.recipient_id.in_(parties),
            or_(DirectMessage.student_id.is_(None), DirectMessage.student_id.in_(students)))

    async def _names(self, school_id: uuid.UUID, ids: set[uuid.UUID]) -> dict[uuid.UUID, str]:
        if not ids:
            return {}
        rows = await self.db.execute(
            select(User.id, User.full_name).where(User.id.in_(ids), self._school_party(school_id))
        )
        return dict(rows.all())

    def _out(
        self, m: DirectMessage, names: dict[uuid.UUID, str]
    ) -> schemas.DirectMessageOut:
        return schemas.DirectMessageOut(
            id=m.id,
            school_id=m.school_id,
            sender_id=m.sender_id,
            sender_name=names.get(m.sender_id, ""),
            recipient_id=m.recipient_id,
            recipient_name=names.get(m.recipient_id, ""),
            student_id=m.student_id,
            kind=m.kind,
            body=m.body,
            read_at=m.read_at,
            created_at=m.created_at,
        )

    async def send(
        self, school_id: uuid.UUID, sender: User, data: schemas.DirectMessageCreate
    ) -> schemas.DirectMessageOut:
        if data.recipient_id == sender.id:
            raise bad_request("You cannot message yourself")
        recipient = await self.db.scalar(select(User).where(
            User.id == data.recipient_id, User.is_active.is_(True), self._school_party(school_id)))
        if recipient is None:
            raise not_found("Recipient not found in this school")
        allowed = await self._contact_ids(school_id, sender)
        if recipient.id not in allowed:
            # Students cannot discover administrators in the picker, but may
            # answer an administrator who has already contacted them.
            admin = any(r.code in {SystemRole.HEADMASTER.value, SystemRole.SUPER_ADMIN.value}
                        for r in recipient.roles)
            incoming = await self.db.scalar(select(DirectMessage.id).where(
                self._valid_history(school_id), DirectMessage.sender_id == recipient.id,
                DirectMessage.recipient_id == sender.id).limit(1)) if admin else None
            if incoming is None:
                raise forbidden("This recipient is not available for a conversation")
        if data.student_id is not None:
            student = await self.db.scalar(select(User).where(User.id == data.student_id,
                User.school_id == school_id, User.is_active.is_(True),
                User.roles.any(Role.code == SystemRole.STUDENT.value)))
            if student is None:
                raise not_found("Student not found in this school")
            for party in (sender, recipient):
                if not await self._may_discuss(school_id, party, student.id):
                    raise forbidden("Both participants must be entitled to discuss this student")
        message = DirectMessage(
            school_id=school_id,
            sender_id=sender.id,
            recipient_id=data.recipient_id,
            student_id=data.student_id,
            kind=data.kind,
            body=data.body,
        )
        self.db.add(message)
        await self.db.flush()
        names = await self._names(school_id, {message.sender_id, message.recipient_id})
        return self._out(message, names)

    async def list_for_user(
        self, school_id: uuid.UUID, user_id: uuid.UUID, box: str = "inbox",
        counterpart_id: uuid.UUID | None = None,
    ) -> list[schemas.DirectMessageOut]:
        """The acting user's messages: 'inbox' (received), 'sent', or 'all'."""
        stmt = select(DirectMessage).where(self._valid_history(school_id))
        if box == "sent":
            stmt = stmt.where(DirectMessage.sender_id == user_id)
        elif box == "all":
            stmt = stmt.where(
                or_(
                    DirectMessage.sender_id == user_id,
                    DirectMessage.recipient_id == user_id,
                )
            )
        else:  # inbox
            stmt = stmt.where(DirectMessage.recipient_id == user_id)
        if counterpart_id is not None:
            stmt = stmt.where(or_(
                and_(DirectMessage.sender_id == user_id, DirectMessage.recipient_id == counterpart_id),
                and_(DirectMessage.recipient_id == user_id, DirectMessage.sender_id == counterpart_id),
            ))
        stmt = stmt.order_by(DirectMessage.created_at.desc(), DirectMessage.id.desc())
        messages = list((await self.db.execute(stmt)).scalars().all())
        ids: set[uuid.UUID] = set()
        for m in messages:
            ids.add(m.sender_id)
            ids.add(m.recipient_id)
        names = await self._names(school_id, ids)
        return [self._out(m, names) for m in messages]

    async def list_contacts(
        self, school_id: uuid.UUID, user: User
    ) -> list[schemas.ContactOut]:
        """People the acting user may start a conversation with, scoped by role:

        - **Headmaster / super-admin**: everyone in the school.
        - **Teacher**: current students and their guardians, plus the headmaster.
        - **Guardian**: their children's teachers, plus the headmaster.
        - **Student**: their own teachers only.
        - Any other staff: the headmaster.

        "Teachers" of a section means its class teacher and its timetable
        (subject) teachers; "students" means the active enrollments in the
        sections a teacher takes. The acting user is always excluded.
        """
        return await self._contacts_from_ids(school_id, await self._contact_ids(school_id, user))

    async def _contact_ids(self, school_id: uuid.UUID, user: User) -> set[uuid.UUID]:
        codes = {r.code for r in user.roles}
        me = user.id

        # Headmaster / super-admin see the whole school.
        if SystemRole.HEADMASTER.value in codes or SystemRole.SUPER_ADMIN.value in codes:
            everyone = await self._scalar_set(
                select(User.id).where(
                    User.school_id == school_id,
                    User.is_active.is_(True),
                    User.id != me,
                )
            )
            return everyone

        ids: set[uuid.UUID] = set()
        if SystemRole.TEACHER.value in codes:
            sections = await self._sections_taught_by(school_id, me)
            students = await self._student_ids_in_sections(school_id, sections)
            ids |= students
            ids |= await self._guardian_ids_of(school_id, students)
            ids |= await self._headmaster_ids(school_id)
        if SystemRole.GUARDIAN.value in codes:
            children = await self._child_ids_of(school_id, me)
            sections = await self._sections_of_students(school_id, children)
            ids |= await self._teacher_ids_of_sections(school_id, sections)
            ids |= await self._headmaster_ids(school_id)
        if SystemRole.STUDENT.value in codes:
            sections = await self._sections_of_students(school_id, {me})
            ids |= await self._teacher_ids_of_sections(school_id, sections)
            # Students see only their teachers — no headmaster.
        if not (codes & {
            SystemRole.TEACHER.value,
            SystemRole.GUARDIAN.value,
            SystemRole.STUDENT.value,
        }):
            # Generic staff (librarian, accountant, …): the headmaster only.
            ids |= await self._headmaster_ids(school_id)

        ids.discard(me)
        return ids

    async def _may_discuss(self, school_id: uuid.UUID, party: User, student_id: uuid.UUID) -> bool:
        roles = {r.code for r in party.roles}
        if roles & {SystemRole.HEADMASTER.value, SystemRole.SUPER_ADMIN.value}:
            return True
        if SystemRole.STUDENT.value in roles and party.id == student_id:
            return True
        if SystemRole.GUARDIAN.value in roles and student_id in await self._child_ids_of(school_id, party.id):
            return True
        if SystemRole.TEACHER.value in roles:
            sections = await self._sections_taught_by(school_id, party.id)
            return student_id in await self._student_ids_in_sections(school_id, sections)
        return False

    # ── contact-scoping helpers ─────────────────────────────────

    async def _scalar_set(self, stmt) -> set[uuid.UUID]:
        rows = await self.db.execute(stmt)
        return {v for v in rows.scalars().all() if v is not None}

    async def _headmaster_ids(self, school_id: uuid.UUID) -> set[uuid.UUID]:
        return await self._scalar_set(
            select(User.id)
            .join(User.roles)
            .where(
                User.school_id == school_id,
                User.is_active.is_(True),
                Role.code == SystemRole.HEADMASTER.value,
            )
        )

    @staticmethod
    def _valid_sections(school_id: uuid.UUID):
        return select(Section.id).join(SchoolClass, SchoolClass.id == Section.class_id).where(
            Section.school_id == school_id, SchoolClass.school_id == school_id)

    @classmethod
    def _valid_slots(cls, school_id: uuid.UUID):
        return select(TimetableSlot).join(Subject, Subject.id == TimetableSlot.subject_id).where(
            TimetableSlot.school_id == school_id, Subject.school_id == school_id,
            TimetableSlot.section_id.in_(cls._valid_sections(school_id)))

    async def _sections_taught_by(self, school_id: uuid.UUID, teacher_id: uuid.UUID) -> set[uuid.UUID]:
        as_class_teacher = await self._scalar_set(
            self._valid_sections(school_id).where(Section.class_teacher_id == teacher_id)
        )
        as_subject_teacher = await self._scalar_set(
            self._valid_slots(school_id).with_only_columns(TimetableSlot.section_id).where(
                TimetableSlot.teacher_id == teacher_id
            )
        )
        return as_class_teacher | as_subject_teacher

    async def _teacher_ids_of_sections(
        self, school_id: uuid.UUID, section_ids: set[uuid.UUID]
    ) -> set[uuid.UUID]:
        if not section_ids:
            return set()
        class_teachers = await self._scalar_set(
            self._valid_sections(school_id).with_only_columns(Section.class_teacher_id).where(Section.id.in_(section_ids))
        )
        subject_teachers = await self._scalar_set(
            self._valid_slots(school_id).with_only_columns(TimetableSlot.teacher_id).where(
                TimetableSlot.section_id.in_(section_ids)
            )
        )
        return await self._active_role_ids(school_id, class_teachers | subject_teachers, SystemRole.TEACHER.value)

    async def _student_ids_in_sections(
        self, school_id: uuid.UUID, section_ids: set[uuid.UUID]
    ) -> set[uuid.UUID]:
        if not section_ids:
            return set()
        return await self._scalar_set(
            select(StudentEnrollment.student_id).where(
                StudentEnrollment.section_id.in_(section_ids),
                StudentEnrollment.section_id.in_(self._valid_sections(school_id)),
                StudentEnrollment.school_id == school_id,
                StudentEnrollment.status == "active",
                StudentEnrollment.student_id.in_(select(User.id).where(User.school_id == school_id,
                    User.is_active.is_(True), User.roles.any(Role.code == SystemRole.STUDENT.value))),
            )
        )

    async def _sections_of_students(
        self, school_id: uuid.UUID, student_ids: set[uuid.UUID]
    ) -> set[uuid.UUID]:
        if not student_ids:
            return set()
        return await self._scalar_set(
            select(StudentEnrollment.section_id).where(
                StudentEnrollment.student_id.in_(student_ids),
                StudentEnrollment.section_id.in_(self._valid_sections(school_id)),
                StudentEnrollment.school_id == school_id,
                StudentEnrollment.status == "active",
                StudentEnrollment.student_id.in_(select(User.id).where(User.school_id == school_id,
                    User.is_active.is_(True), User.roles.any(Role.code == SystemRole.STUDENT.value))),
            )
        )

    async def _child_ids_of(
        self, school_id: uuid.UUID, guardian_id: uuid.UUID
    ) -> set[uuid.UUID]:
        ids = await self._scalar_set(
            select(guardian_students.c.student_id).where(
                guardian_students.c.guardian_id == guardian_id,
                guardian_students.c.school_id == school_id,
            )
        )
        return await self._active_role_ids(school_id, ids, SystemRole.STUDENT.value)

    async def _guardian_ids_of(self, school_id: uuid.UUID, student_ids: set[uuid.UUID]) -> set[uuid.UUID]:
        ids = await self._scalar_set(select(guardian_students.c.guardian_id).where(
            guardian_students.c.school_id == school_id, guardian_students.c.student_id.in_(student_ids)))
        return await self._active_role_ids(school_id, ids, SystemRole.GUARDIAN.value)

    async def _active_role_ids(self, school_id: uuid.UUID, ids: set[uuid.UUID], role: str) -> set[uuid.UUID]:
        return await self._scalar_set(select(User.id).where(User.id.in_(ids), User.school_id == school_id,
            User.is_active.is_(True), User.roles.any(Role.code == role)))

    async def _contacts_from_ids(
        self, school_id: uuid.UUID, ids: set[uuid.UUID]
    ) -> list[schemas.ContactOut]:
        """Materialises `ContactOut`s for `ids`, re-scoped to active members of
        `school_id` and ordered by name."""
        if not ids:
            return []
        rows = await self.db.execute(
            select(User)
            .where(
                User.id.in_(ids),
                User.school_id == school_id,
                User.is_active.is_(True),
            )
            .order_by(User.full_name)
        )
        return [
            schemas.ContactOut(id=u.id, name=u.full_name, role=_primary_role(u))
            for u in rows.scalars().all()
        ]

    async def mark_read(
        self, school_id: uuid.UUID, message_id: uuid.UUID, user_id: uuid.UUID
    ) -> schemas.DirectMessageOut:
        message = await self.db.scalar(select(DirectMessage).where(
            DirectMessage.id == message_id, self._valid_history(school_id),
            or_(DirectMessage.sender_id == user_id, DirectMessage.recipient_id == user_id),
        ).with_for_update())
        if message is None:
            raise not_found("Message not found in this school")
        if message.recipient_id != user_id:
            raise forbidden("Only the recipient can mark a message as read")
        if message.read_at is None:
            message.read_at = datetime.now(timezone.utc)
            await self.db.flush()
        names = await self._names(school_id, {message.sender_id, message.recipient_id})
        return self._out(message, names)
