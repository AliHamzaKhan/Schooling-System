"""Homework & Assignment schemas."""
import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field


class AssignmentCreate(BaseModel):
    section_id: uuid.UUID
    subject_id: uuid.UUID
    title: str = Field(min_length=2, max_length=200)
    description: str | None = None
    due_date: date
    assigned_on: date | None = None
    max_marks: float | None = Field(default=None, gt=0)


class AssignmentUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=2, max_length=200)
    description: str | None = None
    due_date: date | None = None
    max_marks: float | None = Field(default=None, gt=0)


class AssignmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    section_id: uuid.UUID
    subject_id: uuid.UUID
    title: str
    description: str | None = None
    assigned_on: date
    due_date: date
    max_marks: float | None = None
    assigned_by: uuid.UUID | None = None


class SubmissionBrief(BaseModel):
    """Compact submission summary embedded in the assignment list."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    status: str
    submitted_on: date
    attachment_url: str | None = None
    marks_obtained: float | None = None
    feedback: str | None = None
    seen_at: datetime | None = None


class AssignmentListOut(AssignmentOut):
    """Assignment enriched for list views: resolved subject name, total
    submission count, and the requesting user's own submission (if any)."""

    subject_name: str | None = None
    submission_count: int = 0
    my_submission: SubmissionBrief | None = None


class SubmissionCreate(BaseModel):
    content: str | None = None
    attachment_url: str | None = Field(default=None, max_length=500)
    submitted_on: date | None = None


class GradeSubmission(BaseModel):
    marks_obtained: float = Field(ge=0)
    feedback: str | None = None


class ReviewSubmission(BaseModel):
    approved: bool
    feedback: str | None = None


class SubmissionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    assignment_id: uuid.UUID
    student_id: uuid.UUID
    student_name: str | None = None
    submitted_on: date
    content: str | None = None
    attachment_url: str | None = None
    status: str
    marks_obtained: float | None = None
    feedback: str | None = None
    graded_by: uuid.UUID | None = None
    seen_at: datetime | None = None
