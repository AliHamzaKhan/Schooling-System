"""HR & Payroll schemas."""
import uuid
from datetime import date, time
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class StaffProfileCreate(BaseModel):
    user_id: uuid.UUID
    designation: str = Field(min_length=1, max_length=120)
    department: str | None = Field(default=None, max_length=120)
    joining_date: date | None = None
    base_salary: float = Field(ge=0)


class StaffProfileUpdate(BaseModel):
    designation: str | None = Field(default=None, min_length=1, max_length=120)
    department: str | None = Field(default=None, max_length=120)
    joining_date: date | None = None
    base_salary: float | None = Field(default=None, ge=0)


class StaffProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    user_id: uuid.UUID
    designation: str
    department: str | None = None
    joining_date: date | None = None
    base_salary: float


class PayslipGenerate(BaseModel):
    period_month: int = Field(ge=1, le=12)
    period_year: int = Field(ge=2000, le=2100)
    allowances: float = Field(default=0.0, ge=0)
    deductions: float = Field(default=0.0, ge=0)
    # When true the server computes an absence deduction of
    # (base_salary / 30) * absent_days for the period and folds it into
    # [deductions]. The attendance counts are snapshotted onto the payslip
    # either way so the PDF can show them.
    deduct_absences: bool = False


class PayslipOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    staff_profile_id: uuid.UUID
    period_month: int
    period_year: int
    gross: float
    allowances: float = 0.0
    deductions: float
    net: float
    status: str
    paid_on: date | None = None
    present_days: int = 0
    absent_days: int = 0
    late_days: int = 0
    leave_days: int = 0
    absence_deduction: float = 0.0


class MonthlyAttendanceSummary(BaseModel):
    """Teacher attendance roll-up for one month — drives the payslip screen."""

    teacher_id: uuid.UUID
    period_month: int
    period_year: int
    present_days: int
    absent_days: int
    late_days: int
    leave_days: int
    marked_days: int
    # (base_salary / 30) * absent_days — what WOULD be deducted if the
    # headmaster enables the toggle. Zero when the staff profile is unknown.
    projected_absence_deduction: float = 0.0


# --------------------------------------------------------------------------- #
# Teacher attendance
# --------------------------------------------------------------------------- #


TeacherAttendanceStatus = Literal["present", "absent", "late", "on_leave"]


class TeacherAttendanceMark(BaseModel):
    """Upsert payload — one entry per teacher per date."""

    teacher_id: uuid.UUID
    attendance_date: date
    status: TeacherAttendanceStatus
    arrival_time: time | None = None
    remarks: str | None = Field(default=None, max_length=255)


class TeacherAttendanceBulkMark(BaseModel):
    """Mark several teachers at once for the same day (Save button)."""

    entries: list[TeacherAttendanceMark] = Field(min_length=1)


class TeacherAttendanceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    teacher_id: uuid.UUID
    teacher_name: str | None = None
    attendance_date: date
    status: str
    arrival_time: time | None = None
    remarks: str | None = None


class TeacherAttendanceDay(BaseModel):
    """Snapshot for a given date — every teacher plus their attendance entry
    (may be null if not yet marked). Used by the Reports drill-in and the
    marking screen so the UI shows the full roster in one hop.
    """

    attendance_date: date
    total_teachers: int
    present: int
    absent: int
    late: int
    on_leave: int
    unmarked: int
    entries: list["TeacherAttendanceRosterRow"]


class TeacherAttendanceRosterRow(BaseModel):
    teacher_id: uuid.UUID
    teacher_name: str
    status: TeacherAttendanceStatus | None = None
    arrival_time: time | None = None
    remarks: str | None = None


TeacherAttendanceDay.model_rebuild()
