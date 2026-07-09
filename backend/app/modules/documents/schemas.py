"""Student document schemas."""
import uuid

from pydantic import BaseModel, ConfigDict, Field


class DocumentCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    doc_type: str | None = Field(default=None, max_length=50)
    file_url: str = Field(min_length=1, max_length=500)


class DocumentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    student_id: uuid.UUID
    title: str
    doc_type: str | None = None
    file_url: str
    uploaded_by: uuid.UUID | None = None
