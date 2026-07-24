"""Examination endpoints.

Exam setup + marks entry are gated by Module.EXAMS; result publication and
viewing (including report cards) by Module.RESULTS. This mirrors docs/permissions:
teachers enter marks (EXAMS), results are a separately-controlled surface
(RESULTS) visible to guardians/students.
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
from app.modules.examination import schemas
from app.modules.examination.service import ExaminationService

router = APIRouter(prefix="/schools/{school_id}/exams", tags=["Examination"])

_exam_view = Depends(require_school_permission(Module.EXAMS, PA.VIEW))
_exam_create = Depends(require_school_permission(Module.EXAMS, PA.CREATE))
_exam_edit = Depends(require_school_permission(Module.EXAMS, PA.EDIT))
_exam_delete = Depends(require_school_permission(Module.EXAMS, PA.DELETE))
_result_view = Depends(require_school_permission(Module.RESULTS, PA.VIEW))
_result_publish = Depends(require_school_permission(Module.RESULTS, PA.APPROVE))


# -------------------------------- exams --------------------------------- #


@router.post("", response_model=schemas.ExamOut, status_code=status.HTTP_201_CREATED, dependencies=[_exam_create])
async def create_exam(school_id: uuid.UUID, data: schemas.ExamCreate, db: DbDep) -> schemas.ExamOut:
    return await ExaminationService(db).create_exam(school_id, data)


@router.get("", response_model=list[schemas.ExamOut], dependencies=[_exam_view])
async def list_exams(
    school_id: uuid.UUID, db: DbDep, class_id: uuid.UUID | None = Query(default=None)
) -> list[schemas.ExamOut]:
    return await ExaminationService(db).list_exams(school_id, class_id)


@router.patch("/{exam_id}", response_model=schemas.ExamOut, dependencies=[_exam_edit])
async def update_exam(
    school_id: uuid.UUID, exam_id: uuid.UUID, data: schemas.ExamUpdate, db: DbDep
) -> schemas.ExamOut:
    return await ExaminationService(db).update_exam(school_id, exam_id, data)


@router.delete("/{exam_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_exam_delete])
async def delete_exam(school_id: uuid.UUID, exam_id: uuid.UUID, db: DbDep) -> None:
    await ExaminationService(db).delete_exam(school_id, exam_id)


# -------------------------------- papers -------------------------------- #


@router.post("/{exam_id}/papers", response_model=schemas.ExamSubjectOut, status_code=status.HTTP_201_CREATED, dependencies=[_exam_create])
async def add_paper(
    school_id: uuid.UUID, exam_id: uuid.UUID, data: schemas.ExamSubjectCreate, db: DbDep
) -> schemas.ExamSubjectOut:
    return await ExaminationService(db).add_paper(school_id, exam_id, data)


@router.get("/{exam_id}/papers", response_model=list[schemas.ExamSubjectOut], dependencies=[_exam_view])
async def list_papers(school_id: uuid.UUID, exam_id: uuid.UUID, db: DbDep) -> list[schemas.ExamSubjectOut]:
    return await ExaminationService(db).list_papers(school_id, exam_id)


@router.delete("/papers/{paper_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_exam_delete])
async def delete_paper(school_id: uuid.UUID, paper_id: uuid.UUID, db: DbDep) -> None:
    await ExaminationService(db).delete_paper(school_id, paper_id)


# --------------------------------- marks -------------------------------- #


@router.post("/papers/{paper_id}/marks", response_model=list[schemas.MarkOut], dependencies=[_exam_edit])
async def enter_marks(
    school_id: uuid.UUID,
    paper_id: uuid.UUID,
    data: schemas.MarksEntryRequest,
    db: DbDep,
    current_user: CurrentUser,
) -> list[schemas.MarkOut]:
    return await ExaminationService(db).enter_marks(school_id, paper_id, data, current_user.id)


@router.get(
    "/papers/{paper_id}/gradebook",
    response_model=schemas.GradebookOut,
    dependencies=[_exam_view],
)
async def paper_gradebook(
    school_id: uuid.UUID, paper_id: uuid.UUID, db: DbDep
) -> schemas.GradebookOut:
    """Full marks sheet for a paper — every enrolled student, marked or not."""
    return await ExaminationService(db).gradebook(school_id, paper_id)


@router.get("/papers/{paper_id}/marks", response_model=list[schemas.MarkOut], dependencies=[_exam_view])
async def list_marks(school_id: uuid.UUID, paper_id: uuid.UUID, db: DbDep) -> list[schemas.MarkOut]:
    return await ExaminationService(db).list_marks(school_id, paper_id)


# -------------------------------- results ------------------------------- #


@router.post("/{exam_id}/results/publish", response_model=list[schemas.ExamResultOut], dependencies=[_result_publish])
async def publish_results(school_id: uuid.UUID, exam_id: uuid.UUID, db: DbDep) -> list[schemas.ExamResultOut]:
    return await ExaminationService(db).publish_results(school_id, exam_id)


@router.get("/{exam_id}/results", response_model=list[schemas.ExamResultOut], dependencies=[_result_view])
async def list_results(school_id: uuid.UUID, exam_id: uuid.UUID, db: DbDep) -> list[schemas.ExamResultOut]:
    return await ExaminationService(db).list_results(school_id, exam_id)


@router.get(
    "/students/{student_id}/results",
    response_model=list[schemas.StudentExamResult],
    dependencies=[_result_view, Depends(verify_student_access)],
)
async def student_exam_results(
    school_id: uuid.UUID, student_id: uuid.UUID, db: DbDep
) -> list[schemas.StudentExamResult]:
    """Every published exam result for one student (their own, or a guardian's
    child / a teacher). Powers the student academic results screen."""
    return await ExaminationService(db).student_results(school_id, student_id)


@router.get("/{exam_id}/students/{student_id}/report-card", response_model=schemas.ReportCard, dependencies=[_result_view, Depends(verify_student_access)])
async def report_card(
    school_id: uuid.UUID, exam_id: uuid.UUID, student_id: uuid.UUID, db: DbDep
) -> schemas.ReportCard:
    return await ExaminationService(db).report_card(school_id, exam_id, student_id)


# ---------------------------- admit card & seating ---------------------------- #


@router.get(
    "/{exam_id}/students/{student_id}/admit-card",
    response_model=schemas.AdmitCard,
    dependencies=[_exam_view, Depends(verify_student_access)],
)
async def admit_card(
    school_id: uuid.UUID, exam_id: uuid.UUID, student_id: uuid.UUID, db: DbDep
) -> schemas.AdmitCard:
    return await ExaminationService(db).admit_card(school_id, exam_id, student_id)


@router.post(
    "/{exam_id}/seating/generate",
    response_model=list[schemas.SeatOut],
    status_code=status.HTTP_201_CREATED,
    dependencies=[_exam_create],
)
async def generate_seating(
    school_id: uuid.UUID, exam_id: uuid.UUID, data: schemas.SeatingGenerate, db: DbDep
) -> list[schemas.SeatOut]:
    return await ExaminationService(db).generate_seating(school_id, exam_id, data)


@router.get(
    "/{exam_id}/seating",
    response_model=list[schemas.SeatOut],
    dependencies=[_exam_view],
)
async def list_seating(
    school_id: uuid.UUID, exam_id: uuid.UUID, db: DbDep
) -> list[schemas.SeatOut]:
    return await ExaminationService(db).list_seating(school_id, exam_id)
