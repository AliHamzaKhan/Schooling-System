"""Compatibility surface for existing public raster avatar/uniform images only."""
import uuid

from fastapi import APIRouter, Response

from app.core.exceptions import not_found
from app.core.storage import get_storage
from app.modules.uploads.policy import PUBLIC_FOLDERS, raster_type

router = APIRouter(include_in_schema=False)


@router.get("/media/{folder}/{school_id}/{filename}")
async def public_image(folder: str, school_id: uuid.UUID, filename: str):
    if folder not in PUBLIC_FOLDERS or any(c in filename for c in ("/", "\\", "%")) or filename in (".", ".."):
        raise not_found("File not found")
    stored = await get_storage().load(f"{folder}/{school_id}/{filename}")
    media_type = raster_type(stored[0]) if stored else None
    if not media_type:
        raise not_found("File not found")
    return Response(stored[0], media_type=media_type, headers={
        "X-Content-Type-Options": "nosniff", "Cache-Control": "no-store",
        "Content-Security-Policy": "default-src 'none'; sandbox",
    })
