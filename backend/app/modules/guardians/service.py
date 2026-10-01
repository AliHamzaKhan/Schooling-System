"""Guardian ↔ student linkage service.

A guardian is a normal school user holding the `guardian` role; a child is a
user holding the `student` role in the same school. The `guardian_students`
association records the relationship. Guardians get read-only access to their
linked children's data (attendance, results, fees, timetable, …) — the
read-side enforcement lives in `verify_student_access` (app/core/deps.py); the
write restrictions are enforced by the guardian role's permission set (VIEW
only on the relevant modules).

Authorization model (mirrors UserService):
  - Super Admin bypasses all checks.
  - Managing links (link/unlink, listing another guardian's children) requires
    GUARDIAN_MANAGEMENT permission within the caller's own school.
  - A guardian may always read their own children (`/me/children`).
"""
import uuid
from datetime import date

from sqlalchemy import case, delete, func, insert, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.enums import AttendanceStatus, InvoiceStatus, Module, PermissionAction, SystemRole
from app.core.exceptions import bad_request, forbidden, not_found
from app.models.academic import Section, SchoolClass, StudentEnrollment
from app.models.associations import guardian_students
from app.models.attendance import AttendanceRecord
from app.models.fees import Invoice
from app.models.homework import Assignment, Submission
from app.models.user import User
from app.modules.guardians import schemas
from app.modules.permissions.service import PermissionService


