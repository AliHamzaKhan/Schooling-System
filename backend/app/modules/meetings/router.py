"""Parent-Teacher Meeting endpoints, gated by the MEETINGS module."""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.meetings import schemas
from app.modules.meetings.service import MeetingService

router = APIRouter(prefix="/schools/{school_id}/meetings", tags=["Parent-Teacher Meetings"])

_view = Depends(require_school_permission(Module.MEETINGS, PA.VIEW))
_create = Depends(require_school_permission(Module.MEETINGS, PA.CREATE))
_edit = Depends(require_school_permission(Module.MEETINGS, PA.EDIT))
_delete = Depends(require_school_permission(Module.MEETINGS, PA.DELETE))


@router.post("", response_model=schemas.MeetingOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def schedule_meeting(school_id: uuid.UUID, data: schemas.MeetingCreate, db: DbDep) -> schemas.MeetingOut:
    return await MeetingService(db).schedule(school_id, data)


@router.get("", response_model=list[schemas.MeetingOut], dependencies=[_view])
async def list_meetings(school_id: uuid.UUID, db: DbDep, status: str | None = Query(default=None)) -> list[schemas.MeetingOut]:
    return await MeetingService(db).list_meetings(school_id, status)


@router.patch("/{meeting_id}", response_model=schemas.MeetingOut, dependencies=[_edit])
async def update_meeting(school_id: uuid.UUID, meeting_id: uuid.UUID, data: schemas.MeetingUpdate, db: DbDep) -> schemas.MeetingOut:
    return await MeetingService(db).update(school_id, meeting_id, data)


@router.delete("/{meeting_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_meeting(school_id: uuid.UUID, meeting_id: uuid.UUID, db: DbDep) -> None:
    await MeetingService(db).delete(school_id, meeting_id)
