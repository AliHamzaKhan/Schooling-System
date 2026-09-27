"""Attendance Service: enrollment, daily + subject attendance, and queries."""
import logging
import uuid
from datetime import date

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import (
    AttendanceStatus,
    EnrollmentStatus,
    NotificationEvent,
    SystemRole,
)
from app.core.exceptions import bad_request, forbidden, not_found
from app.core.pagination import OffsetPage
from app.models.academic import SchoolClass, Section, StudentEnrollment, Subject, TimetableSlot
from app.models.attendance import AttendanceRecord
from app.models.role import Role
from app.modules.academic.access import enrolled_students, role_ids, valid_sections
from app.models.school import AcademicSession
from app.models.user import User
from app.modules.attendance import schemas

logger = logging.getLogger("attendance")

# Marks worth waking a guardian's phone for, and the NotificationConfig event
# each one is routed by. "present" and "excused" deliberately never notify;
# NotificationEvent.ATTENDANCE_PRESENT exists if that is ever wanted, but it
# would message every guardian every day. Early departure rides on the LATE
# event, since both mean "partially attended" to a guardian.
STATUS_EVENTS: dict[str, str] = {
    AttendanceStatus.ABSENT.value: NotificationEvent.ATTENDANCE_ABSENT.value,
    AttendanceStatus.LATE.value: NotificationEvent.ATTENDANCE_LATE.value,
    AttendanceStatus.EARLY_DEPARTURE.value: NotificationEvent.ATTENDANCE_LATE.value,
}


