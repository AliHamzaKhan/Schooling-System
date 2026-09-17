"""Upload schemas."""
from pydantic import BaseModel


class UploadOut(BaseModel):
    """Stored reference plus metadata. Private references require a record-based
    download ticket; they are not public links. Callers persist ``url`` in
    ``attachment_url`` or ``file_url``, never a temporary ticket URL.
    """

    url: str
    filename: str
    size: int
    content_type: str | None = None
