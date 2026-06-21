"""AI Features schemas."""
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class GenerateRequest(BaseModel):
    feature: str = Field(min_length=2, max_length=80, description="e.g. lesson_plan, summary, quiz")
    prompt: str = Field(min_length=1, max_length=8000)
    system: str | None = Field(default=None, max_length=2000)


class GenerateResponse(BaseModel):
    id: uuid.UUID
    feature: str
    response: str
    provider: str


class InteractionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    feature: str
    prompt: str
    response: str
    provider: str
    created_by: uuid.UUID | None = None
    created_at: datetime
