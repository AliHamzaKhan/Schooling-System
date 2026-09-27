"""Allowlisted upload folders and content signatures for new assets.

Stored metadata is never used as proof of a file's type.  This policy applies
only to new uploads; historical references remain governed by the F04.2
record-authorized download boundary and the F04.3 inventory process.
"""
from dataclasses import dataclass

from app.core.exceptions import bad_request


PUBLIC_FOLDERS = frozenset({"avatars", "uniform"})
PRIVATE_FOLDERS = frozenset({"documents", "submissions", "payment_proofs"})
ALLOWED_FOLDERS = PUBLIC_FOLDERS | PRIVATE_FOLDERS


@dataclass(frozen=True)
class UploadContent:
    media_type: str
    extension: str


def raster_type(data: bytes) -> str | None:
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"
    if data.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"
    if data.startswith(b"RIFF") and data[8:12] == b"WEBP":
        return "image/webp"
    return None


_EXTENSIONS = {
    "application/pdf": ".pdf",
    "image/png": ".png",
    "image/jpeg": ".jpg",
    "image/webp": ".webp",
}


def validate_folder(folder: str) -> str:
    """Accept only named, intentionally supported storage categories."""
    raw = (folder or "").strip()
    safe = "".join(char for char in raw if char.isalnum() or char in ("-", "_"))
    if raw != safe or safe not in ALLOWED_FOLDERS:
        raise bad_request("Unsupported upload folder")
    return safe


def inspect_content(folder: str, data: bytes) -> UploadContent:
    """Derive a supported media type from bytes, never from a form header."""
    raster = raster_type(data)
    if folder in PUBLIC_FOLDERS:
        if raster is None:
            raise bad_request("Public images must be PNG, JPEG or WebP")
        return UploadContent(raster, _EXTENSIONS[raster])
    if data.startswith(b"%PDF-"):
        return UploadContent("application/pdf", _EXTENSIONS["application/pdf"])
    if raster is not None:
        return UploadContent(raster, _EXTENSIONS[raster])
    raise bad_request("Private attachments must be PDF, PNG, JPEG or WebP")


def canonical_filename(filename: str, content: UploadContent) -> str:
    """Discard a caller-chosen extension before the key is made public/private."""
    raw = (filename or "upload").strip()
    stem = raw.rsplit(".", 1)[0] if "." in raw else raw
    return f"{stem or 'upload'}{content.extension}"