class AttendanceService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

    async def _get_section(self, school_id: uuid.UUID, section_id: uuid.UUID) -> Section:
        section = await self.db.scalar(select(Section).where(
            Section.id == section_id, Section.id.in_(valid_sections(school_id)),
        ))
        if section is None:
            raise not_found("Section not found in this school")
        return section

    async def _get_enrollment_section(
        self, school_id: uuid.UUID, section_id: uuid.UUID
    ) -> tuple[Section, uuid.UUID | None]:
        """Return a usable section and the session of its parent class.

        A section does not store a session itself.  Resolving it through its
        class keeps an enrollment from being attached to an unrelated local
        academic session.  ``valid_sections`` also rejects malformed legacy
        section/class ownership before an enrollment can be created.
        """
        row = (await self.db.execute(
            select(Section, SchoolClass.session_id)
            .join(SchoolClass, SchoolClass.id == Section.class_id)
            .where(
                Section.id == section_id,
                Section.id.in_(valid_sections(school_id)),
            )
        )).one_or_none()
        if row is None:
            raise not_found("Section not found in this school")
        return row

    async def _validate_student(
        self, school_id: uuid.UUID, student_id: uuid.UUID, *, active: bool = True,
    ) -> None:
        user = await self.db.scalar(
            select(User)
            .where(User.id == student_id, User.school_id == school_id, (User.is_active.is_(True) if active else True))
            .join(User.roles)
            .where(Role.code == SystemRole.STUDENT.value)
        )
        if user is None:
            raise bad_request("User is not a student in this school")

    # ----------------------------- enrollment ---------------------------- #

    async def enroll(
        self, school_id: uuid.UUID, section_id: uuid.UUID, data: schemas.EnrollIn
    ) -> StudentEnrollment:
        _, class_session_id = await self._get_enrollment_section(school_id, section_id)
        await self._validate_student(school_id, data.student_id)
        await self._validate_session(school_id, data.session_id)

        # A class scoped to a school session carries that scope into every
        # enrollment.  Omitting it is convenient for admission forms, while
        # supplying another valid local session must never silently detach a
        # student from the class's academic year.
        if class_session_id is not None and data.session_id not in (None, class_session_id):
            raise bad_request("Enrollment session must match the section's class session")
        enrollment_session_id = data.session_id or class_session_id

        existing = await self.db.scalar(
            select(StudentEnrollment).where(
                StudentEnrollment.section_id == section_id,
                StudentEnrollment.student_id == data.student_id,
            )
        )
        if existing is not None:
            if existing.school_id != school_id:
                raise bad_request("Enrollment ownership is inconsistent")
            await self._validate_session(school_id, existing.session_id)

            # Repeating an admission request must be a no-op.  In particular,
            # do not let a retry with a different session rewrite an active
            # enrollment and change the student's historical placement.
            if existing.status == EnrollmentStatus.ACTIVE.value:
                if enrollment_session_id is not None and existing.session_id != enrollment_session_id:
                    raise bad_request("Student already has an active enrollment with a different session")
                return existing

            existing.status = EnrollmentStatus.ACTIVE.value
            existing.session_id = enrollment_session_id
            # Backfill a roll number for enrollments created before the field
            # existed (or re-activated ones that never got one).
            if existing.roll_number is None:
                existing.roll_number = await self._next_roll_number(section_id)
            await self.db.flush()
            return existing
        enrollment = StudentEnrollment(
            school_id=school_id,
            section_id=section_id,
            student_id=data.student_id,
            session_id=enrollment_session_id,
            status=EnrollmentStatus.ACTIVE.value,
            roll_number=await self._next_roll_number(section_id),
        )
        self.db.add(enrollment)
        await self.db.flush()
        return enrollment

    async def _validate_session(self, school_id, session_id):
        if session_id is not None and await self.db.scalar(select(AcademicSession.id).where(
            AcademicSession.id == session_id, AcademicSession.school_id == school_id,
        )) is None:
            raise not_found("Academic session not found in this school")

    async def _validate_subject(self, school_id, subject_id):
        if subject_id is not None and await self.db.scalar(select(Subject.id).where(
            Subject.id == subject_id, Subject.school_id == school_id,
        )) is None:
            raise not_found("Subject not found in this school")

    async def _next_roll_number(self, section_id: uuid.UUID) -> int:
        """The next sequential roll number for a section: max existing + 1,
        starting at 1. Roll numbers are unique within a section."""
        current_max = await self.db.scalar(
            select(func.max(StudentEnrollment.roll_number)).where(
                StudentEnrollment.section_id == section_id,
            )
        )
        return (current_max or 0) + 1

    async def list_enrollments(
        self, school_id: uuid.UUID, section_id: uuid.UUID
    ) -> list[schemas.EnrollmentOut]:
        """Active enrollments with the student's name resolved.

        The name is joined in so a marking roster renders from this single
        call — otherwise the client would have to fetch each student
        separately just to show who it is marking.
        """
        await self._get_section(school_id, section_id)
        rows = (await self.db.execute(
            select(StudentEnrollment, User.full_name)
            .join(User, User.id == StudentEnrollment.student_id)
            .where(
                StudentEnrollment.section_id == section_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                StudentEnrollment.school_id == school_id,
                or_(StudentEnrollment.session_id.is_(None), StudentEnrollment.session_id.in_(
                    select(AcademicSession.id).where(AcademicSession.school_id == school_id))),
                User.id.in_(enrolled_students(school_id, [section_id])),
            )
            .order_by(StudentEnrollment.roll_number.nulls_last(), User.full_name)
        )).all()
        return [
            schemas.EnrollmentOut(
                id=e.id,
                school_id=e.school_id,
                section_id=e.section_id,
                student_id=e.student_id,
                session_id=e.session_id,
                status=e.status,
                roll_number=e.roll_number,
                student_name=name,
            )
            for e, name in rows
        ]

    async def unenroll(
        self, school_id: uuid.UUID, section_id: uuid.UUID, student_id: uuid.UUID
    ) -> None:
        await self._get_section(school_id, section_id)
        enrollment = await self.db.scalar(
            select(StudentEnrollment).where(
                StudentEnrollment.section_id == section_id,
                StudentEnrollment.student_id == student_id,
            )
        )
        if enrollment is None or enrollment.school_id != school_id:
            raise not_found("Enrollment not found")
        await self._validate_student(school_id, student_id, active=False)
        await self._validate_session(school_id, enrollment.session_id)
        await self.db.delete(enrollment)
        await self.db.flush()

    async def _enrolled_student_ids(self, school_id, section_id) -> set[uuid.UUID]:
        return set((await self.db.scalars(
            enrolled_students(school_id, [section_id]).where(
                StudentEnrollment.student_id.in_(role_ids(school_id, SystemRole.STUDENT.value, active=True)),
                or_(StudentEnrollment.session_id.is_(None), StudentEnrollment.session_id.in_(
                    select(AcademicSession.id).where(AcademicSession.school_id == school_id))),
            )
        )).all())

    # -------------------------- marking authority ------------------------ #

    async def _is_teacher_only(self, user_id: uuid.UUID) -> bool:
        """True when the user holds the teacher role and no admin role.

        Headmasters and super admins bypass the class-teacher/subject-teacher
        rules entirely; the restrictions exist to stop one teacher marking
        another teacher's register, not to limit school leadership.
        """
        result = await self.db.execute(
            select(Role.code).join(Role.users).where(User.id == user_id)
        )
        codes = set(result.scalars().all())
        if codes & {SystemRole.SUPER_ADMIN.value, SystemRole.HEADMASTER.value}:
            return False
        return SystemRole.TEACHER.value in codes

    async def _authorize_marking(
        self,
        school_id: uuid.UUID,
        section: Section,
        data: schemas.AttendanceMarkRequest,
        marked_by: uuid.UUID,
    ) -> None:
        """Enforce which teacher may mark which kind of attendance.

        * Daily register (no subject) — only the section's class teacher.
        * Subject/period attendance — any teacher timetabled to teach that
          subject to that section.
        """
        if not await self._is_teacher_only(marked_by):
            return

        if data.is_daily:
            if section.class_teacher_id != marked_by:
                raise forbidden(
                    "Only this section's class teacher can mark the daily register. "
                    "Mark subject attendance instead by supplying subject_id."
                )
            return

        subject = await self.db.get(Subject, data.subject_id)
        if subject is None or subject.school_id != school_id:
            raise not_found("Subject not found in this school")

        teaches = await self.db.scalar(
            select(TimetableSlot.id).where(
                TimetableSlot.school_id == school_id,
                TimetableSlot.section_id == section.id,
                TimetableSlot.subject_id == data.subject_id,
                TimetableSlot.teacher_id == marked_by,
            )
        )
        # The section's class teacher may cover any subject for their own
        # section, which is what happens when a colleague is absent.
        if teaches is None and section.class_teacher_id != marked_by:
            raise forbidden("You are not timetabled to teach this subject to this section")

    # ----------------------------- attendance ---------------------------- #

    async def mark(
        self, school_id: uuid.UUID, data: schemas.AttendanceMarkRequest, marked_by: uuid.UUID
    ) -> list[AttendanceRecord]:
        section = await self._get_section(school_id, data.section_id)
        await self._validate_subject(school_id, data.subject_id)
        if data.timetable_slot_id is not None:
            slot = await self.db.get(TimetableSlot, data.timetable_slot_id)
            if (data.is_daily or slot is None or slot.school_id != school_id
                    or slot.section_id != section.id or slot.subject_id != data.subject_id):
                raise bad_request("Timetable slot does not match this section and subject")
        await self._authorize_marking(school_id, section, data, marked_by)
        enrolled = await self._enrolled_student_ids(school_id, data.section_id)

        entry_ids = [e.student_id for e in data.entries]
        not_enrolled = [str(sid) for sid in entry_ids if sid not in enrolled]
        if not_enrolled:
            raise bad_request(
                f"These students are not enrolled in the section: {', '.join(not_enrolled)}"
            )
        if len(set(entry_ids)) != len(entry_ids):
            raise bad_request("Duplicate students in the same request")

        # Existing records for this date so we upsert. Scoped to the same
        # flavour: a daily mark must not overwrite a subject mark, or vice
        # versa, since both can exist for one student on one day.
        stmt = select(AttendanceRecord).where(
            AttendanceRecord.attendance_date == data.attendance_date,
            AttendanceRecord.student_id.in_(entry_ids),
        )
        stmt = stmt.where(
            AttendanceRecord.subject_id.is_(None)
            if data.is_daily
            else AttendanceRecord.subject_id == data.subject_id
        )
        # Uniqueness spans schools/sections. Reject an inconsistent collision
        # before any mutation rather than overwriting it or surfacing a DB error.
        existing = {r.student_id: r for r in (await self.db.execute(stmt.with_for_update())).scalars().all()}
        if any(r.school_id != school_id or r.section_id != data.section_id for r in existing.values()):
            raise bad_request("Attendance belongs to a different school or section")

        records: list[AttendanceRecord] = []
        newly_notifiable: list[tuple[uuid.UUID, str]] = []
        for entry in data.entries:
            row = existing.get(entry.student_id)
            previous_status = row.status if row is not None else None
            if row is None:
                row = AttendanceRecord(
                    school_id=school_id,
                    section_id=data.section_id,
                    student_id=entry.student_id,
                    attendance_date=data.attendance_date,
                    subject_id=data.subject_id,
                )
                self.db.add(row)
            row.section_id = data.section_id
            row.timetable_slot_id = data.timetable_slot_id
            row.period_label = data.period_label
            row.status = entry.status.value
            row.check_in_time = entry.check_in_time
            row.check_out_time = entry.check_out_time
            row.remarks = entry.remarks
            row.marked_by = marked_by
            records.append(row)

            # Only alert on a *change* into a notifying status, so correcting a
            # typo or re-saving the register does not re-message guardians.
            if entry.status.value in STATUS_EVENTS and previous_status != entry.status.value:
                newly_notifiable.append((entry.student_id, entry.status.value))

        await self.db.flush()
        await self._notify_guardians(school_id, data, newly_notifiable, marked_by)
        return records

    async def _notify_guardians(
        self,
        school_id: uuid.UUID,
        data: schemas.AttendanceMarkRequest,
        notifiable: list[tuple[uuid.UUID, str]],
        marked_by: uuid.UUID,
    ) -> None:
        """Alert guardians about absent/late marks, best-effort.

        Delivery must never fail the attendance save: a teacher who marked a
        register correctly should not see an error because Twilio was down.
        """
        if not notifiable:
            return
        # Imported here to avoid a circular import at module load.
        from app.modules.communication.service import CommunicationService

        comms = CommunicationService(self.db)
        subject_name = ""
        if data.subject_id is not None:
            subject = await self.db.get(Subject, data.subject_id)
            if subject is not None:
                subject_name = f" for {subject.name}"

        # Batch-load the students' names in one query instead of one `get` per
        # student — attendance is marked a whole class at a time, so this is the
        # difference between 1 and N queries on a hot write path.
        student_ids = [sid for sid, _ in notifiable]
        names_by_id = {
            uid: full_name
            for uid, full_name in (
                await self.db.execute(
                    select(User.id, User.full_name).where(User.id.in_(student_ids))
                )
            ).all()
        }
        for student_id, status_value in notifiable:
            name = names_by_id.get(student_id) or "Your child"
            label = status_value.replace("_", " ")
            period = f" ({data.period_label})" if data.period_label else ""
            try:
                await comms.notify_student_guardians(
                    school_id,
                    student_id,
                    event=STATUS_EVENTS[status_value],
                    title="Attendance alert",
                    body=(
                        f"{name} was marked {label}{subject_name}{period} "
                        f"on {data.attendance_date.isoformat()}."
                    ),
                    created_by=marked_by,
                )
            except Exception:
                # The delivery error can carry provider content/recipient data;
                # the notification itself already records its durable outcome.
                logger.warning("Guardian attendance alert enqueue failed")

    def visible_records(self, school_id):
        # Historical attendance survives withdrawal; only structurally valid
        # same-school references are returned, after the caller relationship gate.
        valid_slot = select(TimetableSlot.id).where(
            TimetableSlot.school_id == school_id,
            TimetableSlot.section_id == AttendanceRecord.section_id,
            TimetableSlot.subject_id == AttendanceRecord.subject_id,
        )
        return select(AttendanceRecord).where(
            AttendanceRecord.school_id == school_id,
            AttendanceRecord.section_id.in_(valid_sections(school_id)),
            AttendanceRecord.student_id.in_(role_ids(school_id, SystemRole.STUDENT.value)),
            or_(AttendanceRecord.subject_id.is_(None), AttendanceRecord.subject_id.in_(
                select(Subject.id).where(Subject.school_id == school_id))),
            or_(AttendanceRecord.timetable_slot_id.is_(None), AttendanceRecord.timetable_slot_id.in_(valid_slot)),
            or_(AttendanceRecord.marked_by.is_(None), AttendanceRecord.marked_by.in_(
                select(User.id).where(or_(User.school_id == school_id,
                    User.roles.any(Role.code == SystemRole.SUPER_ADMIN.value))))),
        )

    async def list_for_section_date(
        self,
        school_id: uuid.UUID,
        section_id: uuid.UUID,
        on_date: date,
        subject_id: uuid.UUID | None = None,
        daily_only: bool = False,
    ) -> list[AttendanceRecord]:
        """Records for a section on a date.

        Defaults to *everything* marked that day. Pass ``subject_id`` for one
        subject's period, or ``daily_only`` for just the class-teacher register.
        """
        await self._get_section(school_id, section_id)
        await self._validate_subject(school_id, subject_id)
        stmt = self.visible_records(school_id).where(
            AttendanceRecord.section_id == section_id,
            AttendanceRecord.attendance_date == on_date,
        )
        if subject_id is not None:
            stmt = stmt.where(AttendanceRecord.subject_id == subject_id)
        elif daily_only:
            stmt = stmt.where(AttendanceRecord.subject_id.is_(None))
        return list((await self.db.execute(stmt)).scalars().all())

    async def list_for_student(
        self,
        school_id: uuid.UUID,
        student_id: uuid.UUID,
        date_from: date | None = None,
        date_to: date | None = None,
        page: OffsetPage | None = None,
    ) -> list[AttendanceRecord]:
        if date_from is not None and date_to is not None and date_from > date_to:
            raise bad_request("date_from must not be after date_to")
        stmt = self.visible_records(school_id).where(
            AttendanceRecord.student_id == student_id,
        )
        if date_from is not None:
            stmt = stmt.where(AttendanceRecord.attendance_date >= date_from)
        if date_to is not None:
            stmt = stmt.where(AttendanceRecord.attendance_date <= date_to)
        # Scope and date constraints must precede the page. Otherwise an
        # invisible legacy/foreign row could consume a slot and hide a valid
        # attendance record from the caller.
        stmt = stmt.order_by(AttendanceRecord.attendance_date, AttendanceRecord.id)
        if page is not None:
            stmt = page.apply(stmt)
        return list((await self.db.execute(stmt)).scalars().all())

    async def summary(
        self,
        school_id: uuid.UUID,
        section_id: uuid.UUID,
        on_date: date,
        subject_id: uuid.UUID | None = None,
    ) -> schemas.AttendanceSummary:
        """Status counts for a section on a date.

        With no ``subject_id`` this summarises the daily register only, so the
        totals stay comparable to the pre-subject-attendance behaviour instead
        of multiplying by the number of periods taught.
        """
        records = await self.list_for_section_date(
            school_id, section_id, on_date, subject_id, daily_only=subject_id is None
        )
        counts = {s.value: 0 for s in AttendanceStatus}
        for r in records:
            counts[r.status] = counts.get(r.status, 0) + 1
        return schemas.AttendanceSummary(
            section_id=section_id,
            attendance_date=on_date,
            subject_id=subject_id,
            total=len(records),
            counts=counts,
        )
