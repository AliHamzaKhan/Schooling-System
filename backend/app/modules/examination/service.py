"""Examination Service: exams, papers, marks entry, result computation."""
import uuid
from datetime import datetime, timezone

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.constants import grade_for
from app.core.enums import (
    AudienceType,
    Channel,
    EnrollmentStatus,
    ExamStatus,
    ResultStatus,
)
from app.core.exceptions import bad_request, not_found
from app.core.pagination import OffsetPage
from app.models.academic import Section, SchoolClass, StudentEnrollment, Subject
from app.models.examination import (
    Exam,
    ExamCategory,
    ExamResult,
    ExamSeat,
    ExamSubject,
    Mark,
)
from app.models.user import User
from app.models.school import AcademicSession
from app.modules.academic.access import role_ids, valid_classes, valid_sections, valid_subjects
from app.core.enums import Module, PermissionAction as PA
from app.modules.permissions.service import PermissionService
from app.modules.examination import schemas


class ExaminationService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

    async def _get_scoped(self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    async def _student_ids(self, school_id: uuid.UUID, class_id: uuid.UUID) -> set[uuid.UUID]:
        return set((await self.db.scalars(
            select(StudentEnrollment.student_id)
            .join(Section, Section.id == StudentEnrollment.section_id)
            .where(
                StudentEnrollment.school_id == school_id,
                Section.school_id == school_id,
                Section.class_id == class_id,
                Section.id.in_(valid_sections(school_id)),
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                StudentEnrollment.student_id.in_(role_ids(school_id, "student", active=True)),
                or_(StudentEnrollment.session_id.is_(None), StudentEnrollment.session_id.in_(
                    select(AcademicSession.id).where(AcademicSession.school_id == school_id))),
            )
        )).all())

    async def _validate_exam_links(
        self, school_id: uuid.UUID, class_id: uuid.UUID,
        category_id: uuid.UUID | None = None, session_id: uuid.UUID | None = None,
    ) -> None:
        if await self.db.scalar(valid_classes(school_id).where(SchoolClass.id == class_id)) is None:
            raise not_found("Class not found in this school")
        if category_id is not None:
            await self._get_scoped(ExamCategory, school_id, category_id, "Exam category")
        if session_id is not None and await self.db.scalar(select(AcademicSession.id).where(
            AcademicSession.id == session_id, AcademicSession.school_id == school_id,
        )) is None:
            raise not_found("Academic session not found in this school")

    async def _get_exam(self, school_id: uuid.UUID, exam_id: uuid.UUID) -> Exam:
        exam = await self._get_scoped(Exam, school_id, exam_id, "Exam")
        await self._validate_exam_links(school_id, exam.class_id, exam.category_id, exam.session_id)
        return exam

    async def _get_paper(self, school_id: uuid.UUID, paper_id: uuid.UUID) -> ExamSubject:
        paper = await self._get_scoped(ExamSubject, school_id, paper_id, "Exam paper")
        exam = await self._get_exam(school_id, paper.exam_id)
        if await self.db.scalar(valid_subjects(school_id).where(Subject.id == paper.subject_id)) is None:
            raise not_found("Subject not found in this school")
        if exam.school_id != paper.school_id:
            raise not_found("Exam paper not found in this school")
        return paper

    @staticmethod
    def _validate_exam_dates(start_date, end_date) -> None:
        if start_date is not None and end_date is not None and end_date < start_date:
            raise bad_request("end_date cannot be before start_date")

    @staticmethod
    def _validate_paper_date(exam: Exam, exam_date) -> None:
        if exam_date is None:
            return
        if exam.start_date is not None and exam_date < exam.start_date:
            raise bad_request("exam_date cannot be before the exam start_date")
        if exam.end_date is not None and exam_date > exam.end_date:
            raise bad_request("exam_date cannot be after the exam end_date")

    async def _validate_exam_window_against_papers(
        self,
        school_id: uuid.UUID,
        exam_id: uuid.UUID,
        start_date,
        end_date,
    ) -> None:
        """Keep an edited exam window consistent with its existing dated papers."""
        if start_date is not None:
            before_start = await self.db.scalar(
                select(ExamSubject.id).where(
                    ExamSubject.school_id == school_id,
                    ExamSubject.exam_id == exam_id,
                    ExamSubject.exam_date.is_not(None),
                    ExamSubject.exam_date < start_date,
                )
            )
            if before_start is not None:
                raise bad_request(
                    "exam start_date cannot be after an existing paper's exam_date"
                )
        if end_date is not None:
            after_end = await self.db.scalar(
                select(ExamSubject.id).where(
                    ExamSubject.school_id == school_id,
                    ExamSubject.exam_id == exam_id,
                    ExamSubject.exam_date.is_not(None),
                    ExamSubject.exam_date > end_date,
                )
            )
            if after_end is not None:
                raise bad_request(
                    "exam end_date cannot be before an existing paper's exam_date"
                )

    # -------------------------- exam categories -------------------------- #

    async def create_category(
        self, school_id: uuid.UUID, data: schemas.ExamCategoryCreate
    ) -> ExamCategory:
        existing = await self.db.scalar(
            select(ExamCategory).where(
                ExamCategory.school_id == school_id,
                ExamCategory.name == data.name,
            )
        )
        if existing is not None:
            raise bad_request(f'An exam category named "{data.name}" already exists')
        category = ExamCategory(
            school_id=school_id,
            name=data.name,
            start_date=data.start_date,
            end_date=data.end_date,
        )
        self.db.add(category)
        await self.db.flush()
        return category

    async def list_categories(self, school_id: uuid.UUID) -> list[ExamCategory]:
        return list(
            (
                await self.db.execute(
                    select(ExamCategory)
                    .where(ExamCategory.school_id == school_id)
                    .order_by(ExamCategory.name)
                )
            )
            .scalars()
            .all()
        )

    async def update_category(
        self, school_id: uuid.UUID, category_id: uuid.UUID, data: schemas.ExamCategoryUpdate
    ) -> ExamCategory:
        category = await self._get_scoped(ExamCategory, school_id, category_id, "Exam category")
        payload = data.model_dump(exclude_unset=True)
        if "name" in payload and payload["name"] is not None:
            clash = await self.db.scalar(
                select(ExamCategory).where(
                    ExamCategory.school_id == school_id,
                    ExamCategory.name == payload["name"],
                    ExamCategory.id != category_id,
                )
            )
            if clash is not None:
                raise bad_request(f'An exam category named "{payload["name"]}" already exists')
        for field in ("name", "start_date", "end_date"):
            if field in payload:
                setattr(category, field, payload[field])
        if category.start_date and category.end_date and category.end_date < category.start_date:
            raise bad_request("end_date cannot be before start_date")
        await self.db.flush()
        return category

    async def delete_category(self, school_id: uuid.UUID, category_id: uuid.UUID) -> None:
        category = await self._get_scoped(ExamCategory, school_id, category_id, "Exam category")
        await self.db.delete(category)  # exams.category_id => SET NULL
        await self.db.flush()

    async def announce_category(
        self,
        school_id: uuid.UUID,
        category_id: uuid.UUID,
        data: schemas.ExamCategoryAnnounce,
        created_by: uuid.UUID,
    ) -> ExamCategory:
        """Push an announcement about the exam category to the whole school.

        Only allowed once the term has started (start_date reached), matching the
        Headmaster UI where the Announce button unlocks on the start date.
        """
        category = await self._get_scoped(ExamCategory, school_id, category_id, "Exam category")
        today = datetime.now(timezone.utc).date()
        if category.start_date is None or category.start_date > today:
            raise bad_request("This exam category can only be announced on or after its start date")

        title = data.title or f"{category.name} exams announced"
        if data.body:
            body = data.body
        else:
            when = ""
            if category.start_date and category.end_date:
                when = f" from {category.start_date.isoformat()} to {category.end_date.isoformat()}"
            elif category.start_date:
                when = f" starting {category.start_date.isoformat()}"
            body = (
                f"{category.name} examinations have been scheduled{when}. "
                "Please check the exam timetable for subject-wise dates."
            )

        # Imported here to avoid a circular import at module load.
        from app.modules.communication.schemas import BroadcastCreate
        from app.modules.communication.service import CommunicationService

        comms = CommunicationService(self.db)
        await comms.create_broadcast(
            school_id,
            BroadcastCreate(
                channel=Channel.PUSH,
                audience_type=AudienceType.ENTIRE_SCHOOL,
                title=title,
                body=body,
            ),
            created_by,
        )
        category.announced_at = datetime.now(timezone.utc)
        await self.db.flush()
        return category

    # ------------------------------- exams ------------------------------- #

    async def create_exam(self, school_id: uuid.UUID, data: schemas.ExamCreate) -> Exam:
        await self._validate_exam_links(school_id, data.class_id, data.category_id, data.session_id)
        self._validate_exam_dates(data.start_date, data.end_date)
        exam = Exam(
            school_id=school_id,
            class_id=data.class_id,
            category_id=data.category_id,
            session_id=data.session_id,
            name=data.name,
            status=ExamStatus.DRAFT.value,
            start_date=data.start_date,
            end_date=data.end_date,
        )
        self.db.add(exam)
        await self.db.flush()
        return exam

    async def list_exams(
        self,
        school_id: uuid.UUID,
        class_id: uuid.UUID | None = None,
        page: OffsetPage | None = None,
    ) -> list[Exam]:
        stmt = select(Exam).where(
            Exam.school_id == school_id,
            Exam.class_id.in_(valid_classes(school_id)),
            or_(Exam.session_id.is_(None), Exam.session_id.in_(select(AcademicSession.id).where(AcademicSession.school_id == school_id))),
            or_(Exam.category_id.is_(None), Exam.category_id.in_(select(ExamCategory.id).where(ExamCategory.school_id == school_id))),
        )
        if class_id is not None:
            if await self.db.scalar(valid_classes(school_id).where(SchoolClass.id == class_id)) is None:
                raise not_found("Class not found in this school")
            stmt = stmt.where(Exam.class_id == class_id)
        stmt = stmt.order_by(Exam.created_at.desc(), Exam.id.desc())
        if page is not None:
            stmt = page.apply(stmt)
        return list((await self.db.execute(stmt)).scalars().all())

    async def update_exam(
        self, school_id: uuid.UUID, exam_id: uuid.UUID, data: schemas.ExamUpdate
    ) -> Exam:
        exam = await self._get_scoped(Exam, school_id, exam_id, "Exam")
        payload = data.model_dump(exclude_unset=True)
        if "status" in payload and payload["status"] is not None:
            payload["status"] = payload["status"].value
        start_date = payload.get("start_date", exam.start_date)
        end_date = payload.get("end_date", exam.end_date)
        self._validate_exam_dates(start_date, end_date)
        await self._validate_exam_window_against_papers(
            school_id, exam_id, start_date, end_date
        )
        for field, value in payload.items():
            if field == "category_id" and value is not None:
                await self._get_scoped(ExamCategory, school_id, value, "Exam category")
            setattr(exam, field, value)
        await self._validate_exam_links(school_id, exam.class_id, exam.category_id, exam.session_id)
        await self.db.flush()
        return exam

    async def delete_exam(self, school_id: uuid.UUID, exam_id: uuid.UUID) -> None:
        exam = await self._get_scoped(Exam, school_id, exam_id, "Exam")
        await self.db.delete(exam)
        await self.db.flush()

    # ------------------------------ papers ------------------------------- #

    async def add_paper(
        self, school_id: uuid.UUID, exam_id: uuid.UUID, data: schemas.ExamSubjectCreate
    ) -> ExamSubject:
        exam = await self._get_exam(school_id, exam_id)
        self._validate_paper_date(exam, data.exam_date)
        if await self.db.scalar(valid_subjects(school_id).where(Subject.id == data.subject_id)) is None:
            raise not_found("Subject not found in this school")
        subject = await self.db.get(Subject, data.subject_id)
        # A school-wide subject is deliberately reusable, but a class-specific
        # subject must stay with its own grade.  Otherwise a paper can be
        # created for a subject students in the exam's class never study.
        if subject.class_id is not None and subject.class_id != exam.class_id:
            raise bad_request("Subject is not assigned to the exam's class")
        dupe = await self.db.scalar(
            select(ExamSubject).where(
                ExamSubject.exam_id == exam_id, ExamSubject.subject_id == data.subject_id
            )
        )
        if dupe is not None:
            raise bad_request("This subject is already a paper in the exam")
        paper = ExamSubject(
            school_id=school_id,
            exam_id=exam_id,
            subject_id=data.subject_id,
            max_marks=data.max_marks,
            pass_marks=data.pass_marks,
            exam_date=data.exam_date,
            exam_time=data.exam_time,
        )
        self.db.add(paper)
        await self.db.flush()
        return paper

    async def list_papers(self, school_id: uuid.UUID, exam_id: uuid.UUID) -> list[ExamSubject]:
        await self._get_exam(school_id, exam_id)
        result = await self.db.execute(
            select(ExamSubject).where(ExamSubject.exam_id == exam_id, ExamSubject.school_id == school_id)
        )
        return list(result.scalars().all())

    async def delete_paper(self, school_id: uuid.UUID, paper_id: uuid.UUID) -> None:
        paper = await self._get_paper(school_id, paper_id)
        await self.db.delete(paper)
        await self.db.flush()

    # ------------------------------- marks ------------------------------- #

    async def enter_marks(
        self,
        school_id: uuid.UUID,
        paper_id: uuid.UUID,
        data: schemas.MarksEntryRequest,
        marked_by: uuid.UUID,
    ) -> list[Mark]:
        paper = await self._get_paper(school_id, paper_id)
        exam = await self._get_exam(school_id, paper.exam_id)
        valid_students = await self._student_ids(school_id, exam.class_id)

        ids = [e.student_id for e in data.entries]
        if len(set(ids)) != len(ids):
            raise bad_request("Duplicate students in the same request")
        not_enrolled = [str(i) for i in ids if i not in valid_students]
        if not_enrolled:
            raise bad_request(
                f"These students are not enrolled in the exam's class: {', '.join(not_enrolled)}"
            )
        for entry in data.entries:
            if entry.marks_obtained is not None and entry.marks_obtained > paper.max_marks:
                raise bad_request(
                    f"marks_obtained ({entry.marks_obtained}) exceeds max_marks ({paper.max_marks})"
                )

        existing_rows = await self.db.execute(
            select(Mark).where(Mark.school_id == school_id,
                Mark.exam_subject_id == paper_id, Mark.student_id.in_(ids))
        )
        existing = {m.student_id: m for m in existing_rows.scalars().all()}

        marks: list[Mark] = []
        for entry in data.entries:
            row = existing.get(entry.student_id)
            if row is None:
                row = Mark(
                    school_id=school_id,
                    exam_subject_id=paper_id,
                    student_id=entry.student_id,
                )
                self.db.add(row)
            row.marks_obtained = None if entry.is_absent else entry.marks_obtained
            row.is_absent = entry.is_absent
            row.remarks = entry.remarks
            row.marked_by = marked_by
            marks.append(row)

        await self.db.flush()
        return marks

    async def gradebook(
        self, school_id: uuid.UUID, paper_id: uuid.UUID
    ) -> schemas.GradebookOut:
        """The full marks sheet for a paper: every enrolled student, marked or not.

        Built for the marks-entry screen. Existing marks are merged onto the
        roster so a teacher sees who is still outstanding rather than only the
        students already graded.
        """
        paper = await self._get_paper(school_id, paper_id)
        exam = await self._get_exam(school_id, paper.exam_id)
        subject = await self.db.get(Subject, paper.subject_id)
        school_class = await self.db.get(SchoolClass, exam.class_id)

        student_ids = await self._student_ids(school_id, exam.class_id)
        names = dict((await self.db.execute(
            select(User.id, User.full_name).where(User.id.in_(student_ids))
        )).all()) if student_ids else {}

        existing = {
            m.student_id: m
            for m in (await self.db.execute(
                select(Mark).where(Mark.school_id == school_id, Mark.exam_subject_id == paper_id)
            )).scalars().all()
        }

        rows = [
            schemas.GradebookRow(
                student_id=sid,
                student_name=names.get(sid, "Student"),
                marks_obtained=existing[sid].marks_obtained if sid in existing else None,
                is_absent=existing[sid].is_absent if sid in existing else False,
                remarks=existing[sid].remarks if sid in existing else None,
            )
            for sid in student_ids
        ]
        rows.sort(key=lambda r: r.student_name.lower())

        return schemas.GradebookOut(
            paper_id=paper.id,
            exam_name=exam.name if exam else "Exam",
            subject_name=subject.name if subject else "Subject",
            class_name=school_class.name if school_class else "Class",
            max_marks=paper.max_marks,
            pass_marks=paper.pass_marks,
            total_students=len(rows),
            marked_count=sum(
                1 for r in rows if r.marks_obtained is not None or r.is_absent
            ),
            students=rows,
        )

    async def list_marks(self, school_id: uuid.UUID, paper_id: uuid.UUID) -> list[Mark]:
        await self._get_paper(school_id, paper_id)
        result = await self.db.execute(select(Mark).where(
            Mark.school_id == school_id, Mark.exam_subject_id == paper_id,
            Mark.student_id.in_(role_ids(school_id, "student")),
        ))
        return list(result.scalars().all())

    # ------------------------------ results ------------------------------ #

    async def _compute_student_result(
        self, exam_id: uuid.UUID, student_id: uuid.UUID, papers: list[ExamSubject],
        marks_by_paper: dict[uuid.UUID, dict[uuid.UUID, Mark]],
    ) -> dict:
        total = 0.0
        max_total = 0.0
        failed = False
        lines = []
        for paper in papers:
            max_total += paper.max_marks
            mark = marks_by_paper.get(paper.id, {}).get(student_id)
            obtained = None
            absent = True
            if mark is not None:
                obtained = mark.marks_obtained
                absent = mark.is_absent
            score = 0.0 if (absent or obtained is None) else obtained
            total += score
            passed = (not absent) and obtained is not None and obtained >= paper.pass_marks
            if not passed:
                failed = True
            lines.append(
                {
                    "subject_id": paper.subject_id,
                    "max_marks": paper.max_marks,
                    "pass_marks": paper.pass_marks,
                    "marks_obtained": obtained,
                    "is_absent": absent,
                    "passed": passed,
                }
            )
        percentage = round((total / max_total) * 100, 2) if max_total > 0 else 0.0
        status = ResultStatus.FAIL.value if failed else ResultStatus.PASS.value
        return {
            "total": total,
            "max_total": max_total,
            "percentage": percentage,
            "grade": grade_for(percentage),
            "status": status,
            "lines": lines,
        }

    async def _papers_and_marks(self, school_id: uuid.UUID, exam_id: uuid.UUID):
        papers = list(
            (await self.db.execute(select(ExamSubject).where(
                ExamSubject.school_id == school_id,
                ExamSubject.exam_id == exam_id,
            )))
            .scalars()
            .all()
        )
        marks_by_paper: dict[uuid.UUID, dict[uuid.UUID, Mark]] = {}
        if papers:
            rows = await self.db.execute(
                select(Mark).where(
                    Mark.school_id == school_id,
                    Mark.exam_subject_id.in_([p.id for p in papers]),
                    Mark.student_id.in_(role_ids(school_id, "student")),
                )
            )
            for m in rows.scalars().all():
                marks_by_paper.setdefault(m.exam_subject_id, {})[m.student_id] = m
        return papers, marks_by_paper

    async def publish_results(self, school_id: uuid.UUID, exam_id: uuid.UUID) -> list[ExamResult]:
        exam = await self._get_exam(school_id, exam_id)
        papers, marks_by_paper = await self._papers_and_marks(school_id, exam_id)
        if not papers:
            raise bad_request("Cannot publish results: the exam has no papers")
        students = await self._student_ids(school_id, exam.class_id)
        if not students:
            raise bad_request("Cannot publish results: no students enrolled in the class")

        # Publishing turns every unrecorded paper into an absence during result
        # computation. Require an explicit score or absence for every roster
        # entry so an incomplete gradebook cannot become a final result.
        incomplete = sum(
            1
            for paper in papers
            for student_id in students
            if (mark := marks_by_paper.get(paper.id, {}).get(student_id)) is None
            or (mark.marks_obtained is None and not mark.is_absent)
        )
        if incomplete:
            total = len(papers) * len(students)
            raise bad_request(
                "Cannot publish results: marks are incomplete "
                f"({incomplete} of {total} paper entries remain unmarked)"
            )

        existing_rows = await self.db.execute(
            select(ExamResult).where(ExamResult.school_id == school_id, ExamResult.exam_id == exam_id)
        )
        existing = {r.student_id: r for r in existing_rows.scalars().all()}

        now = datetime.now(timezone.utc)
        results: list[ExamResult] = []
        for student_id in students:
            computed = await self._compute_student_result(
                exam_id, student_id, papers, marks_by_paper
            )
            row = existing.get(student_id)
            if row is None:
                row = ExamResult(school_id=school_id, exam_id=exam_id, student_id=student_id)
                self.db.add(row)
            row.total_marks = computed["total"]
            row.max_total = computed["max_total"]
            row.percentage = computed["percentage"]
            row.grade = computed["grade"]
            row.status = computed["status"]
            row.published = True
            row.published_at = now
            results.append(row)

        exam.status = ExamStatus.COMPLETED.value
        await self.db.flush()
        return results

    async def list_results(self, school_id: uuid.UUID, exam_id: uuid.UUID) -> list[ExamResult]:
        await self._get_exam(school_id, exam_id)
        result = await self.db.execute(
            select(ExamResult).where(
                ExamResult.school_id == school_id,
                ExamResult.exam_id == exam_id,
                ExamResult.student_id.in_(role_ids(school_id, "student")),
                ExamResult.published.is_(True),
            )
        )
        return list(result.scalars().all())

    async def student_results(
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> list[schemas.StudentExamResult]:
        """Every published exam result for a student, newest first (with the
        exam name) — for their academic results view."""
        if await self.db.scalar(role_ids(school_id, "student").where(User.id == student_id)) is None:
            raise not_found("Student not found in this school")
        rows = await self.db.execute(
            select(ExamResult, Exam.name)
            .join(Exam, Exam.id == ExamResult.exam_id)
            .where(
                ExamResult.school_id == school_id,
                ExamResult.student_id == student_id,
                ExamResult.published.is_(True),
                Exam.class_id.in_(valid_classes(school_id)),
                or_(Exam.session_id.is_(None), Exam.session_id.in_(select(AcademicSession.id).where(AcademicSession.school_id == school_id))),
            )
            .order_by(ExamResult.published_at.desc().nullslast())
        )
        return [
            schemas.StudentExamResult(
                exam_id=res.exam_id,
                exam_name=exam_name,
                total_marks=res.total_marks,
                max_total=res.max_total,
                percentage=res.percentage,
                grade=res.grade,
                status=res.status,
            )
            for res, exam_name in rows.all()
        ]

    async def report_card(
        self, school_id: uuid.UUID, exam_id: uuid.UUID, student_id: uuid.UUID,
        viewer_id: uuid.UUID | None = None,
    ) -> schemas.ReportCard:
        exam = await self._get_exam(school_id, exam_id)
        if student_id not in await self._student_ids(school_id, exam.class_id):
            raise not_found("Student is not enrolled in this exam's class")
        papers, marks_by_paper = await self._papers_and_marks(school_id, exam_id)
        computed = await self._compute_student_result(exam_id, student_id, papers, marks_by_paper)
        published = await self.db.scalar(
            select(ExamResult.published).where(
                ExamResult.school_id == school_id,
                ExamResult.exam_id == exam_id,
                ExamResult.student_id == student_id,
            )
        )
        if not published:
            viewer = await self.db.get(User, viewer_id) if viewer_id else None
            if viewer is None or not await PermissionService(self.db).has_permission(viewer, Module.RESULTS, PA.APPROVE):
                raise not_found("Report card is not published")
        return schemas.ReportCard(
            exam_id=exam_id,
            student_id=student_id,
            lines=[schemas.ReportCardLine(**line) for line in computed["lines"]],
            total_marks=computed["total"],
            max_total=computed["max_total"],
            percentage=computed["percentage"],
            grade=computed["grade"],
            status=computed["status"],
            published=bool(published),
        )

    # -------------------------- admit card & seating -------------------------- #

    async def admit_card(
        self, school_id: uuid.UUID, exam_id: uuid.UUID, student_id: uuid.UUID
    ) -> schemas.AdmitCard:
        exam = await self._get_exam(school_id, exam_id)
        # The student must be enrolled in a section of the exam's class.
        if student_id not in await self._student_ids(school_id, exam.class_id):
            raise not_found("Student is not enrolled in this exam's class")
        section_id = await self.db.scalar(
            select(StudentEnrollment.section_id)
            .join(Section, Section.id == StudentEnrollment.section_id)
            .where(
                Section.class_id == exam.class_id,
                Section.school_id == school_id,
                StudentEnrollment.school_id == school_id,
                StudentEnrollment.student_id == student_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
        )
        if section_id is None:
            raise not_found("Student is not enrolled in this exam's class")

        papers = list(
            (
                await self.db.execute(
                    select(ExamSubject)
                    .where(ExamSubject.school_id == school_id, ExamSubject.exam_id == exam_id)
                    .order_by(ExamSubject.exam_date)
                )
            )
            .scalars()
            .all()
        )
        seat = await self.db.scalar(
            select(ExamSeat).where(
                ExamSeat.school_id == school_id,
                ExamSeat.exam_id == exam_id, ExamSeat.student_id == student_id
            )
        )
        return schemas.AdmitCard(
            exam_id=exam_id,
            exam_name=exam.name,
            student_id=student_id,
            class_id=exam.class_id,
            section_id=section_id,
            start_date=exam.start_date,
            end_date=exam.end_date,
            room=seat.room if seat else None,
            seat_no=seat.seat_no if seat else None,
            papers=[
                schemas.AdmitCardPaper(
                    subject_id=p.subject_id, exam_date=p.exam_date, max_marks=p.max_marks
                )
                for p in papers
            ],
        )

    async def generate_seating(
        self, school_id: uuid.UUID, exam_id: uuid.UUID, data: schemas.SeatingGenerate
    ) -> list[ExamSeat]:
        exam = await self._get_exam(school_id, exam_id)
        student_ids = sorted(await self._student_ids(school_id, exam.class_id), key=str)
        if not student_ids:
            raise bad_request("No students enrolled in the exam's class")
        total_capacity = sum(r.capacity for r in data.rooms)
        if len(student_ids) > total_capacity:
            raise bad_request(
                f"Seating capacity ({total_capacity}) is less than the number of "
                f"students ({len(student_ids)})"
            )

        # Clear any existing plan for a clean regeneration.
        existing = await self.db.execute(select(ExamSeat).where(
            ExamSeat.school_id == school_id, ExamSeat.exam_id == exam_id
        ))
        for row in existing.scalars().all():
            await self.db.delete(row)
        await self.db.flush()

        seats: list[ExamSeat] = []
        idx = 0
        for room in data.rooms:
            for seat_no in range(1, room.capacity + 1):
                if idx >= len(student_ids):
                    break
                seat = ExamSeat(
                    school_id=school_id,
                    exam_id=exam_id,
                    student_id=student_ids[idx],
                    room=room.name,
                    seat_no=seat_no,
                )
                self.db.add(seat)
                seats.append(seat)
                idx += 1
        await self.db.flush()
        return seats

    async def list_seating(self, school_id: uuid.UUID, exam_id: uuid.UUID) -> list[ExamSeat]:
        await self._get_exam(school_id, exam_id)
        result = await self.db.execute(
            select(ExamSeat)
            .where(ExamSeat.school_id == school_id, ExamSeat.exam_id == exam_id)
            .order_by(ExamSeat.room, ExamSeat.seat_no)
        )
        return list(result.scalars().all())
