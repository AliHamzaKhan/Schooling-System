"""Attendance Service schemas."""
import uuid
from datetime import date, time

from pydantic import BaseModel, ConfigDict, Field

from app.core.enums import AttendanceStatus

# --------------------------------------------------------------------------- #
# Enrollment
# --------------------------------------------------------------------------- #


class EnrollIn(BaseModel):
    student_id: uuid.UUID
    session_id: uuid.UUID | None = None


class EnrollmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    section_id: uuid.UUID
    student_id: uuid.UUID
    session_id: uuid.UUID | None = None
    status: str


# --------------------------------------------------------------------------- #
# Attendance
# --------------------------------------------------------------------------- #


class AttendanceEntry(BaseModel):
    student_id: uuid.UUID
    status: AttendanceStatus
    check_in_time: time | None = None
    check_out_time: time | None = None
    remarks: str | None = Field(default=None, max_length=255)


class AttendanceMarkRequest(BaseModel):
    section_id: uuid.UUID
    attendance_date: date
    # Omit for the daily register (class teacher only). Set to mark attendance
    # for a single subject/period, which any teacher of that subject may do.
    subject_id: uuid.UUID | None = None
    timetable_slot_id: uuid.UUID | None = None
    period_label: str | None = Field(default=None, max_length=50)
    entries: list[AttendanceEntry] = Field(min_length=1)

    @property
    def is_daily(self) -> bool:
        return self.subject_id is None


class AttendanceRecordOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    section_id: uuid.UUID
    student_id: uuid.UUID
    attendance_date: date
    subject_id: uuid.UUID | None = None
    timetable_slot_id: uuid.UUID | None = None
    period_label: str | None = None
    status: str
    check_in_time: time | None = None
    check_out_time: time | None = None
    remarks: str | None = None
    marked_by: uuid.UUID | None = None


class AttendanceSummary(BaseModel):
    section_id: uuid.UUID
    attendance_date: date
    subject_id: uuid.UUID | None = None
    total: int
    counts: dict[str, int]
