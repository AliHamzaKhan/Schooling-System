"""Academic Service schemas."""
import uuid
from datetime import date, datetime, time

from pydantic import BaseModel, ConfigDict, Field, model_validator

# --------------------------------------------------------------------------- #
# Class
# --------------------------------------------------------------------------- #


class ClassCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    level: int | None = Field(default=None, ge=0, le=20)
    room_no: str | None = Field(default=None, max_length=50)
    session_id: uuid.UUID | None = None


class ClassUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    level: int | None = Field(default=None, ge=0, le=20)
    room_no: str | None = Field(default=None, max_length=50)
    session_id: uuid.UUID | None = None


class ClassOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    session_id: uuid.UUID | None = None
    name: str
    level: int | None = None
    room_no: str | None = None


# --------------------------------------------------------------------------- #
# Section
# --------------------------------------------------------------------------- #


class SectionCreate(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    room_no: str | None = Field(default=None, max_length=50)
    class_teacher_id: uuid.UUID | None = None


class SectionUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=50)
    room_no: str | None = Field(default=None, max_length=50)
    class_teacher_id: uuid.UUID | None = None


class SectionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    class_id: uuid.UUID
    name: str
    room_no: str | None = None
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


class SectionStudentPerformance(BaseModel):
    """One student's standing within a section, for the teacher's ranking view."""

    student_id: uuid.UUID
    full_name: str

    # Attendance over the daily register (subject periods excluded so the rate
    # means "days attended", not "periods attended").
    present_days: int = 0
    total_days: int = 0
    attendance_rate: float = 0.0

    # Marks aggregated across every graded paper the student sat.
    average_percentage: float = 0.0
    papers_counted: int = 0
    grade: str = "—"

    # 0..1 blend of attendance and marks used for the default ranking.
    overall_score: float = 0.0


class SectionPerformanceOut(BaseModel):
    section_id: uuid.UUID
    section_name: str
    class_name: str
    students: list[SectionStudentPerformance] = []


class TeacherTodo(BaseModel):
    """A real piece of outstanding work, derived from the database.

    There is no "todo" table: every item here is computed from something the
    teacher genuinely has to act on — submissions awaiting a grade, or an exam
    they have a paper in that is coming up.
    """

    id: str
    title: str
    due_line: str
    urgent: bool = False
    kind: str  # "grading" | "exam"


class TeacherActivity(BaseModel):
    """Something the teacher recently created, newest first."""

    label: str
    time: datetime
    kind: str  # "assignment" | "announcement"


class TeacherDashboard(BaseModel):
    """Everything the teacher home screen shows, all database-derived."""

    greeting: str
    summary: str
    today: date
    schedule: list["TeacherTimetableSlot"] = []
    todos: list[TeacherTodo] = []
    recent_activity: list[TeacherActivity] = []
    pending_grades: int = 0
    new_submissions: int = 0
    sections_taught: int = 0


class TeacherTimetableSlot(BaseModel):
    """A period a teacher takes, with class/section/subject names resolved.

    ``attendance_marked`` is only meaningful when the caller passed a date: it
    reports whether this specific period already has attendance saved that day,
    which is what lets the app show a session as finished.
    """

    id: uuid.UUID
    day_of_week: int
    start_time: time
    end_time: time
    section_id: uuid.UUID
    section_name: str
    class_name: str
    subject_id: uuid.UUID
    subject: str
    room: str | None = None
    student_count: int = 0
    is_class_teacher: bool = False
    attendance_marked: bool = False


class StudentTimetableSlot(BaseModel):
    """A period on a student's own timetable, with subject/teacher names
    resolved (0=Mon .. 6=Sun)."""

    day_of_week: int
    start_time: time
    end_time: time
    subject: str
    teacher: str | None = None
    room: str | None = None
