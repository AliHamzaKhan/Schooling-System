"""Academic calendar service.

Manages calendar events and provides an exam-schedule feed derived from the
Examination module so the calendar can surface exams without duplicating them.
"""
import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import CalendarEventType
from app.core.exceptions import not_found
from app.models.calendar import CalendarEvent
from app.models.examination import Exam
from app.modules.calendar import schemas


class CalendarService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _get_scoped(self, event_id: uuid.UUID, school_id: uuid.UUID) -> CalendarEvent:
        event = await self.db.get(CalendarEvent, event_id)
        if event is None or event.school_id != school_id:
            raise not_found("Calendar event not found in this school")
        return event

    async def create(
        self, school_id: uuid.UUID, data: schemas.EventCreate, created_by: uuid.UUID
    ) -> CalendarEvent:
        event = CalendarEvent(
            school_id=school_id,
            session_id=data.session_id,
            title=data.title,
            description=data.description,
            event_type=data.event_type.value,
            start_date=data.start_date,
            end_date=data.end_date,
            all_day=data.all_day,
            start_time=data.start_time,
            end_time=data.end_time,
            location=data.location,
            created_by=created_by,
        )
        self.db.add(event)
        await self.db.flush()
        return event

    async def list_events(
        self,
        school_id: uuid.UUID,
        event_type: CalendarEventType | None = None,
        session_id: uuid.UUID | None = None,
        from_date: date | None = None,
        to_date: date | None = None,
    ) -> list[CalendarEvent]:
        stmt = select(CalendarEvent).where(CalendarEvent.school_id == school_id)
        if event_type is not None:
            stmt = stmt.where(CalendarEvent.event_type == event_type.value)
        if session_id is not None:
            stmt = stmt.where(CalendarEvent.session_id == session_id)
        if from_date is not None:
            # Include multi-day events that overlap the window.
            stmt = stmt.where(
                (CalendarEvent.end_date >= from_date)
                | ((CalendarEvent.end_date.is_(None)) & (CalendarEvent.start_date >= from_date))
            )
        if to_date is not None:
            stmt = stmt.where(CalendarEvent.start_date <= to_date)
        stmt = stmt.order_by(CalendarEvent.start_date)
        return list((await self.db.execute(stmt)).scalars().all())

    async def update(
        self, school_id: uuid.UUID, event_id: uuid.UUID, data: schemas.EventUpdate
    ) -> CalendarEvent:
        event = await self._get_scoped(event_id, school_id)
        payload = data.model_dump(exclude_unset=True)
        if "event_type" in payload and data.event_type is not None:
            payload["event_type"] = data.event_type.value
        for field, value in payload.items():
            setattr(event, field, value)
        await self.db.flush()
        return event

    async def delete(self, school_id: uuid.UUID, event_id: uuid.UUID) -> None:
        event = await self._get_scoped(event_id, school_id)
        await self.db.delete(event)
        await self.db.flush()

    async def exam_schedule(
        self, school_id: uuid.UUID, session_id: uuid.UUID | None = None
    ) -> list[schemas.EventOut]:
        """Exam events derived from the Examination module (read-only feed)."""
        stmt = select(Exam).where(
            Exam.school_id == school_id, Exam.start_date.is_not(None)
        )
        if session_id is not None:
            stmt = stmt.where(Exam.session_id == session_id)
        stmt = stmt.order_by(Exam.start_date)
        exams = list((await self.db.execute(stmt)).scalars().all())
        return [
            schemas.EventOut(
                id=e.id,
                school_id=e.school_id,
                session_id=e.session_id,
                title=e.name,
                description=None,
                event_type=CalendarEventType.EXAM.value,
                start_date=e.start_date,
                end_date=e.end_date,
                all_day=True,
                start_time=None,
                end_time=None,
                location=None,
                created_by=None,
            )
            for e in exams
        ]
