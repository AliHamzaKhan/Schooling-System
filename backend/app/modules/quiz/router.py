"""Quiz endpoints, gated by the HOMEWORK module.

Quiz authoring and grading require create/edit; students attempt quizzes with
the view permission (enrollment is enforced in the service).
"""
import uuid
from io import BytesIO

from fastapi import APIRouter, Depends, File, Form, Query, UploadFile, status
from pypdf import PdfReader

from app.core.deps import (
    CurrentUser,
    DbDep,
    require_school_permission,
    verify_student_access,
)
from app.core.enums import Module, PermissionAction as PA, QuizStatus
from app.core.exceptions import bad_request
from app.modules.permissions.service import PermissionService
from app.modules.quiz import schemas
from app.modules.quiz.service import QuizService

router = APIRouter(prefix="/schools/{school_id}/quizzes", tags=["Quizzes"])


def _extract_pdf_text(data: bytes) -> str:
    reader = PdfReader(BytesIO(data))
    return "\n".join((page.extract_text() or "") for page in reader.pages)

_view = Depends(require_school_permission(Module.HOMEWORK, PA.VIEW))
_create = Depends(require_school_permission(Module.HOMEWORK, PA.CREATE))
_edit = Depends(require_school_permission(Module.HOMEWORK, PA.EDIT))
_delete = Depends(require_school_permission(Module.HOMEWORK, PA.DELETE))


# ------------------------------- quizzes -------------------------------- #


