"""Student document records (metadata + file URL).

The file itself is stored externally (object storage / uploads); this table
tracks the metadata and link so documents can be listed per student.
"""
import uuid

from sqlalchemy import ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class StudentDocument(Base, UUIDMixin, TimestampMixin):
    """A document attached to a student's profile (e.g. birth certificate)."""

    __tablename__ = "student_documents"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    doc_type: Mapped[str | None] = mapped_column(String(50), nullable=True)
    file_url: Mapped[str] = mapped_column(String(500), nullable=False)
    uploaded_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
