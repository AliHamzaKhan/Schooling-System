"""Academic Service: classes, sections, subjects, timetable.

Everything is school-scoped; cross-school references are rejected. Timetable
writes are checked for clashes (same section, or same teacher, overlapping on
the same weekday).
"""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import EnrollmentStatus
from app.core.exceptions import bad_request, not_found
from app.models.academic import (
    Section,
    SchoolClass,
    StudentEnrollment,
    Subject,
    TimetableSlot,
)
from app.models.school import AcademicSession, School
from app.models.user import User
from app.modules.academic import schemas


class AcademicService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

    async def _ensure_school(self, school_id: uuid.UUID) -> None:
        if await self.db.get(School, school_id) is None:
            raise not_found("School not found")

    async def _get_scoped(self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    async def _validate_teacher(self, school_id: uuid.UUID, teacher_id: uuid.UUID | None) -> None:
        if teacher_id is None:
            return
        teacher = await self.db.get(User, teacher_id)
        if teacher is None or teacher.school_id != school_id:
            raise bad_request("Teacher does not belong to this school")

    # ------------------------------ classes ------------------------------ #

    async def create_class(self, school_id: uuid.UUID, data: schemas.ClassCreate) -> SchoolClass:
        await self._ensure_school(school_id)
        if data.session_id is not None:
            await self._get_scoped(AcademicSession, school_id, data.session_id, "Academic session")
        dupe = await self.db.scalar(
            select(SchoolClass).where(
                SchoolClass.school_id == school_id,
                SchoolClass.session_id == data.session_id,
                SchoolClass.name == data.name,
            )
        )
        if dupe is not None:
            raise bad_request(f"Class '{data.name}' already exists for this session")
        obj = SchoolClass(
            school_id=school_id, session_id=data.session_id, name=data.name, level=data.level
        )
        self.db.add(obj)
        await self.db.flush()
        return obj

    async def list_classes(self, school_id: uuid.UUID) -> list[SchoolClass]:
        result = await self.db.execute(
            select(SchoolClass).where(SchoolClass.school_id == school_id).order_by(SchoolClass.level, SchoolClass.name)
        )
        return list(result.scalars().all())

    async def update_class(
        self, school_id: uuid.UUID, class_id: uuid.UUID, data: schemas.ClassUpdate
    ) -> SchoolClass:
        obj = await self._get_scoped(SchoolClass, school_id, class_id, "Class")
        payload = data.model_dump(exclude_unset=True)
        if "session_id" in payload and payload["session_id"] is not None:
            await self._get_scoped(AcademicSession, school_id, payload["session_id"], "Academic session")
        for field, value in payload.items():
            setattr(obj, field, value)
        await self.db.flush()
        return obj

    async def delete_class(self, school_id: uuid.UUID, class_id: uuid.UUID) -> None:
        obj = await self._get_scoped(SchoolClass, school_id, class_id, "Class")
        await self.db.delete(obj)
        await self.db.flush()

    # ------------------------------ sections ----------------------------- #

    async def create_section(
        self, school_id: uuid.UUID, class_id: uuid.UUID, data: schemas.SectionCreate
    ) -> Section:
        await self._get_scoped(SchoolClass, school_id, class_id, "Class")
        await self._validate_teacher(school_id, data.class_teacher_id)
        dupe = await self.db.scalar(
            select(Section).where(Section.class_id == class_id, Section.name == data.name)
        )
        if dupe is not None:
            raise bad_request(f"Section '{data.name}' already exists for this class")
        obj = Section(
            school_id=school_id,
            class_id=class_id,
            name=data.name,
            class_teacher_id=data.class_teacher_id,
        )
        self.db.add(obj)
        await self.db.flush()
        return obj

    async def list_sections(self, school_id: uuid.UUID, class_id: uuid.UUID) -> list[Section]:
        await self._get_scoped(SchoolClass, school_id, class_id, "Class")
        result = await self.db.execute(
            select(Section).where(Section.class_id == class_id).order_by(Section.name)
        )
        return list(result.scalars().all())

    async def update_section(
        self, school_id: uuid.UUID, section_id: uuid.UUID, data: schemas.SectionUpdate
    ) -> Section:
        obj = await self._get_scoped(Section, school_id, section_id, "Section")
        payload = data.model_dump(exclude_unset=True)
        if "class_teacher_id" in payload:
            await self._validate_teacher(school_id, payload["class_teacher_id"])
        for field, value in payload.items():
            setattr(obj, field, value)
        await self.db.flush()
        return obj

    async def delete_section(self, school_id: uuid.UUID, section_id: uuid.UUID) -> None:
        obj = await self._get_scoped(Section, school_id, section_id, "Section")
        await self.db.delete(obj)
        await self.db.flush()

    # ------------------------------ subjects ----------------------------- #

    async def create_subject(self, school_id: uuid.UUID, data: schemas.SubjectCreate) -> Subject:
        await self._ensure_school(school_id)
        if data.class_id is not None:
            await self._get_scoped(SchoolClass, school_id, data.class_id, "Class")
        dupe = await self.db.scalar(
            select(Subject).where(Subject.school_id == school_id, Subject.code == data.code)
        )
        if dupe is not None:
            raise bad_request(f"Subject code '{data.code}' already exists")
        obj = Subject(
            school_id=school_id, class_id=data.class_id, code=data.code, name=data.name
        )
        self.db.add(obj)
        await self.db.flush()
        return obj

    async def list_subjects(self, school_id: uuid.UUID) -> list[Subject]:
        result = await self.db.execute(
            select(Subject).where(Subject.school_id == school_id).order_by(Subject.name)
        )
        return list(result.scalars().all())

    async def update_subject(
        self, school_id: uuid.UUID, subject_id: uuid.UUID, data: schemas.SubjectUpdate
    ) -> Subject:
        obj = await self._get_scoped(Subject, school_id, subject_id, "Subject")
        payload = data.model_dump(exclude_unset=True)
        if "class_id" in payload and payload["class_id"] is not None:
            await self._get_scoped(SchoolClass, school_id, payload["class_id"], "Class")
        for field, value in payload.items():
            setattr(obj, field, value)
        await self.db.flush()
        return obj

    async def delete_subject(self, school_id: uuid.UUID, subject_id: uuid.UUID) -> None:
        obj = await self._get_scoped(Subject, school_id, subject_id, "Subject")
        await self.db.delete(obj)
        await self.db.flush()

    # ------------------------------ timetable ---------------------------- #

    async def _assert_no_clash(
        self,
        school_id: uuid.UUID,
        section_id: uuid.UUID,
        teacher_id: uuid.UUID | None,
        day_of_week: int,
        start_time,
        end_time,
        exclude_id: uuid.UUID | None = None,
    ) -> None:
        stmt = select(TimetableSlot).where(
            TimetableSlot.school_id == school_id,
            TimetableSlot.day_of_week == day_of_week,
            TimetableSlot.start_time < end_time,
            TimetableSlot.end_time > start_time,
        )
        if exclude_id is not None:
            stmt = stmt.where(TimetableSlot.id != exclude_id)
        for slot in (await self.db.execute(stmt)).scalars().all():
            if slot.section_id == section_id:
                raise bad_request("Timetable clash: this section already has a period at that time")
            if teacher_id is not None and slot.teacher_id == teacher_id:
                raise bad_request("Timetable clash: this teacher is already booked at that time")

    async def create_slot(
        self, school_id: uuid.UUID, data: schemas.TimetableSlotCreate
    ) -> TimetableSlot:
        section = await self._get_scoped(Section, school_id, data.section_id, "Section")
        await self._get_scoped(Subject, school_id, data.subject_id, "Subject")
        await self._validate_teacher(school_id, data.teacher_id)
        await self._assert_no_clash(
            school_id, section.id, data.teacher_id, data.day_of_week, data.start_time, data.end_time
        )
        obj = TimetableSlot(
            school_id=school_id,
            section_id=data.section_id,
            subject_id=data.subject_id,
            teacher_id=data.teacher_id,
            day_of_week=data.day_of_week,
            start_time=data.start_time,
            end_time=data.end_time,
            room=data.room,
        )
        self.db.add(obj)
        await self.db.flush()
        return obj

    async def list_slots(
        self, school_id: uuid.UUID, section_id: uuid.UUID | None = None
    ) -> list[TimetableSlot]:
        stmt = select(TimetableSlot).where(TimetableSlot.school_id == school_id)
        if section_id is not None:
            stmt = stmt.where(TimetableSlot.section_id == section_id)
        stmt = stmt.order_by(TimetableSlot.day_of_week, TimetableSlot.start_time)
        return list((await self.db.execute(stmt)).scalars().all())

    async def update_slot(
        self, school_id: uuid.UUID, slot_id: uuid.UUID, data: schemas.TimetableSlotUpdate
    ) -> TimetableSlot:
        slot = await self._get_scoped(TimetableSlot, school_id, slot_id, "Timetable slot")
        payload = data.model_dump(exclude_unset=True)
        if "subject_id" in payload:
            await self._get_scoped(Subject, school_id, payload["subject_id"], "Subject")
        if "teacher_id" in payload:
            await self._validate_teacher(school_id, payload["teacher_id"])

        new_day = payload.get("day_of_week", slot.day_of_week)
        new_start = payload.get("start_time", slot.start_time)
        new_end = payload.get("end_time", slot.end_time)
        new_teacher = payload.get("teacher_id", slot.teacher_id)
        if new_end <= new_start:
            raise bad_request("end_time must be after start_time")
        await self._assert_no_clash(
            school_id, slot.section_id, new_teacher, new_day, new_start, new_end, exclude_id=slot.id
        )
        for field, value in payload.items():
            setattr(slot, field, value)
        await self.db.flush()
        return slot

    async def delete_slot(self, school_id: uuid.UUID, slot_id: uuid.UUID) -> None:
        slot = await self._get_scoped(TimetableSlot, school_id, slot_id, "Timetable slot")
        await self.db.delete(slot)
        await self.db.flush()

    async def student_timetable(
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> list[schemas.StudentTimetableSlot]:
        """A student's own weekly timetable — the slots for the section(s) they're
        actively enrolled in, with subject and teacher names resolved."""
        section_rows = await self.db.execute(
            select(StudentEnrollment.section_id).where(
                StudentEnrollment.school_id == school_id,
                StudentEnrollment.student_id == student_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
        )
        section_ids = [r[0] for r in section_rows.all()]
        if not section_ids:
            return []

        slots = (await self.db.execute(
            select(TimetableSlot)
            .where(
                TimetableSlot.school_id == school_id,
                TimetableSlot.section_id.in_(section_ids),
            )
            .order_by(TimetableSlot.day_of_week, TimetableSlot.start_time)
        )).scalars().all()
        if not slots:
            return []

        subject_ids = {s.subject_id for s in slots}
        teacher_ids = {s.teacher_id for s in slots if s.teacher_id}
        subjects = dict(
            (await self.db.execute(
                select(Subject.id, Subject.name).where(Subject.id.in_(subject_ids))
            )).all()
        )
        teachers = (
            dict(
                (await self.db.execute(
                    select(User.id, User.full_name).where(User.id.in_(teacher_ids))
                )).all()
            )
            if teacher_ids
            else {}
        )
        return [
            schemas.StudentTimetableSlot(
                day_of_week=s.day_of_week,
                start_time=s.start_time,
                end_time=s.end_time,
                subject=subjects.get(s.subject_id, "Subject"),
                teacher=teachers.get(s.teacher_id),
                room=s.room,
            )
            for s in slots
        ]
