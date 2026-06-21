"""Academic Service schemas."""
import uuid
from datetime import time

from pydantic import BaseModel, ConfigDict, Field, model_validator

# --------------------------------------------------------------------------- #
# Class
# --------------------------------------------------------------------------- #


class ClassCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    level: int | None = Field(default=None, ge=0, le=20)
    session_id: uuid.UUID | None = None


class ClassUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    level: int | None = Field(default=None, ge=0, le=20)
    session_id: uuid.UUID | None = None


class ClassOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    session_id: uuid.UUID | None = None
    name: str
    level: int | None = None


# --------------------------------------------------------------------------- #
# Section
# --------------------------------------------------------------------------- #


class SectionCreate(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    class_teacher_id: uuid.UUID | None = None


class SectionUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=50)
    class_teacher_id: uuid.UUID | None = None


class SectionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    class_id: uuid.UUID
    name: str
    class_teacher_id: uuid.UUID | None = None


# --------------------------------------------------------------------------- #
# Subject
# --------------------------------------------------------------------------- #


class SubjectCreate(BaseModel):
    code: str = Field(min_length=1, max_length=50)
    name: str = Field(min_length=1, max_length=100)
    class_id: uuid.UUID | None = None


class SubjectUpdate(BaseModel):
    code: str | None = Field(default=None, min_length=1, max_length=50)
    name: str | None = Field(default=None, min_length=1, max_length=100)
    class_id: uuid.UUID | None = None


class SubjectOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    class_id: uuid.UUID | None = None
    code: str
    name: str


# --------------------------------------------------------------------------- #
# Timetable
# --------------------------------------------------------------------------- #


class TimetableSlotCreate(BaseModel):
    section_id: uuid.UUID
    subject_id: uuid.UUID
    teacher_id: uuid.UUID | None = None
    day_of_week: int = Field(ge=0, le=6, description="0=Monday .. 6=Sunday")
    start_time: time
    end_time: time
    room: str | None = Field(default=None, max_length=50)

    @model_validator(mode="after")
    def _check_times(self) -> "TimetableSlotCreate":
        if self.end_time <= self.start_time:
            raise ValueError("end_time must be after start_time")
        return self


class TimetableSlotUpdate(BaseModel):
    subject_id: uuid.UUID | None = None
    teacher_id: uuid.UUID | None = None
    day_of_week: int | None = Field(default=None, ge=0, le=6)
    start_time: time | None = None
    end_time: time | None = None
    room: str | None = Field(default=None, max_length=50)


class TimetableSlotOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    section_id: uuid.UUID
    subject_id: uuid.UUID
    teacher_id: uuid.UUID | None = None
    day_of_week: int
    start_time: time
    end_time: time
    room: str | None = None
