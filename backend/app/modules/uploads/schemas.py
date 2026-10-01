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


class StorageUsageOut(BaseModel):
    """File storage used against the subscription plan (quota None = unlimited)."""

    used_bytes: int
    quota_bytes: int | None = None
    plan_code: str | None = None
