"""Leave Management endpoints.

Submitting and viewing one's own requests only requires school membership.
Reviewing (approve/reject) and viewing all requests require the
LEAVE_MANAGEMENT module permission (typically the Headmaster).
"""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import CurrentUser, DbDep, require_school_member, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.leave import schemas
from app.modules.leave.service import LeaveService

router = APIRouter(prefix="/schools/{school_id}/leave", tags=["Leave Management"])

_member = Depends(require_school_member)
_view = Depends(require_school_permission(Module.LEAVE_MANAGEMENT, PA.VIEW))
_approve = Depends(require_school_permission(Module.LEAVE_MANAGEMENT, PA.APPROVE))


@router.post("/requests", response_model=schemas.LeaveOut, status_code=status.HTTP_201_CREATED, dependencies=[_member])
async def submit_leave(school_id: uuid.UUID, data: schemas.LeaveSubmit, db: DbDep, current_user: CurrentUser) -> schemas.LeaveOut:
    return await LeaveService(db).submit(school_id, current_user, data)


@router.get("/requests/mine", response_model=list[schemas.LeaveOut], dependencies=[_member])
async def my_leave(school_id: uuid.UUID, db: DbDep, current_user: CurrentUser) -> list[schemas.LeaveOut]:
    return await LeaveService(db).list_own(school_id, current_user.id)


@router.get("/requests/for-review", response_model=list[schemas.LeaveOut], dependencies=[_member])
async def review_queue(
    school_id: uuid.UUID, db: DbDep, current_user: CurrentUser, status: str | None = Query(default=None)
) -> list[schemas.LeaveOut]:
    """Leaves the caller may review — all for a headmaster/approver, or their own
    sections' students for a class teacher."""
    return await LeaveService(db).list_for_review(school_id, current_user, status)


@router.get("/requests", response_model=list[schemas.LeaveOut], dependencies=[_view])
async def list_leave(school_id: uuid.UUID, db: DbDep, status: str | None = Query(default=None)) -> list[schemas.LeaveOut]:
    return await LeaveService(db).list_all(school_id, status)


@router.post("/requests/{leave_id}/approve", response_model=schemas.LeaveOut, dependencies=[_member])
async def approve_leave(school_id: uuid.UUID, leave_id: uuid.UUID, data: schemas.LeaveReview, db: DbDep, current_user: CurrentUser) -> schemas.LeaveOut:
    return await LeaveService(db).review(school_id, leave_id, True, current_user, data.note)


@router.post("/requests/{leave_id}/reject", response_model=schemas.LeaveOut, dependencies=[_member])
async def reject_leave(school_id: uuid.UUID, leave_id: uuid.UUID, data: schemas.LeaveReview, db: DbDep, current_user: CurrentUser) -> schemas.LeaveOut:
    return await LeaveService(db).review(school_id, leave_id, False, current_user, data.note)
