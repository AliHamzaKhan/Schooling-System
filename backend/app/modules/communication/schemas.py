"""Communication schemas."""
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.core.enums import AudienceType, Channel, NotificationEvent

# --------------------------------------------------------------------------- #
# Templates
# --------------------------------------------------------------------------- #


class TemplateCreate(BaseModel):
    code: str = Field(min_length=2, max_length=80)
    name: str = Field(min_length=2, max_length=150)
    subject: str | None = Field(default=None, max_length=200)
    body: str = Field(min_length=1)


class TemplateOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    code: str
    name: str
    subject: str | None = None
    body: str


# --------------------------------------------------------------------------- #
# Notification config
# --------------------------------------------------------------------------- #


class NotificationConfigSet(BaseModel):
    event: NotificationEvent
    enabled: bool = True
    channels: list[Channel] = Field(default_factory=list)


class NotificationConfigOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    event: str
    enabled: bool
    channels: list[str]


# --------------------------------------------------------------------------- #
# Device tokens
# --------------------------------------------------------------------------- #


class DeviceTokenRegister(BaseModel):
    token: str = Field(min_length=8, max_length=500)
    platform: str | None = Field(default=None, max_length=20)


class DeviceTokenOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    token: str
    platform: str | None = None


# --------------------------------------------------------------------------- #
# Broadcast / messages
# --------------------------------------------------------------------------- #


class BroadcastCreate(BaseModel):
    channel: Channel
    audience_type: AudienceType
    audience_ref: uuid.UUID | None = None  # class_id or section_id when applicable
    title: str | None = Field(default=None, max_length=200)
    body: str = Field(min_length=1)
    scheduled_at: datetime | None = None


class MessageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    title: str | None = None
    body: str
    channel: str
    audience_type: str
    audience_ref: uuid.UUID | None = None
    status: str
    scheduled_at: datetime | None = None
    sent_at: datetime | None = None


class DeliveryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    message_id: uuid.UUID
    user_id: uuid.UUID | None = None
    channel: str
    address: str | None = None
    status: str
    provider: str | None = None
    error: str | None = None


class DeliverySummary(BaseModel):
    message_id: uuid.UUID
    total: int
    counts: dict[str, int]