@router.post("", response_model=schemas.QuizOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_quiz(
    school_id: uuid.UUID, data: schemas.QuizCreate, db: DbDep, current_user: CurrentUser
) -> schemas.QuizOut:
    return await QuizService(db).create_quiz(school_id, data, current_user.id)


@router.post(
    "/generate-questions",
    response_model=list[schemas.GeneratedQuestion],
    dependencies=[_create],
)
async def generate_questions_from_pdf(
    school_id: uuid.UUID,
    db: DbDep,
    file: UploadFile = File(...),
    num_questions: int = Form(default=5),
) -> list[schemas.GeneratedQuestion]:
    """Extract text from an uploaded PDF and generate draft MCQs with AI. The
    questions are returned (not persisted) to pre-fill the create-quiz form so
    the teacher can review, edit, and publish them."""
    data = await file.read()
    if not data:
        raise bad_request("Uploaded file is empty")
    try:
        text = _extract_pdf_text(data)
    except Exception:  # noqa: BLE001 — any parse failure means an unusable PDF
        raise bad_request("Couldn't read this file as a PDF.")
    return await QuizService(db).generate_questions(text, num_questions)


@router.get("", response_model=list[schemas.QuizOut], dependencies=[_view])
async def list_quizzes(
    school_id: uuid.UUID, db: DbDep, current_user: CurrentUser,
    section_id: uuid.UUID | None = Query(default=None)
) -> list[schemas.QuizOut]:
    return await QuizService(db).list_quizzes(school_id, section_id, current_user.id)


@router.get("/assigned", response_model=list[schemas.QuizOut], dependencies=[_view])
async def list_assigned_quizzes(
    school_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> list[schemas.QuizOut]:
    """Published quizzes visible to the acting student (assigned to them, or
    section-wide for the sections they're enrolled in)."""
    return await QuizService(db).list_for_student(school_id, current_user.id)


@router.get(
    "/sections/{section_id}/students",
    response_model=list[schemas.RosterStudent],
    dependencies=[_view],
)
async def section_roster(
    school_id: uuid.UUID, section_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> list[schemas.RosterStudent]:
    """Enrolled students of a section, for the assignee picker."""
    from app.modules.academic.access import AcademicAccess

    await AcademicAccess(db, school_id, current_user).section(section_id)
    return await QuizService(db).list_section_students(school_id, section_id)


@router.get("/{quiz_id}", response_model=schemas.QuizDetailOut, dependencies=[_view])
async def get_quiz(
    school_id: uuid.UUID, quiz_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.QuizDetailOut:
    quiz = await QuizService(db).get_quiz(school_id, quiz_id, current_user.id)
    detail = schemas.QuizDetailOut.model_validate(quiz)
    # Students (view-only) must not receive the answer key. Teachers/graders
    # (HOMEWORK edit) keep it so they can review questions.
    can_edit = await PermissionService(db).has_permission(
        current_user, Module.HOMEWORK, PA.EDIT
    )
    if not can_edit:
        for question in detail.questions:
            question.correct_answer = None
    return detail


@router.post("/{quiz_id}/assign", response_model=schemas.QuizOut, dependencies=[_edit])
async def assign_quiz(
    school_id: uuid.UUID, quiz_id: uuid.UUID, data: schemas.AssignQuiz, db: DbDep
) -> schemas.QuizOut:
    """Target a quiz at specific students (empty list → section-wide)."""
    return await QuizService(db).assign(school_id, quiz_id, data)


@router.get("/{quiz_id}/performance", response_model=schemas.QuizPerformance, dependencies=[_view])
async def quiz_performance(
    school_id: uuid.UUID, quiz_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.QuizPerformance:
    """Per-student scores for a quiz (roster joined with attempts)."""
    return await QuizService(db).performance(school_id, quiz_id, current_user.id)


@router.patch("/{quiz_id}", response_model=schemas.QuizOut, dependencies=[_edit])
async def update_quiz(
    school_id: uuid.UUID, quiz_id: uuid.UUID, data: schemas.QuizUpdate, db: DbDep
) -> schemas.QuizOut:
    return await QuizService(db).update_quiz(school_id, quiz_id, data)


@router.delete("/{quiz_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_quiz(school_id: uuid.UUID, quiz_id: uuid.UUID, db: DbDep) -> None:
    await QuizService(db).delete_quiz(school_id, quiz_id)


@router.post("/{quiz_id}/publish", response_model=schemas.QuizOut, dependencies=[_edit])
async def publish_quiz(school_id: uuid.UUID, quiz_id: uuid.UUID, db: DbDep) -> schemas.QuizOut:
    return await QuizService(db).set_status(school_id, quiz_id, QuizStatus.PUBLISHED)


@router.post("/{quiz_id}/close", response_model=schemas.QuizOut, dependencies=[_edit])
async def close_quiz(school_id: uuid.UUID, quiz_id: uuid.UUID, db: DbDep) -> schemas.QuizOut:
    return await QuizService(db).set_status(school_id, quiz_id, QuizStatus.CLOSED)


# ------------------------------ questions ------------------------------- #


@router.post("/{quiz_id}/questions", response_model=schemas.QuestionOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def add_question(
    school_id: uuid.UUID, quiz_id: uuid.UUID, data: schemas.QuestionCreate, db: DbDep
) -> schemas.QuestionOut:
    return await QuizService(db).add_question(school_id, quiz_id, data)


@router.patch("/questions/{question_id}", response_model=schemas.QuestionOut, dependencies=[_edit])
async def update_question(
    school_id: uuid.UUID, question_id: uuid.UUID, data: schemas.QuestionUpdate, db: DbDep
) -> schemas.QuestionOut:
    return await QuizService(db).update_question(school_id, question_id, data)


@router.delete("/questions/{question_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_question(school_id: uuid.UUID, question_id: uuid.UUID, db: DbDep) -> None:
    await QuizService(db).delete_question(school_id, question_id)


# ------------------------------- attempts ------------------------------- #


@router.post("/{quiz_id}/attempts/start", response_model=schemas.AttemptOut, dependencies=[_view])
async def start_attempt(
    school_id: uuid.UUID, quiz_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.AttemptOut:
    """Student self-start. The acting user must be enrolled in the quiz's section."""
    return await QuizService(db).start_attempt(school_id, quiz_id, current_user.id)


@router.post("/{quiz_id}/attempts/submit", response_model=schemas.AttemptDetailOut, dependencies=[_view])
async def submit_attempt(
    school_id: uuid.UUID,
    quiz_id: uuid.UUID,
    data: schemas.AttemptSubmit,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.AttemptDetailOut:
    """Student self-submission; objective questions are auto-graded."""
    return await QuizService(db).submit_attempt(school_id, quiz_id, current_user.id, data)


@router.get("/{quiz_id}/attempts", response_model=list[schemas.AttemptOut], dependencies=[_view])
async def list_attempts(
    school_id: uuid.UUID, quiz_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> list[schemas.AttemptOut]:
    return await QuizService(db).list_attempts(school_id, quiz_id, current_user.id)


@router.get("/attempts/{attempt_id}", response_model=schemas.AttemptDetailOut, dependencies=[_view])
async def get_attempt(
    school_id: uuid.UUID, attempt_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.AttemptDetailOut:
    return await QuizService(db).get_attempt(school_id, attempt_id, current_user.id)


@router.patch("/attempts/{attempt_id}/grade", response_model=schemas.AttemptDetailOut, dependencies=[_edit])
async def grade_attempt(
    school_id: uuid.UUID,
    attempt_id: uuid.UUID,
    data: schemas.GradeAttempt,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.AttemptDetailOut:
    return await QuizService(db).grade_attempt(school_id, attempt_id, data, current_user.id)


@router.get("/students/{student_id}/attempts", response_model=list[schemas.AttemptOut], dependencies=[_view, Depends(verify_student_access)])
async def student_attempts(
    school_id: uuid.UUID, student_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> list[schemas.AttemptOut]:
    return await QuizService(db).student_attempts(school_id, student_id, current_user.id)


# -------------------------------- report -------------------------------- #


@router.get("/{quiz_id}/report", response_model=schemas.QuizReport, dependencies=[_view])
async def quiz_report(school_id: uuid.UUID, quiz_id: uuid.UUID, db: DbDep, current_user: CurrentUser) -> schemas.QuizReport:
    return await QuizService(db).report(school_id, quiz_id, current_user.id)
