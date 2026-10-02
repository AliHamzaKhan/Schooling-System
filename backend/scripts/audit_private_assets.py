"""Inventory persisted asset references without changing metadata or blobs.

Use a read-only database credential in the target environment::

    PRIVATE_ASSET_AUDIT_DATABASE_URL=postgresql+asyncpg://... \
      python scripts/audit_private_assets.py --details

The command explicitly opens a read-only transaction, emits JSON to stdout, and
does not print stored URLs.  Detail rows use the record ID and a short reference
shape so an authorized operator can remediate the source record separately.
"""
from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import os
from pathlib import Path
import sys
from collections import Counter
from dataclasses import asdict, dataclass
from typing import Any, Iterable
from urllib.parse import urlsplit

# Running ``python scripts/audit_private_assets.py`` puts ``scripts`` rather
# than the backend root on ``sys.path``.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

from app.models.course import Course
from app.models.document import StudentDocument
from app.models.homework import Submission
from app.models.school import School
from app.models.school_info import SchoolInfo
from app.models.user import User


PRIVATE_SOURCES = {"document", "submission"}
# Photos and logos: visible only to signed-in members of the school.
PUBLIC_SOURCES = {"avatar", "uniform", "logo"}
POLICY_SOURCES = {"course_cover", "profile_other", "school_setting_other"}


@dataclass(frozen=True)
class AssetFinding:
    source: str
    record_id: str
    school_id: str
    state: str
    target_visibility: str
    reference_shape: str


def _shape(reference: str) -> str:
    """Describe an unsafe reference without exposing its path or query."""
    digest = hashlib.sha256(reference.encode("utf-8")).hexdigest()[:12]
    try:
        parsed = urlsplit(reference)
    except ValueError:
        return f"unparseable#{digest}"
    if parsed.scheme or parsed.netloc:
        return f"origin:{parsed.scheme or 'unknown'}://{parsed.netloc or 'unknown'}#{digest}"
    segments = [part for part in parsed.path.split("/") if part]
    return f"path:{'/'.join(segments[:2]) or 'empty'}#{digest}"


def _local_media_key(reference: str, public_origin: str | None) -> tuple[str | None, str | None]:
    """Return a local media key or an inventory state for a non-local reference."""
    try:
        parsed = urlsplit(reference)
    except ValueError:
        return None, "invalid_reference"
    if parsed.query or parsed.fragment:
        return None, "invalid_reference"
    if parsed.scheme or parsed.netloc:
        if parsed.scheme not in {"http", "https"}:
            return None, "invalid_reference"
        if not public_origin:
            return None, "external_reference"
        origin = urlsplit(public_origin)
        if (parsed.scheme, parsed.netloc) != (origin.scheme, origin.netloc):
            return None, "external_reference"
    if not parsed.path.startswith("/media/"):
        return None, "invalid_reference"
    key = parsed.path[len("/media/"):]
    if not key or any(part in {"", ".", ".."} for part in key.split("/")) or "%" in key or "\\" in key:
        return None, "invalid_reference"
    return key, None


def classify_reference(
    *, source: str, record_id: str, school_id: str, reference: str | None,
    owner_id: str | None = None, public_origin: str | None = None,
) -> AssetFinding:
    """Classify a persisted reference against the F04.2 storage contract."""
    normalized = (reference or "").strip()
    if not normalized:
        return AssetFinding(source, record_id, school_id, "empty", "none", "empty")
    key, error = _local_media_key(normalized, public_origin)
    if error:
        visibility = "review" if error == "external_reference" else "blocked"
        return AssetFinding(source, record_id, school_id, error, visibility, _shape(normalized))
    assert key is not None
    parts = key.split("/")
    if source in PRIVATE_SOURCES:
        kind = "documents" if source == "document" else "submissions"
        private = ["private", kind, school_id, str(owner_id)]
        legacy = [kind, school_id]
        if len(parts) == 5 and parts[:4] == private:
            return AssetFinding(source, record_id, school_id, "managed_private", "private", _shape(normalized))
        if len(parts) == 3 and parts[:2] == legacy:
            return AssetFinding(source, record_id, school_id, "legacy_record_path", "private", _shape(normalized))
        return AssetFinding(source, record_id, school_id, "misowned_or_unrecognized_local", "blocked", _shape(normalized))
    if source in PUBLIC_SOURCES:
        expected = "uniform" if source == "uniform" else "avatars"
        if len(parts) == 3 and parts[:2] == [expected, school_id]:
            return AssetFinding(source, record_id, school_id, "school_members_path", "school_members", _shape(normalized))
        return AssetFinding(source, record_id, school_id, "unrecognized_local_path", "review", _shape(normalized))
    if source in POLICY_SOURCES:
        return AssetFinding(source, record_id, school_id, "managed_or_local_reference", "policy_decision", _shape(normalized))
    return AssetFinding(source, record_id, school_id, "unclassified", "review", _shape(normalized))


