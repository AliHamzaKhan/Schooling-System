"""Lesson planning & teaching-progress service."""
import uuid

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import LessonStatus
from app.core.exceptions import not_found
from app.models.academic import Section, Subject
from app.models.lesson import LessonPlan
from app.modules.academic.access import valid_sections, valid_subjects
from app.modules.lessons import schemas


class LessonService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _get_scoped(self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    async def _validate_links(
        self, school_id: uuid.UUID, section_id: uuid.UUID, subject_id: uuid.UUID
    ) -> None:
        row = await self.db.execute(
            select(Section.class_id, Subject.class_id)
            .join(Subject, Subject.id == subject_id)
            .where(
                Section.id == section_id,
                Section.id.in_(valid_sections(school_id)),
                Subject.id.in_(valid_subjects(school_id)),
            )
        )
        links = row.first()
        if links is None or (links[1] is not None and links[1] != links[0]):
            raise not_found("Section and subject must belong to this school and class")

    async def _get_lesson(self, school_id: uuid.UUID, lesson_id: uuid.UUID) -> LessonPlan:
        lesson = await self._get_scoped(LessonPlan, school_id, lesson_id, "Lesson plan")
        await self._validate_links(school_id, lesson.section_id, lesson.subject_id)
        return lesson

    async def create(
        self, school_id: uuid.UUID, data: schemas.LessonCreate, teacher_id: uuid.UUID
    ) -> LessonPlan:
        await self._validate_links(school_id, data.section_id, data.subject_id)
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
        stmt = (
            select(LessonPlan)
            .join(Section, Section.id == LessonPlan.section_id)
            .join(Subject, Subject.id == LessonPlan.subject_id)
            .where(
                LessonPlan.school_id == school_id,
                LessonPlan.section_id.in_(valid_sections(school_id)),
                LessonPlan.subject_id.in_(valid_subjects(school_id)),
                or_(Subject.class_id.is_(None), Subject.class_id == Section.class_id),
            )
        )
        if section_id is not None:
            if await self.db.scalar(valid_sections(school_id).where(Section.id == section_id)) is None:
                raise not_found("Section not found in this school")
            stmt = stmt.where(LessonPlan.section_id == section_id)
        if subject_id is not None:
            if await self.db.scalar(valid_subjects(school_id).where(Subject.id == subject_id)) is None:
                raise not_found("Subject not found in this school")
            stmt = stmt.where(LessonPlan.subject_id == subject_id)
        if section_id is not None and subject_id is not None:
            await self._validate_links(school_id, section_id, subject_id)
        stmt = stmt.order_by(LessonPlan.planned_date.nulls_last(), LessonPlan.created_at)
        return list((await self.db.execute(stmt)).scalars().all())

    async def update(
        self, school_id: uuid.UUID, lesson_id: uuid.UUID, data: schemas.LessonUpdate
    ) -> LessonPlan:
        lesson = await self._get_lesson(school_id, lesson_id)
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
        lesson = await self._get_lesson(school_id, lesson_id)
        await self.db.delete(lesson)
        await self.db.flush()

    async def progress(
        self, school_id: uuid.UUID, section_id: uuid.UUID, subject_id: uuid.UUID
    ) -> schemas.TeachingProgress:
        await self._validate_links(school_id, section_id, subject_id)
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
