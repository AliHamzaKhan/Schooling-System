"""Student attendance records."""
import uuid
from datetime import date, time

from sqlalchemy import Date, ForeignKey, Index, String, Time, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class AttendanceRecord(Base, UUIDMixin, TimestampMixin):
    """A student attendance mark (docs/permissions/08).

    Two flavours share this table, distinguished by ``subject_id``:

    * **Daily register** (``subject_id IS NULL``) — one row per student per day,
      marked by the section's class teacher. This is the original behaviour.
    * **Subject/period attendance** (``subject_id`` set) — one row per student
      per day *per subject*, marked by whichever teacher takes that period.
      Needed for college/university timetables, and useful in schools too.

    Uniqueness is enforced by two *partial* indexes rather than one constraint:
    a plain ``UNIQUE (student_id, attendance_date, subject_id)`` would not
    constrain the daily rows at all, because Postgres treats NULLs as distinct
    and would happily accept many NULL-subject rows for the same day.
    """

    __tablename__ = "attendance_records"
    __table_args__ = (
        Index(
            "uq_attendance_student_date_daily",
            "student_id",
            "attendance_date",
            unique=True,
            postgresql_where=text("subject_id IS NULL"),
        ),
        Index(
            "uq_attendance_student_date_subject",
            "student_id",
            "attendance_date",
            "subject_id",
            unique=True,
            postgresql_where=text("subject_id IS NOT NULL"),
        ),
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
    attendance_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    # NULL => the daily register row; set => attendance for that one subject.
    subject_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("subjects.id", ondelete="CASCADE"), nullable=True, index=True
    )
    # The timetable period this mark came from, when marked off a timetable.
    timetable_slot_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("timetable_slots.id", ondelete="SET NULL"), nullable=True
    )
    # Free-form period label for institutions that don't drive off the timetable
    # (e.g. "Period 3", "Lecture 2").
    period_label: Mapped[str | None] = mapped_column(String(50), nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    check_in_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    check_out_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    remarks: Mapped[str | None] = mapped_column(String(255), nullable=True)
    marked_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
