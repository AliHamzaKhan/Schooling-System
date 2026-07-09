"""Upload schemas."""
from pydantic import BaseModel


class UploadOut(BaseModel):
    """The stored file's public URL plus metadata. Callers persist ``url``
    wherever a file reference is needed (``attachment_url``, ``file_url``, …)."""

    url: str
    filename: str
    size: int
    content_type: str | None = None
