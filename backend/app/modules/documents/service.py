"""Student document service."""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import not_found
from app.models.document import StudentDocument
from app.modules.documents import schemas


class DocumentService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def add(
        self,
        school_id: uuid.UUID,
        student_id: uuid.UUID,
        data: schemas.DocumentCreate,
        uploaded_by: uuid.UUID,
    ) -> StudentDocument:
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
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> list[StudentDocument]:
        result = await self.db.execute(
            select(StudentDocument)
            .where(
                StudentDocument.school_id == school_id,
                StudentDocument.student_id == student_id,
            )
            .order_by(StudentDocument.created_at.desc())
        )
        return list(result.scalars().all())

    async def delete(self, school_id: uuid.UUID, document_id: uuid.UUID) -> None:
        doc = await self.db.get(StudentDocument, document_id)
        if doc is None or doc.school_id != school_id:
            raise not_found("Document not found in this school")
        await self.db.delete(doc)
        await self.db.flush()
