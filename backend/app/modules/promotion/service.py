"""Promotion service: exam-driven preview, batch promotion, merit list, reports."""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import EnrollmentStatus, PromotionOutcome, ResultStatus
from app.core.exceptions import bad_request, not_found
from app.models.academic import SchoolClass, Section, StudentEnrollment
from app.models.examination import Exam, ExamResult
from app.models.promotion import PromotionRecord
from app.models.user import User
from app.modules.promotion import schemas


class PromotionService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

    async def _get_scoped(self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    async def _active_enrollment(
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> StudentEnrollment | None:
        return await self.db.scalar(
            select(StudentEnrollment).where(
                StudentEnrollment.school_id == school_id,
                StudentEnrollment.student_id == student_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
        )

    # ------------------------------ preview ------------------------------ #

    async def preview_from_exam(
        self, school_id: uuid.UUID, exam_id: uuid.UUID
    ) -> list[schemas.PromotionPreviewRow]:
        """Suggest promote/retain per student from a published exam's results."""
        await self._get_scoped(Exam, school_id, exam_id, "Exam")
        results = list(
            (
                await self.db.execute(
                    select(ExamResult).where(
                        ExamResult.school_id == school_id, ExamResult.exam_id == exam_id
                    )
                )
            )
            .scalars()
            .all()
        )
        if not results:
            raise bad_request("No results found for this exam; publish results first")

        # Resolve student names and current class+section labels in bulk.
        student_ids = [r.student_id for r in results]
        names = dict(
            (
                await self.db.execute(
                    select(User.id, User.full_name).where(User.id.in_(student_ids))
                )
            ).all()
        )

        rows: list[schemas.PromotionPreviewRow] = []
        for r in results:
            enrollment = await self._active_enrollment(school_id, r.student_id)
            section_label: str | None = None
            if enrollment is not None:
                labels = (
                    await self.db.execute(
                        select(SchoolClass.name, Section.name)
                        .join(Section, Section.class_id == SchoolClass.id)
                        .where(Section.id == enrollment.section_id)
                    )
                ).first()
                if labels is not None:
                    section_label = f"{labels[0]} · {labels[1]}"
            passed = r.status == ResultStatus.PASS.value
            rows.append(
                schemas.PromotionPreviewRow(
                    student_id=r.student_id,
                    student_name=names.get(r.student_id),
                    current_section_id=enrollment.section_id if enrollment else None,
                    current_section_label=section_label,
                    total_marks=r.total_marks,
                    percentage=r.percentage,
                    result_status=r.status,
                    suggested_outcome=(
                        PromotionOutcome.PROMOTED if passed else PromotionOutcome.RETAINED
                    ),
                )
            )
        rows.sort(key=lambda x: (x.percentage or 0), reverse=True)
        return rows

    # ------------------------------ promote ------------------------------ #

    async def promote_batch(
        self, school_id: uuid.UUID, data: schemas.PromoteBatch, created_by: uuid.UUID
    ) -> list[PromotionRecord]:
        records: list[PromotionRecord] = []
        for item in data.items:
            enrollment = await self._active_enrollment(school_id, item.student_id)
            from_section_id = enrollment.section_id if enrollment else None
            from_session_id = enrollment.session_id if enrollment else None
            to_section_id: uuid.UUID | None = None

            if item.outcome == PromotionOutcome.PROMOTED:
                if item.to_section_id is None:
                    raise bad_request(
                        f"to_section_id is required to promote student {item.student_id}"
                    )
                target = await self._get_scoped(
                    Section, school_id, item.to_section_id, "Target section"
                )
                to_section_id = target.id
                if enrollment is not None:
                    enrollment.status = EnrollmentStatus.INACTIVE.value
                await self._upsert_active_enrollment(
                    school_id, target.id, item.student_id, data.to_session_id
                )
            elif item.outcome == PromotionOutcome.GRADUATED:
                if enrollment is not None:
                    enrollment.status = EnrollmentStatus.INACTIVE.value
            # RETAINED: leave the current enrollment untouched.

            record = PromotionRecord(
                school_id=school_id,
                student_id=item.student_id,
                from_section_id=from_section_id,
                to_section_id=to_section_id,
                from_session_id=from_session_id,
                to_session_id=data.to_session_id,
                exam_id=data.exam_id,
                outcome=item.outcome.value,
                created_by=created_by,
            )
            self.db.add(record)
            records.append(record)

        await self.db.flush()
        return records

    async def _upsert_active_enrollment(
        self,
        school_id: uuid.UUID,
        section_id: uuid.UUID,
        student_id: uuid.UUID,
        session_id: uuid.UUID | None,
    ) -> None:
        existing = await self.db.scalar(
            select(StudentEnrollment).where(
                StudentEnrollment.section_id == section_id,
                StudentEnrollment.student_id == student_id,
            )
        )
        if existing is not None:
            existing.status = EnrollmentStatus.ACTIVE.value
            if session_id is not None:
                existing.session_id = session_id
            return
        self.db.add(
            StudentEnrollment(
                school_id=school_id,
                section_id=section_id,
                student_id=student_id,
                session_id=session_id,
                status=EnrollmentStatus.ACTIVE.value,
            )
        )

    # ------------------------------ reports ------------------------------ #

    async def list_records(
        self,
        school_id: uuid.UUID,
        student_id: uuid.UUID | None = None,
        to_session_id: uuid.UUID | None = None,
    ) -> list[PromotionRecord]:
        stmt = select(PromotionRecord).where(PromotionRecord.school_id == school_id)
        if student_id is not None:
            stmt = stmt.where(PromotionRecord.student_id == student_id)
        if to_session_id is not None:
            stmt = stmt.where(PromotionRecord.to_session_id == to_session_id)
        stmt = stmt.order_by(PromotionRecord.created_at.desc())
        return list((await self.db.execute(stmt)).scalars().all())

    # ----------------------------- merit list ---------------------------- #

    async def merit_list(
        self, school_id: uuid.UUID, exam_id: uuid.UUID, limit: int | None = None
    ) -> list[schemas.MeritListRow]:
        await self._get_scoped(Exam, school_id, exam_id, "Exam")
        results = list(
            (
                await self.db.execute(
                    select(ExamResult)
                    .where(ExamResult.school_id == school_id, ExamResult.exam_id == exam_id)
                    .order_by(ExamResult.percentage.desc(), ExamResult.total_marks.desc())
                )
            )
            .scalars()
            .all()
        )
        if limit is not None:
            results = results[:limit]
        return [
            schemas.MeritListRow(
                rank=i + 1,
                student_id=r.student_id,
                total_marks=r.total_marks,
                max_total=r.max_total,
                percentage=r.percentage,
                grade=r.grade,
                status=r.status,
            )
            for i, r in enumerate(results)
        ]
