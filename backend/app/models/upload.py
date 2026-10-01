"""Ledger of stored uploads: who stored what, and how many bytes.

It is the basis for per-plan storage quotas and for cleaning up files that no
record references any more.
"""
import uuid

from sqlalchemy import BigInteger, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class StoredUpload(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "stored_uploads"

    school_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("schools.id", ondelete="CASCADE"), index=True, nullable=False
    )
    uploaded_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    storage_key: Mapped[str] = mapped_column(String(500), unique=True, nullable=False)
    url: Mapped[str] = mapped_column(String(500), nullable=False)
    folder: Mapped[str] = mapped_column(String(50), nullable=False)
    size_bytes: Mapped[int] = mapped_column(BigInteger, nullable=False)
    content_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
