"""Homework & Assignment Service."""
import uuid
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import EnrollmentStatus, SubmissionStatus
from app.core.exceptions import bad_request, forbidden, not_found
from app.models.academic import Section, StudentEnrollment, Subject
from app.models.homework import Assignment, Submission
from app.modules.homework import schemas


class HomeworkService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

    async def _get_scoped(self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    async def _is_enrolled(self, section_id: uuid.UUID, student_id: uuid.UUID) -> bool:
        row = await self.db.scalar(
            select(StudentEnrollment).where(
                StudentEnrollment.section_id == section_id,
                StudentEnrollment.student_id == student_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
        )
        return row is not None

    # ---------------------------- assignments ---------------------------- #

    async def create_assignment(
        self, school_id: uuid.UUID, data: schemas.AssignmentCreate, created_by: uuid.UUID
    ) -> Assignment:
        await self._get_scoped(Section, school_id, data.section_id, "Section")
        await self._get_scoped(Subject, school_id, data.subject_id, "Subject")
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
    ) -> list[schemas.AssignmentListOut]:
        """Assignments enriched for list views.

        Each item resolves its subject name, carries a total ``submission_count``,
        and — when ``current_user_id`` is a student — embeds that student's own
        submission so clients can render "Submitted / Graded" state directly.
        """
        stmt = select(Assignment).where(Assignment.school_id == school_id)
        if section_id is not None:
            stmt = stmt.where(Assignment.section_id == section_id)
        stmt = stmt.order_by(Assignment.due_date.desc())
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
                    submission_count=counts.get(a.id, 0),
                    my_submission=(
                        schemas.SubmissionBrief.model_validate(submission)
                        if submission is not None
                        else None
                    ),
                )
            )
        return out

    async def update_assignment(
        self, school_id: uuid.UUID, assignment_id: uuid.UUID, data: schemas.AssignmentUpdate
    ) -> Assignment:
        assignment = await self._get_scoped(Assignment, school_id, assignment_id, "Assignment")
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(assignment, field, value)
        await self.db.flush()
        return assignment

    async def delete_assignment(self, school_id: uuid.UUID, assignment_id: uuid.UUID) -> None:
        assignment = await self._get_scoped(Assignment, school_id, assignment_id, "Assignment")
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
        assignment = await self._get_scoped(Assignment, school_id, assignment_id, "Assignment")
        if not await self._is_enrolled(assignment.section_id, student_id):
            raise forbidden("Only a student enrolled in this section can submit this assignment")

        submitted_on = data.submitted_on or date.today()
        status = (
            SubmissionStatus.LATE.value
            if submitted_on > assignment.due_date
            else SubmissionStatus.SUBMITTED.value
        )

        existing = await self.db.scalar(
            select(Submission).where(
                Submission.assignment_id == assignment_id,
                Submission.student_id == student_id,
            )
        )
        if existing is not None:
            if existing.status == SubmissionStatus.GRADED.value:
                raise bad_request("This submission has already been graded and cannot be changed")
            existing.content = data.content
            existing.attachment_url = data.attachment_url
            existing.submitted_on = submitted_on
            existing.status = status
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
        self, school_id: uuid.UUID, assignment_id: uuid.UUID
    ) -> list[Submission]:
        await self._get_scoped(Assignment, school_id, assignment_id, "Assignment")
        result = await self.db.execute(
            select(Submission).where(Submission.assignment_id == assignment_id)
        )
        return list(result.scalars().all())

    async def grade(
        self,
        school_id: uuid.UUID,
        submission_id: uuid.UUID,
        data: schemas.GradeSubmission,
        graded_by: uuid.UUID,
    ) -> Submission:
        submission = await self._get_scoped(Submission, school_id, submission_id, "Submission")
        assignment = await self.db.get(Assignment, submission.assignment_id)
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
        result = await self.db.execute(
            select(Submission).where(
                Submission.school_id == school_id, Submission.student_id == student_id
            )
        )
        return list(result.scalars().all())
