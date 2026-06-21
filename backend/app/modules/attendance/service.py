"""Attendance Service: enrollment + daily attendance marking and queries."""
import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import AttendanceStatus, EnrollmentStatus, SystemRole
from app.core.exceptions import bad_request, not_found
from app.models.academic import Section, StudentEnrollment
from app.models.attendance import AttendanceRecord
from app.models.role import Role
from app.models.school import School
from app.models.user import User
from app.modules.attendance import schemas


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

    # ----------------------------- attendance ---------------------------- #

    async def mark(
        self, school_id: uuid.UUID, data: schemas.AttendanceMarkRequest, marked_by: uuid.UUID
    ) -> list[AttendanceRecord]:
        await self._get_section(school_id, data.section_id)
        enrolled = await self._enrolled_student_ids(data.section_id)

        entry_ids = [e.student_id for e in data.entries]
        not_enrolled = [str(sid) for sid in entry_ids if sid not in enrolled]
        if not_enrolled:
            raise bad_request(
                f"These students are not enrolled in the section: {', '.join(not_enrolled)}"
            )
        if len(set(entry_ids)) != len(entry_ids):
            raise bad_request("Duplicate students in the same request")

        # Existing records for this date so we upsert.
        existing_rows = await self.db.execute(
            select(AttendanceRecord).where(
                AttendanceRecord.attendance_date == data.attendance_date,
                AttendanceRecord.student_id.in_(entry_ids),
            )
        )
        existing = {r.student_id: r for r in existing_rows.scalars().all()}

        records: list[AttendanceRecord] = []
        for entry in data.entries:
            row = existing.get(entry.student_id)
            if row is None:
                row = AttendanceRecord(
                    school_id=school_id,
                    section_id=data.section_id,
                    student_id=entry.student_id,
                    attendance_date=data.attendance_date,
                )
                self.db.add(row)
            row.section_id = data.section_id
            row.status = entry.status.value
            row.check_in_time = entry.check_in_time
            row.check_out_time = entry.check_out_time
            row.remarks = entry.remarks
            row.marked_by = marked_by
            records.append(row)

        await self.db.flush()
        return records

    async def list_for_section_date(
        self, school_id: uuid.UUID, section_id: uuid.UUID, on_date: date
    ) -> list[AttendanceRecord]:
        await self._get_section(school_id, section_id)
        result = await self.db.execute(
            select(AttendanceRecord).where(
                AttendanceRecord.section_id == section_id,
                AttendanceRecord.attendance_date == on_date,
            )
        )
        return list(result.scalars().all())

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
        self, school_id: uuid.UUID, section_id: uuid.UUID, on_date: date
    ) -> schemas.AttendanceSummary:
        records = await self.list_for_section_date(school_id, section_id, on_date)
        counts = {s.value: 0 for s in AttendanceStatus}
        for r in records:
            counts[r.status] = counts.get(r.status, 0) + 1
        return schemas.AttendanceSummary(
            section_id=section_id,
            attendance_date=on_date,
            total=len(records),
            counts=counts,
        )
