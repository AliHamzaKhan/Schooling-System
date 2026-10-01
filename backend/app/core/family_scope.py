"""Per-record scope for family readers (guardians and students).

Module permissions such as FEE_MANAGEMENT or RESULTS view are granted to
guardians and students so they can read *their own family's* records. The
module permission alone must never open other families' records, so
school-wide list endpoints apply this scope on top of it.
"""
import uuid

from fastapi import Depends
from sqlalchemy import select

from app.core.deps import CurrentUser, DbDep
from app.core.enums import SystemRole
from app.core.exceptions import forbidden
from app.models.associations import guardian_students
from app.modules.permissions.service import PermissionService

_FAMILY_ROLES = {SystemRole.GUARDIAN.value, SystemRole.STUDENT.value}


async def family_scope(
    school_id: uuid.UUID, current_user: CurrentUser, db: DbDep
) -> set[uuid.UUID] | None:
    """Student ids this caller may read; ``None`` means the whole school.

    A caller whose only roles are guardian/student is limited to themselves
    and their currently linked children. Staff roles keep school-wide access.
    """
    codes = {role.code for role in current_user.roles}
    if PermissionService.is_super_admin(current_user) or not codes <= _FAMILY_ROLES:
        return None
    visible = {current_user.id} if SystemRole.STUDENT.value in codes else set()
    if SystemRole.GUARDIAN.value in codes:
        visible |= set((await db.execute(
            select(guardian_students.c.student_id).where(
                guardian_students.c.school_id == school_id,
                guardian_students.c.guardian_id == current_user.id,
            )
        )).scalars())
    return visible


FamilyScope = Depends(family_scope)


async def require_staff_reader(
    scope: set[uuid.UUID] | None = FamilyScope,
) -> None:
    """Reject family readers from staff-only, school-wide record views."""
    if scope is not None:
        raise forbidden("This view is available to school staff only")
