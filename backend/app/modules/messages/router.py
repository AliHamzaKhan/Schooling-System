"""Direct message endpoints (1-to-1, e.g. teacher/headmaster ↔ guardian).

All endpoints are self-scoped to the acting user (your inbox, your sent
messages), so they only require school membership — the service enforces that
the recipient belongs to the same school and that only the recipient can mark
a message read.
"""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import CurrentUser, DbDep, require_school_member
from app.modules.messages import schemas
from app.modules.messages.service import DirectMessageService

router = APIRouter(prefix="/schools/{school_id}/messages", tags=["Direct Messages"])

_member = Depends(require_school_member)


@router.post(
    "",
    response_model=schemas.DirectMessageOut,
    status_code=status.HTTP_201_CREATED,
    dependencies=[_member],
)
async def send_message(
    school_id: uuid.UUID,
    data: schemas.DirectMessageCreate,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.DirectMessageOut:
    """Send a direct message or complaint to another member of the school."""
    return await DirectMessageService(db).send(school_id, current_user.id, data)


@router.get("", response_model=list[schemas.DirectMessageOut], dependencies=[_member])
async def list_messages(
    school_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
    box: str = Query(default="inbox", pattern="^(inbox|sent|all)$"),
) -> list[schemas.DirectMessageOut]:
    """The acting user's direct messages (inbox / sent / all), newest first."""
    return await DirectMessageService(db).list_for_user(school_id, current_user.id, box)


@router.patch(
    "/{message_id}/read",
    response_model=schemas.DirectMessageOut,
    dependencies=[_member],
)
async def mark_read(
    school_id: uuid.UUID, message_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.DirectMessageOut:
    return await DirectMessageService(db).mark_read(school_id, message_id, current_user.id)
