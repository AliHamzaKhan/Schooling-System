"""Academic calendar endpoints, gated by the TIMETABLE module.

Holidays, events, exam markers and academic milestones live here; the
exam-schedule feed is derived read-only from the Examination module.
"""
import uuid
from datetime import date

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import CurrentUser, DbDep, require_school_permission
from app.core.enums import CalendarEventType, Module, PermissionAction as PA
from app.modules.calendar import schemas
from app.modules.calendar.service import CalendarService

router = APIRouter(prefix="/schools/{school_id}/calendar", tags=["Calendar"])

_view = Depends(require_school_permission(Module.TIMETABLE, PA.VIEW))
_create = Depends(require_school_permission(Module.TIMETABLE, PA.CREATE))
_edit = Depends(require_school_permission(Module.TIMETABLE, PA.EDIT))
_delete = Depends(require_school_permission(Module.TIMETABLE, PA.DELETE))


@router.post("/events", response_model=schemas.EventOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_event(
    school_id: uuid.UUID, data: schemas.EventCreate, db: DbDep, current_user: CurrentUser
) -> schemas.EventOut:
    return await CalendarService(db).create(school_id, data, current_user.id)


@router.get("/events", response_model=list[schemas.EventOut], dependencies=[_view])
async def list_events(
    school_id: uuid.UUID,
    db: DbDep,
    event_type: CalendarEventType | None = Query(default=None),
    session_id: uuid.UUID | None = Query(default=None),
    from_date: date | None = Query(default=None),
    to_date: date | None = Query(default=None),
) -> list[schemas.EventOut]:
    return await CalendarService(db).list_events(
        school_id, event_type, session_id, from_date, to_date
    )


@router.patch("/events/{event_id}", response_model=schemas.EventOut, dependencies=[_edit])
async def update_event(
    school_id: uuid.UUID, event_id: uuid.UUID, data: schemas.EventUpdate, db: DbDep
) -> schemas.EventOut:
    return await CalendarService(db).update(school_id, event_id, data)


@router.delete("/events/{event_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_event(school_id: uuid.UUID, event_id: uuid.UUID, db: DbDep) -> None:
    await CalendarService(db).delete(school_id, event_id)


@router.get("/exam-schedule", response_model=list[schemas.EventOut], dependencies=[_view])
async def exam_schedule(
    school_id: uuid.UUID, db: DbDep, session_id: uuid.UUID | None = Query(default=None)
) -> list[schemas.EventOut]:
    return await CalendarService(db).exam_schedule(school_id, session_id)
