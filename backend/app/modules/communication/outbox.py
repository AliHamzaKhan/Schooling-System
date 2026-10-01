"""Committed notification work with fenced leases and at-most-once attempts.

An attempt marker commits BEFORE provider I/O. An interrupted/ambiguous attempt
is never retried automatically: without provider idempotency it may have sent.
Only work that has not reached a provider attempt is safe to resume.
"""
import hashlib
import json
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import or_, select, update

from app.models.communication import Message, MessageDelivery, NotificationOutbox
from app.models.school import School
from app.modules.communication.providers import DeliveryResult, notifier
from app.modules.communication.service import CommunicationService

LEASE_SECONDS = 300
MAX_JOB_ATTEMPTS = 5
DELIVERY_ERROR_MAX_LENGTH = 255


def _safe_delivery_error(value: object | None) -> str | None:
    """Keep adapter diagnostics within the durable delivery column limit.

    A provider adapter is an integration boundary and may return an arbitrary
    error payload. Letting that overflow abort the completion transaction can
    turn a known terminal result into an ambiguous sending marker.
    """
    if value is None:
        return None
    return str(value)[:DELIVERY_ERROR_MAX_LENGTH]



def now():
    return datetime.now(timezone.utc)


class OutboxWorker:
    def __init__(self, sessions):
        self.sessions = sessions

    async def run_due(self, limit=50):
        """Bounded DB poll; Redis is neither a source of truth nor a dependency."""
        async with self.sessions() as db:
            ids = list((await db.scalars(select(NotificationOutbox.message_id).where(
                or_(
                    (NotificationOutbox.state == "pending") & (NotificationOutbox.available_at <= now()),
                    (NotificationOutbox.state == "processing") & (NotificationOutbox.lease_until <= now()),
                )
            ).order_by(NotificationOutbox.available_at).limit(limit))).all())
        for message_id in ids:
            await self.process(message_id)
        return len(ids)

    async def _owned(self, db, message_id, token):
        job = await db.scalar(select(NotificationOutbox).where(
            NotificationOutbox.message_id == message_id
        ).with_for_update().execution_options(populate_existing=True))
        if job is None or job.state != "processing" or job.lease_token != token or job.lease_until <= now():
            return None
        return job

    async def _claim(self, message_id):
        async with self.sessions() as db, db.begin():
            job = await db.scalar(select(NotificationOutbox).where(
                NotificationOutbox.message_id == message_id
            ).with_for_update(skip_locked=True))
            if job is None or job.state not in {"pending", "processing"}:
                return None
            if job.available_at > now() or (job.state == "processing" and job.lease_until > now()):
                return None
            # A prior worker may have sent before it disappeared. Never resend.
            await db.execute(update(MessageDelivery).where(
                MessageDelivery.message_id == message_id, MessageDelivery.status == "sending"
            ).values(status="uncertain", error="Worker interrupted after attempt started; review before retry"))
            if job.attempts >= MAX_JOB_ATTEMPTS:
                job.state = "needs_review"
                job.last_error = "Worker recovery limit reached; review pending recipients"
                message = await db.get(Message, message_id)
                message.status = "uncertain"
                return None
            job.attempts += 1
            job.state = "processing"
            job.lease_token = uuid.uuid4()
            job.lease_until = now() + timedelta(seconds=LEASE_SECONDS)
            return job.lease_token

    async def _addresses(self, db, message):
        school = await db.get(School, message.school_id)
        if school is None or school.status != "active":
            return {}
        service = CommunicationService(db)
        users = await service._resolve_audience(message.school_id, message.audience_type, message.audience_ref)
        tokens = await service._tokens_for([u.id for u in users]) if message.channel == "push" else {}
        return {
            user.id: set(tokens.get(user.id) or [None]) if message.channel == "push"
            else {service._address_for(message.channel, user)}
            for user in users
        }

    async def _prepare(self, message_id, token):
        async with self.sessions() as db, db.begin():
            job = await self._owned(db, message_id, token)
            if job is None:
                return False
            if job.prepared_at is not None:
                return True
            # Never adopt/re-send historical deliveries by accidentally adding a job.
            if await db.scalar(select(MessageDelivery.id).where(MessageDelivery.message_id == message_id).limit(1)):
                job.state = "needs_review"
                job.last_error = "Existing delivery history requires review"
                return False
            message = await db.get(Message, message_id)
            addresses = await self._addresses(db, message)
            for user_id, targets in addresses.items():
                for address in targets:
                    key = hashlib.sha256(json.dumps([str(user_id), message.channel, address]).encode()).hexdigest()
                    db.add(MessageDelivery(
                        school_id=message.school_id, message_id=message_id, user_id=user_id,
                        channel=message.channel, address=address, status="pending", recipient_key=key,
                    ))
            job.prepared_at = now()
            message.status = "pending"
            return True

    async def _take(self, message_id, token):
        async with self.sessions() as db, db.begin():
            job = await self._owned(db, message_id, token)
            if job is None:
                return None
            delivery = await db.scalar(select(MessageDelivery).where(
                MessageDelivery.message_id == message_id, MessageDelivery.status == "pending"
            ).order_by(MessageDelivery.id).limit(1).with_for_update())
            if delivery is None:
                return None
            message = await db.get(Message, message_id)
            # Do not deliver a frozen address after account/token/roster reassignment.
            eligible = await self._addresses(db, message)
            if delivery.user_id not in eligible or delivery.address not in eligible[delivery.user_id]:
                delivery.status = "failed"
                delivery.error = "Recipient or address is no longer eligible"
                return "skip"
            job.lease_until = now() + timedelta(seconds=LEASE_SECONDS)
            delivery.status = "sending"
            # Leaving this transaction commits the marker before process() calls I/O.
            return delivery.id, delivery.channel, delivery.address, message.title, message.body

    async def _finish(self, message_id, token, delivery_id, result):
        async with self.sessions() as db, db.begin():
            if await self._owned(db, message_id, token) is None:
                return
            delivery = await db.get(MessageDelivery, delivery_id)
            if delivery.status != "sending":
                return
            status = "simulated" if result.stub or result.provider == "stub" else result.status
            if status == "sent":
                status = "accepted"
            if status not in {"simulated", "accepted", "failed", "uncertain"}:
                status = "uncertain"
            delivery.status = status
            delivery.provider = result.provider
            delivery.error = _safe_delivery_error(result.error)
            if status == "accepted":
                message = await db.get(Message, message_id)
                message.sent_at = message.sent_at or now()

    async def _finalize(self, message_id, token):
        async with self.sessions() as db, db.begin():
            job = await self._owned(db, message_id, token)
            if job is None:
                return
            statuses = set((await db.scalars(select(MessageDelivery.status).where(
                MessageDelivery.message_id == message_id
            ))).all())
            message = await db.get(Message, message_id)
            if statuses & {"uncertain", "sending"}:
                message.status, job.state = "uncertain", "needs_review"
            elif "pending" in statuses:
                message.status, job.state = "pending", "pending"
            else:
                job.state = "complete"
                if "accepted" in statuses:
                    message.status = "partial" if statuses != {"accepted"} else "accepted"
                elif statuses == {"simulated"}:
                    message.status = "simulated"
                else:
                    message.status = "failed"
            job.lease_token = job.lease_until = None

    async def _recover(self, message_id, token):
        async with self.sessions() as db, db.begin():
            job = await self._owned(db, message_id, token)
            if job is None:
                return
            job.state = "pending"
            job.available_at = now() + timedelta(seconds=min(300, 5 * 2 ** job.attempts))
            job.last_error = "Worker transaction failed; unattempted work will be retried"
            job.lease_token = job.lease_until = None

    async def process(self, message_id):
        token = await self._claim(message_id)
        if token is None:
            return
        try:
            if not await self._prepare(message_id, token):
                return
            while True:
                item = await self._take(message_id, token)
                if item is None:
                    break
                if item == "skip":
                    continue
                delivery_id, channel, address, title, body = item
                try:
                    result = await notifier.dispatch(channel, address, title, body)
                except Exception:
                    # A custom adapter may throw after accepting a message.
                    result = DeliveryResult(status="uncertain", provider="error",
                                            error="Provider outcome unknown; review before retry")
                await self._finish(message_id, token, delivery_id, result)
            await self._finalize(message_id, token)
        except Exception:
            # No provider retry here. Recovery preserves every durable marker.
            await self._recover(message_id, token)
