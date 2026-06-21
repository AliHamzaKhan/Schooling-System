"""Permission inspection endpoints."""
from fastapi import APIRouter

from app.core.deps import CurrentUser, DbDep
from app.core.enums import Module
from app.modules.permissions.schemas import EffectivePermissions, ModuleInfo
from app.modules.permissions.service import PermissionService

router = APIRouter(prefix="/permissions", tags=["Permissions"])


@router.get("/me", response_model=EffectivePermissions)
async def my_permissions(current_user: CurrentUser, db: DbDep) -> EffectivePermissions:
    """Return the current user's effective modules and per-action matrix.

    The frontend uses this to hide modules from UI/navigation
    (docs/permissions/07-permission-flow.md).
    """
    service = PermissionService(db)
    return EffectivePermissions(
        school_id=str(current_user.school_id) if current_user.school_id else None,
        is_super_admin=PermissionService.is_super_admin(current_user),
        modules=sorted(await service.get_effective_modules(current_user)),
        matrix=await service.get_permission_matrix(current_user),
    )


@router.get("/modules", response_model=list[ModuleInfo])
async def list_modules() -> list[ModuleInfo]:
    """All platform modules (catalogue, independent of any grant)."""
    return [
        ModuleInfo(code=m.value, name=m.name.replace("_", " ").title())
        for m in Module
    ]
