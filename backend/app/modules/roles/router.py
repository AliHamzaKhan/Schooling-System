"""Role & Permission Management endpoints (docs/permissions/03, 06).

Accessible to the Super Admin (any school) and a school's Headmaster (own
school), with grant bounding enforced in RoleService.
"""
import uuid

from fastapi import APIRouter, status

from app.core.deps import CurrentUser, DbDep
from app.modules.roles import schemas
from app.modules.roles.service import RoleService

router = APIRouter(prefix="/schools/{school_id}/roles", tags=["Role Management"])


@router.post("", response_model=schemas.RoleDetailOut, status_code=status.HTTP_201_CREATED)
async def create_role(
    school_id: uuid.UUID, data: schemas.RoleCreate, db: DbDep, current_user: CurrentUser
) -> schemas.RoleDetailOut:
    role = await RoleService(db).create_role(current_user, school_id, data)
    return RoleService.to_out(role)


@router.get("/{role_id}", response_model=schemas.RoleDetailOut)
async def get_role(
    school_id: uuid.UUID, role_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.RoleDetailOut:
    role = await RoleService(db).get_role(current_user, school_id, role_id)
    return RoleService.to_out(role)


@router.patch("/{role_id}", response_model=schemas.RoleDetailOut)
async def rename_role(
    school_id: uuid.UUID,
    role_id: uuid.UUID,
    data: schemas.RoleRename,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.RoleDetailOut:
    role = await RoleService(db).rename_role(current_user, school_id, role_id, data.name)
    return RoleService.to_out(role)


@router.put("/{role_id}/permissions", response_model=schemas.RoleDetailOut)
async def set_permissions(
    school_id: uuid.UUID,
    role_id: uuid.UUID,
    data: schemas.RolePermissionsUpdate,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.RoleDetailOut:
    role = await RoleService(db).set_permissions(
        current_user, school_id, role_id, data.permissions
    )
    return RoleService.to_out(role)


@router.delete("/{role_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_role(
    school_id: uuid.UUID, role_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> None:
    await RoleService(db).delete_role(current_user, school_id, role_id)
