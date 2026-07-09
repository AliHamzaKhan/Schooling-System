"""Homework & Assignment endpoints, gated by the HOMEWORK module.

Assignment management and grading require create/edit; viewing and student
self-submission require view (the student-self check is enforced in the service).
"""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import (
    CurrentUser,
    DbDep,
    require_school_permission,
    verify_student_access,
)
from app.core.enums import Module, PermissionAction as PA
from app.modules.homework import schemas
from app.modules.homework.service import HomeworkService

router = APIRouter(prefix="/schools/{school_id}/homework", tags=["Homework"])

_view = Depends(require_school_permission(Module.HOMEWORK, PA.VIEW))
_create = Depends(require_school_permission(Module.HOMEWORK, PA.CREATE))
_edit = Depends(require_school_permission(Module.HOMEWORK, PA.EDIT))
_delete = Depends(require_school_permission(Module.HOMEWORK, PA.DELETE))


# ---------------------------- assignments ------------------------------- #


@router.post("/assignments", response_model=schemas.AssignmentOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_assignment(
    school_id: uuid.UUID, data: schemas.AssignmentCreate, db: DbDep, current_user: CurrentUser
) -> schemas.AssignmentOut:
    return await HomeworkService(db).create_assignment(school_id, data, current_user.id)


@router.get("/assignments", response_model=list[schemas.AssignmentListOut], dependencies=[_view])
async def list_assignments(
    school_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
    section_id: uuid.UUID | None = Query(default=None),
) -> list[schemas.AssignmentListOut]:
    return await HomeworkService(db).list_assignments(
        school_id, section_id, current_user_id=current_user.id
    )


@router.patch("/assignments/{assignment_id}", response_model=schemas.AssignmentOut, dependencies=[_edit])
async def update_assignment(
    school_id: uuid.UUID, assignment_id: uuid.UUID, data: schemas.AssignmentUpdate, db: DbDep
) -> schemas.AssignmentOut:
    return await HomeworkService(db).update_assignment(school_id, assignment_id, data)


@router.delete("/assignments/{assignment_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_assignment(school_id: uuid.UUID, assignment_id: uuid.UUID, db: DbDep) -> None:
    await HomeworkService(db).delete_assignment(school_id, assignment_id)


# ---------------------------- submissions ------------------------------- #


@router.post("/assignments/{assignment_id}/submissions", response_model=schemas.SubmissionOut, status_code=status.HTTP_201_CREATED, dependencies=[_view])
async def submit_assignment(
    school_id: uuid.UUID,
    assignment_id: uuid.UUID,
    data: schemas.SubmissionCreate,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.SubmissionOut:
    """Student self-submission. The acting user must be a student enrolled in the section."""
    return await HomeworkService(db).submit(school_id, assignment_id, current_user.id, data)


@router.get("/assignments/{assignment_id}/submissions", response_model=list[schemas.SubmissionOut], dependencies=[_view])
async def list_submissions(school_id: uuid.UUID, assignment_id: uuid.UUID, db: DbDep) -> list[schemas.SubmissionOut]:
    return await HomeworkService(db).list_submissions(school_id, assignment_id)


@router.patch("/submissions/{submission_id}/grade", response_model=schemas.SubmissionOut, dependencies=[_edit])
async def grade_submission(
    school_id: uuid.UUID,
    submission_id: uuid.UUID,
    data: schemas.GradeSubmission,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.SubmissionOut:
    return await HomeworkService(db).grade(school_id, submission_id, data, current_user.id)


@router.patch("/submissions/{submission_id}/review", response_model=schemas.SubmissionOut, dependencies=[_edit])
async def review_submission(
    school_id: uuid.UUID,
    submission_id: uuid.UUID,
    data: schemas.ReviewSubmission,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.SubmissionOut:
    """Approve or reject a submission (moderation, separate from grading)."""
    return await HomeworkService(db).review(school_id, submission_id, data, current_user.id)


@router.get("/students/{student_id}/submissions", response_model=list[schemas.SubmissionOut], dependencies=[_view, Depends(verify_student_access)])
async def student_submissions(
    school_id: uuid.UUID, student_id: uuid.UUID, db: DbDep
) -> list[schemas.SubmissionOut]:
    return await HomeworkService(db).student_submissions(school_id, student_id)
