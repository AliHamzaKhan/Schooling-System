"""Public-facing school information authored by the headmaster.

Complements the core ``School`` row (name, address, contacts) with the
"about us", achievements, and the school uniform image that students and
guardians see. One row per school.
"""
import uuid

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class SchoolInfo(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "school_info"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("schools.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    about: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Each item: {"title": str, "description": str | None, "year": str | None}.
    achievements: Mapped[list] = mapped_column(JSONB, default=list, nullable=False)
    uniform_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
