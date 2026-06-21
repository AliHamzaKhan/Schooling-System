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
