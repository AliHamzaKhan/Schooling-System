"""Find and remove stored uploads that no record references any more.

An upload becomes an orphan when a form is abandoned after the file was stored
or a record later points at a different file. Only rows in the
``stored_uploads`` ledger are considered, so files stored before the ledger
existed are never touched. Records themselves are never deleted here.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Iterable
from urllib.parse import urlsplit

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.storage import StorageBackend
from app.models.course import Course
from app.models.document import StudentDocument
from app.models.fees import Payment
from app.models.homework import Submission
from app.models.school import School
from app.models.school_info import SchoolInfo
from app.models.upload import StoredUpload
from app.models.user import User


def media_key(reference: str | None) -> str | None:
    """The storage key in a ``/media/<key>`` reference, or None."""
    if not reference:
        return None
    try:
        path = urlsplit(reference.strip()).path
    except ValueError:
        return None
    marker = "/media/"
    index = path.find(marker)
    return path[index + len(marker):] or None if index >= 0 else None


def _strings(value: Any) -> Iterable[str]:
    if isinstance(value, dict):
        for nested in value.values():
            yield from _strings(nested)
    elif isinstance(value, list):
        for nested in value:
            yield from _strings(nested)
    elif isinstance(value, str):
        yield value


async def referenced_keys(db: AsyncSession) -> set[str]:
    """Every storage key a record still points at."""
    references: list[str | None] = []
    for column in (
        StudentDocument.file_url, Submission.attachment_url, Payment.proof_url,
        SchoolInfo.uniform_image_url, Course.cover_url,
    ):
        references.extend((await db.execute(select(column).where(column.is_not(None)))).scalars())
    for column in (SchoolInfo.achievements, User.profile_metadata, School.settings):
        for value in (await db.execute(select(column).where(column.is_not(None)))).scalars():
            references.extend(_strings(value))
    return {key for key in map(media_key, references) if key}


@dataclass
class CleanupResult:
    orphan_count: int
    orphan_bytes: int
    deleted: bool


async def cleanup_unreferenced(
    db: AsyncSession, storage: StorageBackend, *, min_age_days: int = 7, apply: bool = False,
    now: datetime | None = None,
) -> CleanupResult:
    """Report (or with ``apply`` delete) ledger uploads older than ``min_age_days``
    that no record references. The age floor protects uploads whose record is
    still being filled in."""
    cutoff = (now or datetime.now(timezone.utc)) - timedelta(days=min_age_days)
    keep = await referenced_keys(db)
    rows = (await db.execute(select(StoredUpload).where(StoredUpload.created_at < cutoff))).scalars().all()
    orphans = [row for row in rows if row.storage_key not in keep]
    if apply and orphans:
        for row in orphans:
            await storage.delete(row.storage_key)
        await db.execute(delete(StoredUpload).where(StoredUpload.id.in_([row.id for row in orphans])))
    return CleanupResult(len(orphans), sum(row.size_bytes for row in orphans), apply)
