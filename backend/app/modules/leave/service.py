"""Leave Management Service."""
import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import EnrollmentStatus, Module, PermissionAction, SystemRole
from app.core.exceptions import bad_request, forbidden, not_found
from app.models.academic import SchoolClass, Section, StudentEnrollment
from app.models.associations import guardian_students
from app.models.leave import LeaveRequest
from app.models.user import User
from app.modules.leave import schemas
from app.modules.permissions.service import PermissionService


class LeaveService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

    @staticmethod
    def _has_role(user: User, code: str) -> bool:
        return any(r.code == code for r in user.roles)

    async def _guardian_children(self, guardian_id: uuid.UUID) -> set[uuid.UUID]:
        rows = await self.db.execute(
            select(guardian_students.c.student_id).where(
                guardian_students.c.guardian_id == guardian_id
            )
        )
        return {r[0] for r in rows.all()}

    async def _teacher_section_ids(self, teacher_id: uuid.UUID) -> list[uuid.UUID]:
        rows = await self.db.execute(
            select(Section.id).where(Section.class_teacher_id == teacher_id)
        )
        return [r[0] for r in rows.all()]

    async def _students_in_sections(self, section_ids: list[uuid.UUID]) -> set[uuid.UUID]:
        if not section_ids:
            return set()
        rows = await self.db.execute(
            select(StudentEnrollment.student_id).where(
                StudentEnrollment.section_id.in_(section_ids),
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
        )
        return {r[0] for r in rows.all()}

    async def _student_classes(
        self, student_ids: set[uuid.UUID]
    ) -> dict[uuid.UUID, tuple[str, str]]:
        """Map each student to their active (class_name, section_name)."""
        if not student_ids:
            return {}
        rows = await self.db.execute(
            select(
                StudentEnrollment.student_id, SchoolClass.name, Section.name
            )
            .join(Section, StudentEnrollment.section_id == Section.id)
            .join(SchoolClass, Section.class_id == SchoolClass.id)
            .where(
                StudentEnrollment.student_id.in_(student_ids),
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
        )
        return {r[0]: (r[1], r[2]) for r in rows.all()}

    async def _attach_names(self, leaves: list[LeaveRequest]) -> list[LeaveRequest]:
        """Set ``student_name`` / ``requester_name`` and the student's current
        class + section on each leave for output."""
        ids: set[uuid.UUID] = set()
        student_ids: set[uuid.UUID] = set()
        for lv in leaves:
            ids.add(lv.requester_id)
            if lv.student_id:
                ids.add(lv.student_id)
                student_ids.add(lv.student_id)
        if not ids:
            return leaves
        rows = await self.db.execute(
            select(User.id, User.full_name).where(User.id.in_(ids))
        )
        names = {r[0]: r[1] for r in rows.all()}
        classes = await self._student_classes(student_ids)
        for lv in leaves:
            lv.requester_name = names.get(lv.requester_id)
            lv.student_name = names.get(lv.student_id) if lv.student_id else None
            cls = classes.get(lv.student_id) if lv.student_id else None
            lv.student_class = cls[0] if cls else None
            lv.student_section = cls[1] if cls else None
        return leaves

    # ------------------------------ submit ------------------------------- #

    async def submit(
        self, school_id: uuid.UUID, user: User, data: schemas.LeaveSubmit
    ) -> LeaveRequest:
        # Resolve the subject student.
        student_id: uuid.UUID | None
        if self._has_role(user, SystemRole.STUDENT.value):
            student_id = user.id  # a student's own request
        elif self._has_role(user, SystemRole.GUARDIAN.value):
            if data.student_id is None:
                raise bad_request("Select which child this leave is for")
            children = await self._guardian_children(user.id)
            if data.student_id not in children:
                raise forbidden("You can only apply for your own children")
            student_id = data.student_id
        else:
            student_id = data.student_id  # staff applying for someone (optional)

        leave = LeaveRequest(
            school_id=school_id,
            requester_id=user.id,
            student_id=student_id,
            leave_type=data.leave_type,
            start_date=data.start_date,
            end_date=data.end_date,
            reason=data.reason,
            status="pending",
        )
        self.db.add(leave)
        await self.db.flush()
        return leave

    async def _get(self, school_id: uuid.UUID, leave_id: uuid.UUID) -> LeaveRequest:
        leave = await self.db.get(LeaveRequest, leave_id)
        if leave is None or leave.school_id != school_id:
            raise not_found("Leave request not found in this school")
        return leave

    # ------------------------------ lists -------------------------------- #

    async def list_own(self, school_id: uuid.UUID, requester_id: uuid.UUID) -> list[LeaveRequest]:
        result = await self.db.execute(
            select(LeaveRequest).where(
                LeaveRequest.school_id == school_id, LeaveRequest.requester_id == requester_id
            ).order_by(LeaveRequest.created_at.desc())
        )
        return await self._attach_names(list(result.scalars().all()))

    async def list_all(self, school_id: uuid.UUID, status: str | None = None) -> list[LeaveRequest]:
        stmt = select(LeaveRequest).where(LeaveRequest.school_id == school_id)
        if status is not None:
            stmt = stmt.where(LeaveRequest.status == status)
        stmt = stmt.order_by(LeaveRequest.created_at.desc())
        return await self._attach_names(list((await self.db.execute(stmt)).scalars().all()))

    async def _can_review_all(self, user: User) -> bool:
        """Headmaster / anyone holding the leave approve permission."""
        if PermissionService.is_super_admin(user):
            return True
        return await PermissionService(self.db).has_permission(
            user, Module.LEAVE_MANAGEMENT, PermissionAction.APPROVE
        )

    async def list_for_review(
        self, school_id: uuid.UUID, user: User, status: str | None = None
    ) -> list[LeaveRequest]:
        """Leaves the caller may review: everything for a headmaster/approver, or
        just their own sections' students for a class teacher."""
        if await self._can_review_all(user):
            return await self.list_all(school_id, status)

        # Class teacher: only their sections' students.
        section_ids = await self._teacher_section_ids(user.id)
        student_ids = await self._students_in_sections(section_ids)
        if not student_ids:
            return []
        stmt = select(LeaveRequest).where(
            LeaveRequest.school_id == school_id,
            LeaveRequest.student_id.in_(student_ids),
        )
        if status is not None:
            stmt = stmt.where(LeaveRequest.status == status)
        stmt = stmt.order_by(LeaveRequest.created_at.desc())
        return await self._attach_names(list((await self.db.execute(stmt)).scalars().all()))

    # ------------------------------ review ------------------------------- #

    async def _may_review_leave(self, user: User, leave: LeaveRequest) -> bool:
        if await self._can_review_all(user):
            return True
        # A class teacher may review leaves for their own section students.
        if leave.student_id is not None and self._has_role(user, SystemRole.TEACHER.value):
            section_ids = await self._teacher_section_ids(user.id)
            students = await self._students_in_sections(section_ids)
            return leave.student_id in students
        return False

    async def review(
        self, school_id: uuid.UUID, leave_id: uuid.UUID, approve: bool, reviewer: User, note: str | None
    ) -> LeaveRequest:
        leave = await self._get(school_id, leave_id)
        if not await self._may_review_leave(reviewer, leave):
            raise forbidden("You are not allowed to review this leave request")
        if leave.status != "pending":
            raise bad_request(f"Leave request is already {leave.status}")
        leave.status = "approved" if approve else "rejected"
        leave.reviewed_by = reviewer.id
        leave.review_note = note
        leave.reviewed_at = datetime.now(timezone.utc)
        await self.db.flush()
        return (await self._attach_names([leave]))[0]
