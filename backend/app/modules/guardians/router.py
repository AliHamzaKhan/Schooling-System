"""Guardian ↔ student linkage endpoints, scoped under a school.

Linking/unlinking and listing another guardian's children require
GUARDIAN_MANAGEMENT permission (typically the Headmaster). A signed-in guardian
can always read their own children via `GET /me/children`.
"""
import uuid

from fastapi import APIRouter, status

from app.core.deps import CurrentUser, DbDep
from app.modules.guardians import schemas
from app.modules.guardians.service import GuardianService

router = APIRouter(prefix="/schools/{school_id}", tags=["Guardians"])


@router.get("/me/children", response_model=list[schemas.ChildOut])
async def my_children(
    school_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> list[schemas.ChildOut]:
    """List the children linked to the signed-in guardian."""
    return await GuardianService(db).my_children(current_user, school_id)


@router.get(
    "/guardians/{guardian_id}/children", response_model=list[schemas.ChildOut]
)
async def list_children(
    school_id: uuid.UUID,
    guardian_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
) -> list[schemas.ChildOut]:
    return await GuardianService(db).list_children(
        current_user, school_id, guardian_id
    )


@router.post(
    "/guardians/{guardian_id}/children",
    response_model=schemas.ChildOut,
    status_code=status.HTTP_201_CREATED,
)
async def link_child(
    school_id: uuid.UUID,
    guardian_id: uuid.UUID,
    data: schemas.ChildLink,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.ChildOut:
    return await GuardianService(db).link_child(
        current_user, school_id, guardian_id, data
    )


@router.delete(
    "/guardians/{guardian_id}/children/{student_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def unlink_child(
    school_id: uuid.UUID,
    guardian_id: uuid.UUID,
    student_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
) -> None:
    await GuardianService(db).unlink_child(
        current_user, school_id, guardian_id, student_id
    )
