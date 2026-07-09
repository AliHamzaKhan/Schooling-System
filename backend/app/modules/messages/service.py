"""Direct message service: 1-to-1 messages/complaints between school members."""
import uuid
from datetime import datetime, timezone

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import bad_request, forbidden, not_found
from app.models.direct_message import DirectMessage
from app.models.user import User
from app.modules.messages import schemas


class DirectMessageService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _names(self, ids: set[uuid.UUID]) -> dict[uuid.UUID, str]:
        if not ids:
            return {}
        rows = await self.db.execute(
            select(User.id, User.full_name).where(User.id.in_(ids))
        )
        return dict(rows.all())

    def _out(
        self, m: DirectMessage, names: dict[uuid.UUID, str]
    ) -> schemas.DirectMessageOut:
        return schemas.DirectMessageOut(
            id=m.id,
            school_id=m.school_id,
            sender_id=m.sender_id,
            sender_name=names.get(m.sender_id, ""),
            recipient_id=m.recipient_id,
            recipient_name=names.get(m.recipient_id, ""),
            student_id=m.student_id,
            kind=m.kind,
            body=m.body,
            read_at=m.read_at,
            created_at=m.created_at,
        )

    async def send(
        self, school_id: uuid.UUID, sender_id: uuid.UUID, data: schemas.DirectMessageCreate
    ) -> schemas.DirectMessageOut:
        if data.recipient_id == sender_id:
            raise bad_request("You cannot message yourself")
        recipient = await self.db.get(User, data.recipient_id)
        if recipient is None or recipient.school_id != school_id:
            raise not_found("Recipient not found in this school")
        message = DirectMessage(
            school_id=school_id,
            sender_id=sender_id,
            recipient_id=data.recipient_id,
            student_id=data.student_id,
            kind=data.kind,
            body=data.body,
        )
        self.db.add(message)
        await self.db.flush()
        names = await self._names({message.sender_id, message.recipient_id})
        return self._out(message, names)

    async def list_for_user(
        self, school_id: uuid.UUID, user_id: uuid.UUID, box: str = "inbox"
    ) -> list[schemas.DirectMessageOut]:
        """The acting user's messages: 'inbox' (received), 'sent', or 'all'."""
        stmt = select(DirectMessage).where(DirectMessage.school_id == school_id)
        if box == "sent":
            stmt = stmt.where(DirectMessage.sender_id == user_id)
        elif box == "all":
            stmt = stmt.where(
                or_(
                    DirectMessage.sender_id == user_id,
                    DirectMessage.recipient_id == user_id,
                )
            )
        else:  # inbox
            stmt = stmt.where(DirectMessage.recipient_id == user_id)
        stmt = stmt.order_by(DirectMessage.created_at.desc())
        messages = list((await self.db.execute(stmt)).scalars().all())
        ids: set[uuid.UUID] = set()
        for m in messages:
            ids.add(m.sender_id)
            ids.add(m.recipient_id)
        names = await self._names(ids)
        return [self._out(m, names) for m in messages]

    async def mark_read(
        self, school_id: uuid.UUID, message_id: uuid.UUID, user_id: uuid.UUID
    ) -> schemas.DirectMessageOut:
        message = await self.db.get(DirectMessage, message_id)
        if message is None or message.school_id != school_id:
            raise not_found("Message not found in this school")
        if message.recipient_id != user_id:
            raise forbidden("Only the recipient can mark a message as read")
        if message.read_at is None:
            message.read_at = datetime.now(timezone.utc)
            await self.db.flush()
        names = await self._names({message.sender_id, message.recipient_id})
        return self._out(message, names)
