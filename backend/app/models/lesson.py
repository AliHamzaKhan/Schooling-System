"""Lesson planning & teaching-progress models."""
import uuid
from datetime import date

from sqlalchemy import Date, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.enums import LessonStatus
from app.models.base import Base, TimestampMixin, UUIDMixin


class LessonPlan(Base, UUIDMixin, TimestampMixin):
    """A planned lesson/topic for a section+subject, with teaching progress."""

    __tablename__ = "lesson_plans"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    section_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sections.id", ondelete="CASCADE"), nullable=False, index=True
    )
    subject_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    planned_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default=LessonStatus.PLANNED.value, nullable=False)
    progress_percent: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    teacher_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
