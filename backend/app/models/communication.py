"""Communication models: templates, notification configs, messages, deliveries, device tokens."""
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import MessageStatus
from app.models.base import Base, TimestampMixin, UUIDMixin


class NotificationTemplate(Base, UUIDMixin, TimestampMixin):
    """A reusable message template (supports {placeholders})."""

    __tablename__ = "notification_templates"
    __table_args__ = (UniqueConstraint("school_id", "code", name="uq_template_school_code"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    code: Mapped[str] = mapped_column(String(80), nullable=False)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    subject: Mapped[str | None] = mapped_column(String(200), nullable=True)
    body: Mapped[str] = mapped_column(Text, nullable=False)


class NotificationConfig(Base, UUIDMixin, TimestampMixin):
    """Per-school enable/disable + channel choice for an event (docs/permissions/08)."""

    __tablename__ = "notification_configs"
    __table_args__ = (UniqueConstraint("school_id", "event", name="uq_notifconfig_school_event"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    event: Mapped[str] = mapped_column(String(80), nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    channels: Mapped[list[str]] = mapped_column(ARRAY(String(20)), default=list, nullable=False)


class Message(Base, UUIDMixin, TimestampMixin):
    """A broadcast or notification send (one row per send action)."""

    __tablename__ = "messages"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str | None] = mapped_column(String(200), nullable=True)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    channel: Mapped[str] = mapped_column(String(20), nullable=False)
    audience_type: Mapped[str] = mapped_column(String(30), nullable=False)
    audience_ref: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default=MessageStatus.PENDING.value, nullable=False)
    scheduled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    deliveries: Mapped[list["MessageDelivery"]] = relationship(
        back_populates="message", cascade="all, delete-orphan"
    )


class MessageDelivery(Base, UUIDMixin, TimestampMixin):
    """Per-recipient delivery record (Sent/Delivered/Read/Failed)."""

    __tablename__ = "message_deliveries"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    message_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("messages.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    channel: Mapped[str] = mapped_column(String(20), nullable=False)
    address: Mapped[str | None] = mapped_column(String(255), nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    provider: Mapped[str | None] = mapped_column(String(20), nullable=True)
    error: Mapped[str | None] = mapped_column(String(255), nullable=True)

    message: Mapped["Message"] = relationship(back_populates="deliveries")


class DeviceToken(Base, UUIDMixin, TimestampMixin):
    """A user's push device token (for FCM)."""

    __tablename__ = "device_tokens"
    __table_args__ = (UniqueConstraint("token", name="uq_device_token"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    token: Mapped[str] = mapped_column(String(500), nullable=False)
    platform: Mapped[str | None] = mapped_column(String(20), nullable=True)
