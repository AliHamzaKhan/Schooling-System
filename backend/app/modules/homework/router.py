"""Homework & Assignment endpoints, gated by the HOMEWORK module.

Assignment management and grading require create/edit; viewing and student
self-submission require view (the student-self check is enforced in the service).
"""
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.deps import (
    CurrentUser,
    DbDep,
    require_school_permission,
    verify_student_access,
)
from app.core.enums import Module, PermissionAction as PA
from app.modules.homework import schemas
from app.modules.homework.service import HomeworkService
from app.models.homework import Assignment, Submission
from app.modules.uploads.access import has_personal_student_access, require_assignment_staff

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


@router.get(
    "/assignments/{assignment_id}",
    response_model=schemas.AssignmentListOut,
    dependencies=[_view],
)
async def get_assignment(
    school_id: uuid.UUID,
    assignment_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.AssignmentListOut:
    """One assignment with subject name and the caller's own submission."""
    return await HomeworkService(db).get_assignment_detail(
        school_id, assignment_id, current_user_id=current_user.id
    )


@router.patch("/assignments/{assignment_id}", response_model=schemas.AssignmentOut, dependencies=[_edit])
async def update_assignment(
    school_id: uuid.UUID, assignment_id: uuid.UUID, data: schemas.AssignmentUpdate, db: DbDep,
    current_user: CurrentUser,
) -> schemas.AssignmentOut:
    service = HomeworkService(db)
    assignment = await service._get_scoped(Assignment, school_id, assignment_id, "Assignment")
    await require_assignment_staff(school_id, assignment, current_user, db)
    return await service.update_assignment(school_id, assignment_id, data)


@router.delete("/assignments/{assignment_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_assignment(school_id: uuid.UUID, assignment_id: uuid.UUID, db: DbDep,
                            current_user: CurrentUser) -> None:
    service = HomeworkService(db)
    assignment = await service._get_scoped(Assignment, school_id, assignment_id, "Assignment")
    await require_assignment_staff(school_id, assignment, current_user, db)
    await service.delete_assignment(school_id, assignment_id)


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
async def list_submissions(school_id: uuid.UUID, assignment_id: uuid.UUID, db: DbDep,
                           current_user: CurrentUser) -> list[schemas.SubmissionOut]:
    """A teacher viewing an assignment's submissions marks each as seen (the
    student's read receipt)."""
    service = HomeworkService(db)
    assignment = await service._get_scoped(Assignment, school_id, assignment_id, "Assignment")
    await require_assignment_staff(school_id, assignment, current_user, db)
    return await service.list_submissions(school_id, assignment_id, mark_seen=True)


@router.patch("/submissions/{submission_id}/grade", response_model=schemas.SubmissionOut, dependencies=[_edit])
async def grade_submission(
    school_id: uuid.UUID,
    submission_id: uuid.UUID,
    data: schemas.GradeSubmission,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.SubmissionOut:
    service = HomeworkService(db)
    submission = await service._get_scoped(Submission, school_id, submission_id, "Submission")
    assignment = await service._get_scoped(Assignment, school_id, submission.assignment_id, "Assignment")
    await require_assignment_staff(school_id, assignment, current_user, db)
    return await service.grade(school_id, submission_id, data, current_user.id)


@router.patch("/submissions/{submission_id}/review", response_model=schemas.SubmissionOut, dependencies=[_edit])
async def review_submission(
    school_id: uuid.UUID,
    submission_id: uuid.UUID,
    data: schemas.ReviewSubmission,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.SubmissionOut:
    """Approve or reject a submission (moderation, separate from grading)."""
    service = HomeworkService(db)
    submission = await service._get_scoped(Submission, school_id, submission_id, "Submission")
    assignment = await service._get_scoped(Assignment, school_id, submission.assignment_id, "Assignment")
    await require_assignment_staff(school_id, assignment, current_user, db)
    return await service.review(school_id, submission_id, data, current_user.id)


@router.get("/students/{student_id}/submissions", response_model=list[schemas.SubmissionOut], dependencies=[_view, Depends(verify_student_access)])
async def student_submissions(
    school_id: uuid.UUID, student_id: uuid.UUID, db: DbDep, current_user: CurrentUser,
) -> list[schemas.SubmissionOut]:
    service = HomeworkService(db)
    submissions = await service.student_submissions(school_id, student_id)
    if await has_personal_student_access(school_id, student_id, current_user, db):
        return submissions
    visible = []
    for submission in submissions:
        assignment = await service._get_scoped(Assignment, school_id, submission.assignment_id, "Assignment")
        try:
            await require_assignment_staff(school_id, assignment, current_user, db)
        except HTTPException as exc:
            if exc.status_code != 403:
                raise
            continue
        visible.append(submission)
    return visible
