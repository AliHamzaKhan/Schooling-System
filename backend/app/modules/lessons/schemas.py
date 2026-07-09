"""Lesson planning & teaching-progress schemas."""
import uuid
from datetime import date

from pydantic import BaseModel, ConfigDict, Field

from app.core.enums import LessonStatus


class LessonCreate(BaseModel):
    section_id: uuid.UUID
    subject_id: uuid.UUID
    title: str = Field(min_length=2, max_length=200)
    description: str | None = None
    planned_date: date | None = None
    status: LessonStatus = LessonStatus.PLANNED
    progress_percent: int = Field(default=0, ge=0, le=100)


class LessonUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=2, max_length=200)
    description: str | None = None
    planned_date: date | None = None
    status: LessonStatus | None = None
    progress_percent: int | None = Field(default=None, ge=0, le=100)


class LessonOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    section_id: uuid.UUID
    subject_id: uuid.UUID
    title: str
    description: str | None = None
    planned_date: date | None = None
    status: str
    progress_percent: int
    teacher_id: uuid.UUID | None = None


class TeachingProgress(BaseModel):
    section_id: uuid.UUID
    subject_id: uuid.UUID
    total_lessons: int
    completed_lessons: int
    average_progress: float
