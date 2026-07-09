"""Direct message schemas."""
import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class DirectMessageCreate(BaseModel):
    recipient_id: uuid.UUID
    student_id: uuid.UUID | None = None  # the student the message concerns
    kind: Literal["message", "complaint"] = "message"
    body: str = Field(min_length=1, max_length=4000)


class DirectMessageOut(BaseModel):
    id: uuid.UUID
    school_id: uuid.UUID
    sender_id: uuid.UUID
    sender_name: str
    recipient_id: uuid.UUID
    recipient_name: str
    student_id: uuid.UUID | None = None
    kind: str
    body: str
    read_at: datetime | None = None
    created_at: datetime
