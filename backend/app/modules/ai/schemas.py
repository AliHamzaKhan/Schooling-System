"""AI Features schemas."""
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.core.enums import QuestionType


class GenerateRequest(BaseModel):
    feature: str = Field(min_length=2, max_length=80, description="e.g. lesson_plan, summary, quiz")
    prompt: str = Field(min_length=1, max_length=8000)
    system: str | None = Field(default=None, max_length=2000)


class GenerateResponse(BaseModel):
    id: uuid.UUID
    feature: str
    response: str
    provider: str


class QuizGenerateRequest(BaseModel):
    """Ask the AI to draft quiz questions for a teacher to review."""

    topic: str = Field(min_length=2, max_length=300)
    question_count: int = Field(default=5, ge=1, le=20)
    difficulty: str = Field(default="medium", pattern="^(easy|medium|hard)$")
    question_type: QuestionType = QuestionType.MCQ
    grade_level: str | None = Field(default=None, max_length=50)
    subject_name: str | None = Field(default=None, max_length=100)
    # Extra steer from the teacher, e.g. "focus on word problems".
    instructions: str | None = Field(default=None, max_length=1000)


class GeneratedQuestion(BaseModel):
    prompt: str
    question_type: QuestionType = QuestionType.MCQ
    options: list[str] | None = None
    correct_answer: str | None = None
    marks: float = Field(default=1.0, gt=0)


class QuizGenerateResponse(BaseModel):
    """Drafts only — nothing is persisted until the teacher saves the quiz."""

    questions: list[GeneratedQuestion]
    provider: str


class InteractionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    feature: str
    prompt: str
    response: str
    provider: str
    created_by: uuid.UUID | None = None
    created_at: datetime
