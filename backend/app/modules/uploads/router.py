"""Generic file upload endpoint backed by the pluggable storage layer.

Any active member of the school may upload (e.g. a student attaching a PDF to a
homework submission). The response carries the stored file's reference URL, which
callers persist wherever a file reference is needed (``attachment_url`` on a
submission, ``file_url`` on a document, …). The concrete storage provider is
selected by ``settings.STORAGE_BACKEND`` — see ``app/core/storage.py``.
"""
import uuid

from fastapi import APIRouter, Depends, File, Form, UploadFile, status

from app.core.config import settings
from app.core.deps import CurrentUser, require_school_member
from app.core.exceptions import bad_request, service_unavailable
from app.core.storage import build_key, get_storage
from app.modules.uploads import schemas
from app.modules.uploads.limits import read_limited_upload
from app.modules.uploads.policy import (
    PUBLIC_FOLDERS,
    canonical_filename,
    inspect_content,
    validate_folder,
)
from app.modules.uploads.scanner import ScanRejected, ScannerUnavailable, get_upload_scanner

router = APIRouter(prefix="/schools/{school_id}/uploads", tags=["Uploads"])


@router.post(
    "",
    response_model=schemas.UploadOut,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_school_member)],
)
async def upload_file(
    school_id: uuid.UUID,
    current_user: CurrentUser,
    file: UploadFile = File(...),
    folder: str = Form(default="submissions"),
) -> schemas.UploadOut:
    """Store an uploaded file and return its URL.

    ``folder`` is a logical bucket ("submissions", "documents", …) used to
    namespace the storage key; files are additionally scoped under the school id.
    """
    safe_folder = validate_folder(folder)
    max_bytes = settings.MAX_UPLOAD_MB * 1024 * 1024
    data = await read_limited_upload(file, max_bytes)
    content = inspect_content(safe_folder, data)
    try:
        await get_upload_scanner().scan(data)
    except ScanRejected:
        raise bad_request("File rejected by security scanning")
    except ScannerUnavailable:
        raise service_unavailable("Upload scanning is temporarily unavailable. Try again later.")
    if safe_folder in PUBLIC_FOLDERS:
        prefix = f"{safe_folder}/{school_id}"
    else:
        prefix = f"private/{safe_folder}/{school_id}/{current_user.id}"
    key = build_key(prefix, canonical_filename(file.filename or "upload", content))
    url = await get_storage().save(key=key, data=data, content_type=content.media_type)
    return schemas.UploadOut(
        url=url,
        filename=key.rsplit("/", 1)[-1],
        size=len(data),
        content_type=content.media_type,
    )
