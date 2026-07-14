"""Lesson planning & teaching-progress service."""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import LessonStatus
from app.core.exceptions import not_found
from app.models.academic import Section, Subject
from app.models.lesson import LessonPlan
from app.modules.lessons import schemas


class LessonService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _get_scoped(self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    async def create(
        self, school_id: uuid.UUID, data: schemas.LessonCreate, teacher_id: uuid.UUID
    ) -> LessonPlan:
        await self._get_scoped(Section, school_id, data.section_id, "Section")
        await self._get_scoped(Subject, school_id, data.subject_id, "Subject")
        lesson = LessonPlan(
            school_id=school_id,
            section_id=data.section_id,
            subject_id=data.subject_id,
            title=data.title,
            description=data.description,
            planned_date=data.planned_date,
            status=data.status.value,
            progress_percent=data.progress_percent,
            teacher_id=teacher_id,
        )
        self.db.add(lesson)
        await self.db.flush()
        return lesson

    async def list_lessons(
        self,
        school_id: uuid.UUID,
        section_id: uuid.UUID | None = None,
        subject_id: uuid.UUID | None = None,
    ) -> list[LessonPlan]:
        stmt = select(LessonPlan).where(LessonPlan.school_id == school_id)
        if section_id is not None:
            stmt = stmt.where(LessonPlan.section_id == section_id)
        if subject_id is not None:
            stmt = stmt.where(LessonPlan.subject_id == subject_id)
        stmt = stmt.order_by(LessonPlan.planned_date.nulls_last(), LessonPlan.created_at)
        return list((await self.db.execute(stmt)).scalars().all())

    async def update(
        self, school_id: uuid.UUID, lesson_id: uuid.UUID, data: schemas.LessonUpdate
    ) -> LessonPlan:
        lesson = await self._get_scoped(LessonPlan, school_id, lesson_id, "Lesson plan")
        payload = data.model_dump(exclude_unset=True)
        if "status" in payload and data.status is not None:
            payload["status"] = data.status.value
        for field, value in payload.items():
            setattr(lesson, field, value)
        # Keep progress and status consistent at the boundaries.
        if lesson.status == LessonStatus.COMPLETED.value:
            lesson.progress_percent = 100
        await self.db.flush()
        return lesson

    async def delete(self, school_id: uuid.UUID, lesson_id: uuid.UUID) -> None:
        lesson = await self._get_scoped(LessonPlan, school_id, lesson_id, "Lesson plan")
        await self.db.delete(lesson)
        await self.db.flush()

    async def progress(
        self, school_id: uuid.UUID, section_id: uuid.UUID, subject_id: uuid.UUID
    ) -> schemas.TeachingProgress:
        lessons = await self.list_lessons(school_id, section_id, subject_id)
        total = len(lessons)
        completed = sum(1 for lesson in lessons if lesson.status == LessonStatus.COMPLETED.value)
        avg = (sum(lesson.progress_percent for lesson in lessons) / total) if total else 0.0
        return schemas.TeachingProgress(
            section_id=section_id,
            subject_id=subject_id,
            total_lessons=total,
            completed_lessons=completed,
            average_progress=round(avg, 2),
        )
