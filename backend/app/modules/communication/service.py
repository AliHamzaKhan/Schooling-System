"""Communication Service: templates, configs, device tokens, broadcasts, delivery."""
import hashlib
import uuid
from datetime import datetime, timezone

from sqlalchemy import and_, func, or_, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import (
    AudienceType,
    Channel,
    DeliveryStatus,
    EnrollmentStatus,
    MessageStatus,
    SystemRole,
)
from app.core.exceptions import AppHTTPException, ErrorCode, bad_request, forbidden, not_found
from app.core.pagination import OffsetPage
from app.models.academic import SchoolClass, Section, StudentEnrollment
from app.models.associations import guardian_students
from app.models.communication import (
    DeviceToken,
    Message,
    MessageDelivery,
    NotificationConfig,
    NotificationTemplate,
    NotificationOutbox,
)
from app.models.role import Role
from app.models.user import User
from app.modules.communication import schemas


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

    async def _validate_audience_reference(
        self, school_id: uuid.UUID, audience_type: str, audience_ref: uuid.UUID | None
    ) -> None:
        model = {
            AudienceType.CLASS.value: SchoolClass,
            AudienceType.SECTION.value: Section,
            AudienceType.STUDENT_GUARDIANS.value: User,
        }.get(audience_type)
        if model is None:
            if audience_ref is not None:
                raise bad_request("This audience does not accept an audience_ref")
            return
        if audience_ref is None:
            raise bad_request("audience_ref is required for this audience")
        stmt = select(model.id).where(model.id == audience_ref, model.school_id == school_id)
        if model is User:
            stmt = stmt.where(
                User.is_active.is_(True),
                User.roles.any(Role.code == SystemRole.STUDENT.value),
            )
        if await self.db.scalar(stmt) is None:
            # Do not disclose whether the ID exists in a different school.
            raise not_found("Audience reference not found in this school")

    async def _resolve_audience(
        self, school_id: uuid.UUID, audience_type: str, audience_ref: uuid.UUID | None
    ) -> list[User]:
        # Recheck at delivery time too: queued work may outlive enrollment changes.
        await self._validate_audience_reference(school_id, audience_type, audience_ref)
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
                .join(Section, Section.id == StudentEnrollment.section_id)
                .join(SchoolClass, SchoolClass.id == Section.class_id)
                .where(
                    User.school_id == school_id,
                    User.is_active.is_(True),
                    User.roles.any(Role.code == SystemRole.STUDENT.value),
                    StudentEnrollment.school_id == school_id,
                    StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                    Section.school_id == school_id,
                    SchoolClass.school_id == school_id,
                )
            )
            if audience_type == AudienceType.SECTION.value:
                stmt = stmt.where(StudentEnrollment.section_id == audience_ref)
            else:
                stmt = stmt.where(
                    Section.class_id == audience_ref
                )
        elif audience_type == AudienceType.STUDENT_GUARDIANS.value:
            if audience_ref is None:
                raise bad_request(
                    "audience_ref (the student id) is required for "
                    f"audience_type '{audience_type}'"
                )
            stmt = (
                select(User)
                .join(guardian_students, guardian_students.c.guardian_id == User.id)
                .where(
                    guardian_students.c.student_id == audience_ref,
                    guardian_students.c.school_id == school_id,
                    User.school_id == school_id,
                    User.is_active.is_(True),
                    User.roles.any(Role.code == SystemRole.GUARDIAN.value),
                )
            )
        else:
            raise bad_request(f"Unsupported audience_type '{audience_type}'")

        result = await self.db.execute(stmt)
        return list(result.scalars().unique().all())

    # -------------------------- event notifications ---------------------- #

    async def channels_for_event(self, school_id: uuid.UUID, event: str) -> list[str]:
        """Channels a school has enabled for ``event``; empty when opted out.

        An absent config means the event is off, so a school must opt in before
        any guardian is messaged.
        """
        config = await self.db.scalar(
            select(NotificationConfig).where(
                NotificationConfig.school_id == school_id,
                NotificationConfig.event == event,
            )
        )
        if config is None or not config.enabled:
            return []
        return list(config.channels or [])

    async def notify_student_guardians(
        self,
        school_id: uuid.UUID,
        student_id: uuid.UUID,
        *,
        event: str,
        title: str,
        body: str,
        created_by: uuid.UUID | None = None,
    ) -> list[Message]:
        """Message a student's guardians on every channel enabled for ``event``.

        Returns one [Message] per channel (empty when the school has not enabled
        the event), each dispatched and logged through the normal delivery
        pipeline so failures are visible and retryable.
        """
        messages: list[Message] = []
        for channel in await self.channels_for_event(school_id, event):
            message = Message(
                school_id=school_id,
                title=title,
                body=body,
                channel=channel,
                audience_type=AudienceType.STUDENT_GUARDIANS.value,
                audience_ref=student_id,
                created_by=created_by,
                status=MessageStatus.PENDING.value,
            )
            self.db.add(message)
            await self.db.flush()
            await self._dispatch_delivery(message)
            messages.append(message)
        return messages

    @staticmethod
    def _address_for(channel: str, user: User) -> str | None:
        if channel in (Channel.WHATSAPP.value, Channel.SMS.value):
            return user.phone
        if channel == Channel.EMAIL.value:
            return user.email
        return None  # push handled via device tokens

    # ------------------------------ broadcast ---------------------------- #

    async def create_broadcast(
        self, school_id: uuid.UUID, data: schemas.BroadcastCreate, created_by: uuid.UUID,
        *, idempotency_key: uuid.UUID | None = None,
    ) -> Message:
        if idempotency_key is not None:
            key = int.from_bytes(hashlib.sha256(b"broadcast:" + idempotency_key.bytes).digest()[:8], "big", signed=True)
            await self.db.execute(text("SELECT pg_advisory_xact_lock(:key)"), {"key": key})
            existing = await self.db.get(Message, idempotency_key)
            if existing is not None:
                if not (
                    existing.school_id == school_id and existing.created_by == created_by
                    and existing.title == data.title and existing.body == data.body
                    and existing.channel == data.channel.value
                    and existing.audience_type == data.audience_type.value
                    and existing.audience_ref == data.audience_ref
                    and existing.scheduled_at == data.scheduled_at
                ):
                    raise AppHTTPException(409, "Broadcast request key was already used for different details", ErrorCode.CONFLICT)
                # Replay resolves the SAME intent with its current delivery state.
                return existing
        # Validate before persisting OR enqueueing, including scheduled messages.
        await self._validate_audience_reference(
            school_id, data.audience_type.value, data.audience_ref
        )
        message = Message(
            id=idempotency_key or uuid.uuid4(),
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

        await self._dispatch_delivery(message)
        return message

    async def _dispatch_delivery(self, message: Message) -> None:
        """Persist intent in the business transaction; never send or enqueue here."""
        self.db.add(NotificationOutbox(
            message_id=message.id,
            available_at=message.scheduled_at or datetime.now(timezone.utc),
        ))
        await self.db.flush()

    @staticmethod
    def _oversight_condition(user: User):
        """School scoping is always applied separately, including for admins."""
        roles = {role.code for role in user.roles}
        if roles & {SystemRole.HEADMASTER.value, SystemRole.SUPER_ADMIN.value}:
            return True
        return Message.created_by == user.id

    @classmethod
    def _visibility_condition(cls, school_id: uuid.UUID, user: User):
        """Current membership is authoritative; historical sends grant no access.

        Evaluate in SQL before serialization, for both feed and direct URLs.
        No per-message recipient expansion or delivery/provider dependency.
        """
        roles = {role.code for role in user.roles}
        unscoped = Message.audience_ref.is_(None)
        audiences = [and_(Message.audience_type == AudienceType.ENTIRE_SCHOOL.value, unscoped)]
        for role, audience in (
            (SystemRole.TEACHER, AudienceType.TEACHERS),
            (SystemRole.GUARDIAN, AudienceType.GUARDIANS),
            (SystemRole.STUDENT, AudienceType.STUDENTS),
        ):
            if role.value in roles:
                audiences.append(and_(Message.audience_type == audience.value, unscoped))
        if SystemRole.STUDENT.value in roles:
            # Include the entire hierarchy: legacy corrupt cross-school links
            # must not grant access even if one referenced ID happens to match.
            enrolled = select(Section.id, Section.class_id).join(
                StudentEnrollment, StudentEnrollment.section_id == Section.id,
            ).join(SchoolClass, SchoolClass.id == Section.class_id).where(
                StudentEnrollment.student_id == user.id,
                StudentEnrollment.school_id == school_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                Section.school_id == school_id, SchoolClass.school_id == school_id,
            ).subquery()
            audiences.extend([
                and_(Message.audience_type == AudienceType.SECTION.value,
                     Message.audience_ref.in_(select(enrolled.c.id))),
                and_(Message.audience_type == AudienceType.CLASS.value,
                     Message.audience_ref.in_(select(enrolled.c.class_id))),
            ])
        if SystemRole.GUARDIAN.value in roles:
            children = select(User.id).join(
                guardian_students, guardian_students.c.student_id == User.id,
            ).where(
                guardian_students.c.guardian_id == user.id,
                guardian_students.c.school_id == school_id,
                User.school_id == school_id, User.is_active.is_(True),
                User.roles.any(Role.code == SystemRole.STUDENT.value),
            )
            audiences.append(and_(
                Message.audience_type == AudienceType.STUDENT_GUARDIANS.value,
                Message.audience_ref.in_(children),
            ))
        return or_(cls._oversight_condition(user), and_(
            user.school_id == school_id, user.is_active,
            or_(Message.scheduled_at <= datetime.now(timezone.utc), and_(
                Message.scheduled_at.is_(None), Message.status != MessageStatus.SCHEDULED.value,
            )),
            or_(*audiences),
        ))

    async def process_due(self, school_id: uuid.UUID, user: User) -> list[Message]:
        """List due committed work. The independent worker performs delivery.

        Historical messages without an outbox are intentionally not requeued.
        """
        now = datetime.now(timezone.utc)
        rows = await self.db.execute(
            select(Message).join(NotificationOutbox, NotificationOutbox.message_id == Message.id).where(
                Message.school_id == school_id,
                Message.status == MessageStatus.SCHEDULED.value,
                Message.scheduled_at <= now,
                self._oversight_condition(user),
            )
        )
        return list(rows.scalars().all())

    async def list_messages(
        self, school_id: uuid.UUID, user: User, page: OffsetPage | None = None,
    ) -> list[Message]:
        """Return a bounded page after enforcing tenant and audience visibility."""
        stmt = select(Message).where(
            Message.school_id == school_id, self._visibility_condition(school_id, user),
        ).order_by(Message.created_at.desc(), Message.id.desc())
        if page is not None:
            stmt = page.apply(stmt)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_visible_message(self, school_id: uuid.UUID, message_id: uuid.UUID, user: User) -> Message:
        msg = await self.db.scalar(select(Message).where(
            Message.id == message_id, Message.school_id == school_id,
            self._visibility_condition(school_id, user),
        ))
        if msg is None:
            # Same response for missing, foreign-school and hidden messages.
            raise not_found("Message not found in this school")
        return msg

    async def get_message(self, school_id: uuid.UUID, message_id: uuid.UUID) -> Message:
        """Internal school lookup; HTTP callers must also authorize visibility/review."""
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

    async def require_review_access(self, school_id: uuid.UUID, message_id: uuid.UUID, user: User) -> None:
        message = await self.get_message(school_id, message_id)
        roles = {role.code for role in user.roles}
        if message.created_by != user.id and not roles & {SystemRole.HEADMASTER.value, SystemRole.SUPER_ADMIN.value}:
            raise forbidden("Delivery review is limited to the sender and school administrators")

    async def review_broadcast(
        self, school_id: uuid.UUID, message_id: uuid.UUID, limit: int, offset: int,
    ) -> schemas.BroadcastReview:
        message = await self.get_message(school_id, message_id)
        job = await self.db.get(NotificationOutbox, message_id)
        counts = {status.value: 0 for status in DeliveryStatus}
        grouped = await self.db.execute(select(MessageDelivery.status, func.count()).where(
            MessageDelivery.message_id == message_id, MessageDelivery.school_id == school_id
        ).group_by(MessageDelivery.status))
        counts.update(dict(grouped.all()))
        rows = await self.db.execute(select(MessageDelivery, User.full_name).outerjoin(
            User, (User.id == MessageDelivery.user_id) & (User.school_id == school_id)
        ).where(MessageDelivery.message_id == message_id, MessageDelivery.school_id == school_id)
            .order_by(MessageDelivery.id).offset(offset).limit(limit))
        items = []
        for delivery, name in rows:
            address = delivery.address
            if not address:
                label = "No address registered"
            elif delivery.channel == "push":
                label = "Registered device"
            elif delivery.channel == "email":
                label = "Email address on file"
            else:
                label = "Phone ending " + address[-2:]
            items.append(schemas.DeliveryReviewItem(
                id=delivery.id, recipient=name or "Former or unavailable recipient",
                address_label=label, status=delivery.status,
                provider=delivery.provider if delivery.provider in {"twilio", "fcm", "stub", "none", "error"} else None,
                updated_at=delivery.updated_at,
            ))
        total = sum(counts.values())
        return schemas.BroadcastReview(
            message=schemas.MessageOut.model_validate(message),
            outbox_state=job.state if job else "legacy", worker_attempts=job.attempts if job else 0,
            available_at=job.available_at if job else None,
            lease_expired=bool(job and job.state == "processing" and job.lease_until and job.lease_until <= datetime.now(timezone.utc)),
            counts=counts, total=total, offset=offset, has_more=offset + len(items) < total, items=items,
        )
