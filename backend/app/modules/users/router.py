"""User Management endpoints, scoped under a school.

Headmaster creation and role provisioning are Super-Admin-only. Other user
operations are available to authorized school users (typically the Headmaster),
gated by the permission cascade in UserService.
"""
import uuid

from fastapi import APIRouter, Query, status

from app.core.deps import CurrentUser, DbDep, SuperAdmin
from app.modules.users import schemas
from app.modules.users.service import UserService

router = APIRouter(prefix="/schools/{school_id}", tags=["User Management"])


# ------------------------------ provisioning ---------------------------- #


@router.post("/headmaster", response_model=schemas.UserDetailOut, status_code=status.HTTP_201_CREATED)
async def create_headmaster(
    school_id: uuid.UUID, data: schemas.HeadmasterCreate, db: DbDep, _: SuperAdmin
) -> schemas.UserDetailOut:
    return await UserService(db).create_headmaster(
        school_id, data.email, data.password, data.full_name, data.phone
    )


@router.post("/provision-roles", response_model=list[schemas.RoleOut])
async def provision_roles(
    school_id: uuid.UUID, db: DbDep, _: SuperAdmin
) -> list[schemas.RoleOut]:
    service = UserService(db)
    await service.provision_school_roles(school_id)
    return await service.list_school_roles(school_id)


@router.get("/roles", response_model=list[schemas.RoleOut])
async def list_roles(
    school_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> list[schemas.RoleOut]:
    service = UserService(db)
    await service._authorize_read(current_user, school_id)  # noqa: SLF001
    return await service.list_school_roles(school_id)


# --------------------------------- users -------------------------------- #


@router.post("/users", response_model=schemas.UserDetailOut, status_code=status.HTTP_201_CREATED)
async def create_user(
    school_id: uuid.UUID, data: schemas.UserCreate, db: DbDep, current_user: CurrentUser
) -> schemas.UserDetailOut:
    return await UserService(db).create_user(
        current_user, school_id, data.email, data.password,
        data.full_name, data.phone, data.role_codes,
        profile_metadata=data.profile_metadata,
    )


@router.get("/users", response_model=list[schemas.UserDetailOut])
async def list_users(
    school_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
    role_code: str | None = Query(default=None),
    limit: int = 50,
    offset: int = 0,
) -> list[schemas.UserDetailOut]:
    return await UserService(db).list_users(
        current_user, school_id, role_code=role_code, limit=limit, offset=offset
    )


@router.get("/users/{user_id}", response_model=schemas.UserDetailOut)
async def get_user(
    school_id: uuid.UUID, user_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.UserDetailOut:
    return await UserService(db).get_user(current_user, school_id, user_id)


@router.patch("/users/{user_id}", response_model=schemas.UserDetailOut)
async def update_user(
    school_id: uuid.UUID,
    user_id: uuid.UUID,
    data: schemas.UserUpdate,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.UserDetailOut:
    return await UserService(db).update_user(
        current_user, school_id, user_id, data.model_dump(exclude_unset=True)
    )


@router.post("/users/{user_id}/deactivate", response_model=schemas.UserDetailOut)
async def deactivate_user(
    school_id: uuid.UUID, user_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.UserDetailOut:
    return await UserService(db).deactivate_user(current_user, school_id, user_id)


@router.post("/users/{user_id}/roles", response_model=schemas.UserDetailOut)
async def assign_roles(
    school_id: uuid.UUID,
    user_id: uuid.UUID,
    data: schemas.RoleAssign,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.UserDetailOut:
    return await UserService(db).assign_roles(
        current_user, school_id, user_id, data.role_codes
    )


@router.delete("/users/{user_id}/roles/{role_id}", response_model=schemas.UserDetailOut)
async def remove_role(
    school_id: uuid.UUID,
    user_id: uuid.UUID,
    role_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.UserDetailOut:
    return await UserService(db).remove_role(current_user, school_id, user_id, role_id)
