"""Current relationship gates for student reports and academic rosters.

Module permissions remain necessary; they never grant an unrelated teacher
access to every student. Custom school-wide staff policy is not implicit.
"""
import uuid

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import CurrentUser, DbDep
from app.core.enums import EnrollmentStatus, Module, PermissionAction, SystemRole
from app.core.exceptions import forbidden, not_found
from app.models.academic import SchoolClass, Section, StudentEnrollment, Subject, TimetableSlot
from app.models.associations import guardian_students
from app.models.role import Role
from app.models.user import User
from app.modules.permissions.service import PermissionService


def role_ids(school_id, code, *, active=False):
    stmt = select(User.id).where(
        User.school_id == school_id, User.roles.any(Role.code == code),
    )
    return stmt.where(User.is_active.is_(True)) if active else stmt


def valid_sections(school_id):
    return select(Section.id).join(SchoolClass).where(
        Section.school_id == school_id, SchoolClass.school_id == school_id,
    )


def taught_sections(school_id, teacher_id):
    slots = select(TimetableSlot.section_id).join(Subject).where(
        TimetableSlot.school_id == school_id, Subject.school_id == school_id,
        TimetableSlot.teacher_id == teacher_id,
    )
    return select(Section.id).where(
        Section.id.in_(valid_sections(school_id)),
        or_(Section.class_teacher_id == teacher_id, Section.id.in_(slots)),
    )


def enrolled_students(school_id, sections):
    return select(StudentEnrollment.student_id).where(
        StudentEnrollment.school_id == school_id,
        StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
        StudentEnrollment.section_id.in_(sections),
        StudentEnrollment.section_id.in_(valid_sections(school_id)),
        StudentEnrollment.student_id.in_(role_ids(school_id, SystemRole.STUDENT.value)),
    )


class AcademicAccess:
    def __init__(self, db: AsyncSession, school_id: uuid.UUID, user: User):
        self.db, self.school_id, self.user = db, school_id, user

    @property
    def leadership(self):
        return PermissionService.is_super_admin(self.user) or (
            self.user.school_id == self.school_id
            and any(r.code == SystemRole.HEADMASTER.value for r in self.user.roles)
        )

    async def staff(self):
        if not PermissionService.is_super_admin(self.user) and self.user.school_id != self.school_id:
            raise forbidden("You can only act within your own school")
        if not self.leadership and not any(r.code == SystemRole.TEACHER.value for r in self.user.roles):
            raise forbidden("Academic staff access required")
        if not await PermissionService(self.db).has_permission(
            self.user, Module.STUDENT_MANAGEMENT, PermissionAction.VIEW,
        ):
            raise forbidden("Student management view permission required")

    async def section(self, section_id):
        if await self.db.scalar(valid_sections(self.school_id).where(Section.id == section_id)) is None:
            raise not_found("Section not found in this school")
        await self.staff()
        if not self.leadership and await self.db.scalar(
            taught_sections(self.school_id, self.user.id).where(Section.id == section_id)
        ) is None:
            raise forbidden("You do not teach this section")

    async def student(self, student_id):
        """Return whether this caller may preview unpublished marks."""
        if await self.db.scalar(role_ids(self.school_id, SystemRole.STUDENT.value).where(User.id == student_id)) is None:
            raise not_found("Student not found in this school")
        if not PermissionService.is_super_admin(self.user) and self.user.school_id != self.school_id:
            raise forbidden("You can only act within your own school")
        if self.leadership:
            await self.staff()
            return True
        codes = {r.code for r in self.user.roles}
        if SystemRole.TEACHER.value in codes and await PermissionService(self.db).has_permission(
            self.user, Module.STUDENT_MANAGEMENT, PermissionAction.VIEW,
        ):
            if student_id in (await self.db.scalars(enrolled_students(
                self.school_id, taught_sections(self.school_id, self.user.id),
            ))).all():
                return True
        if self.user.id == student_id:
            return False
        if SystemRole.GUARDIAN.value in codes and await self.db.scalar(
            select(guardian_students.c.student_id).where(
                guardian_students.c.school_id == self.school_id,
                guardian_students.c.guardian_id == self.user.id,
                guardian_students.c.student_id == student_id,
            )
        ) is not None:
            return False
        raise forbidden("You cannot access this student's academic records")


async def verify_academic_student(school_id: uuid.UUID, student_id: uuid.UUID, user: CurrentUser, db: DbDep) -> bool:
    return await AcademicAccess(db, school_id, user).student(student_id)
