"""Reporting & Analytics Service: read-only cross-module aggregation."""
import uuid
from datetime import date

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import AttendanceStatus, EnrollmentStatus, ResultStatus, SystemRole
from app.models.academic import Section, SchoolClass, StudentEnrollment, Subject
from app.models.associations import guardian_students
from app.models.attendance import AttendanceRecord
from app.models.examination import Exam, ExamCategory, ExamResult
from app.models.homework import Assignment, Submission
from app.models.quiz import Quiz, QuizAttempt
from app.models.role import Role
from app.models.school import AcademicSession
from app.models.user import User
from app.modules.fees.service import FeeService
from app.modules.reports import schemas
from app.modules.academic.access import role_ids, valid_classes, valid_sections, valid_subjects
from app.modules.attendance.service import AttendanceService
from app.core.exceptions import bad_request, not_found


class ReportingService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    def _sections(self, school_id):
        return valid_sections(school_id).where(Section.class_id.in_(valid_classes(school_id)))

    def _enrollments(self, school_id):
        return select(StudentEnrollment).where(
            StudentEnrollment.school_id == school_id,
            StudentEnrollment.section_id.in_(self._sections(school_id)),
            StudentEnrollment.student_id.in_(role_ids(school_id, SystemRole.STUDENT.value)),
            StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            or_(StudentEnrollment.session_id.is_(None), StudentEnrollment.session_id.in_(
                select(AcademicSession.id).where(AcademicSession.school_id == school_id))),
        )

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
            select(func.count()).select_from(SchoolClass).where(SchoolClass.id.in_(valid_classes(school_id)))
        ) or 0
        sections = await self.db.scalar(
            select(func.count()).select_from(Section).where(Section.id.in_(self._sections(school_id)))
        ) or 0
        subjects = await self.db.scalar(
            select(func.count()).select_from(Subject).where(Subject.id.in_(valid_subjects(school_id)))
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
        if section_id is not None and await self.db.scalar(
            valid_sections(school_id).where(Section.id == section_id)
        ) is None:
            raise not_found("Section not found in this school")
        if date_from is not None and date_to is not None and date_from > date_to:
            raise bad_request("date_from must not be after date_to")
        # Reuse the register's structural boundary so JSON and CSV agree with
        # the authorized source rows. Unknown legacy statuses are not CSV labels.
        stmt = AttendanceService(self.db).visible_records(school_id).with_only_columns(
            AttendanceRecord.status, func.count(),
        ).where(AttendanceRecord.status.in_([s.value for s in AttendanceStatus]))
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
            (await self.db.execute(select(Exam).where(
                Exam.school_id == school_id, Exam.class_id.in_(valid_classes(school_id)),
                or_(Exam.session_id.is_(None), Exam.session_id.in_(select(AcademicSession.id).where(AcademicSession.school_id == school_id))),
                or_(Exam.category_id.is_(None), Exam.category_id.in_(select(ExamCategory.id).where(ExamCategory.school_id == school_id))),
            ))).scalars().all()
        )
        summaries: list[schemas.ExamSummary] = []
        for exam in exams:
            rows = list(
                (
                    await self.db.execute(
                        select(ExamResult).where(
                            ExamResult.exam_id == exam.id, ExamResult.published.is_(True),
                            ExamResult.school_id == school_id,
                            ExamResult.student_id.in_(role_ids(school_id, SystemRole.STUDENT.value)),
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
            (await self.db.execute(select(SchoolClass).where(SchoolClass.id.in_(valid_classes(school_id)))))
            .scalars()
            .all()
        )
        # Bounded grouped queries for the whole school, not per-class COUNTs.
        # A separate distinct total avoids double-counting across classes.
        section_counts = {
            class_id: n
            for class_id, n in (
                await self.db.execute(
                    select(Section.class_id, func.count())
                    .select_from(Section)
                    .join(SchoolClass, SchoolClass.id == Section.class_id)
                    .where(Section.id.in_(self._sections(school_id)))
                    .group_by(Section.class_id)
                )
            ).all()
        }
        student_counts = {
            class_id: n
            for class_id, n in (
                await self.db.execute(
                    select(
                        Section.class_id,
                        func.count(func.distinct(StudentEnrollment.student_id)),
                    )
                    .select_from(StudentEnrollment)
                    .join(Section, Section.id == StudentEnrollment.section_id)
                    .join(SchoolClass, SchoolClass.id == Section.class_id)
                    .where(
                        StudentEnrollment.id.in_(self._enrollments(school_id).with_only_columns(StudentEnrollment.id)),
                    )
                    .group_by(Section.class_id)
                )
            ).all()
        }

        out: list[schemas.ClassEnrollment] = []
        for cls in classes:
            students = student_counts.get(cls.id, 0)
            out.append(
                schemas.ClassEnrollment(
                    class_id=cls.id,
                    class_name=cls.name,
                    sections=section_counts.get(cls.id, 0),
                    students=students,
                )
            )
        # A student enrolled in two classes is one school-wide student; each
        # class still counts them once. Historical/inactive user accounts remain
        # counted if their enrollment is active, preserving existing semantics.
        total_students = await self.db.scalar(self._enrollments(school_id).with_only_columns(
            func.count(func.distinct(StudentEnrollment.student_id)),
        )) or 0
        return schemas.EnrollmentReport(
            school_id=school_id, total_students=total_students, classes=out
        )

    # -------------------------- per-student report -------------------------- #

    async def student_report(
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> schemas.StudentReport:
        """Cross-module 360-degree report for one student."""
        student = await self.db.scalar(select(User).where(
            User.id == student_id, User.id.in_(role_ids(school_id, SystemRole.STUDENT.value)),
        ))
        if student is None:
            raise not_found("Student not found in this school")
        name = student.full_name if student else ""
        avatar_url = (student.profile_metadata or {}).get("avatar_url") if student else None

        # Active sections (assignment scope).  Reuse the school-wide enrollment
        # boundary so a legacy enrollment pointing to another school's session
        # cannot make assignments appear in this student's report.
        section_ids = [
            r[0]
            for r in (await self.db.execute(
                self._enrollments(school_id)
                .where(StudentEnrollment.student_id == student_id)
                .with_only_columns(StudentEnrollment.section_id)
            )).all()
        ]

        # Attendance summary.
        att_counts = {
            status: count
            for status, count in (await self.db.execute(
                select(AttendanceRecord.status, func.count())
                .where(
                    AttendanceRecord.school_id == school_id,
                    AttendanceRecord.student_id == student_id,
                    AttendanceRecord.section_id.in_(valid_sections(school_id)),
                    (AttendanceRecord.subject_id.is_(None) | AttendanceRecord.subject_id.in_(
                        select(Subject.id).where(Subject.school_id == school_id)
                    )),
                )
                .group_by(AttendanceRecord.status)
            )).all()
        }
        present = att_counts.get(AttendanceStatus.PRESENT.value, 0)
        absent = att_counts.get(AttendanceStatus.ABSENT.value, 0)
        late = att_counts.get(AttendanceStatus.LATE.value, 0)
        excused = att_counts.get(AttendanceStatus.EXCUSED.value, 0)
        att_total = sum(att_counts.values())
        att_pct = round((present + late + excused) * 100 / att_total, 1) if att_total else 0.0
        attendance = schemas.ReportAttendance(
            present=present, absent=absent, late=late, excused=excused,
            total=att_total, percentage=att_pct,
        )

        # Published exam results.
        exams: list[schemas.ReportExam] = []
        exam_percents: list[float] = []
        exam_points = 0.0
        for res, exam_name in (await self.db.execute(
            select(ExamResult, Exam.name)
            .join(Exam, Exam.id == ExamResult.exam_id)
            .where(
                ExamResult.school_id == school_id,
                ExamResult.student_id == student_id,
                ExamResult.published.is_(True),
                Exam.school_id == school_id,
                Exam.class_id.in_(select(SchoolClass.id).where(SchoolClass.school_id == school_id)),
            )
            .order_by(ExamResult.published_at.desc().nullslast())
        )).all():
            exams.append(schemas.ReportExam(
                exam_name=exam_name, percentage=res.percentage,
                grade=res.grade, status=res.status,
            ))
            exam_percents.append(res.percentage)
            exam_points += res.total_marks
        exam_avg = round(sum(exam_percents) / len(exam_percents), 1) if exam_percents else 0.0

        # Assignments: assigned to the student's sections vs submitted.
        assignments_total = 0
        if section_ids:
            assignments_total = (await self.db.scalar(
                select(func.count()).select_from(Assignment).where(
                    Assignment.school_id == school_id,
                    Assignment.section_id.in_(section_ids),
                    Assignment.subject_id.in_(select(Subject.id).where(Subject.school_id == school_id)),
                )
            )) or 0
        assignments_submitted = (await self.db.scalar(
            select(func.count()).select_from(Submission).join(Assignment, Assignment.id == Submission.assignment_id).where(
                Submission.school_id == school_id,
                Submission.student_id == student_id,
                Assignment.school_id == school_id,
                Assignment.section_id.in_(section_ids),
                Assignment.subject_id.in_(select(Subject.id).where(Subject.school_id == school_id)),
            )
        )) or 0

        # Quiz attempts (submitted).
        quizzes: list[schemas.ReportQuiz] = []
        quiz_scores: list[float] = []
        quiz_points = 0.0
        for attempt, title in (await self.db.execute(
            select(QuizAttempt, Quiz.title)
            .join(Quiz, Quiz.id == QuizAttempt.quiz_id)
            .where(
                QuizAttempt.school_id == school_id,
                QuizAttempt.student_id == student_id,
                QuizAttempt.submitted_at.isnot(None),
                Quiz.school_id == school_id,
                Quiz.section_id.in_(valid_sections(school_id)),
                Quiz.subject_id.in_(select(Subject.id).where(Subject.school_id == school_id)),
            )
        )).all():
            quizzes.append(schemas.ReportQuiz(title=title, score=attempt.score))
            if attempt.score is not None:
                quiz_scores.append(attempt.score)
                quiz_points += attempt.score
        quiz_avg = round(sum(quiz_scores) / len(quiz_scores), 1) if quiz_scores else None

        # Linked guardians (for messaging / meeting requests).
        guardians = [
            schemas.ReportGuardian(id=gid, name=gname)
            for gid, gname in (await self.db.execute(
                select(guardian_students.c.guardian_id, User.full_name)
                .join(User, User.id == guardian_students.c.guardian_id)
                .where(
                    guardian_students.c.school_id == school_id,
                    guardian_students.c.student_id == student_id,
                    User.id.in_(role_ids(school_id, SystemRole.GUARDIAN.value, active=True)),
                )
            )).all()
        ]

        return schemas.StudentReport(
            student_id=student_id,
            student_name=name,
            avatar_url=avatar_url,
            guardians=guardians,
            attendance=attendance,
            exams=exams,
            exam_average=exam_avg,
            assignments_total=assignments_total,
            assignments_submitted=assignments_submitted,
            quizzes=quizzes,
            quiz_average=quiz_avg,
            total_points=round(exam_points + quiz_points, 1),
        )
