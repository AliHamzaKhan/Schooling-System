"""Promotion & merit-list endpoints.

Promotion (moving students between classes/sections) is gated by the
STUDENT_MANAGEMENT module; the merit list is derived from published exam
results and gated by the EXAMS module.
"""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import CurrentUser, DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.core.family_scope import require_staff_reader
from app.modules.promotion import schemas
from app.modules.promotion.service import PromotionService

router = APIRouter(prefix="/schools/{school_id}", tags=["Promotion"])

_view = Depends(require_school_permission(Module.STUDENT_MANAGEMENT, PA.VIEW))
_create = Depends(require_school_permission(Module.STUDENT_MANAGEMENT, PA.CREATE))
_exam_view = Depends(require_school_permission(Module.EXAMS, PA.VIEW))


@router.get(
    "/promotions/preview",
    response_model=list[schemas.PromotionPreviewRow],
    dependencies=[_view, _exam_view],
)
async def preview_promotion(
    school_id: uuid.UUID, db: DbDep, exam_id: uuid.UUID = Query(...)
) -> list[schemas.PromotionPreviewRow]:
    """Suggest promote/retain per student based on a published exam's pass/fail."""
    return await PromotionService(db).preview_from_exam(school_id, exam_id)


@router.post(
    "/promotions",
    response_model=list[schemas.PromotionRecordOut],
    status_code=status.HTTP_201_CREATED,
    dependencies=[_create],
)
async def promote_students(
    school_id: uuid.UUID, data: schemas.PromoteBatch, db: DbDep, current_user: CurrentUser
) -> list[schemas.PromotionRecordOut]:
    return await PromotionService(db).promote_batch(school_id, data, current_user.id)


@router.get(
    "/promotions",
    response_model=list[schemas.PromotionRecordOut],
    dependencies=[_view],
)
async def list_promotions(
    school_id: uuid.UUID,
    db: DbDep,
    student_id: uuid.UUID | None = Query(default=None),
    to_session_id: uuid.UUID | None = Query(default=None),
) -> list[schemas.PromotionRecordOut]:
    return await PromotionService(db).list_records(school_id, student_id, to_session_id)


@router.get(
    "/exams/{exam_id}/merit-list",
    response_model=list[schemas.MeritListRow],
    # A ranked list of every student's marks is a staff view; publishing a
    # merit list to families would be an explicit school-policy decision.
    dependencies=[_exam_view, Depends(require_staff_reader)],
)
async def merit_list(
    school_id: uuid.UUID,
    exam_id: uuid.UUID,
    db: DbDep,
    limit: int | None = Query(default=None, gt=0),
) -> list[schemas.MeritListRow]:
    return await PromotionService(db).merit_list(school_id, exam_id, limit)
