"""User Management Service.

Handles per-school role provisioning, user lifecycle, and role assignment.
Authorization model (docs/permissions/03, 05, 07):
  - Super Admin bypasses all checks.
  - A school user may only act within their own school AND must hold the
    relevant management permission (which is itself gated by the subscription /
    module cascade in PermissionService).
"""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.constants import (
    DEFAULT_ROLE_PERMISSIONS,
    DEFAULT_STAFF_MODULE,
    ROLE_DISPLAY_NAMES,
    ROLE_MODULE_MAP,
)
from app.core.enums import Module, PermissionAction, SystemRole
from app.core.exceptions import bad_request, forbidden, not_found
from app.core.security import hash_password
from app.models.role import Role, RolePermission
from app.models.school import School
from app.models.user import User
from app.modules.permissions.service import PermissionService


class UserService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db
        self.perms = PermissionService(db)

    # --------------------------- provisioning ---------------------------- #

    async def provision_school_roles(self, school_id: uuid.UUID) -> list[Role]:
        """Create the default school-scoped roles + permissions if absent."""
        await self._get_school(school_id)
        existing = await self.db.execute(
            select(Role).where(Role.school_id == school_id)
        )
        by_code = {r.code: r for r in existing.scalars().all()}

        created: list[Role] = []
        for code, module_perms in DEFAULT_ROLE_PERMISSIONS.items():
            if code in by_code:
                continue
            role = Role(
                school_id=school_id,
                code=code,
                name=ROLE_DISPLAY_NAMES.get(code, code.title()),
                is_system=False,
                permissions=[
                    self._build_permission(module, actions)
                    for module, actions in module_perms.items()
                ],
            )
            self.db.add(role)
            created.append(role)
        await self.db.flush()
        return created

    @staticmethod
    def _build_permission(module: Module, actions: set[PermissionAction]) -> RolePermission:
        return RolePermission(
            module=module.value,
            can_view=PermissionAction.VIEW in actions,
            can_create=PermissionAction.CREATE in actions,
            can_edit=PermissionAction.EDIT in actions,
            can_delete=PermissionAction.DELETE in actions,
            can_approve=PermissionAction.APPROVE in actions,
            can_export=PermissionAction.EXPORT in actions,
        )

    async def list_school_roles(self, school_id: uuid.UUID) -> list[Role]:
        result = await self.db.execute(
            select(Role).where(Role.school_id == school_id).order_by(Role.name)
        )
        return list(result.scalars().all())

    # ----------------------------- helpers ------------------------------- #

    async def _get_school(self, school_id: uuid.UUID) -> School:
        school = await self.db.get(School, school_id)
        if school is None:
            raise not_found("School not found")
        return school

    async def _get_user_in_school(self, school_id: uuid.UUID, user_id: uuid.UUID) -> User:
        result = await self.db.execute(
            select(User)
            .where(User.id == user_id, User.school_id == school_id)
            .options(selectinload(User.roles).selectinload(Role.permissions))
        )
        user = result.scalar_one_or_none()
        if user is None:
            raise not_found("User not found in this school")
        return user

    async def _resolve_roles(
        self, school_id: uuid.UUID, role_codes: list[str]
    ) -> list[Role]:
        result = await self.db.execute(
            select(Role)
            .where(Role.school_id == school_id, Role.code.in_(role_codes))
            .options(selectinload(Role.permissions))
        )
        roles = list(result.scalars().all())
        found = {r.code for r in roles}
        missing = set(role_codes) - found
        if missing:
            raise bad_request(
                f"Roles not provisioned for this school: {', '.join(sorted(missing))}"
            )
        return roles

    @staticmethod
    def _module_for_role(role_code: str) -> Module:
        return ROLE_MODULE_MAP.get(role_code, DEFAULT_STAFF_MODULE)

    # --------------------------- authorization --------------------------- #

    async def _authorize_write(
        self, actor: User, school_id: uuid.UUID, modules: set[Module], action: PermissionAction
    ) -> None:
        if PermissionService.is_super_admin(actor):
            return
        if actor.school_id != school_id:
            raise forbidden("You can only manage users within your own school")
        for module in modules:
            if not await self.perms.has_permission(actor, module, action):
                raise forbidden(f"Missing permission: {action.value} on {module.value}")

    async def _authorize_read(self, actor: User, school_id: uuid.UUID) -> None:
        if PermissionService.is_super_admin(actor):
            return
        if actor.school_id != school_id:
            raise forbidden("You can only view users within your own school")
        mgmt = (
            Module.TEACHER_MANAGEMENT,
            Module.STUDENT_MANAGEMENT,
            Module.GUARDIAN_MANAGEMENT,
        )
        for module in mgmt:
            if await self.perms.has_permission(actor, module, PermissionAction.VIEW):
                return
        raise forbidden("Missing permission to view users")

    # ------------------------------ headmaster --------------------------- #

    async def create_headmaster(
        self, school_id: uuid.UUID, email: str, password: str, full_name: str, phone: str | None
    ) -> User:
        """Super-Admin-only: provision roles and create the school's Headmaster."""
        await self.provision_school_roles(school_id)
        roles = await self._resolve_roles(school_id, [SystemRole.HEADMASTER.value])
        return await self._create_user(school_id, email, password, full_name, phone, roles)

    # ------------------------------ users -------------------------------- #

    async def create_user(
        self,
        actor: User,
        school_id: uuid.UUID,
        email: str,
        password: str,
        full_name: str,
        phone: str | None,
        role_codes: list[str],
    ) -> User:
        if SystemRole.HEADMASTER.value in role_codes:
            raise bad_request("Use the create-headmaster endpoint to assign the Headmaster role")
        if SystemRole.SUPER_ADMIN.value in role_codes:
            raise bad_request("Super Admin cannot be assigned as a school role")

        roles = await self._resolve_roles(school_id, role_codes)
        modules = {self._module_for_role(code) for code in role_codes}
        await self._authorize_write(actor, school_id, modules, PermissionAction.CREATE)
        return await self._create_user(school_id, email, password, full_name, phone, roles)

    async def _create_user(
        self,
        school_id: uuid.UUID,
        email: str,
        password: str,
        full_name: str,
        phone: str | None,
        roles: list[Role],
    ) -> User:
        email = email.lower()
        dupe = await self.db.scalar(select(User).where(User.email == email))
        if dupe is not None:
            raise bad_request(f"A user with email '{email}' already exists")

        user = User(
            school_id=school_id,
            email=email,
            hashed_password=hash_password(password),
            full_name=full_name,
            phone=phone,
            is_active=True,
            roles=roles,
        )
        self.db.add(user)
        await self.db.flush()
        return await self._get_user_in_school(school_id, user.id)

    async def list_users(
        self, actor: User, school_id: uuid.UUID, role_code: str | None = None,
        limit: int = 50, offset: int = 0,
    ) -> list[User]:
        await self._authorize_read(actor, school_id)
        stmt = (
            select(User)
            .where(User.school_id == school_id)
            .options(selectinload(User.roles).selectinload(Role.permissions))
            .order_by(User.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        if role_code:
            stmt = stmt.join(User.roles).where(Role.code == role_code)
        result = await self.db.execute(stmt)
        return list(result.scalars().unique().all())

    async def get_user(self, actor: User, school_id: uuid.UUID, user_id: uuid.UUID) -> User:
        await self._authorize_read(actor, school_id)
        return await self._get_user_in_school(school_id, user_id)

    async def update_user(
        self, actor: User, school_id: uuid.UUID, user_id: uuid.UUID, data: dict
    ) -> User:
        user = await self._get_user_in_school(school_id, user_id)
        modules = {self._module_for_role(r.code) for r in user.roles} or {DEFAULT_STAFF_MODULE}
        await self._authorize_write(actor, school_id, modules, PermissionAction.EDIT)
        for field, value in data.items():
            setattr(user, field, value)
        await self.db.flush()
        return await self._get_user_in_school(school_id, user_id)

    async def deactivate_user(
        self, actor: User, school_id: uuid.UUID, user_id: uuid.UUID
    ) -> User:
        return await self.update_user(actor, school_id, user_id, {"is_active": False})

    async def assign_roles(
        self, actor: User, school_id: uuid.UUID, user_id: uuid.UUID, role_codes: list[str]
    ) -> User:
        if SystemRole.HEADMASTER.value in role_codes:
            raise bad_request("The Headmaster role cannot be assigned via this endpoint")
        roles = await self._resolve_roles(school_id, role_codes)
        modules = {self._module_for_role(code) for code in role_codes}
        await self._authorize_write(actor, school_id, modules, PermissionAction.EDIT)

        user = await self._get_user_in_school(school_id, user_id)
        current = {r.id for r in user.roles}
        for role in roles:
            if role.id not in current:
                user.roles.append(role)
        await self.db.flush()
        return await self._get_user_in_school(school_id, user_id)

    async def remove_role(
        self, actor: User, school_id: uuid.UUID, user_id: uuid.UUID, role_id: uuid.UUID
    ) -> User:
        user = await self._get_user_in_school(school_id, user_id)
        target = next((r for r in user.roles if r.id == role_id), None)
        if target is None:
            raise not_found("Role is not assigned to this user")
        await self._authorize_write(
            actor, school_id, {self._module_for_role(target.code)}, PermissionAction.EDIT
        )
        user.roles.remove(target)
        await self.db.flush()
        return await self._get_user_in_school(school_id, user_id)
