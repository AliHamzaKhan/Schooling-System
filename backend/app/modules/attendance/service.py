"""Attendance Service: enrollment, daily + subject attendance, and queries."""
import logging
import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import (
    AttendanceStatus,
    EnrollmentStatus,
    NotificationEvent,
    SystemRole,
)
from app.core.exceptions import bad_request, forbidden, not_found
from app.models.academic import Section, StudentEnrollment, Subject, TimetableSlot
from app.models.attendance import AttendanceRecord
from app.models.role import Role
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
        section = await self.db.get(Section, section_id)
        if section is None or section.school_id != school_id:
            raise not_found("Section not found in this school")
        return section

    async def _validate_student(self, school_id: uuid.UUID, student_id: uuid.UUID) -> None:
        user = await self.db.scalar(
            select(User)
            .where(User.id == student_id, User.school_id == school_id)
            .join(User.roles)
            .where(Role.code == SystemRole.STUDENT.value)
        )
        if user is None:
            raise bad_request("User is not a student in this school")

    # ----------------------------- enrollment ---------------------------- #

    async def enroll(
        self, school_id: uuid.UUID, section_id: uuid.UUID, data: schemas.EnrollIn
    ) -> StudentEnrollment:
        await self._get_section(school_id, section_id)
        await self._validate_student(school_id, data.student_id)
        existing = await self.db.scalar(
            select(StudentEnrollment).where(
                StudentEnrollment.section_id == section_id,
                StudentEnrollment.student_id == data.student_id,
            )
        )
        if existing is not None:
            existing.status = EnrollmentStatus.ACTIVE.value
            if data.session_id is not None:
                existing.session_id = data.session_id
            await self.db.flush()
            return existing
        enrollment = StudentEnrollment(
            school_id=school_id,
            section_id=section_id,
            student_id=data.student_id,
            session_id=data.session_id,
            status=EnrollmentStatus.ACTIVE.value,
        )
        self.db.add(enrollment)
        await self.db.flush()
        return enrollment

    async def list_enrollments(
        self, school_id: uuid.UUID, section_id: uuid.UUID
    ) -> list[StudentEnrollment]:
        await self._get_section(school_id, section_id)
        result = await self.db.execute(
            select(StudentEnrollment).where(
                StudentEnrollment.section_id == section_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
        )
        return list(result.scalars().all())

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
        if enrollment is None:
            raise not_found("Enrollment not found")
        await self.db.delete(enrollment)
        await self.db.flush()

    async def _enrolled_student_ids(self, section_id: uuid.UUID) -> set[uuid.UUID]:
        result = await self.db.execute(
            select(StudentEnrollment.student_id).where(
                StudentEnrollment.section_id == section_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
        )
        return set(result.scalars().all())

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
        await self._authorize_marking(school_id, section, data, marked_by)
        enrolled = await self._enrolled_student_ids(data.section_id)

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
        existing = {r.student_id: r for r in (await self.db.execute(stmt)).scalars().all()}

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

        for student_id, status_value in notifiable:
            student = await self.db.get(User, student_id)
            name = student.full_name if student is not None else "Your child"
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
                logger.exception(
                    "Guardian attendance alert failed for student %s", student_id
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
        stmt = select(AttendanceRecord).where(
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
    ) -> list[AttendanceRecord]:
        stmt = select(AttendanceRecord).where(
            AttendanceRecord.school_id == school_id,
            AttendanceRecord.student_id == student_id,
        )
        if date_from is not None:
            stmt = stmt.where(AttendanceRecord.attendance_date >= date_from)
        if date_to is not None:
            stmt = stmt.where(AttendanceRecord.attendance_date <= date_to)
        stmt = stmt.order_by(AttendanceRecord.attendance_date)
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
