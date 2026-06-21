"""Permission resolution service — the RBAC cascade enforcer.

Implements the hierarchical inheritance from docs/permissions/04 and the
effective-access formula from docs/permissions/07-permission-flow.md:

    Effective Access =
          School Module Toggle (Super Admin)
        ∩ Subscription Plan Feature
        ∩ Role / Staff Permission

The Super Admin bypasses all checks. Any denial upstream removes the module
entirely.
"""
from app.core.enums import Module, PermissionAction, SchoolStatus, SystemRole
from app.models.school import School
from app.models.user import User
from sqlalchemy.ext.asyncio import AsyncSession


class PermissionService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    @staticmethod
    def is_super_admin(user: User) -> bool:
        return any(role.code == SystemRole.SUPER_ADMIN.value for role in user.roles)

    async def school_effective_modules(self, school_id) -> set[str]:
        """Modules a school can access: subscription plan ∩ Super Admin toggles.

        Returns empty for a missing or non-active school. This is the school-level
        ceiling that bounds every role and user within the school.
        """
        if school_id is None:
            return set()
        school = await self.db.get(School, school_id)
        if school is None or school.status != SchoolStatus.ACTIVE.value:
            return set()

        plan_modules = set(school.subscription_plan.modules) if school.subscription_plan else set()
        # Explicit per-school toggles; missing row defaults to enabled.
        toggles = {sm.module: sm.enabled for sm in school.modules}
        return {m for m in plan_modules if toggles.get(m, True)}

    async def get_effective_modules(self, user: User) -> set[str]:
        """Modules actually available to this user after the full cascade."""
        if self.is_super_admin(user):
            return {m.value for m in Module}
        return await self.school_effective_modules(user.school_id)

    async def has_permission(
        self,
        user: User,
        module: Module | str,
        action: PermissionAction | str,
    ) -> bool:
        """True if the user may perform `action` on `module` after the cascade."""
        if self.is_super_admin(user):
            return True

        module_val = module.value if isinstance(module, Module) else module
        action_val = action.value if isinstance(action, PermissionAction) else action

        # Step 1+2: module must survive school toggle ∩ subscription.
        if module_val not in await self.get_effective_modules(user):
            return False

        # Step 3: at least one of the user's roles grants the action on the module.
        attr = f"can_{action_val}"
        for role in user.roles:
            for perm in role.permissions:
                if perm.module == module_val and getattr(perm, attr, False):
                    return True
        return False

    async def get_permission_matrix(self, user: User) -> dict[str, dict[str, bool]]:
        """Per-module action map for the user, bounded by effective modules."""
        effective = await self.get_effective_modules(user)
        super_admin = self.is_super_admin(user)
        matrix: dict[str, dict[str, bool]] = {}

        for module in effective:
            actions = {a.value: super_admin for a in PermissionAction}
            if not super_admin:
                for role in user.roles:
                    for perm in role.permissions:
                        if perm.module != module:
                            continue
                        for a in PermissionAction:
                            if getattr(perm, f"can_{a.value}", False):
                                actions[a.value] = True
            matrix[module] = actions
        return matrix
