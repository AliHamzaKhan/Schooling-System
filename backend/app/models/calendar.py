"""Academic calendar: holidays, events, exam markers, and academic milestones."""
import uuid
from datetime import date, time

from sqlalchemy import Boolean, Date, ForeignKey, String, Text, Time
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.enums import CalendarEventType
from app.models.base import Base, TimestampMixin, UUIDMixin


class CalendarEvent(Base, UUIDMixin, TimestampMixin):
    """A dated entry on the school calendar.

    Covers holidays, general events, exam markers and academic milestones. A
    single-day entry has ``end_date`` null; a timed entry sets start/end time
    and ``all_day`` false.
    """

    __tablename__ = "calendar_events"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    session_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("academic_sessions.id", ondelete="SET NULL"), nullable=True
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    event_type: Mapped[str] = mapped_column(
        String(20), default=CalendarEventType.EVENT.value, nullable=False, index=True
    )
    start_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    all_day: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    start_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    end_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    location: Mapped[str | None] = mapped_column(String(200), nullable=True)
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
