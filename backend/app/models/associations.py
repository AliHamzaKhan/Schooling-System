"""Association tables."""
import uuid

from sqlalchemy import Column, DateTime, ForeignKey, String, Table, func
from sqlalchemy.dialects.postgresql import UUID

from app.models.base import Base

user_roles = Table(
    "user_roles",
    Base.metadata,
    Column(
        "user_id",
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column(
        "role_id",
        UUID(as_uuid=True),
        ForeignKey("roles.id", ondelete="CASCADE"),
        primary_key=True,
    ),
)


# Links a guardian (user) to a student (user) they are responsible for. Both
# sides are rows in `users`; a guardian may have many children and a student
# many guardians. `school_id` keeps the link inside one tenant; `relationship`
# is an optional label such as "father" / "mother" / "guardian".
guardian_students = Table(
    "guardian_students",
    Base.metadata,
    Column(
        "guardian_id",
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column(
        "student_id",
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column(
        "school_id",
        UUID(as_uuid=True),
        ForeignKey("schools.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    ),
    Column("relationship", String(50), nullable=True),
    Column(
        "created_at",
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    ),
)
