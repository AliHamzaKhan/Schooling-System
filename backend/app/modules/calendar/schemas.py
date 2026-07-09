"""Academic calendar schemas."""
import uuid
from datetime import date, time

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.core.enums import CalendarEventType


class EventCreate(BaseModel):
    title: str = Field(min_length=2, max_length=200)
    description: str | None = None
    event_type: CalendarEventType = CalendarEventType.EVENT
    start_date: date
    end_date: date | None = None
    all_day: bool = True
    start_time: time | None = None
    end_time: time | None = None
    location: str | None = Field(default=None, max_length=200)
    session_id: uuid.UUID | None = None

    @model_validator(mode="after")
    def _check_range(self) -> "EventCreate":
        if self.end_date is not None and self.end_date < self.start_date:
            raise ValueError("end_date cannot be before start_date")
        if (
            self.start_time is not None
            and self.end_time is not None
            and self.end_time < self.start_time
        ):
            raise ValueError("end_time cannot be before start_time")
        return self


class EventUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=2, max_length=200)
    description: str | None = None
    event_type: CalendarEventType | None = None
    start_date: date | None = None
    end_date: date | None = None
    all_day: bool | None = None
    start_time: time | None = None
    end_time: time | None = None
    location: str | None = Field(default=None, max_length=200)
    session_id: uuid.UUID | None = None


class EventOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    session_id: uuid.UUID | None = None
    title: str
    description: str | None = None
    event_type: str
    start_date: date
    end_date: date | None = None
    all_day: bool
    start_time: time | None = None
    end_time: time | None = None
    location: str | None = None
    created_by: uuid.UUID | None = None
