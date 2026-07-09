"""Pluggable file storage.

The rest of the app depends only on the [StorageBackend] interface, so the
concrete provider — local disk for development, or S3 / Firebase / GCS in
production — can be swapped by implementing a new backend and pointing
``settings.STORAGE_BACKEND`` at it, with no call-site changes. ``get_storage()``
returns the configured singleton.

Adding a cloud provider later is a two-step change:
  1. Implement a ``StorageBackend`` subclass (e.g. ``S3StorageBackend``) whose
     ``save`` uploads the bytes and returns the object's public/signed URL.
  2. Wire it into ``get_storage()`` under its ``STORAGE_BACKEND`` value.
Nothing that calls ``get_storage().save(...)`` needs to change.
"""
from __future__ import annotations

import mimetypes
import re
import uuid
from abc import ABC, abstractmethod
from functools import lru_cache
from pathlib import Path

from app.core.config import settings

_UNSAFE = re.compile(r"[^A-Za-z0-9._-]+")


def _safe_name(name: str) -> str:
    """Collapse anything non-portable in a filename and cap its length."""
    cleaned = _UNSAFE.sub("_", (name or "").strip()).lstrip(".") or "file"
    return cleaned[-120:]


def build_key(folder: str, filename: str) -> str:
    """A collision-resistant storage key: ``folder/<uuid>_<safe filename>``."""
    return f"{folder.strip('/')}/{uuid.uuid4().hex}_{_safe_name(filename)}"


class StorageBackend(ABC):
    """Provider-agnostic blob storage."""

    @abstractmethod
    async def save(self, *, key: str, data: bytes, content_type: str | None = None) -> str:
        """Persist ``data`` under ``key`` and return a URL to store/serve it."""

    @abstractmethod
    async def load(self, key: str) -> tuple[bytes, str] | None:
        """Return ``(data, content_type)`` for a stored object, or ``None``.

        Cloud backends whose URLs are served directly by the provider may return
        ``None`` here — the app only reads back objects for the local backend.
        """

    @abstractmethod
    async def delete(self, key: str) -> None:
        """Remove a stored object (no-op if it doesn't exist)."""


class LocalStorageBackend(StorageBackend):
    """Development/debug backend that writes under ``STORAGE_LOCAL_DIR`` and is
    served by the ``/media`` static mount (see ``app/main.py``)."""

    def __init__(self, root: str | None = None) -> None:
        self._root = Path(root or settings.STORAGE_LOCAL_DIR).resolve()
        self._root.mkdir(parents=True, exist_ok=True)

    def _path(self, key: str) -> Path:
        path = (self._root / key).resolve()
        # Path-traversal guard: the resolved path must stay inside the root.
        if self._root not in path.parents and path != self._root:
            raise ValueError("Invalid storage key")
        return path

    async def save(self, *, key: str, data: bytes, content_type: str | None = None) -> str:
        path = self._path(key)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        base = settings.PUBLIC_BASE_URL.rstrip("/")
        return f"{base}/media/{key}" if base else f"/media/{key}"

    async def load(self, key: str) -> tuple[bytes, str] | None:
        path = self._path(key)
        if not path.is_file():
            return None
        content_type = mimetypes.guess_type(str(path))[0] or "application/octet-stream"
        return path.read_bytes(), content_type

    async def delete(self, key: str) -> None:
        path = self._path(key)
        if path.is_file():
            path.unlink()


# --- Future cloud backends -------------------------------------------------- #
# Implement and register these under get_storage() when moving off local disk.
#
# class S3StorageBackend(StorageBackend):        # boto3 / aioboto3 + a bucket
#     async def save(self, *, key, data, content_type=None) -> str:
#         await self._client.put_object(Bucket=..., Key=key, Body=data,
#                                       ContentType=content_type)
#         return f"https://{bucket}.s3.amazonaws.com/{key}"  # or a presigned URL
#
# class FirebaseStorageBackend(StorageBackend):  # firebase_admin / google-cloud-storage
#     ...


@lru_cache
def get_storage() -> StorageBackend:
    """The storage backend selected by ``settings.STORAGE_BACKEND``."""
    backend = (settings.STORAGE_BACKEND or "local").lower()
    if backend == "local":
        return LocalStorageBackend()
    # Register cloud providers here once implemented, e.g.:
    #   if backend == "s3": return S3StorageBackend(...)
    #   if backend == "firebase": return FirebaseStorageBackend(...)
    raise RuntimeError(
        f"Unsupported STORAGE_BACKEND '{backend}'. Only 'local' is implemented; "
        "add the matching StorageBackend and register it in get_storage()."
    )
