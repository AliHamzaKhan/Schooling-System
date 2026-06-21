"""Parent-teacher meeting schemas."""
import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class MeetingCreate(BaseModel):
    title: str = Field(min_length=2, max_length=200)
    teacher_id: uuid.UUID | None = None
    guardian_id: uuid.UUID | None = None
    student_id: uuid.UUID | None = None
    scheduled_at: datetime
    duration_minutes: int | None = Field(default=None, gt=0)
    location: str | None = Field(default=None, max_length=200)


class MeetingUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=2, max_length=200)
    scheduled_at: datetime | None = None
    duration_minutes: int | None = Field(default=None, gt=0)
    location: str | None = Field(default=None, max_length=200)
    status: Literal["scheduled", "completed", "cancelled"] | None = None
    notes: str | None = None


class MeetingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    title: str
    teacher_id: uuid.UUID | None = None
    guardian_id: uuid.UUID | None = None
    student_id: uuid.UUID | None = None
    scheduled_at: datetime
    duration_minutes: int | None = None
    location: str | None = None
    status: str
    notes: str | None = None