def _url_values(value: Any, path: str = "") -> Iterable[tuple[str, str]]:
    """Find URL-looking metadata values, preserving only their JSON key path."""
    if isinstance(value, dict):
        for key, nested in value.items():
            child_path = f"{path}.{key}" if path else str(key)
            yield from _url_values(nested, child_path)
    elif isinstance(value, list):
        for index, nested in enumerate(value):
            yield from _url_values(nested, f"{path}[{index}]")
    elif isinstance(value, str) and (path.endswith("_url") or value.startswith(("/media/", "http://", "https://"))):
        yield path, value


async def collect_findings(db: AsyncSession, public_origin: str | None) -> list[AssetFinding]:
    findings: list[AssetFinding] = []
    documents = (await db.execute(select(StudentDocument))).scalars()
    for row in documents:
        findings.append(classify_reference(
            source="document", record_id=str(row.id), school_id=str(row.school_id),
            owner_id=str(row.uploaded_by) if row.uploaded_by else None,
            reference=row.file_url, public_origin=public_origin,
        ))
    submissions = (await db.execute(select(Submission))).scalars()
    for row in submissions:
        findings.append(classify_reference(
            source="submission", record_id=str(row.id), school_id=str(row.school_id),
            owner_id=str(row.student_id), reference=row.attachment_url, public_origin=public_origin,
        ))
    infos = (await db.execute(select(SchoolInfo))).scalars()
    for row in infos:
        findings.append(classify_reference(
            source="uniform", record_id=str(row.id), school_id=str(row.school_id),
            reference=row.uniform_image_url, public_origin=public_origin,
        ))
    courses = (await db.execute(select(Course))).scalars()
    for row in courses:
        findings.append(classify_reference(
            source="course_cover", record_id=str(row.id), school_id=str(row.school_id),
            reference=row.cover_url, public_origin=public_origin,
        ))
    users = (await db.execute(select(User))).scalars()
    for row in users:
        for path, value in _url_values(row.profile_metadata or {}):
            source = "avatar" if path == "avatar_url" else "profile_other"
            findings.append(classify_reference(
                source=source, record_id=f"{row.id}:{path}", school_id=str(row.school_id),
                reference=value, public_origin=public_origin,
            ))
    schools = (await db.execute(select(School))).scalars()
    for row in schools:
        for path, value in _url_values(row.settings or {}):
            source = "logo" if path == "logo_url" else "school_setting_other"
            findings.append(classify_reference(
                source=source, record_id=f"{row.id}:{path}", school_id=str(row.id),
                reference=value, public_origin=public_origin,
            ))
    return findings


def report(findings: list[AssetFinding], include_details: bool) -> dict[str, Any]:
    summary = Counter((finding.source, finding.state, finding.target_visibility) for finding in findings)
    output: dict[str, Any] = {
        "read_only": True,
        "finding_count": len(findings),
        "summary": [
            {"source": source, "state": state, "target_visibility": visibility, "count": count}
            for (source, state, visibility), count in sorted(summary.items())
        ],
    }
    if include_details:
        output["details"] = [asdict(finding) for finding in findings]
    return output


async def run(database_url: str, public_origin: str | None, include_details: bool) -> dict[str, Any]:
    engine = create_async_engine(database_url)
    try:
        async with AsyncSession(engine) as db:
            async with db.begin():
                await db.execute(text("SET TRANSACTION READ ONLY"))
                findings = await collect_findings(db, public_origin)
        return report(findings, include_details)
    finally:
        await engine.dispose()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database-url", default=os.environ.get("PRIVATE_ASSET_AUDIT_DATABASE_URL"))
    parser.add_argument("--public-origin", default=os.environ.get("PRIVATE_ASSET_AUDIT_PUBLIC_ORIGIN"))
    parser.add_argument("--details", action="store_true", help="include record IDs and redacted reference shapes")
    args = parser.parse_args()
    if not args.database_url:
        parser.error("set PRIVATE_ASSET_AUDIT_DATABASE_URL or pass --database-url")
    try:
        print(json.dumps(asyncio.run(run(args.database_url, args.public_origin, args.details)), indent=2, sort_keys=True))
    except Exception as exc:
        print(json.dumps({"error": "audit failed", "error_type": type(exc).__name__}))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
