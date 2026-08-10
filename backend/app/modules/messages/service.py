"""Direct message service: 1-to-1 messages/complaints between school members."""
import uuid
from datetime import datetime, timezone

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import SystemRole
from app.core.exceptions import bad_request, forbidden, not_found
from app.models.academic import Section, StudentEnrollment, TimetableSlot
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

    async def _names(self, ids: set[uuid.UUID]) -> dict[uuid.UUID, str]:
        if not ids:
            return {}
        rows = await self.db.execute(
            select(User.id, User.full_name).where(User.id.in_(ids))
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
        self, school_id: uuid.UUID, sender_id: uuid.UUID, data: schemas.DirectMessageCreate
    ) -> schemas.DirectMessageOut:
        if data.recipient_id == sender_id:
            raise bad_request("You cannot message yourself")
        recipient = await self.db.get(User, data.recipient_id)
        if recipient is None or recipient.school_id != school_id:
            raise not_found("Recipient not found in this school")
        message = DirectMessage(
            school_id=school_id,
            sender_id=sender_id,
            recipient_id=data.recipient_id,
            student_id=data.student_id,
            kind=data.kind,
            body=data.body,
        )
        self.db.add(message)
        await self.db.flush()
        names = await self._names({message.sender_id, message.recipient_id})
        return self._out(message, names)

    async def list_for_user(
        self, school_id: uuid.UUID, user_id: uuid.UUID, box: str = "inbox"
    ) -> list[schemas.DirectMessageOut]:
        """The acting user's messages: 'inbox' (received), 'sent', or 'all'."""
        stmt = select(DirectMessage).where(DirectMessage.school_id == school_id)
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
        stmt = stmt.order_by(DirectMessage.created_at.desc())
        messages = list((await self.db.execute(stmt)).scalars().all())
        ids: set[uuid.UUID] = set()
        for m in messages:
            ids.add(m.sender_id)
            ids.add(m.recipient_id)
        names = await self._names(ids)
        return [self._out(m, names) for m in messages]

    async def list_contacts(
        self, school_id: uuid.UUID, user: User
    ) -> list[schemas.ContactOut]:
        """People the acting user may start a conversation with, scoped by role:

        - **Headmaster / super-admin**: everyone in the school.
        - **Teacher**: the students they teach, plus the headmaster.
        - **Guardian**: their children's teachers, plus the headmaster.
        - **Student**: their own teachers only.
        - Any other staff: the headmaster.

        "Teachers" of a section means its class teacher and its timetable
        (subject) teachers; "students" means the active enrollments in the
        sections a teacher takes. The acting user is always excluded.
        """
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
            return await self._contacts_from_ids(school_id, everyone)

        ids: set[uuid.UUID] = set()
        if SystemRole.TEACHER.value in codes:
            sections = await self._sections_taught_by(me)
            ids |= await self._student_ids_in_sections(sections)
            ids |= await self._headmaster_ids(school_id)
        if SystemRole.GUARDIAN.value in codes:
            children = await self._child_ids_of(school_id, me)
            sections = await self._sections_of_students(children)
            ids |= await self._teacher_ids_of_sections(sections)
            ids |= await self._headmaster_ids(school_id)
        if SystemRole.STUDENT.value in codes:
            sections = await self._sections_of_students({me})
            ids |= await self._teacher_ids_of_sections(sections)
            # Students see only their teachers — no headmaster.
        if not (codes & {
            SystemRole.TEACHER.value,
            SystemRole.GUARDIAN.value,
            SystemRole.STUDENT.value,
        }):
            # Generic staff (librarian, accountant, …): the headmaster only.
            ids |= await self._headmaster_ids(school_id)

        ids.discard(me)
        return await self._contacts_from_ids(school_id, ids)

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

    async def _sections_taught_by(self, teacher_id: uuid.UUID) -> set[uuid.UUID]:
        as_class_teacher = await self._scalar_set(
            select(Section.id).where(Section.class_teacher_id == teacher_id)
        )
        as_subject_teacher = await self._scalar_set(
            select(TimetableSlot.section_id).where(
                TimetableSlot.teacher_id == teacher_id
            )
        )
        return as_class_teacher | as_subject_teacher

    async def _teacher_ids_of_sections(
        self, section_ids: set[uuid.UUID]
    ) -> set[uuid.UUID]:
        if not section_ids:
            return set()
        class_teachers = await self._scalar_set(
            select(Section.class_teacher_id).where(Section.id.in_(section_ids))
        )
        subject_teachers = await self._scalar_set(
            select(TimetableSlot.teacher_id).where(
                TimetableSlot.section_id.in_(section_ids)
            )
        )
        return class_teachers | subject_teachers

    async def _student_ids_in_sections(
        self, section_ids: set[uuid.UUID]
    ) -> set[uuid.UUID]:
        if not section_ids:
            return set()
        return await self._scalar_set(
            select(StudentEnrollment.student_id).where(
                StudentEnrollment.section_id.in_(section_ids),
                StudentEnrollment.status == "active",
            )
        )

    async def _sections_of_students(
        self, student_ids: set[uuid.UUID]
    ) -> set[uuid.UUID]:
        if not student_ids:
            return set()
        return await self._scalar_set(
            select(StudentEnrollment.section_id).where(
                StudentEnrollment.student_id.in_(student_ids),
                StudentEnrollment.status == "active",
            )
        )

    async def _child_ids_of(
        self, school_id: uuid.UUID, guardian_id: uuid.UUID
    ) -> set[uuid.UUID]:
        return await self._scalar_set(
            select(guardian_students.c.student_id).where(
                guardian_students.c.guardian_id == guardian_id,
                guardian_students.c.school_id == school_id,
            )
        )

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
        message = await self.db.get(DirectMessage, message_id)
        if message is None or message.school_id != school_id:
            raise not_found("Message not found in this school")
        if message.recipient_id != user_id:
            raise forbidden("Only the recipient can mark a message as read")
        if message.read_at is None:
            message.read_at = datetime.now(timezone.utc)
            await self.db.flush()
        names = await self._names({message.sender_id, message.recipient_id})
        return self._out(message, names)
