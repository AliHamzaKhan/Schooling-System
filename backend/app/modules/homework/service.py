"""Homework & Assignment Service."""
import uuid
from datetime import date, datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import EnrollmentStatus, SubmissionStatus
from app.core.exceptions import bad_request, forbidden, not_found
from app.core.pagination import OffsetPage
from app.models.academic import SchoolClass, Section, StudentEnrollment, Subject
from app.models.homework import Assignment, Submission
from app.models.user import User
from app.modules.homework import schemas
from app.modules.academic.access import role_ids, valid_sections, valid_subjects


class HomeworkService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

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

    async def _get_assignment(self, school_id: uuid.UUID, assignment_id: uuid.UUID) -> Assignment:
        assignment = await self._get_scoped(Assignment, school_id, assignment_id, "Assignment")
        await self._validate_links(school_id, assignment.section_id, assignment.subject_id)
        return assignment

    async def _is_enrolled(self, school_id: uuid.UUID, section_id: uuid.UUID, student_id: uuid.UUID) -> bool:
        row = await self.db.scalar(
            select(StudentEnrollment).where(
                StudentEnrollment.school_id == school_id,
                StudentEnrollment.section_id == section_id,
                StudentEnrollment.student_id == student_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                StudentEnrollment.section_id.in_(valid_sections(school_id)),
                StudentEnrollment.student_id.in_(role_ids(school_id, "student", active=True)),
            )
        )
        return row is not None

    # ---------------------------- assignments ---------------------------- #

    async def create_assignment(
        self, school_id: uuid.UUID, data: schemas.AssignmentCreate, created_by: uuid.UUID
    ) -> Assignment:
        await self._validate_links(school_id, data.section_id, data.subject_id)
        assignment = Assignment(
            school_id=school_id,
            section_id=data.section_id,
            subject_id=data.subject_id,
            title=data.title,
            description=data.description,
            assigned_on=data.assigned_on or date.today(),
            due_date=data.due_date,
            max_marks=data.max_marks,
            assigned_by=created_by,
        )
        self.db.add(assignment)
        await self.db.flush()
        return assignment

    async def list_assignments(
        self,
        school_id: uuid.UUID,
        section_id: uuid.UUID | None = None,
        current_user_id: uuid.UUID | None = None,
        page: OffsetPage | None = None,
    ) -> list[schemas.AssignmentListOut]:
        """Assignments enriched for list views.

        Each item resolves its subject name, carries a total ``submission_count``,
        and — when ``current_user_id`` is a student — embeds that student's own
        submission so clients can render "Submitted / Graded" state directly.
        """
        stmt = select(Assignment).where(
            Assignment.school_id == school_id,
            Assignment.section_id.in_(valid_sections(school_id)),
            Assignment.subject_id.in_(valid_subjects(school_id)),
        )
        if section_id is not None:
            if await self.db.scalar(valid_sections(school_id).where(Section.id == section_id)) is None:
                raise not_found("Section not found in this school")
            stmt = stmt.where(Assignment.section_id == section_id)
        if current_user_id is not None and await self.db.scalar(
            role_ids(school_id, "student").where(User.id == current_user_id)
        ) is not None:
            stmt = stmt.where(Assignment.section_id.in_(select(StudentEnrollment.section_id).where(
                StudentEnrollment.school_id == school_id,
                StudentEnrollment.student_id == current_user_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                StudentEnrollment.section_id.in_(valid_sections(school_id)),
            )))
        # Keep pagination after every school, academic-link and student
        # enrollment visibility filter.  The identifier tie-breaker makes a
        # page stable when multiple assignments share the same due date.
        stmt = stmt.order_by(Assignment.due_date.desc(), Assignment.id.desc())
        if page is not None:
            stmt = page.apply(stmt)
        assignments = list((await self.db.execute(stmt)).scalars().all())
        if not assignments:
            return []

        assignment_ids = [a.id for a in assignments]
        subject_ids = {a.subject_id for a in assignments}

        # Subject names (single batched query).
        subject_names: dict[uuid.UUID, str] = dict(
            (await self.db.execute(
                select(Subject.id, Subject.name).where(Subject.id.in_(subject_ids))
            )).all()
        )

        # Total submissions per assignment.
        counts: dict[uuid.UUID, int] = dict(
            (await self.db.execute(
                select(Submission.assignment_id, func.count())
                .where(Submission.assignment_id.in_(assignment_ids))
                .group_by(Submission.assignment_id)
            )).all()
        )

        reviewed = (
            SubmissionStatus.GRADED.value, SubmissionStatus.APPROVED.value,
            SubmissionStatus.REJECTED.value,
        )
        graded: dict[uuid.UUID, int] = dict(
            (await self.db.execute(
                select(Submission.assignment_id, func.count())
                .where(
                    Submission.assignment_id.in_(assignment_ids),
                    Submission.status.in_(reviewed),
                )
                .group_by(Submission.assignment_id)
            )).all()
        )
        section_ids = {a.section_id for a in assignments}
        placements = {
            sid: (section_name, class_name)
            for sid, section_name, class_name in (await self.db.execute(
                select(Section.id, Section.name, SchoolClass.name)
                .join(SchoolClass, SchoolClass.id == Section.class_id)
                .where(Section.id.in_(section_ids))
            )).all()
        }
        rosters: dict[uuid.UUID, int] = dict(
            (await self.db.execute(
                select(StudentEnrollment.section_id, func.count(StudentEnrollment.student_id))
                .where(
                    StudentEnrollment.section_id.in_(section_ids),
                    StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                )
                .group_by(StudentEnrollment.section_id)
            )).all()
        )

        # The requesting user's own submissions (for students).
        mine: dict[uuid.UUID, Submission] = {}
        if current_user_id is not None:
            rows = (await self.db.execute(
                select(Submission).where(
                    Submission.assignment_id.in_(assignment_ids),
                    Submission.student_id == current_user_id,
                )
            )).scalars().all()
            mine = {s.assignment_id: s for s in rows}

        out: list[schemas.AssignmentListOut] = []
        for a in assignments:
            submission = mine.get(a.id)
            out.append(
                schemas.AssignmentListOut(
                    id=a.id,
                    school_id=a.school_id,
                    section_id=a.section_id,
                    subject_id=a.subject_id,
                    title=a.title,
                    description=a.description,
                    assigned_on=a.assigned_on,
                    due_date=a.due_date,
                    max_marks=a.max_marks,
                    assigned_by=a.assigned_by,
                    subject_name=subject_names.get(a.subject_id),
                    section_name=placements.get(a.section_id, (None, None))[0],
                    class_name=placements.get(a.section_id, (None, None))[1],
                    submission_count=counts.get(a.id, 0),
                    graded_count=graded.get(a.id, 0),
                    roster_size=rosters.get(a.section_id, 0),
                    my_submission=(
                        schemas.SubmissionBrief.model_validate(submission)
                        if submission is not None
                        else None
                    ),
                )
            )
        return out

    async def get_assignment_detail(
        self,
        school_id: uuid.UUID,
        assignment_id: uuid.UUID,
        current_user_id: uuid.UUID | None = None,
    ) -> schemas.AssignmentListOut:
        """One assignment, enriched like the list rows.

        Resolves the subject name, counts submissions, and — for a student —
        embeds their own submission, so the detail screen renders real state
        instead of a fixture.
        """
        a = await self._get_assignment(school_id, assignment_id)
        if current_user_id is not None and await self.db.scalar(
            role_ids(school_id, "student").where(User.id == current_user_id)
        ) is not None and not await self._is_enrolled(school_id, a.section_id, current_user_id):
            raise not_found("Assignment not found")

        subject = await self.db.get(Subject, a.subject_id)
        count = int((await self.db.scalar(
            select(func.count()).where(Submission.assignment_id == a.id)
        )) or 0)

        submission = None
        if current_user_id is not None:
            submission = (await self.db.execute(
                select(Submission).where(
                    Submission.assignment_id == a.id,
                    Submission.student_id == current_user_id,
                )
            )).scalars().first()

        return schemas.AssignmentListOut(
            id=a.id,
            school_id=a.school_id,
            section_id=a.section_id,
            subject_id=a.subject_id,
            title=a.title,
            description=a.description,
            assigned_on=a.assigned_on,
            due_date=a.due_date,
            max_marks=a.max_marks,
            assigned_by=a.assigned_by,
            subject_name=subject.name if subject else None,
            submission_count=count,
            my_submission=(
                schemas.SubmissionBrief.model_validate(submission)
                if submission is not None
                else None
            ),
        )

    async def update_assignment(
        self, school_id: uuid.UUID, assignment_id: uuid.UUID, data: schemas.AssignmentUpdate
    ) -> Assignment:
        assignment = await self._get_assignment(school_id, assignment_id)
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(assignment, field, value)
        await self.db.flush()
        return assignment

    async def delete_assignment(self, school_id: uuid.UUID, assignment_id: uuid.UUID) -> None:
        assignment = await self._get_assignment(school_id, assignment_id)
        await self.db.delete(assignment)
        await self.db.flush()

    # ---------------------------- submissions ---------------------------- #

    async def submit(
        self,
        school_id: uuid.UUID,
        assignment_id: uuid.UUID,
        student_id: uuid.UUID,
        data: schemas.SubmissionCreate,
    ) -> Submission:
        assignment = await self._get_assignment(school_id, assignment_id)
        if not await self._is_enrolled(school_id, assignment.section_id, student_id):
            raise forbidden("Only a student enrolled in this section can submit this assignment")

        submitted_on = data.submitted_on or date.today()
        status = (
            SubmissionStatus.LATE.value
            if submitted_on > assignment.due_date
            else SubmissionStatus.SUBMITTED.value
        )

        existing = await self.db.scalar(
            select(Submission).where(
                Submission.school_id == school_id,
                Submission.assignment_id == assignment_id,
                Submission.student_id == student_id,
            )
        )
        from app.modules.uploads.access import validate_new_reference
        validate_new_reference(data.attachment_url, school_id, student_id, "submissions",
                               existing=existing.attachment_url if existing else None)
        if existing is not None:
            if existing.status == SubmissionStatus.GRADED.value:
                raise bad_request("This submission has already been graded and cannot be changed")

            # A client may retry the same POST after losing its response.  Keep
            # that retry idempotent: in particular, do not turn a teacher's
            # existing read receipt back into an unread submission.
            if (
                existing.content == data.content
                and existing.attachment_url == data.attachment_url
                and existing.submitted_on == submitted_on
            ):
                return existing

            existing.content = data.content
            existing.attachment_url = data.attachment_url
            existing.submitted_on = submitted_on
            existing.status = status
            # This is a new revision.  The old receipt described the previous
            # content, so clients must not report it as read until staff opens
            # the revised submission.
            existing.seen_at = None
            await self.db.flush()
            return existing

        submission = Submission(
            school_id=school_id,
            assignment_id=assignment_id,
            student_id=student_id,
            submitted_on=submitted_on,
            content=data.content,
            attachment_url=data.attachment_url,
            status=status,
        )
        self.db.add(submission)
        await self.db.flush()
        return submission

    async def list_submissions(
        self, school_id: uuid.UUID, assignment_id: uuid.UUID, *, mark_seen: bool = False
    ) -> list[Submission]:
        await self._get_assignment(school_id, assignment_id)
        result = await self.db.execute(
            select(Submission).where(
                Submission.school_id == school_id, Submission.assignment_id == assignment_id
            )
        )
        submissions = list(result.scalars().all())

        # A teacher opening the list "reads" every submission (records a receipt
        # the student sees). Only stamps the first time.
        if mark_seen:
            now = datetime.now(timezone.utc)
            for s in submissions:
                if s.seen_at is None:
                    s.seen_at = now
            await self.db.flush()

        # Attach the submitting student's name for the grading UI.
        student_ids = {s.student_id for s in submissions}
        if student_ids:
            rows = await self.db.execute(
                select(User.id, User.full_name).where(User.id.in_(student_ids))
            )
            names = {r[0]: r[1] for r in rows.all()}
            for s in submissions:
                s.student_name = names.get(s.student_id)
        return submissions

    async def grade(
        self,
        school_id: uuid.UUID,
        submission_id: uuid.UUID,
        data: schemas.GradeSubmission,
        graded_by: uuid.UUID,
    ) -> Submission:
        submission = await self._get_scoped(Submission, school_id, submission_id, "Submission")
        assignment = await self._get_assignment(school_id, submission.assignment_id)
        if assignment.max_marks is not None and data.marks_obtained > assignment.max_marks:
            raise bad_request(
                f"marks_obtained ({data.marks_obtained}) exceeds max_marks ({assignment.max_marks})"
            )
        submission.marks_obtained = data.marks_obtained
        submission.feedback = data.feedback
        submission.status = SubmissionStatus.GRADED.value
        submission.graded_by = graded_by
        await self.db.flush()
        return submission

    async def review(
        self,
        school_id: uuid.UUID,
        submission_id: uuid.UUID,
        data: schemas.ReviewSubmission,
        reviewed_by: uuid.UUID,
    ) -> Submission:
        """Approve or reject a submission (moderation, distinct from grading)."""
        submission = await self._get_scoped(Submission, school_id, submission_id, "Submission")
        await self._get_assignment(school_id, submission.assignment_id)
        submission.status = (
            SubmissionStatus.APPROVED.value if data.approved else SubmissionStatus.REJECTED.value
        )
        if data.feedback is not None:
            submission.feedback = data.feedback
        submission.graded_by = reviewed_by
        await self.db.flush()
        return submission

    async def student_submissions(
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> list[Submission]:
        if await self.db.scalar(role_ids(school_id, "student").where(User.id == student_id)) is None:
            raise not_found("Student not found in this school")
        result = await self.db.execute(
            select(Submission)
            .join(Assignment, Assignment.id == Submission.assignment_id)
            .where(
                Submission.school_id == school_id,
                Submission.student_id == student_id,
                Assignment.school_id == school_id,
                Assignment.section_id.in_(valid_sections(school_id)),
                Assignment.subject_id.in_(valid_subjects(school_id)),
            )
        )
        return list(result.scalars().all())
