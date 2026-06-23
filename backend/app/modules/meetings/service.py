"""Parent-Teacher Meetings Service."""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import Module, PermissionAction
from app.core.exceptions import bad_request, not_found
from app.models.meeting import Meeting
from app.models.user import User
from app.modules.meetings import schemas
from app.modules.permissions.service import PermissionService


class MeetingService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db
        self.perms = PermissionService(db)

    async def _validate_user(self, school_id: uuid.UUID, user_id: uuid.UUID | None, label: str) -> None:
        if user_id is None:
            return
        user = await self.db.get(User, user_id)
        if user is None or user.school_id != school_id:
            raise bad_request(f"{label} is not a member of this school")

    async def schedule(self, school_id: uuid.UUID, data: schemas.MeetingCreate) -> Meeting:
        await self._validate_user(school_id, data.teacher_id, "Teacher")
        await self._validate_user(school_id, data.guardian_id, "Guardian")
        await self._validate_user(school_id, data.student_id, "Student")
        meeting = Meeting(school_id=school_id, status="scheduled", **data.model_dump())
        self.db.add(meeting)
        await self.db.flush()
        return meeting

    async def _get(self, school_id: uuid.UUID, meeting_id: uuid.UUID) -> Meeting:
        meeting = await self.db.get(Meeting, meeting_id)
        if meeting is None or meeting.school_id != school_id:
            raise not_found("Meeting not found in this school")
        return meeting

    async def list_meetings(
        self,
        school_id: uuid.UUID,
        current_user: User,
        status: str | None = None,
    ) -> list[Meeting]:
        stmt = select(Meeting).where(Meeting.school_id == school_id)
        if status is not None:
            stmt = stmt.where(Meeting.status == status)
        # Staff who manage meetings (Headmaster) see all; a guardian only sees
        # meetings they are a party to (their own children's parent-teacher
        # meetings). Super Admin sees all.
        is_staff = PermissionService.is_super_admin(
            current_user
        ) or await self.perms.has_permission(
            current_user, Module.MEETINGS, PermissionAction.EDIT
        )
        if not is_staff:
            stmt = stmt.where(Meeting.guardian_id == current_user.id)
        stmt = stmt.order_by(Meeting.scheduled_at.desc())
        return list((await self.db.execute(stmt)).scalars().all())

    async def update(self, school_id: uuid.UUID, meeting_id: uuid.UUID, data: schemas.MeetingUpdate) -> Meeting:
        meeting = await self._get(school_id, meeting_id)
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(meeting, field, value)
        await self.db.flush()
        return meeting

    async def delete(self, school_id: uuid.UUID, meeting_id: uuid.UUID) -> None:
        meeting = await self._get(school_id, meeting_id)
        await self.db.delete(meeting)
        await self.db.flush()
