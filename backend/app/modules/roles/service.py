"""Role & Permission Management Service (docs/permissions/03, 05, 06).

Grant bounding rules:
  - Every granted (module, action) must be within the school's effective modules
    (subscription plan ∩ Super Admin toggles).
  - A Headmaster may only grant a permission they themselves hold (cannot escalate
    or grant beyond their own access).
  - A Headmaster may not edit the headmaster/super_admin roles; the Super Admin
    sets the Headmaster's own permissions (bounded by effective modules).
"""
import re
import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.enums import PermissionAction, SystemRole
from app.core.exceptions import bad_request, forbidden, not_found
from app.models.associations import user_roles
from app.models.role import Role, RolePermission
from app.models.school import School
from app.models.user import User
from app.modules.permissions.service import PermissionService
from app.modules.roles import schemas

_PROTECTED_CODES = {SystemRole.HEADMASTER.value, SystemRole.SUPER_ADMIN.value}
_DEFAULT_CODES = {
    SystemRole.HEADMASTER.value,
    SystemRole.TEACHER.value,
    SystemRole.GUARDIAN.value,
    SystemRole.STUDENT.value,
    SystemRole.DRIVER.value,
    SystemRole.ACCOUNTANT.value,
}


def _slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", value.strip().lower()).strip("_")
    return slug[:50] or "role"


