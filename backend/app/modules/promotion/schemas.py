"""Promotion & merit-list schemas."""
import uuid

from pydantic import BaseModel, ConfigDict, Field

from app.core.enums import PromotionOutcome


# ------------------------------ preview --------------------------------- #


class PromotionPreviewRow(BaseModel):
    student_id: uuid.UUID
    student_name: str | None = None
    current_section_id: uuid.UUID | None = None
    current_section_label: str | None = None  # "Grade 5 · A"
    total_marks: float | None = None
    percentage: float | None = None
    result_status: str | None = None  # pass / fail / None if no result
    suggested_outcome: PromotionOutcome


# ------------------------------ promote --------------------------------- #


class PromotionItem(BaseModel):
    student_id: uuid.UUID
    to_section_id: uuid.UUID | None = None  # required when outcome=promoted
    outcome: PromotionOutcome = PromotionOutcome.PROMOTED


class PromoteBatch(BaseModel):
    to_session_id: uuid.UUID | None = None
    exam_id: uuid.UUID | None = None
    items: list[PromotionItem] = Field(min_length=1)


class PromotionRecordOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    student_id: uuid.UUID
    from_section_id: uuid.UUID | None = None
    to_section_id: uuid.UUID | None = None
    from_session_id: uuid.UUID | None = None
    to_session_id: uuid.UUID | None = None
    exam_id: uuid.UUID | None = None
    outcome: str
    created_by: uuid.UUID | None = None


# ----------------------------- merit list ------------------------------- #


class MeritListRow(BaseModel):
    rank: int
    student_id: uuid.UUID
    total_marks: float
    max_total: float
    percentage: float
    grade: str
    status: str
