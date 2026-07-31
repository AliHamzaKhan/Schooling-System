"""Leave management schemas."""
import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field, model_validator


class LeaveSubmit(BaseModel):
    leave_type: str | None = Field(default=None, max_length=50)
    start_date: date
    end_date: date
    reason: str | None = None
    # The student the leave concerns. Required when a guardian applies for a
    # child; ignored for a student's own request (defaults to themselves).
    student_id: uuid.UUID | None = None

    @model_validator(mode="after")
    def _check(self) -> "LeaveSubmit":
        if self.end_date < self.start_date:
            raise ValueError("end_date cannot be before start_date")
        return self


class LeaveReview(BaseModel):
    note: str | None = Field(default=None, max_length=255)


class LeaveOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    requester_id: uuid.UUID
    student_id: uuid.UUID | None = None
    # Composed for review lists (subject student + who submitted); may be absent.
    student_name: str | None = None
    requester_name: str | None = None
    # The subject student's current class + section, for the review card.
    student_class: str | None = None
    student_section: str | None = None
    leave_type: str | None = None
    start_date: date
    end_date: date
    reason: str | None = None
    status: str
    reviewed_by: uuid.UUID | None = None
    review_note: str | None = None
    reviewed_at: datetime | None = None
