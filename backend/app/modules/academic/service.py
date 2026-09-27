"""Academic Service: classes, sections, subjects, timetable.

Everything is school-scoped; cross-school references are rejected. Timetable
writes are checked for clashes (same section, or same teacher, overlapping on
the same weekday).
"""
import uuid
from datetime import date, datetime, timedelta, timezone

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import grade_for
from app.core.enums import AttendanceStatus, EnrollmentStatus, SubmissionStatus, SystemRole
from app.models.role import Role
from app.core.exceptions import bad_request, not_found
from app.models.academic import (
    Section,
    SchoolClass,
    StudentEnrollment,
    Subject,
    TimetableSlot,
)
from app.models.attendance import AttendanceRecord
from app.models.communication import Message
from app.models.homework import Assignment, Submission
from app.models.examination import Exam, ExamResult, ExamSubject, Mark
from app.models.school import AcademicSession, School
from app.models.user import User
from app.modules.academic import schemas
from app.modules.academic.access import (
    enrolled_students,
    role_ids,
    taught_sections,
    valid_classes,
    valid_sections,
)


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

    async def _get_valid_class(self, school_id: uuid.UUID, class_id: uuid.UUID) -> SchoolClass:
        """Return a class only when its optional session belongs to this school.

        A class with a malformed foreign-session reference must never become a
        usable setup target merely because its ``school_id`` happens to match.
        """
        obj = await self._get_scoped(SchoolClass, school_id, class_id, "Class")
        if obj.session_id is not None:
            await self._get_scoped(
                AcademicSession, school_id, obj.session_id, "Academic session"
            )
        return obj

    async def _validate_teacher(self, school_id: uuid.UUID, teacher_id: uuid.UUID | None) -> None:
        if teacher_id is None:
            return
        teacher = await self.db.scalar(role_ids(school_id, SystemRole.TEACHER.value, active=True).where(User.id == teacher_id))
        if teacher is None:
            raise bad_request("Teacher must be an active teacher in this school")

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
            school_id=school_id, session_id=data.session_id, name=data.name,
            level=data.level, room_no=data.room_no,
        )
        self.db.add(obj)
        await self.db.flush()
        return obj

    async def list_classes(
        self, school_id: uuid.UUID, session_id: uuid.UUID | None = None
    ) -> list[SchoolClass]:
        await self._ensure_school(school_id)
        stmt = select(SchoolClass).where(SchoolClass.id.in_(valid_classes(school_id)))
        if session_id is not None:
            await self._get_scoped(AcademicSession, school_id, session_id, "Academic session")
            stmt = stmt.where(SchoolClass.session_id == session_id)
        result = await self.db.execute(stmt.order_by(SchoolClass.level, SchoolClass.name))
        return list(result.scalars().all())

    async def student_roster(self, school_id: uuid.UUID, *, teacher_id: uuid.UUID | None = None) -> list[schemas.StudentRosterOut]:
        """Every student in the school with their current active enrollment
        (roll number, class, section) resolved. Students with no active
        enrollment still appear, with those fields left blank.
        """
        await self._ensure_school(school_id)
        rows = (await self.db.execute(
            select(
                User,
                StudentEnrollment.roll_number,
                SchoolClass.name.label("class_name"),
                Section.name.label("section_name"),
            )
            .join(User.roles)
            .where(User.school_id == school_id, Role.code == SystemRole.STUDENT.value)
            .where(User.id.in_(enrolled_students(school_id, taught_sections(school_id, teacher_id))) if teacher_id else True)
            .outerjoin(
                StudentEnrollment,
                and_(
                    StudentEnrollment.student_id == User.id,
                    StudentEnrollment.school_id == school_id,
                    StudentEnrollment.section_id.in_(valid_sections(school_id)),
                    StudentEnrollment.section_id.in_(taught_sections(school_id, teacher_id)) if teacher_id else True,
                    StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                ),
            )
            .outerjoin(Section, Section.id == StudentEnrollment.section_id)
            .outerjoin(SchoolClass, SchoolClass.id == Section.class_id)
            .order_by(User.full_name, StudentEnrollment.created_at.desc())
        )).all()

        # A student can hold more than one active enrollment; keep the most
        # recent (first, given the ordering above) so each appears once.
        seen: set[uuid.UUID] = set()
        roster: list[schemas.StudentRosterOut] = []
        for user, roll, class_name, section_name in rows:
            if user.id in seen:
                continue
            seen.add(user.id)
            meta = user.profile_metadata or {}
            roster.append(schemas.StudentRosterOut(
                id=user.id,
                full_name=user.full_name,
                avatar_url=(meta.get("avatar_url") or None),
                is_active=user.is_active,
                roll_number=roll,
                class_name=class_name,
                section_name=section_name,
            ))
        return roster

    async def update_class(
        self, school_id: uuid.UUID, class_id: uuid.UUID, data: schemas.ClassUpdate
    ) -> SchoolClass:
        obj = await self._get_valid_class(school_id, class_id)
        payload = data.model_dump(exclude_unset=True)
        if "session_id" in payload and payload["session_id"] is not None:
            await self._get_scoped(AcademicSession, school_id, payload["session_id"], "Academic session")
        if "session_id" in payload and payload["session_id"] != obj.session_id:
            has_enrollments = await self.db.scalar(
                select(StudentEnrollment.id)
                .join(Section, Section.id == StudentEnrollment.section_id)
                .where(
                    StudentEnrollment.school_id == school_id,
                    Section.school_id == school_id,
                    Section.class_id == obj.id,
                )
                .limit(1)
            )
            if has_enrollments is not None:
                raise bad_request(
                    "Cannot change a class's academic session after students have been enrolled"
                )
        name = payload.get("name", obj.name)
        session_id = payload.get("session_id", obj.session_id)
        clash = await self.db.scalar(
            select(SchoolClass).where(
                SchoolClass.school_id == school_id,
                SchoolClass.session_id == session_id,
                SchoolClass.name == name,
                SchoolClass.id != obj.id,
            )
        )
        if clash is not None:
            raise bad_request(f"Class '{name}' already exists for this session")
        for field, value in payload.items():
            setattr(obj, field, value)
        await self.db.flush()
        return obj

    async def delete_class(self, school_id: uuid.UUID, class_id: uuid.UUID) -> None:
        obj = await self._get_valid_class(school_id, class_id)
        await self.db.delete(obj)
        await self.db.flush()

    # ------------------------------ sections ----------------------------- #

    async def create_section(
        self, school_id: uuid.UUID, class_id: uuid.UUID, data: schemas.SectionCreate
    ) -> Section:
        await self._get_valid_class(school_id, class_id)
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
            room_no=data.room_no,
            class_teacher_id=data.class_teacher_id,
        )
        self.db.add(obj)
        await self.db.flush()
        return obj

    async def list_sections(self, school_id: uuid.UUID, class_id: uuid.UUID) -> list[Section]:
        await self._get_valid_class(school_id, class_id)
        result = await self.db.execute(
            select(Section)
            .where(Section.class_id == class_id, Section.school_id == school_id)
            .order_by(Section.name)
        )
        return list(result.scalars().all())

    async def update_section(
        self, school_id: uuid.UUID, section_id: uuid.UUID, data: schemas.SectionUpdate
    ) -> Section:
        obj = await self._get_scoped(Section, school_id, section_id, "Section")
        payload = data.model_dump(exclude_unset=True)
        if "name" in payload and payload["name"] != obj.name:
            duplicate = await self.db.scalar(
                select(Section).where(
                    Section.class_id == obj.class_id,
                    Section.name == payload["name"],
                    Section.id != obj.id,
                )
            )
            if duplicate is not None:
                raise bad_request(
                    f"Section '{payload['name']}' already exists for this class"
                )
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
            await self._get_valid_class(school_id, data.class_id)
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
            await self._get_valid_class(school_id, payload["class_id"])
            # A class-specific subject cannot be moved underneath slots for a
            # different class.  Without this check a valid timetable becomes
            # semantically invalid after an otherwise ordinary subject edit.
            incompatible_slot = await self.db.scalar(
                select(TimetableSlot.id)
                .join(Section, Section.id == TimetableSlot.section_id)
                .where(
                    TimetableSlot.school_id == school_id,
                    TimetableSlot.subject_id == obj.id,
                    Section.school_id == school_id,
                    Section.class_id != payload["class_id"],
                )
                .limit(1)
            )
            if incompatible_slot is not None:
                raise bad_request(
                    "Cannot restrict a subject to a class while it is timetabled for another class"
                )
        if "code" in payload and payload["code"] != obj.code:
            duplicate = await self.db.scalar(
                select(Subject).where(
                    Subject.school_id == school_id,
                    Subject.code == payload["code"],
                    Subject.id != obj.id,
                )
            )
            if duplicate is not None:
                raise bad_request(f"Subject code '{payload['code']}' already exists")
        for field, value in payload.items():
            setattr(obj, field, value)
        await self.db.flush()
        return obj

    async def delete_subject(self, school_id: uuid.UUID, subject_id: uuid.UUID) -> None:
        obj = await self._get_scoped(Subject, school_id, subject_id, "Subject")
        await self.db.delete(obj)
        await self.db.flush()

    # ------------------------------ timetable ---------------------------- #

    async def _validate_timetable_links(
        self, school_id: uuid.UUID, section_id: uuid.UUID, subject_id: uuid.UUID
    ) -> tuple[Section, Subject]:
        """Ensure a timetable subject can be taught in the slot's section.

        School-wide subjects (without ``class_id``) may appear in any class,
        while a class-specific subject must match the section's class.
        """
        section = await self._get_scoped(Section, school_id, section_id, "Section")
        subject = await self._get_scoped(Subject, school_id, subject_id, "Subject")
        if subject.class_id is not None and subject.class_id != section.class_id:
            raise bad_request("Timetable subject must belong to the slot section's class")
        return section, subject

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
        section, _ = await self._validate_timetable_links(
            school_id, data.section_id, data.subject_id
        )
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
        await self._validate_timetable_links(
            school_id, slot.section_id, payload.get("subject_id", slot.subject_id)
        )
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

    async def student_performance(
        self, school_id: uuid.UUID, student_id: uuid.UUID, *, published_only: bool = True
    ) -> schemas.StudentPerformanceDetail:
        """One student's performance dashboard, entirely database-derived.

        Attendance is the daily register; the trend and recent grades come from
        the marks the student has actually been given. Empty sections mean the
        student has no data yet, not that data is missing.
        """
        user = await self.db.scalar(select(User).where(User.id == student_id, User.id.in_(role_ids(school_id, SystemRole.STUDENT.value))))
        if user is None:
            raise not_found("Student not found in this school")

        # ---- enrolment: which section / class the student is in ---- #
        section = None
        enrolment = (await self.db.execute(
            select(Section)
            .join(StudentEnrollment, StudentEnrollment.section_id == Section.id)
            .where(
                StudentEnrollment.student_id == student_id,
                StudentEnrollment.school_id == school_id,
                Section.id.in_(valid_sections(school_id)),
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
            .order_by(StudentEnrollment.created_at.desc(), StudentEnrollment.id)
            .limit(1)
        )).scalars().first()
        section = enrolment
        class_name = ""
        if section is not None:
            school_class = await self.db.get(SchoolClass, section.class_id)
            class_name = (
                f"{school_class.name} {section.name}" if school_class else section.name
            )

        # ---- attendance over the daily register ---- #
        att_rows = (await self.db.execute(
            select(AttendanceRecord.status, AttendanceRecord.attendance_date)
            .where(
                AttendanceRecord.school_id == school_id,
                AttendanceRecord.student_id == student_id,
                AttendanceRecord.section_id.in_(valid_sections(school_id)),
                AttendanceRecord.subject_id.is_(None),
            )
            .order_by(AttendanceRecord.attendance_date)
        )).all()

        attended = {
            AttendanceStatus.PRESENT.value,
            AttendanceStatus.LATE.value,
            AttendanceStatus.EARLY_DEPARTURE.value,
        }
        present = sum(1 for st, _ in att_rows if st in attended)
        total_days = len(att_rows)
        attendance_pct = round(present / total_days * 100) if total_days else 0

        # Last 7 register days as a mini week strip.
        week = [
            schemas.PerfWeekDay(
                label=d.strftime("%a"),
                mark="present" if st in attended else "absent",
            )
            for st, d in att_rows[-7:]
        ]

        # ---- marks: per-exam percentage trend + recent grades ---- #
        mark_rows = (await self.db.execute(
            select(
                Exam.id,
                Exam.name,
                Exam.start_date,
                Subject.name,
                Mark.marks_obtained,
                ExamSubject.max_marks,
                Mark.created_at,
            )
            .join(ExamSubject, ExamSubject.id == Mark.exam_subject_id)
            .join(Exam, Exam.id == ExamSubject.exam_id)
            .join(Subject, Subject.id == ExamSubject.subject_id)
            .where(
                Mark.school_id == school_id,
                Mark.student_id == student_id,
                ExamSubject.school_id == school_id,
                Exam.school_id == school_id,
                Exam.class_id.in_(select(SchoolClass.id).where(SchoolClass.school_id == school_id)),
                Subject.school_id == school_id,
                Exam.id.in_(select(ExamResult.exam_id).where(
                    ExamResult.school_id == school_id,
                    ExamResult.student_id == student_id,
                    ExamResult.published.is_(True),
                )) if published_only else True,
                Mark.marks_obtained.is_not(None),
                Mark.is_absent.is_(False),
                ExamSubject.max_marks > 0,
            )
            .order_by(Mark.created_at)
        )).all()

        # Trend: one point per exam (average across its papers), oldest first.
        per_exam: dict[uuid.UUID, dict] = {}
        subjects: set[str] = set()
        for exam_id, exam_name, start, subj, obtained, max_marks, _created in mark_rows:
            subjects.add(subj)
            e = per_exam.setdefault(
                exam_id,
                {"name": exam_name, "start": start, "obtained": 0.0, "max": 0.0},
            )
            e["obtained"] += float(obtained)
            e["max"] += float(max_marks)

        ordered = sorted(
            per_exam.values(),
            key=lambda e: (e["start"] is None, e["start"]),
        )
        trend_labels = [e["name"] for e in ordered]
        trend_scores = [
            round(e["obtained"] / e["max"] * 100, 1) if e["max"] else 0.0
            for e in ordered
        ]

        overall_pct = (
            sum(e["obtained"] for e in ordered)
            / sum(e["max"] for e in ordered) * 100
            if ordered and sum(e["max"] for e in ordered)
            else None
        )

        # Recent graded papers, newest first.
        recent = []
        for exam_id, exam_name, _start, subj, obtained, max_marks, created in reversed(
            mark_rows[-5:]
        ):
            pct = round(obtained / max_marks * 100) if max_marks else 0
            recent.append(
                schemas.PerfGrade(
                    id=f"{exam_id}:{subj}",
                    title=f"{subj} — {exam_name}",
                    date_line=created.strftime("%d %b %Y") if created else "",
                    quote=f"{obtained:g} / {max_marks:g} · {pct}%",
                    grade=grade_for(pct),
                )
            )

        return schemas.StudentPerformanceDetail(
            id=student_id,
            name=user.full_name,
            grade=class_name,
            subject=", ".join(sorted(subjects)),
            current_gpa=grade_for(overall_pct) if overall_pct is not None else "—",
            attendance_percent=f"{attendance_pct}%",
            trend_labels=trend_labels,
            trend_scores=trend_scores,
            week=week,
            recent=recent,
        )

    async def section_performance(
        self, school_id: uuid.UUID, section_id: uuid.UUID
    ) -> schemas.SectionPerformanceOut:
        """Every active student in a section with their attendance and marks.

        Attendance is measured over the *daily register* only (rows with no
        subject), so the rate reads as "days attended" rather than being
        multiplied by however many periods happen to be timetabled.

        Marks are aggregated straight from [Mark] against each paper's
        ``max_marks`` rather than from [ExamResult], so a student's standing
        appears as soon as a teacher enters marks — results are only computed
        and published at the end of an exam cycle.
        """
        section = await self._get_scoped(Section, school_id, section_id, "Section")
        school_class = await self._get_scoped(SchoolClass, school_id, section.class_id, "Class")

        student_ids = list((await self.db.execute(
            enrolled_students(school_id, [section_id]).distinct()
        )).scalars().all())
        if not student_ids:
            return schemas.SectionPerformanceOut(
                section_id=section.id,
                section_name=section.name,
                class_name=school_class.name if school_class else "Class",
                students=[],
            )

        names = dict((await self.db.execute(
            select(User.id, User.full_name).where(User.id.in_(student_ids))
        )).all())

        # ---- attendance: one grouped pass over the daily register ---- #
        attendance_rows = (await self.db.execute(
            select(
                AttendanceRecord.student_id,
                AttendanceRecord.status,
                func.count().label("n"),
            )
            .where(
                AttendanceRecord.section_id == section_id,
                AttendanceRecord.school_id == school_id,
                AttendanceRecord.student_id.in_(student_ids),
                AttendanceRecord.subject_id.is_(None),
            )
            .group_by(AttendanceRecord.student_id, AttendanceRecord.status)
        )).all()

        present_by: dict[uuid.UUID, int] = {}
        total_by: dict[uuid.UUID, int] = {}
        for sid_, status_, count in attendance_rows:
            total_by[sid_] = total_by.get(sid_, 0) + count
            # Late and early departure still count as attending the day.
            if status_ in (
                AttendanceStatus.PRESENT.value,
                AttendanceStatus.LATE.value,
                AttendanceStatus.EARLY_DEPARTURE.value,
            ):
                present_by[sid_] = present_by.get(sid_, 0) + count

        # ---- marks: sum obtained vs sum max across graded papers ---- #
        mark_rows = (await self.db.execute(
            select(
                Mark.student_id,
                func.sum(Mark.marks_obtained),
                func.sum(ExamSubject.max_marks),
                func.count(),
            )
            .join(ExamSubject, ExamSubject.id == Mark.exam_subject_id)
            .join(Exam, Exam.id == ExamSubject.exam_id)
            .join(Subject, Subject.id == ExamSubject.subject_id)
            .where(
                Mark.school_id == school_id,
                Mark.student_id.in_(student_ids),
                ExamSubject.school_id == school_id,
                Exam.school_id == school_id,
                Exam.class_id.in_(select(SchoolClass.id).where(SchoolClass.school_id == school_id)),
                Subject.school_id == school_id,
                Mark.marks_obtained.is_not(None),
                Mark.is_absent.is_(False),
                ExamSubject.max_marks > 0,
            )
            .group_by(Mark.student_id)
        )).all()
        marks_by = {
            row[0]: (float(row[1] or 0), float(row[2] or 0), int(row[3] or 0))
            for row in mark_rows
        }

        students: list[schemas.SectionStudentPerformance] = []
        for student_id in student_ids:
            total_days = total_by.get(student_id, 0)
            present_days = present_by.get(student_id, 0)
            rate = present_days / total_days if total_days else 0.0

            obtained, out_of, papers = marks_by.get(student_id, (0.0, 0.0, 0))
            pct = (obtained / out_of * 100) if out_of else 0.0

            # Weighted toward marks, but attendance still moves the ranking.
            # A student with no data at all sorts last rather than mid-table.
            if papers or total_days:
                overall = (pct / 100) * 0.7 + rate * 0.3
            else:
                overall = 0.0

            students.append(
                schemas.SectionStudentPerformance(
                    student_id=student_id,
                    full_name=names.get(student_id, "Student"),
                    present_days=present_days,
                    total_days=total_days,
                    attendance_rate=round(rate, 4),
                    average_percentage=round(pct, 2),
                    papers_counted=papers,
                    grade=grade_for(pct) if papers else "—",
                    overall_score=round(overall, 4),
                )
            )

        # Best first; ties broken by name so the order is stable between loads.
        students.sort(key=lambda s: (-s.overall_score, s.full_name.lower()))
        return schemas.SectionPerformanceOut(
            section_id=section.id,
            section_name=section.name,
            class_name=school_class.name if school_class else "Class",
            students=students,
        )

    async def teacher_dashboard(
        self, school_id: uuid.UUID, teacher_id: uuid.UUID
    ) -> schemas.TeacherDashboard:
        """The teacher home screen, assembled entirely from real records.

        Every field traces back to a table: the schedule is today's timetable
        slots, the to-do list is submissions actually awaiting a grade plus
        exams actually coming up, and recent activity is what this teacher
        actually created. Nothing here is invented — if a teacher has no work
        outstanding, the lists come back empty rather than padded.
        """
        today = date.today()
        user = await self.db.get(User, teacher_id)
        name = (user.full_name if user else "").strip()
        first = name.split(" ")[0] if name else "there"

        # ---- schedule: today's periods off the real timetable ---- #
        all_slots = await self.teacher_timetable(school_id, teacher_id, today)
        schedule = [s for s in all_slots if s.day_of_week == today.weekday()]
        section_ids = {s.section_id for s in all_slots}

        todos: list[schemas.TeacherTodo] = []
        pending_grades = 0
        new_submissions = 0

        if section_ids:
            # ---- grading queue: submissions not yet graded ---- #
            rows = (await self.db.execute(
                select(
                    Assignment.id,
                    Assignment.title,
                    Assignment.due_date,
                    func.count(Submission.id),
                )
                .join(Submission, Submission.assignment_id == Assignment.id)
                .where(
                    Assignment.school_id == school_id,
                    Assignment.section_id.in_(section_ids),
                    Submission.status != SubmissionStatus.GRADED.value,
                )
                .group_by(Assignment.id, Assignment.title, Assignment.due_date)
                .order_by(Assignment.due_date)
            )).all()

            for assignment_id, title, due, count in rows:
                pending_grades += count
                overdue = due is not None and due < today
                todos.append(
                    schemas.TeacherTodo(
                        id=f"grade:{assignment_id}",
                        title=f"Grade {count} submission{'s' if count != 1 else ''} — {title}",
                        due_line=(
                            "Past due" if overdue
                            else f"Due {due.isoformat()}" if due else "No due date"
                        ),
                        urgent=overdue,
                        kind="grading",
                    )
                )

            # Submissions that landed in the last week.
            week_ago = datetime.now(timezone.utc) - timedelta(days=7)
            new_submissions = int((await self.db.scalar(
                select(func.count(Submission.id))
                .join(Assignment, Assignment.id == Submission.assignment_id)
                .where(
                    Assignment.section_id.in_(section_ids),
                    Submission.created_at >= week_ago,
                )
            )) or 0)

        # ---- upcoming exams the teacher's classes sit ---- #
        upcoming = (await self.db.execute(
            select(Exam.id, Exam.name, Exam.start_date)
            .where(
                Exam.school_id == school_id,
                Exam.start_date.is_not(None),
                Exam.start_date >= today,
            )
            .order_by(Exam.start_date)
            .limit(3)
        )).all()
        for exam_id, exam_name, start in upcoming:
            days = (start - today).days
            todos.append(
                schemas.TeacherTodo(
                    id=f"exam:{exam_id}",
                    title=f"{exam_name} starts",
                    due_line=("Today" if days == 0 else f"In {days} day{'s' if days != 1 else ''}"),
                    urgent=days <= 2,
                    kind="exam",
                )
            )

        # ---- recent activity: what this teacher actually created ---- #
        activity: list[schemas.TeacherActivity] = []
        for title, created in (await self.db.execute(
            select(Assignment.title, Assignment.created_at)
            .where(
                Assignment.school_id == school_id,
                Assignment.assigned_by == teacher_id,
            )
            .order_by(Assignment.created_at.desc())
            .limit(5)
        )).all():
            activity.append(
                schemas.TeacherActivity(
                    label=f"Posted “{title}”", time=created, kind="assignment"
                )
            )

        for msg_title, created in (await self.db.execute(
            select(Message.title, Message.created_at)
            .where(Message.school_id == school_id, Message.created_by == teacher_id)
            .order_by(Message.created_at.desc())
            .limit(5)
        )).all():
            activity.append(
                schemas.TeacherActivity(
                    label=f"Announced “{msg_title or 'Update'}”",
                    time=created,
                    kind="announcement",
                )
            )
        activity.sort(key=lambda a: a.time, reverse=True)

        urgent = sum(1 for t in todos if t.urgent)
        summary = (
            f"{len(schedule)} class{'es' if len(schedule) != 1 else ''} today"
            f" · {pending_grades} submission{'s' if pending_grades != 1 else ''} to grade"
            + (f" · {urgent} urgent" if urgent else "")
        )

        return schemas.TeacherDashboard(
            greeting=f"Good day,\n{first}!" if first else "Welcome back!",
            summary=summary,
            today=today,
            schedule=schedule,
            todos=todos,
            recent_activity=activity[:6],
            pending_grades=pending_grades,
            new_submissions=new_submissions,
            sections_taught=len(section_ids),
        )

    async def teacher_timetable(
        self,
        school_id: uuid.UUID,
        teacher_id: uuid.UUID,
        on_date: date | None = None,
    ) -> list[schemas.TeacherTimetableSlot]:
        """A teacher's weekly timetable — every period they take, with class,
        section, subject and room resolved, ordered for a week view.

        When ``on_date`` is given, each slot also reports whether its attendance
        has already been marked that day, so the app can show finished sessions
        without a second round trip.
        """
        slots = (await self.db.execute(
            select(TimetableSlot)
            .where(
                TimetableSlot.school_id == school_id,
                TimetableSlot.teacher_id == teacher_id,
            )
            .order_by(TimetableSlot.day_of_week, TimetableSlot.start_time)
        )).scalars().all()
        if not slots:
            return []

        section_ids = {s.section_id for s in slots}
        subject_ids = {s.subject_id for s in slots}

        sections = {
            row.id: row
            for row in (await self.db.execute(
                select(Section).where(Section.id.in_(section_ids))
            )).scalars().all()
        }
        class_names = dict(
            (await self.db.execute(
                select(SchoolClass.id, SchoolClass.name).where(
                    SchoolClass.id.in_({s.class_id for s in sections.values()})
                )
            )).all()
        ) if sections else {}
        subjects = dict(
            (await self.db.execute(
                select(Subject.id, Subject.name).where(Subject.id.in_(subject_ids))
            )).all()
        )

        # One grouped count instead of a query per section.
        head_counts = dict(
            (await self.db.execute(
                select(
                    StudentEnrollment.section_id,
                    func.count(StudentEnrollment.student_id),
                )
                .where(
                    StudentEnrollment.section_id.in_(section_ids),
                    StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                )
                .group_by(StudentEnrollment.section_id)
            )).all()
        )

        marked: set[uuid.UUID] = set()
        if on_date is not None:
            marked = set((await self.db.execute(
                select(AttendanceRecord.timetable_slot_id).where(
                    AttendanceRecord.attendance_date == on_date,
                    AttendanceRecord.timetable_slot_id.in_({s.id for s in slots}),
                )
            )).scalars().all())

        out: list[schemas.TeacherTimetableSlot] = []
        for slot in slots:
            section = sections.get(slot.section_id)
            if section is None:
                continue
            out.append(
                schemas.TeacherTimetableSlot(
                    id=slot.id,
                    day_of_week=slot.day_of_week,
                    start_time=slot.start_time,
                    end_time=slot.end_time,
                    section_id=section.id,
                    section_name=section.name,
                    class_name=class_names.get(section.class_id, "Class"),
                    subject_id=slot.subject_id,
                    subject=subjects.get(slot.subject_id, "Subject"),
                    room=slot.room or section.room_no,
                    student_count=head_counts.get(section.id, 0),
                    is_class_teacher=section.class_teacher_id == teacher_id,
                    attendance_marked=slot.id in marked,
                )
            )
        return out

    async def student_timetable(
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> list[schemas.StudentTimetableSlot]:
        """A student's own weekly timetable — the slots for the section(s) they're
        actively enrolled in, with subject and teacher names resolved."""
        section_rows = await self.db.execute(
            select(StudentEnrollment.section_id).where(
                StudentEnrollment.school_id == school_id,
                StudentEnrollment.student_id == student_id,
                StudentEnrollment.section_id.in_(valid_sections(school_id)),
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
                TimetableSlot.subject_id.in_(select(Subject.id).where(Subject.school_id == school_id)),
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
                    select(User.id, User.full_name).where(User.id.in_(teacher_ids), User.id.in_(role_ids(school_id, SystemRole.TEACHER.value, active=True)))
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
