"""Academic structure models: classes, sections, subjects, timetable.

All are school-scoped. Classes/sections optionally belong to an AcademicSession
so the structure can be rolled over year to year.
"""
import uuid
from datetime import time

from sqlalchemy import ForeignKey, Integer, String, Time, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDMixin


class SchoolClass(Base, UUIDMixin, TimestampMixin):
    """A grade/year level, e.g. "Grade 5"."""

    __tablename__ = "classes"
    __table_args__ = (
        UniqueConstraint("school_id", "session_id", "name", name="uq_class_school_session_name"),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    session_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("academic_sessions.id", ondelete="SET NULL"), nullable=True
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    level: Mapped[int | None] = mapped_column(Integer, nullable=True)

    sections: Mapped[list["Section"]] = relationship(
        back_populates="school_class", cascade="all, delete-orphan"
    )


class Section(Base, UUIDMixin, TimestampMixin):
    """A division of a class, e.g. "5-A". Optionally has a class teacher."""

    __tablename__ = "sections"
    __table_args__ = (
        UniqueConstraint("class_id", "name", name="uq_section_class_name"),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    class_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("classes.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    class_teacher_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    school_class: Mapped["SchoolClass"] = relationship(back_populates="sections")


class StudentEnrollment(Base, UUIDMixin, TimestampMixin):
    """Links a student (user) to a section. Required before marking attendance."""

    __tablename__ = "student_enrollments"
    __table_args__ = (
        UniqueConstraint("section_id", "student_id", name="uq_enrollment_section_student"),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    section_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sections.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    session_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("academic_sessions.id", ondelete="SET NULL"), nullable=True
    )
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)


class Subject(Base, UUIDMixin, TimestampMixin):
    """A subject, e.g. "Mathematics". Optionally tied to a class."""

    __tablename__ = "subjects"
    __table_args__ = (
        UniqueConstraint("school_id", "code", name="uq_subject_school_code"),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    class_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("classes.id", ondelete="CASCADE"), nullable=True
    )
    code: Mapped[str] = mapped_column(String(50), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)


class TimetableSlot(Base, UUIDMixin, TimestampMixin):
    """A scheduled period: section + subject + teacher on a weekday/time range."""

    __tablename__ = "timetable_slots"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    section_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sections.id", ondelete="CASCADE"), nullable=False, index=True
    )
    subject_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False
    )
    teacher_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    day_of_week: Mapped[int] = mapped_column(Integer, nullable=False)  # 0=Mon .. 6=Sun
    start_time: Mapped[time] = mapped_column(Time, nullable=False)
    end_time: Mapped[time] = mapped_column(Time, nullable=False)
    room: Mapped[str | None] = mapped_column(String(50), nullable=True)
