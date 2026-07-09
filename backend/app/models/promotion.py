"""Promotion history: one record per student per promotion decision.

A promotion moves a student's active enrollment from one section to another
(typically into the next class/level) for a new academic session. Records power
promotion reports and preserve academic history even after enrollments change.
"""
import uuid

from sqlalchemy import ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.enums import PromotionOutcome
from app.models.base import Base, TimestampMixin, UUIDMixin


class PromotionRecord(Base, UUIDMixin, TimestampMixin):
    """An audit record of a single promote/retain/graduate decision."""

    __tablename__ = "promotion_records"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    from_section_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sections.id", ondelete="SET NULL"), nullable=True
    )
    to_section_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sections.id", ondelete="SET NULL"), nullable=True
    )
    from_session_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("academic_sessions.id", ondelete="SET NULL"), nullable=True
    )
    to_session_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("academic_sessions.id", ondelete="SET NULL"), nullable=True
    )
    exam_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("exams.id", ondelete="SET NULL"), nullable=True
    )
    outcome: Mapped[str] = mapped_column(
        String(20), default=PromotionOutcome.PROMOTED.value, nullable=False
    )
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
