"""Password-reset OTP challenges (the forgot-password flow).

One row is created per `POST /auth/forgot-password`. It stores only a *hash* of
the 6-digit OTP (never the code itself), an expiry, and a small attempt counter,
so a database/backup leak can't be replayed into a password reset and repeated
guessing is bounded. The row moves through three states by timestamp:

* **pending**   — created, awaiting a correct OTP (``verified_at`` null)
* **verified**  — OTP matched; a short-lived reset token was issued
  (``verified_at`` set, ``consumed_at`` null)
* **consumed**  — the password was actually changed (``consumed_at`` set)

Access tokens/refresh sessions live elsewhere; this table is touched only by the
three unauthenticated reset endpoints.
"""
import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class PasswordReset(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "password_resets"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # SHA-256 hex of the OTP (64 chars). Never the raw code.
    code_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    attempts: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    verified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    consumed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
