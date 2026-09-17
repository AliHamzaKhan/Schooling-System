"""Bound upload memory before passing bytes to the storage adapter."""
from fastapi import UploadFile

from app.core.exceptions import bad_request

CHUNK_BYTES = 64 * 1024


async def read_limited_upload(file: UploadFile, max_bytes: int) -> bytes:
    if max_bytes <= 0:
        raise ValueError("Upload size limit must be positive")
    data = bytearray()
    while True:
        # Read at most one sentinel byte beyond the limit, never the whole file.
        chunk = await file.read(min(CHUNK_BYTES, max_bytes - len(data) + 1))
        if not chunk:
            break
        data.extend(chunk)
        if len(data) > max_bytes:
            raise bad_request("File exceeds the upload size limit")
    if not data:
        raise bad_request("Uploaded file is empty")
    return bytes(data)
