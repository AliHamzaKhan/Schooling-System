"""Communication Service: templates, configs, device tokens, broadcasts, delivery."""
import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import (
    AudienceType,
    Channel,
    DeliveryStatus,
    EnrollmentStatus,
    MessageStatus,
    SystemRole,
)
from app.core.exceptions import bad_request, not_found
from app.models.academic import Section, StudentEnrollment
from app.models.communication import (
    DeviceToken,
    Message,
    MessageDelivery,
    NotificationConfig,
    NotificationTemplate,
)
from app.models.role import Role
from app.models.user import User
from app.modules.communication import schemas
from app.modules.communication.providers import notifier


class CommunicationService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ----------------------------- templates ----------------------------- #

    async def create_template(self, school_id: uuid.UUID, data: schemas.TemplateCreate) -> NotificationTemplate:
        dupe = await self.db.scalar(
            select(NotificationTemplate).where(
                NotificationTemplate.school_id == school_id, NotificationTemplate.code == data.code
            )
        )
        if dupe is not None:
            raise bad_request(f"Template code '{data.code}' already exists")
        tpl = NotificationTemplate(
            school_id=school_id, code=data.code, name=data.name, subject=data.subject, body=data.body
        )
        self.db.add(tpl)
        await self.db.flush()
        return tpl

    async def list_templates(self, school_id: uuid.UUID) -> list[NotificationTemplate]:
        result = await self.db.execute(
            select(NotificationTemplate).where(NotificationTemplate.school_id == school_id)
        )
        return list(result.scalars().all())

    # ----------------------------- configs ------------------------------- #

    async def set_config(self, school_id: uuid.UUID, data: schemas.NotificationConfigSet) -> NotificationConfig:
        channels = [c.value for c in data.channels]
        existing = await self.db.scalar(
            select(NotificationConfig).where(
                NotificationConfig.school_id == school_id, NotificationConfig.event == data.event.value
            )
        )
        if existing is not None:
            existing.enabled = data.enabled
            existing.channels = channels
            await self.db.flush()
            return existing
        cfg = NotificationConfig(
            school_id=school_id, event=data.event.value, enabled=data.enabled, channels=channels
        )
        self.db.add(cfg)
        await self.db.flush()
        return cfg

    async def list_configs(self, school_id: uuid.UUID) -> list[NotificationConfig]:
        result = await self.db.execute(
            select(NotificationConfig).where(NotificationConfig.school_id == school_id)
        )
        return list(result.scalars().all())

    # --------------------------- device tokens --------------------------- #

    async def register_token(
        self, school_id: uuid.UUID, user_id: uuid.UUID, data: schemas.DeviceTokenRegister
    ) -> DeviceToken:
        existing = await self.db.scalar(select(DeviceToken).where(DeviceToken.token == data.token))
        if existing is not None:
            existing.user_id = user_id
            existing.school_id = school_id
            existing.platform = data.platform
            await self.db.flush()
            return existing
        dt = DeviceToken(
            school_id=school_id, user_id=user_id, token=data.token, platform=data.platform
        )
        self.db.add(dt)
        await self.db.flush()
        return dt

    async def _tokens_for(self, user_ids: list[uuid.UUID]) -> dict[uuid.UUID, list[str]]:
        if not user_ids:
            return {}
        rows = await self.db.execute(
            select(DeviceToken).where(DeviceToken.user_id.in_(user_ids))
        )
        out: dict[uuid.UUID, list[str]] = {}
        for t in rows.scalars().all():
            out.setdefault(t.user_id, []).append(t.token)
        return out

    # ------------------------- audience resolution ----------------------- #

    async def _resolve_audience(
        self, school_id: uuid.UUID, audience_type: str, audience_ref: uuid.UUID | None
    ) -> list[User]:
        if audience_type == AudienceType.ENTIRE_SCHOOL.value:
            stmt = select(User).where(User.school_id == school_id, User.is_active.is_(True))
        elif audience_type in (
            AudienceType.TEACHERS.value,
            AudienceType.GUARDIANS.value,
            AudienceType.STUDENTS.value,
        ):
            role_code = {
                AudienceType.TEACHERS.value: SystemRole.TEACHER.value,
                AudienceType.GUARDIANS.value: SystemRole.GUARDIAN.value,
                AudienceType.STUDENTS.value: SystemRole.STUDENT.value,
            }[audience_type]
            stmt = (
                select(User)
                .where(User.school_id == school_id, User.is_active.is_(True))
                .join(User.roles)
                .where(Role.code == role_code)
            )
        elif audience_type in (AudienceType.CLASS.value, AudienceType.SECTION.value):
            if audience_ref is None:
                raise bad_request(f"audience_ref is required for audience_type '{audience_type}'")
            stmt = (
                select(User)
                .join(StudentEnrollment, StudentEnrollment.student_id == User.id)
                .where(StudentEnrollment.status == EnrollmentStatus.ACTIVE.value)
            )
            if audience_type == AudienceType.SECTION.value:
                stmt = stmt.where(StudentEnrollment.section_id == audience_ref)
            else:
                stmt = stmt.join(Section, Section.id == StudentEnrollment.section_id).where(
                    Section.class_id == audience_ref
                )
        else:
            raise bad_request(f"Unsupported audience_type '{audience_type}'")

        result = await self.db.execute(stmt)
        return list(result.scalars().unique().all())

    @staticmethod
    def _address_for(channel: str, user: User) -> str | None:
        if channel in (Channel.WHATSAPP.value, Channel.SMS.value):
            return user.phone
        if channel == Channel.EMAIL.value:
            return user.email
        return None  # push handled via device tokens

    # ------------------------------ broadcast ---------------------------- #

    async def create_broadcast(
        self, school_id: uuid.UUID, data: schemas.BroadcastCreate, created_by: uuid.UUID
    ) -> Message:
        message = Message(
            school_id=school_id,
            title=data.title,
            body=data.body,
            channel=data.channel.value,
            audience_type=data.audience_type.value,
            audience_ref=data.audience_ref,
            created_by=created_by,
            status=MessageStatus.SCHEDULED.value if data.scheduled_at else MessageStatus.PENDING.value,
            scheduled_at=data.scheduled_at,
        )
        self.db.add(message)
        await self.db.flush()

        if data.scheduled_at is None:
            await self._send(message)
        return message

    async def _send(self, message: Message) -> Message:
        recipients = await self._resolve_audience(
            message.school_id, message.audience_type, message.audience_ref
        )
        channel = message.channel
        tokens = (
            await self._tokens_for([u.id for u in recipients])
            if channel == Channel.PUSH.value
            else {}
        )

        sent = 0
        failed = 0
        for user in recipients:
            if channel == Channel.PUSH.value:
                addresses = tokens.get(user.id, [])
            else:
                addr = self._address_for(channel, user)
                addresses = [addr] if addr else [None]
            for address in addresses:
                result = await notifier.dispatch(channel, address, message.title, message.body)
                self.db.add(
                    MessageDelivery(
                        school_id=message.school_id,
                        message_id=message.id,
                        user_id=user.id,
                        channel=channel,
                        address=address,
                        status=result.status,
                        provider=result.provider,
                        error=result.error,
                    )
                )
                if result.status == DeliveryStatus.FAILED.value:
                    failed += 1
                else:
                    sent += 1

        if sent and failed:
            message.status = MessageStatus.PARTIAL.value
        elif sent:
            message.status = MessageStatus.SENT.value
        else:
            message.status = MessageStatus.FAILED.value
        message.sent_at = datetime.now(timezone.utc)
        await self.db.flush()
        return message

    async def process_due(self, school_id: uuid.UUID) -> list[Message]:
        """Send any scheduled messages whose time has arrived."""
        now = datetime.now(timezone.utc)
        rows = await self.db.execute(
            select(Message).where(
                Message.school_id == school_id,
                Message.status == MessageStatus.SCHEDULED.value,
                Message.scheduled_at <= now,
            )
        )
        due = list(rows.scalars().all())
        for message in due:
            await self._send(message)
        return due

    async def list_messages(self, school_id: uuid.UUID) -> list[Message]:
        result = await self.db.execute(
            select(Message).where(Message.school_id == school_id).order_by(Message.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_message(self, school_id: uuid.UUID, message_id: uuid.UUID) -> Message:
        msg = await self.db.get(Message, message_id)
        if msg is None or msg.school_id != school_id:
            raise not_found("Message not found in this school")
        return msg

    async def list_deliveries(self, school_id: uuid.UUID, message_id: uuid.UUID) -> list[MessageDelivery]:
        await self.get_message(school_id, message_id)
        result = await self.db.execute(
            select(MessageDelivery).where(MessageDelivery.message_id == message_id)
        )
        return list(result.scalars().all())

    async def delivery_summary(self, school_id: uuid.UUID, message_id: uuid.UUID) -> schemas.DeliverySummary:
        deliveries = await self.list_deliveries(school_id, message_id)
        counts = {s.value: 0 for s in DeliveryStatus}
        for d in deliveries:
            counts[d.status] = counts.get(d.status, 0) + 1
        return schemas.DeliverySummary(message_id=message_id, total=len(deliveries), counts=counts)
