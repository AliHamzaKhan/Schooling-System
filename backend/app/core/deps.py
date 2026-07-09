"""Shared FastAPI dependencies: current user and permission enforcement."""
import uuid
from typing import Annotated

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.database import get_db
from app.core.enums import Module, PermissionAction, SystemRole
from app.core.exceptions import credentials_exception, forbidden
from app.core.security import ACCESS_TOKEN, JWTError, decode_token
from app.models.role import Role
from app.models.user import User
from app.modules.permissions.service import PermissionService

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_PREFIX}/auth/login")

DbDep = Annotated[AsyncSession, Depends(get_db)]


async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: DbDep,
) -> User:
    try:
        payload = decode_token(token)
        if payload.get("type") != ACCESS_TOKEN:
            raise credentials_exception()
        user_id = payload.get("sub")
        if not user_id:
            raise credentials_exception()
    except JWTError:
        raise credentials_exception()

    result = await db.execute(
        select(User)
        .where(User.id == user_id)
        .options(selectinload(User.roles).selectinload(Role.permissions))
    )
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        raise credentials_exception()
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


async def require_super_admin(user: CurrentUser) -> User:
    """Allow only the platform Super Admin (manages schools/subscriptions)."""
    if not PermissionService.is_super_admin(user):
        raise forbidden("Super Admin privileges required")
    return user


SuperAdmin = Annotated[User, Depends(require_super_admin)]


async def require_school_member(school_id: uuid.UUID, user: CurrentUser) -> User:
    """Any active user of the school (or Super Admin). For self-service actions."""
    if PermissionService.is_super_admin(user):
        return user
    if user.school_id != school_id:
        raise forbidden("You can only act within your own school")
    return user


async def require_school_admin(school_id: uuid.UUID, user: CurrentUser) -> User:
    """The school's own Headmaster (or Super Admin).

    For school-level administration a Headmaster may perform on their own school
    but ordinary staff/guardians/students may not — e.g. editing school profile
    and branding settings.
    """
    if PermissionService.is_super_admin(user):
        return user
    if user.school_id != school_id:
        raise forbidden("You can only act within your own school")
    if not any(role.code == SystemRole.HEADMASTER.value for role in user.roles):
        raise forbidden("Headmaster privileges required")
    return user


def require_permission(module: Module, action: PermissionAction):
    """Dependency factory that enforces a module/action permission."""

    async def checker(user: CurrentUser, db: DbDep) -> User:
        allowed = await PermissionService(db).has_permission(user, module, action)
        if not allowed:
            raise forbidden(
                f"Missing permission: {action.value} on {module.value}"
            )
        return user

    return checker


async def verify_student_access(
    school_id: uuid.UUID,
    student_id: uuid.UUID,
    user: CurrentUser,
    db: DbDep,
) -> User:
    """Guard for per-student records under /schools/{school_id}/.../{student_id}.

    Access is granted to: the Super Admin; a staff member of the school holding
    STUDENT_MANAGEMENT view (Headmaster/Teacher); the student themselves; and a
    guardian linked to that student. Everyone else is rejected — this both
    enables guardian access to their children and prevents one student/guardian
    from reading another's records.
    """
    from app.models.associations import guardian_students

    if PermissionService.is_super_admin(user):
        return user
    if user.school_id != school_id:
        raise forbidden("You can only act within your own school")
    # The student viewing their own records.
    if user.id == student_id:
        return user
    # A guardian linked to this student.
    linked = await db.scalar(
        select(guardian_students.c.student_id).where(
            guardian_students.c.guardian_id == user.id,
            guardian_students.c.student_id == student_id,
            guardian_students.c.school_id == school_id,
        )
    )
    if linked is not None:
        return user
    # School staff who manage students.
    if await PermissionService(db).has_permission(
        user, Module.STUDENT_MANAGEMENT, PermissionAction.VIEW
    ):
        return user
    raise forbidden("You do not have access to this student's records")


def require_school_permission(module: Module, action: PermissionAction):
    """Dependency factory for routes under /schools/{school_id}.

    Super Admin passes. Otherwise the caller must belong to the path's school
    AND hold the module/action permission (itself gated by the subscription /
    toggle cascade). Reads the `school_id` path parameter directly.
    """

    async def checker(school_id: uuid.UUID, user: CurrentUser, db: DbDep) -> User:
        if PermissionService.is_super_admin(user):
            return user
        if user.school_id != school_id:
            raise forbidden("You can only act within your own school")
        if not await PermissionService(db).has_permission(user, module, action):
            raise forbidden(f"Missing permission: {action.value} on {module.value}")
        return user

    return checker
