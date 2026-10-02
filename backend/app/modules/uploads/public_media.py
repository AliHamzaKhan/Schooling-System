"""School photos and logos (avatar/uniform images), for that school only.

The stored references keep their ``/media/...`` form, but nothing here is
public: the caller must be signed in as a member of the image's school, or be
the platform Super Admin. Anyone else gets 404, so the response does not even
confirm the file exists.
"""
import uuid

from fastapi import APIRouter, Response

from app.core.deps import CurrentUser
from app.core.exceptions import not_found
from app.core.storage import get_storage
from app.modules.permissions.service import PermissionService
from app.modules.uploads.policy import PUBLIC_FOLDERS, raster_type

router = APIRouter(include_in_schema=False)


@router.get("/media/{folder}/{school_id}/{filename}")
async def school_image(folder: str, school_id: uuid.UUID, filename: str, user: CurrentUser):
    if folder not in PUBLIC_FOLDERS or any(c in filename for c in ("/", "\\", "%")) or filename in (".", ".."):
        raise not_found("File not found")
    if not PermissionService.is_super_admin(user) and user.school_id != school_id:
        raise not_found("File not found")
    stored = await get_storage().load(f"{folder}/{school_id}/{filename}")
    media_type = raster_type(stored[0]) if stored else None
    if not media_type:
        raise not_found("File not found")
    return Response(stored[0], media_type=media_type, headers={
        "X-Content-Type-Options": "nosniff", "Cache-Control": "private, no-store",
        "Content-Security-Policy": "default-src 'none'; sandbox",
    })
