"""Reporting & Analytics Service: read-only cross-module aggregation."""
import uuid
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import AttendanceStatus, EnrollmentStatus, ResultStatus, SystemRole
from app.models.academic import Section, SchoolClass, StudentEnrollment, Subject
from app.models.attendance import AttendanceRecord
from app.models.examination import Exam, ExamResult
from app.models.role import Role
from app.models.school import AcademicSession
from app.models.user import User
from app.modules.fees.service import FeeService
from app.modules.reports import schemas


class ReportingService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ----------------------------- overview ------------------------------ #

    async def _count_role(self, school_id: uuid.UUID, role_code: str) -> int:
        return await self.db.scalar(
            select(func.count(func.distinct(User.id)))
            .select_from(User)
            .join(User.roles)
            .where(User.school_id == school_id, Role.code == role_code)
        ) or 0

    async def overview(self, school_id: uuid.UUID) -> schemas.SchoolOverview:
        students = await self._count_role(school_id, SystemRole.STUDENT.value)
        teachers = await self._count_role(school_id, SystemRole.TEACHER.value)
        guardians = await self._count_role(school_id, SystemRole.GUARDIAN.value)
        total_users = await self.db.scalar(
            select(func.count()).select_from(User).where(User.school_id == school_id)
        ) or 0
        classes = await self.db.scalar(
            select(func.count()).select_from(SchoolClass).where(SchoolClass.school_id == school_id)
        ) or 0
        sections = await self.db.scalar(
            select(func.count()).select_from(Section).where(Section.school_id == school_id)
        ) or 0
        subjects = await self.db.scalar(
            select(func.count()).select_from(Subject).where(Subject.school_id == school_id)
        ) or 0
        active_session = await self.db.scalar(
            select(AcademicSession.name).where(
                AcademicSession.school_id == school_id, AcademicSession.is_active.is_(True)
            )
        )
        return schemas.SchoolOverview(
            school_id=school_id,
            students=students,
            teachers=teachers,
            guardians=guardians,
            total_users=total_users,
            classes=classes,
            sections=sections,
            subjects=subjects,
            active_session=active_session,
        )

    # ---------------------------- attendance ----------------------------- #

    async def attendance(
        self,
        school_id: uuid.UUID,
        section_id: uuid.UUID | None = None,
        date_from: date | None = None,
        date_to: date | None = None,
    ) -> schemas.AttendanceReport:
        stmt = select(AttendanceRecord.status, func.count()).where(
            AttendanceRecord.school_id == school_id
        )
        if section_id is not None:
            stmt = stmt.where(AttendanceRecord.section_id == section_id)
        if date_from is not None:
            stmt = stmt.where(AttendanceRecord.attendance_date >= date_from)
        if date_to is not None:
            stmt = stmt.where(AttendanceRecord.attendance_date <= date_to)
        stmt = stmt.group_by(AttendanceRecord.status)

        counts = {s.value: 0 for s in AttendanceStatus}
        for status_val, n in (await self.db.execute(stmt)).all():
            counts[status_val] = n
        total = sum(counts.values())
        present_like = counts.get(AttendanceStatus.PRESENT.value, 0) + counts.get(
            AttendanceStatus.LATE.value, 0
        )
        present_rate = round((present_like / total) * 100, 2) if total else 0.0
        return schemas.AttendanceReport(
            school_id=school_id,
            section_id=section_id,
            total_records=total,
            counts=counts,
            present_rate=present_rate,
        )

    # ----------------------------- academic ------------------------------ #

    async def academic(self, school_id: uuid.UUID) -> schemas.AcademicReport:
        exams = list(
            (await self.db.execute(select(Exam).where(Exam.school_id == school_id))).scalars().all()
        )
        summaries: list[schemas.ExamSummary] = []
        for exam in exams:
            rows = list(
                (
                    await self.db.execute(
                        select(ExamResult).where(
                            ExamResult.exam_id == exam.id, ExamResult.published.is_(True)
                        )
                    )
                )
                .scalars()
                .all()
            )
            if not rows:
                continue
            passed = sum(1 for r in rows if r.status == ResultStatus.PASS.value)
            failed = len(rows) - passed
            avg = round(sum(r.percentage for r in rows) / len(rows), 2)
            top = round(max(r.percentage for r in rows), 2)
            summaries.append(
                schemas.ExamSummary(
                    exam_id=exam.id,
                    name=exam.name,
                    results=len(rows),
                    passed=passed,
                    failed=failed,
                    average_percentage=avg,
                    top_percentage=top,
                )
            )
        return schemas.AcademicReport(school_id=school_id, exams=summaries)

    # ------------------------------ finance ------------------------------ #

    async def finance(self, school_id: uuid.UUID) -> schemas.FinanceReport:
        fee = await FeeService(self.db).report(school_id)
        rate = round((fee.total_collected / fee.total_billed) * 100, 2) if fee.total_billed else 0.0
        return schemas.FinanceReport(
            school_id=school_id,
            total_invoices=fee.total_invoices,
            total_billed=fee.total_billed,
            total_collected=fee.total_collected,
            total_outstanding=fee.total_outstanding,
            overdue_count=fee.overdue_count,
            collection_rate=rate,
        )

    # ---------------------------- enrollment ----------------------------- #

    async def enrollment(self, school_id: uuid.UUID) -> schemas.EnrollmentReport:
        classes = list(
            (await self.db.execute(select(SchoolClass).where(SchoolClass.school_id == school_id)))
            .scalars()
            .all()
        )
        out: list[schemas.ClassEnrollment] = []
        total_students = 0
        for cls in classes:
            sections = await self.db.scalar(
                select(func.count()).select_from(Section).where(Section.class_id == cls.id)
            ) or 0
            students = await self.db.scalar(
                select(func.count(func.distinct(StudentEnrollment.student_id)))
                .select_from(StudentEnrollment)
                .join(Section, Section.id == StudentEnrollment.section_id)
                .where(
                    Section.class_id == cls.id,
                    StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                )
            ) or 0
            total_students += students
            out.append(
                schemas.ClassEnrollment(
                    class_id=cls.id, class_name=cls.name, sections=sections, students=students
                )
            )
        return schemas.EnrollmentReport(
            school_id=school_id, total_students=total_students, classes=out
        )
