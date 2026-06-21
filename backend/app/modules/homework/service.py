"""Homework & Assignment Service."""
import uuid
from datetime import date

from sqlalchemy import select
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
        self, school_id: uuid.UUID, section_id: uuid.UUID | None = None
    ) -> list[Assignment]:
        stmt = select(Assignment).where(Assignment.school_id == school_id)
        if section_id is not None:
            stmt = stmt.where(Assignment.section_id == section_id)
        stmt = stmt.order_by(Assignment.due_date.desc())
        return list((await self.db.execute(stmt)).scalars().all())

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

    async def student_submissions(
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> list[Submission]:
        result = await self.db.execute(
            select(Submission).where(
                Submission.school_id == school_id, Submission.student_id == student_id
            )
        )
        return list(result.scalars().all())
