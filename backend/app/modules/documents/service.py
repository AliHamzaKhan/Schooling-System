"""Student document service."""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import not_found
from app.core.enums import SystemRole
from app.core.pagination import OffsetPage
from app.models.document import StudentDocument
from app.models.role import Role
from app.models.user import User
from app.modules.documents import schemas
from app.modules.uploads.access import validate_new_reference


class DocumentService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _validate_student(self, school_id: uuid.UUID, student_id: uuid.UUID) -> None:
        student = await self.db.scalar(select(User.id).where(
            User.id == student_id,
            User.school_id == school_id,
            User.roles.any(Role.code == SystemRole.STUDENT.value),
        ))
        if student is None:
            raise not_found("Student not found in this school")

    async def add(
        self,
        school_id: uuid.UUID,
        student_id: uuid.UUID,
        data: schemas.DocumentCreate,
        uploaded_by: uuid.UUID,
    ) -> StudentDocument:
        await self._validate_student(school_id, student_id)
        validate_new_reference(data.file_url, school_id, uploaded_by, "documents")
        doc = StudentDocument(
            school_id=school_id,
            student_id=student_id,
            title=data.title,
            doc_type=data.doc_type,
            file_url=data.file_url,
            uploaded_by=uploaded_by,
        )
        self.db.add(doc)
        await self.db.flush()
        return doc

    async def list_for_student(
        self,
        school_id: uuid.UUID,
        student_id: uuid.UUID,
        page: OffsetPage | None = None,
    ) -> list[StudentDocument]:
        """Return a bounded document page after the caller's student access check."""
        await self._validate_student(school_id, student_id)
        stmt = (
            select(StudentDocument)
            .where(
                StudentDocument.school_id == school_id,
                StudentDocument.student_id == student_id,
            )
            .order_by(StudentDocument.created_at.desc(), StudentDocument.id.desc())
        )
        if page is not None:
            stmt = page.apply(stmt)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def delete(self, school_id: uuid.UUID, student_id: uuid.UUID, document_id: uuid.UUID) -> None:
        await self._validate_student(school_id, student_id)
        doc = await self.db.scalar(select(StudentDocument).where(
            StudentDocument.id == document_id,
            StudentDocument.school_id == school_id,
            StudentDocument.student_id == student_id,
        ))
        if doc is None:
            raise not_found("Document not found for this student")
        await self.db.delete(doc)
        await self.db.flush()
