"""Reporting & Analytics schemas (read-only aggregates)."""
import uuid

from pydantic import BaseModel


class SchoolOverview(BaseModel):
    school_id: uuid.UUID
    students: int
    teachers: int
    guardians: int
    total_users: int
    classes: int
    sections: int
    subjects: int
    active_session: str | None = None


class AttendanceReport(BaseModel):
    school_id: uuid.UUID
    section_id: uuid.UUID | None = None
    total_records: int
    counts: dict[str, int]
    present_rate: float  # (present + late) / total * 100


class ExamSummary(BaseModel):
    exam_id: uuid.UUID
    name: str
    results: int
    passed: int
    failed: int
    average_percentage: float
    top_percentage: float


class AcademicReport(BaseModel):
    school_id: uuid.UUID
    exams: list[ExamSummary]


class FinanceReport(BaseModel):
    school_id: uuid.UUID
    total_invoices: int
    total_billed: float
    total_collected: float
    total_outstanding: float
    overdue_count: int
    collection_rate: float  # collected / billed * 100


class ClassEnrollment(BaseModel):
    class_id: uuid.UUID
    class_name: str
    sections: int
    students: int


class EnrollmentReport(BaseModel):
    school_id: uuid.UUID
    total_students: int
    classes: list[ClassEnrollment]


# --------------------------- per-student report --------------------------- #


class ReportGuardian(BaseModel):
    id: uuid.UUID
    name: str


class ReportAttendance(BaseModel):
    present: int = 0
    absent: int = 0
    late: int = 0
    excused: int = 0
    total: int = 0
    percentage: float = 0  # (present + late + excused) / total * 100


class ReportExam(BaseModel):
    exam_name: str
    percentage: float
    grade: str
    status: str


class ReportQuiz(BaseModel):
    title: str
    score: float | None = None


class StudentReport(BaseModel):
    """A teacher/headmaster's 360-degree view of one student — attendance, exam
    results, assignment turn-in, quiz scores, total points, and the linked
    guardian(s) (for messaging / meetings)."""

    student_id: uuid.UUID
    student_name: str
    avatar_url: str | None = None
    guardians: list[ReportGuardian] = []
    attendance: ReportAttendance
    exams: list[ReportExam] = []
    exam_average: float = 0
    assignments_total: int = 0
    assignments_submitted: int = 0
    quizzes: list[ReportQuiz] = []
    quiz_average: float | None = None
    total_points: float = 0
