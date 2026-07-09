"""Server-side refresh-token sessions.

Each successful login opens one session row. The refresh token carries the
session id (`sid`) and the row stores only a hash of the *current* refresh
token. This buys three things a stateless JWT can't:

* **Rotation** — every /refresh mints a new token and overwrites the stored
  hash, so an old refresh token stops working immediately (not at expiry).
* **Reuse detection** — presenting a previously-rotated token whose hash no
  longer matches signals theft; the session is revoked on the spot.
* **Revocation** — logout / logout-everywhere / deactivation set `revoked_at`,
  killing the session before the token's natural expiry.

Access tokens stay stateless and short-lived, so the authenticated request path
never touches this table — only login, refresh, and logout do.
"""
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
import uuid

from app.models.base import Base, TimestampMixin, UUIDMixin


class RefreshSession(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "refresh_sessions"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # SHA-256 hex of the current refresh token (64 chars). Never the raw token.
    token_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    last_used_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    # Lightweight audit context captured at login (best-effort).
    user_agent: Mapped[str | None] = mapped_column(String(255), nullable=True)
    ip_address: Mapped[str | None] = mapped_column(String(45), nullable=True)
