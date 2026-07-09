"""Quiz schemas."""
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.core.enums import QuestionType


# ------------------------------- quizzes -------------------------------- #


class QuizCreate(BaseModel):
    section_id: uuid.UUID
    subject_id: uuid.UUID
    title: str = Field(min_length=2, max_length=200)
    description: str | None = None
    time_limit_minutes: int | None = Field(default=None, gt=0)
    scheduled_at: datetime | None = None
    due_at: datetime | None = None
    # When provided, the quiz is targeted at these specific students instead of
    # the whole section. Each must be enrolled in ``section_id``.
    assignee_ids: list[uuid.UUID] | None = None


class QuizUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=2, max_length=200)
    description: str | None = None
    time_limit_minutes: int | None = Field(default=None, gt=0)
    scheduled_at: datetime | None = None
    due_at: datetime | None = None


class QuizOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    section_id: uuid.UUID
    subject_id: uuid.UUID
    title: str
    description: str | None = None
    time_limit_minutes: int | None = None
    scheduled_at: datetime | None = None
    due_at: datetime | None = None
    status: str
    created_by: uuid.UUID | None = None


# ------------------------------ questions ------------------------------- #


class QuestionCreate(BaseModel):
    prompt: str = Field(min_length=1)
    question_type: QuestionType = QuestionType.MCQ
    options: list[str] | None = None
    correct_answer: str | None = None
    marks: float = Field(default=1.0, gt=0)
    order_index: int = 0


class QuestionUpdate(BaseModel):
    prompt: str | None = Field(default=None, min_length=1)
    question_type: QuestionType | None = None
    options: list[str] | None = None
    correct_answer: str | None = None
    marks: float | None = Field(default=None, gt=0)
    order_index: int | None = None


class QuestionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    quiz_id: uuid.UUID
    prompt: str
    question_type: str
    options: list[str] | None = None
    correct_answer: str | None = None
    marks: float
    order_index: int


class QuizDetailOut(QuizOut):
    questions: list[QuestionOut] = []


# ------------------------------- attempts ------------------------------- #


class AnswerSubmit(BaseModel):
    question_id: uuid.UUID
    response: str | None = None


class AttemptSubmit(BaseModel):
    answers: list[AnswerSubmit] = []


class AnswerOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    question_id: uuid.UUID
    response: str | None = None
    is_correct: bool | None = None
    marks_awarded: float | None = None


class AttemptOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    quiz_id: uuid.UUID
    student_id: uuid.UUID
    started_at: datetime | None = None
    submitted_at: datetime | None = None
    score: float | None = None
    status: str
    graded_by: uuid.UUID | None = None


class AttemptDetailOut(AttemptOut):
    answers: list[AnswerOut] = []


class GradeAnswer(BaseModel):
    answer_id: uuid.UUID
    marks_awarded: float = Field(ge=0)
    is_correct: bool | None = None


class GradeAttempt(BaseModel):
    grades: list[GradeAnswer] = []


# -------------------------------- report -------------------------------- #


class QuizReport(BaseModel):
    quiz_id: uuid.UUID
    title: str
    total_marks: float
    total_attempts: int
    submitted_count: int
    graded_count: int
    average_score: float | None = None
    highest_score: float | None = None
    lowest_score: float | None = None


# ----------------------------- assignment ------------------------------- #


class AssignQuiz(BaseModel):
    """Replace a quiz's per-student targeting. Empty list clears it (section-wide)."""

    student_ids: list[uuid.UUID] = []


class RosterStudent(BaseModel):
    """A student eligible to take a quiz (for the assignee picker)."""

    student_id: uuid.UUID
    name: str


# ----------------------------- performance ------------------------------ #


class QuizPerformanceRow(BaseModel):
    student_id: uuid.UUID
    name: str
    score: float | None = None
    status: str  # not_attempted / in_progress / submitted / graded
    submitted: bool = False


class QuizPerformance(BaseModel):
    quiz_id: uuid.UUID
    title: str
    total_marks: float
    rows: list[QuizPerformanceRow] = []


# ------------------------- AI question generation ------------------------ #


class GeneratedQuestion(BaseModel):
    """An AI-generated MCQ returned to pre-fill the create-quiz form (not yet
    persisted — the teacher reviews and publishes)."""

    prompt: str
    options: list[str]
    correct_answer: str
    marks: float = 1