class RoleService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db
        self.perms = PermissionService(db)

    # ----------------------------- helpers ------------------------------- #

    async def _get_school(self, school_id: uuid.UUID) -> School:
        school = await self.db.get(School, school_id)
        if school is None:
            raise not_found("School not found")
        return school

    async def _get_role(self, school_id: uuid.UUID, role_id: uuid.UUID) -> Role:
        result = await self.db.execute(
            select(Role)
            .where(Role.id == role_id, Role.school_id == school_id)
            .options(selectinload(Role.permissions))
        )
        role = result.scalar_one_or_none()
        if role is None:
            raise not_found("Role not found in this school")
        return role

    @staticmethod
    def _is_headmaster(actor: User) -> bool:
        return any(r.code == SystemRole.HEADMASTER.value for r in actor.roles)

    def _ensure_can_manage(self, actor: User, school_id: uuid.UUID) -> bool:
        """Return True if actor is Super Admin; otherwise require Headmaster + same school."""
        if PermissionService.is_super_admin(actor):
            return True
        if actor.school_id != school_id:
            raise forbidden("You can only manage roles within your own school")
        if not self._is_headmaster(actor):
            raise forbidden("Only the Headmaster may manage roles")
        return False

    async def _validate_grants(
        self,
        actor: User,
        school_id: uuid.UUID,
        is_super: bool,
        entries: list[schemas.ModulePermissionIn],
    ) -> None:
        effective = await self.perms.school_effective_modules(school_id)
        for entry in entries:
            module_val = entry.module.value
            if module_val not in effective:
                raise bad_request(
                    f"Module '{module_val}' is not available for this school "
                    "(disabled by Super Admin or not in the subscription plan)"
                )
            if is_super:
                continue
            # Headmaster: can only grant what they themselves hold.
            for action in entry.actions:
                if not await self.perms.has_permission(actor, entry.module, action):
                    raise forbidden(
                        f"You cannot grant '{action.value}' on '{module_val}' "
                        "because you do not hold that permission"
                    )

    @staticmethod
    def _build_permissions(entries: list[schemas.ModulePermissionIn]) -> list[RolePermission]:
        perms: list[RolePermission] = []
        for entry in entries:
            actions = set(entry.actions)
            perms.append(
                RolePermission(
                    module=entry.module.value,
                    can_view=PermissionAction.VIEW in actions,
                    can_create=PermissionAction.CREATE in actions,
                    can_edit=PermissionAction.EDIT in actions,
                    can_delete=PermissionAction.DELETE in actions,
                    can_approve=PermissionAction.APPROVE in actions,
                    can_export=PermissionAction.EXPORT in actions,
                )
            )
        return perms

    @staticmethod
    def to_out(role: Role) -> schemas.RoleDetailOut:
        actions_by_module: list[schemas.ModulePermissionOut] = []
        for perm in role.permissions:
            granted = [
                a.value
                for a in PermissionAction
                if getattr(perm, f"can_{a.value}", False)
            ]
            if granted:
                actions_by_module.append(
                    schemas.ModulePermissionOut(module=perm.module, actions=granted)
                )
        return schemas.RoleDetailOut(
            id=role.id,
            school_id=role.school_id,
            code=role.code,
            name=role.name,
            is_system=role.is_system,
            permissions=actions_by_module,
        )

    # ------------------------------ operations --------------------------- #

    async def create_role(
        self, actor: User, school_id: uuid.UUID, data: schemas.RoleCreate
    ) -> Role:
        is_super = self._ensure_can_manage(actor, school_id)
        await self._get_school(school_id)

        code = _slugify(data.code or data.name)
        if code in _DEFAULT_CODES or code == SystemRole.SUPER_ADMIN.value:
            raise bad_request(f"'{code}' is a reserved role code")
        existing = await self.db.scalar(
            select(Role).where(Role.school_id == school_id, Role.code == code)
        )
        if existing is not None:
            raise bad_request(f"A role with code '{code}' already exists in this school")

        await self._validate_grants(actor, school_id, is_super, data.permissions)
        role = Role(
            school_id=school_id,
            code=code,
            name=data.name,
            is_system=False,
            permissions=self._build_permissions(data.permissions),
        )
        self.db.add(role)
        await self.db.flush()
        return await self._get_role(school_id, role.id)

    async def get_role(self, actor: User, school_id: uuid.UUID, role_id: uuid.UUID) -> Role:
        self._ensure_can_manage(actor, school_id)
        return await self._get_role(school_id, role_id)

    async def rename_role(
        self, actor: User, school_id: uuid.UUID, role_id: uuid.UUID, name: str
    ) -> Role:
        is_super = self._ensure_can_manage(actor, school_id)
        role = await self._get_role(school_id, role_id)
        if not is_super and role.code in _PROTECTED_CODES:
            raise forbidden("Only the Super Admin may modify this role")
        role.name = name
        await self.db.flush()
        return await self._get_role(school_id, role_id)

    async def set_permissions(
        self,
        actor: User,
        school_id: uuid.UUID,
        role_id: uuid.UUID,
        entries: list[schemas.ModulePermissionIn],
    ) -> Role:
        is_super = self._ensure_can_manage(actor, school_id)
        role = await self._get_role(school_id, role_id)
        # Headmaster cannot edit their own (or the super admin) role; Super Admin can.
        if not is_super and role.code in _PROTECTED_CODES:
            raise forbidden("Only the Super Admin may set permissions for this role")

        await self._validate_grants(actor, school_id, is_super, entries)

        # Replace all existing grants. Clear + flush first so the delete-orphan
        # cascade removes old rows before new ones are inserted, avoiding a
        # collision on the (role_id, module) unique constraint.
        role.permissions.clear()
        await self.db.flush()
        role.permissions.extend(self._build_permissions(entries))
        await self.db.flush()
        return await self._get_role(school_id, role_id)

    async def delete_role(self, actor: User, school_id: uuid.UUID, role_id: uuid.UUID) -> None:
        self._ensure_can_manage(actor, school_id)
        role = await self._get_role(school_id, role_id)
        if role.code in _DEFAULT_CODES:
            raise bad_request("Default roles cannot be deleted")
        assigned = await self.db.scalar(
            select(func.count())
            .select_from(user_roles)
            .where(user_roles.c.role_id == role_id)
        )
        if assigned:
            raise bad_request(
                f"Cannot delete role: it is still assigned to {assigned} user(s)"
            )
        await self.db.delete(role)
        await self.db.flush()
