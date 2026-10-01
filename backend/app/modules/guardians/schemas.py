"""Guardian ↔ student linkage schemas."""
import uuid

from pydantic import BaseModel, ConfigDict, Field


class ChildLink(BaseModel):
    """Request body to link a student to a guardian."""

    student_id: uuid.UUID
    relationship: str | None = Field(default=None, max_length=50)


class ChildOut(BaseModel):
    """A student linked to a guardian, enriched with their current placement.

    `section_id`/`section_name`/`class_name`/`grade_level` come from the
    student's active enrollment and are null when the student is not yet
    enrolled in a section.
    """

    model_config = ConfigDict(from_attributes=True)

    student_id: uuid.UUID
    full_name: str
    email: str
    relationship: str | None = None
    section_id: uuid.UUID | None = None
    section_name: str | None = None
    class_name: str | None = None
    grade_level: int | None = None
    # Live family summary. `attendance_percent` is null when no register was
    # taken this month, so a client never presents a default as a real 0 %.
    attendance_percent: int | None = None
    pending_homework: int = 0
    fees_due: bool = False


class GuardianOut(BaseModel):
    """A guardian linked to a student (used on the student/headmaster side)."""

    model_config = ConfigDict(from_attributes=True)

    guardian_id: uuid.UUID
    full_name: str
    email: str
    phone: str | None = None
    relationship: str | None = None
