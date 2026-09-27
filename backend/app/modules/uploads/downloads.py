"""Short-lived, resource-bound download tickets; no account token in file URLs."""
import hashlib
import logging
import uuid
from datetime import timedelta
from urllib.parse import quote

from fastapi import APIRouter, Query, Request, Response
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.deps import CurrentUser, DbDep, enforce_school_context, verify_active_session
from app.core.exceptions import credentials_exception, not_found
from app.core.security import JWTError, _create_token, decode_token
from app.core.storage import get_storage
from app.models.role import Role
from app.models.user import User
from app.modules.uploads.access import authorize_attachment

router = APIRouter(tags=["Private files"])
HEADERS = {"Cache-Control": "private, no-store", "Referrer-Policy": "no-referrer",
           "X-Content-Type-Options": "nosniff"}


class DownloadLogFilter(logging.Filter):
    def filter(self, record):
        # Uvicorn's access log includes query strings by default. Queries may
        # carry bearer capabilities, reset values, or PII, so access logs retain
        # only the path for every request (not merely file-download tickets).
        if isinstance(record.args, tuple) and len(record.args) == 5:
            args = list(record.args)
            if isinstance(args[2], str) and "?" in args[2]:
                args[2] = args[2].split("?", 1)[0]
                record.args = tuple(args)
        return True


logging.getLogger("uvicorn.access").addFilter(DownloadLogFilter())


@router.post("/schools/{school_id}/files/{kind}/{record_id}/ticket")
async def issue_ticket(school_id: uuid.UUID, kind: str, record_id: uuid.UUID,
                       current_user: CurrentUser, db: DbDep, response: Response, request: Request):
    await enforce_school_context(school_id, current_user, db)
    key = await authorize_attachment(db, school_id, kind, record_id, current_user)
    token = _create_token(str(current_user.id), "file_download", timedelta(seconds=60),
                         school=str(school_id), kind=kind, record=str(record_id),
                         sid=request.state.auth_session_id,
                         blob=hashlib.sha256(key.encode()).hexdigest())
    response.headers.update(HEADERS)
    return {"path": f"{settings.API_V1_PREFIX}/file-download?ticket={token}", "expires_in": 60}


@router.get("/file-download")
async def download(db: DbDep, ticket: str = Query(max_length=4096)):
    try:
        payload = decode_token(ticket)
        if payload.get("type") != "file_download":
            raise ValueError()
        user_id = uuid.UUID(payload["sub"])
        school_id = uuid.UUID(payload["school"])
        record_id = uuid.UUID(payload["record"])
        session_id = uuid.UUID(payload["sid"])
        kind = payload["kind"]
    except (JWTError, ValueError, KeyError, TypeError):
        raise credentials_exception()
    await verify_active_session(db, user_id, session_id)
    user = await db.scalar(select(User).where(User.id == user_id).options(
        selectinload(User.roles).selectinload(Role.permissions)))
    if user is None or not user.is_active:
        raise credentials_exception()
    await enforce_school_context(school_id, user, db)
    key = await authorize_attachment(db, school_id, kind, record_id, user)
    if payload.get("blob") != hashlib.sha256(key.encode()).hexdigest():
        raise credentials_exception()
    stored = await get_storage().load(key)
    if stored is None:
        raise not_found("Attachment not found")
    data, _ = stored
    filename = key.rsplit("/", 1)[-1]
    return Response(data, media_type="application/octet-stream", headers={
        **HEADERS, "Content-Disposition": f"attachment; filename*=UTF-8''{quote(filename)}",
    })
