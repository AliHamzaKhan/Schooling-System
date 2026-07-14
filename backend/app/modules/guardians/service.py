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

from sqlalchemy import delete, insert, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.enums import Module, PermissionAction, SystemRole
from app.core.exceptions import bad_request, forbidden, not_found
from app.models.academic import Section, SchoolClass, StudentEnrollment
from app.models.associations import guardian_students
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
        self, student_ids: list[uuid.UUID]
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

    def _to_child_out(
        self, student: User, relationship: str | None, placements: dict
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

        already = await self.db.scalar(
            select(guardian_students.c.guardian_id).where(
                guardian_students.c.guardian_id == guardian_id,
                guardian_students.c.student_id == student.id,
            )
        )
        if already is None:
            await self.db.execute(
                insert(guardian_students).values(
                    guardian_id=guardian_id,
                    student_id=student.id,
                    school_id=school_id,
                    relationship=data.relationship,
                )
            )
            await self.db.flush()
        placements = await self._placements([student.id])
        return self._to_child_out(student, data.relationship, placements)

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
        placements = await self._placements([u.id for u, _ in rows])
        return [self._to_child_out(u, rel, placements) for u, rel in rows]

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