class GuardianService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db
        self.perms = PermissionService(db)

    # ----------------------------- helpers ------------------------------- #

    async def _get_user_with_role(
        self, school_id: uuid.UUID, user_id: uuid.UUID, role_code: str
    ) -> User:
        result = await self.db.execute(
            select(User)
            .where(User.id == user_id, User.school_id == school_id)
            .options(selectinload(User.roles))
        )
        user = result.scalar_one_or_none()
        if user is None:
            raise not_found("User not found in this school")
        if role_code not in {r.code for r in user.roles}:
            raise bad_request(f"User does not hold the '{role_code}' role")
        return user

    async def _placements(
        self, school_id: uuid.UUID, student_ids: list[uuid.UUID]
    ) -> dict[uuid.UUID, tuple]:
        """student_id → (section_id, section_name, class_name, grade_level).

        Uses each student's most recent active enrollment.
        """
        if not student_ids:
            return {}
        stmt = (
            select(
                StudentEnrollment.student_id,
                Section.id,
                Section.name,
                SchoolClass.name,
                SchoolClass.level,
            )
            .join(Section, StudentEnrollment.section_id == Section.id)
            .join(SchoolClass, Section.class_id == SchoolClass.id)
            .where(
                StudentEnrollment.student_id.in_(student_ids),
                StudentEnrollment.school_id == school_id,
                Section.school_id == school_id,
                SchoolClass.school_id == school_id,
                StudentEnrollment.status == "active",
            )
            .order_by(StudentEnrollment.created_at.desc())
        )
        out: dict[uuid.UUID, tuple] = {}
        for sid, sec_id, sec_name, cls_name, level in (
            await self.db.execute(stmt)
        ).all():
            out.setdefault(sid, (sec_id, sec_name, cls_name, level))
        return out

    async def _summaries(
        self, school_id: uuid.UUID, placements: dict, student_ids: list[uuid.UUID]
    ) -> dict[uuid.UUID, dict]:
        """Per-child fees, homework and this month's attendance in three queries."""
        out: dict[uuid.UUID, dict] = {
            sid: {"attendance_percent": None, "pending_homework": 0, "fees_due": False}
            for sid in student_ids
        }
        if not student_ids:
            return out
        today = date.today()

        owing = await self.db.execute(
            select(Invoice.student_id).where(
                Invoice.school_id == school_id,
                Invoice.student_id.in_(student_ids),
                Invoice.status != InvoiceStatus.PAID.value,
                Invoice.amount > Invoice.amount_paid,
            ).distinct()
        )
        for sid in owing.scalars():
            out[sid]["fees_due"] = True

        sections = {sid: p[0] for sid, p in placements.items() if p[0] is not None}
        if sections:
            open_work = (
                select(Assignment.section_id, func.count(Assignment.id))
                .where(
                    Assignment.school_id == school_id,
                    Assignment.section_id.in_(set(sections.values())),
                    Assignment.due_date >= today,
                )
                .group_by(Assignment.section_id)
            )
            per_section = dict((await self.db.execute(open_work)).all())
            submitted = (
                select(Submission.student_id, func.count(Submission.id))
                .join(Assignment, Assignment.id == Submission.assignment_id)
                .where(
                    Assignment.school_id == school_id,
                    Assignment.due_date >= today,
                    Submission.student_id.in_(list(sections)),
                    Assignment.section_id.in_(set(sections.values())),
                )
                .group_by(Submission.student_id)
            )
            done = dict((await self.db.execute(submitted)).all())
            for sid, section_id in sections.items():
                out[sid]["pending_homework"] = max(0, per_section.get(section_id, 0) - done.get(sid, 0))

        attended = (AttendanceStatus.PRESENT.value, AttendanceStatus.LATE.value)
        month = (
            select(
                AttendanceRecord.student_id,
                func.count(AttendanceRecord.id),
                func.sum(case((AttendanceRecord.status.in_(attended), 1), else_=0)),
            )
            .where(
                AttendanceRecord.school_id == school_id,
                AttendanceRecord.student_id.in_(student_ids),
                AttendanceRecord.subject_id.is_(None),
                AttendanceRecord.attendance_date >= today.replace(day=1),
                AttendanceRecord.attendance_date <= today,
            )
            .group_by(AttendanceRecord.student_id)
        )
        for sid, total, present in (await self.db.execute(month)).all():
            if total:
                out[sid]["attendance_percent"] = round(100 * int(present or 0) / int(total))
        return out

    def _to_child_out(
        self, student: User, relationship: str | None, placements: dict,
        summaries: dict | None = None,
    ) -> schemas.ChildOut:
        sec_id, sec_name, cls_name, level = placements.get(
            student.id, (None, None, None, None)
        )
        return schemas.ChildOut(
            student_id=student.id,
            full_name=student.full_name,
            email=student.email,
            relationship=relationship,
            section_id=sec_id,
            section_name=sec_name,
            class_name=cls_name,
            grade_level=level,
            **((summaries or {}).get(student.id) or {}),
        )

    # --------------------------- authorization --------------------------- #

    async def _authorize_manage(self, actor: User, school_id: uuid.UUID) -> None:
        if PermissionService.is_super_admin(actor):
            return
        if actor.school_id != school_id:
            raise forbidden("You can only manage guardians within your own school")
        if not await self.perms.has_permission(
            actor, Module.GUARDIAN_MANAGEMENT, PermissionAction.EDIT
        ):
            raise forbidden("Missing permission: edit on guardian_management")

    async def _authorize_view_links(
        self, actor: User, school_id: uuid.UUID, guardian_id: uuid.UUID
    ) -> None:
        # A guardian may always view their own children.
        if actor.id == guardian_id:
            return
        if PermissionService.is_super_admin(actor):
            return
        if actor.school_id != school_id:
            raise forbidden("You can only view guardians within your own school")
        if not await self.perms.has_permission(
            actor, Module.GUARDIAN_MANAGEMENT, PermissionAction.VIEW
        ):
            raise forbidden("Missing permission: view on guardian_management")

    # ------------------------------ commands ----------------------------- #

    async def link_child(
        self,
        actor: User,
        school_id: uuid.UUID,
        guardian_id: uuid.UUID,
        data: schemas.ChildLink,
    ) -> schemas.ChildOut:
        await self._authorize_manage(actor, school_id)
        guardian = await self._get_user_with_role(
            school_id, guardian_id, SystemRole.GUARDIAN.value
        )
        student = await self._get_user_with_role(
            school_id, data.student_id, SystemRole.STUDENT.value
        )
        if guardian.id == student.id:
            raise bad_request("A user cannot be their own guardian")

        existing = (
            await self.db.execute(
                select(
                    guardian_students.c.school_id,
                    guardian_students.c.relationship,
                )
                .where(
                    guardian_students.c.guardian_id == guardian_id,
                    guardian_students.c.student_id == student.id,
                )
                .with_for_update()
            )
        ).one_or_none()
        relationship = data.relationship
        if existing is None:
            await self.db.execute(
                insert(guardian_students).values(
                    guardian_id=guardian_id,
                    student_id=student.id,
                    school_id=school_id,
                    relationship=relationship,
                )
            )
        else:
            existing_school_id, existing_relationship = existing
            # The composite key is global to the two users. Do not silently
            # accept a malformed association whose tenant disagrees with both
            # verified users; that would make a successful response lie about
            # a link that is not usable within this school.
            if existing_school_id != school_id:
                raise bad_request("Guardian link ownership is inconsistent")
            # Re-linking without a label is intentionally idempotent and keeps
            # the current relationship. A supplied label is an explicit
            # correction (for example, from "father" to "guardian").
            if relationship is None:
                relationship = existing_relationship
            elif relationship != existing_relationship:
                await self.db.execute(
                    update(guardian_students)
                    .where(
                        guardian_students.c.guardian_id == guardian_id,
                        guardian_students.c.student_id == student.id,
                        guardian_students.c.school_id == school_id,
                    )
                    .values(relationship=relationship)
                )
        await self.db.flush()
        placements = await self._placements(school_id, [student.id])
        summaries = await self._summaries(school_id, placements, [student.id])
        return self._to_child_out(student, relationship, placements, summaries)

    async def unlink_child(
        self,
        actor: User,
        school_id: uuid.UUID,
        guardian_id: uuid.UUID,
        student_id: uuid.UUID,
    ) -> None:
        await self._authorize_manage(actor, school_id)
        result = await self.db.execute(
            delete(guardian_students).where(
                guardian_students.c.guardian_id == guardian_id,
                guardian_students.c.student_id == student_id,
                guardian_students.c.school_id == school_id,
            )
        )
        if result.rowcount == 0:
            raise not_found("This student is not linked to the guardian")
        await self.db.flush()

    # ------------------------------- reads ------------------------------- #

    async def list_children(
        self, actor: User, school_id: uuid.UUID, guardian_id: uuid.UUID
    ) -> list[schemas.ChildOut]:
        await self._authorize_view_links(actor, school_id, guardian_id)
        # Confirm the guardian exists in this school (clear 404 vs empty list).
        await self._get_user_with_role(
            school_id, guardian_id, SystemRole.GUARDIAN.value
        )
        rows = (
            await self.db.execute(
                select(User, guardian_students.c.relationship)
                .join(guardian_students, guardian_students.c.student_id == User.id)
                .where(
                    guardian_students.c.guardian_id == guardian_id,
                    guardian_students.c.school_id == school_id,
                )
                .options(selectinload(User.roles))
                .order_by(User.full_name)
            )
        ).all()
        ids = [u.id for u, _ in rows]
        placements = await self._placements(school_id, ids)
        summaries = await self._summaries(school_id, placements, ids)
        return [self._to_child_out(u, rel, placements, summaries) for u, rel in rows]

    async def my_children(
        self, current_user: User, school_id: uuid.UUID
    ) -> list[schemas.ChildOut]:
        if (
            not PermissionService.is_super_admin(current_user)
            and current_user.school_id != school_id
        ):
            raise forbidden("You can only act within your own school")
        return await self.list_children(current_user, school_id, current_user.id)

    async def linked_student_ids(self, guardian_id: uuid.UUID) -> set[uuid.UUID]:
        rows = await self.db.execute(
            select(guardian_students.c.student_id).where(
                guardian_students.c.guardian_id == guardian_id
            )
        )
        return set(rows.scalars().all())
