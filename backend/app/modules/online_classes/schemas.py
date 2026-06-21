"""Online Classes schemas."""
import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class OnlineClassCreate(BaseModel):
    section_id: uuid.UUID
    subject_id: uuid.UUID | None = None
    title: str = Field(min_length=2, max_length=200)
    meeting_url: str = Field(min_length=4, max_length=500)
    scheduled_start: datetime
    scheduled_end: datetime

    @model_validator(mode="after")
    def _check(self) -> "OnlineClassCreate":
        if self.scheduled_end <= self.scheduled_start:
            raise ValueError("scheduled_end must be after scheduled_start")
        return self


class OnlineClassUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=2, max_length=200)
    meeting_url: str | None = Field(default=None, min_length=4, max_length=500)
    scheduled_start: datetime | None = None
    scheduled_end: datetime | None = None
    status: Literal["scheduled", "live", "ended"] | None = None


class OnlineClassOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    section_id: uuid.UUID
    subject_id: uuid.UUID | None = None
    title: str
    meeting_url: str
    scheduled_start: datetime
    scheduled_end: datetime
    status: str
    host_id: uuid.UUID | None = None
