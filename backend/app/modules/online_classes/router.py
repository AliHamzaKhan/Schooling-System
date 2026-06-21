"""Online Classes endpoints, gated by the ONLINE_CLASSES module."""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import CurrentUser, DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.online_classes import schemas
from app.modules.online_classes.service import OnlineClassService

router = APIRouter(prefix="/schools/{school_id}/online-classes", tags=["Online Classes"])

_view = Depends(require_school_permission(Module.ONLINE_CLASSES, PA.VIEW))
_create = Depends(require_school_permission(Module.ONLINE_CLASSES, PA.CREATE))
_edit = Depends(require_school_permission(Module.ONLINE_CLASSES, PA.EDIT))
_delete = Depends(require_school_permission(Module.ONLINE_CLASSES, PA.DELETE))


@router.post("", response_model=schemas.OnlineClassOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def schedule_class(school_id: uuid.UUID, data: schemas.OnlineClassCreate, db: DbDep, current_user: CurrentUser) -> schemas.OnlineClassOut:
    return await OnlineClassService(db).schedule(school_id, data, current_user.id)


@router.get("", response_model=list[schemas.OnlineClassOut], dependencies=[_view])
async def list_classes(school_id: uuid.UUID, db: DbDep, section_id: uuid.UUID | None = Query(default=None)) -> list[schemas.OnlineClassOut]:
    return await OnlineClassService(db).list_classes(school_id, section_id)


@router.patch("/{class_id}", response_model=schemas.OnlineClassOut, dependencies=[_edit])
async def update_class(school_id: uuid.UUID, class_id: uuid.UUID, data: schemas.OnlineClassUpdate, db: DbDep) -> schemas.OnlineClassOut:
    return await OnlineClassService(db).update(school_id, class_id, data)


@router.delete("/{class_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_class(school_id: uuid.UUID, class_id: uuid.UUID, db: DbDep) -> None:
    await OnlineClassService(db).delete(school_id, class_id)
