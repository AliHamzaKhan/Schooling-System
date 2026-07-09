"""Examination models: exams, papers (exam-subjects), marks, results."""
import uuid
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Float, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import ExamStatus
from app.models.base import Base, TimestampMixin, UUIDMixin


class Exam(Base, UUIDMixin, TimestampMixin):
    """An examination event for a class, e.g. "Midterm 2026"."""

    __tablename__ = "exams"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    class_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("classes.id", ondelete="CASCADE"), nullable=False, index=True
    )
    session_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("academic_sessions.id", ondelete="SET NULL"), nullable=True
    )
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default=ExamStatus.DRAFT.value, nullable=False)
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    papers: Mapped[list["ExamSubject"]] = relationship(
        back_populates="exam", cascade="all, delete-orphan"
    )


class ExamSubject(Base, UUIDMixin, TimestampMixin):
    """A subject paper within an exam, with its max and pass marks."""

    __tablename__ = "exam_subjects"
    __table_args__ = (UniqueConstraint("exam_id", "subject_id", name="uq_exam_subject"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    exam_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("exams.id", ondelete="CASCADE"), nullable=False, index=True
    )
    subject_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False
    )
    exam_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    max_marks: Mapped[float] = mapped_column(Float, nullable=False)
    pass_marks: Mapped[float] = mapped_column(Float, nullable=False)

    exam: Mapped["Exam"] = relationship(back_populates="papers")


class Mark(Base, UUIDMixin, TimestampMixin):
    """A student's marks for one exam paper."""

    __tablename__ = "marks"
    __table_args__ = (UniqueConstraint("exam_subject_id", "student_id", name="uq_mark_paper_student"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    exam_subject_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("exam_subjects.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    marks_obtained: Mapped[float | None] = mapped_column(Float, nullable=True)
    is_absent: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    remarks: Mapped[str | None] = mapped_column(String(255), nullable=True)
    marked_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )


class ExamSeat(Base, UUIDMixin, TimestampMixin):
    """A student's seat allocation for an exam (seating plan)."""

    __tablename__ = "exam_seats"
    __table_args__ = (
        UniqueConstraint("exam_id", "student_id", name="uq_seat_exam_student"),
        UniqueConstraint("exam_id", "room", "seat_no", name="uq_seat_exam_room_seat"),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    exam_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("exams.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    room: Mapped[str] = mapped_column(String(100), nullable=False)
    seat_no: Mapped[int] = mapped_column(Integer, nullable=False)


class ExamResult(Base, UUIDMixin, TimestampMixin):
    """Computed result for a student in an exam (published to guardians/students)."""

    __tablename__ = "exam_results"
    __table_args__ = (UniqueConstraint("exam_id", "student_id", name="uq_result_exam_student"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    exam_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("exams.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    total_marks: Mapped[float] = mapped_column(Float, nullable=False)
    max_total: Mapped[float] = mapped_column(Float, nullable=False)
    percentage: Mapped[float] = mapped_column(Float, nullable=False)
    grade: Mapped[str] = mapped_column(String(5), nullable=False)
    status: Mapped[str] = mapped_column(String(10), nullable=False)
    published: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
