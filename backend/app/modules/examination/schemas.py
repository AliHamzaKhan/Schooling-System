"""Examination Service schemas."""
import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.core.enums import ExamStatus

# --------------------------------------------------------------------------- #
# Exam
# --------------------------------------------------------------------------- #


class ExamCreate(BaseModel):
    class_id: uuid.UUID
    name: str = Field(min_length=2, max_length=150)
    session_id: uuid.UUID | None = None
    start_date: date | None = None
    end_date: date | None = None


class ExamUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=150)
    status: ExamStatus | None = None
    start_date: date | None = None
    end_date: date | None = None


class ExamOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    class_id: uuid.UUID
    session_id: uuid.UUID | None = None
    name: str
    status: str
    start_date: date | None = None
    end_date: date | None = None


# --------------------------------------------------------------------------- #
# Exam subject (paper)
# --------------------------------------------------------------------------- #


class ExamSubjectCreate(BaseModel):
    subject_id: uuid.UUID
    max_marks: float = Field(gt=0)
    pass_marks: float = Field(ge=0)
    exam_date: date | None = None

    @model_validator(mode="after")
    def _check(self) -> "ExamSubjectCreate":
        if self.pass_marks > self.max_marks:
            raise ValueError("pass_marks cannot exceed max_marks")
        return self


class ExamSubjectOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    exam_id: uuid.UUID
    subject_id: uuid.UUID
    max_marks: float
    pass_marks: float
    exam_date: date | None = None


# --------------------------------------------------------------------------- #
# Marks
# --------------------------------------------------------------------------- #


class MarkEntry(BaseModel):
    student_id: uuid.UUID
    marks_obtained: float | None = Field(default=None, ge=0)
    is_absent: bool = False
    remarks: str | None = Field(default=None, max_length=255)


class MarksEntryRequest(BaseModel):
    entries: list[MarkEntry] = Field(min_length=1)


class MarkOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    exam_subject_id: uuid.UUID
    student_id: uuid.UUID
    marks_obtained: float | None = None
    is_absent: bool
    remarks: str | None = None


# --------------------------------------------------------------------------- #
# Results / report card
# --------------------------------------------------------------------------- #


class ExamResultOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    exam_id: uuid.UUID
    student_id: uuid.UUID
    total_marks: float
    max_total: float
    percentage: float
    grade: str
    status: str
    published: bool
    published_at: datetime | None = None


class ReportCardLine(BaseModel):
    subject_id: uuid.UUID
    max_marks: float
    pass_marks: float
    marks_obtained: float | None = None
    is_absent: bool
    passed: bool


class ReportCard(BaseModel):
    exam_id: uuid.UUID
    student_id: uuid.UUID
    lines: list[ReportCardLine]
    total_marks: float
    max_total: float
    percentage: float
    grade: str
    status: str
    published: bool
