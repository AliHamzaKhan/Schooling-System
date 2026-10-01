"""Subscription plan CRUD, per-school subscription lifecycle, and status.

Plan/instance writes are Super Admin scoped (enforced at the router). The status
read is available to any school member (for the Headmaster expiry alert). Expiry
is *soft*: subscriptions past their end date are lazily flipped to `expired` and
reflected in status/lists, but no API access is blocked here.
"""
import calendar
import hashlib
import re
import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy import select, text, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import cache
from app.core.enums import BillingPeriod, DiscountType, SubscriptionStatus
from app.core.exceptions import AppHTTPException, ErrorCode, bad_request, not_found
from app.modules.subscriptions.capacity import active_student_count
from app.models.school import School
from app.models.subscription import (
    SchoolSubscription,
    SubscriptionPayment,
    SubscriptionPlan,
)
from app.modules.subscriptions import schemas

# Days-before-expiry at which the Headmaster expiry alert should start showing.
EXPIRY_WARNING_DAYS = 7


def _add_months(start: date, months: int) -> date:
    """Return `start` advanced by `months`, clamping the day to month length."""
    zero_based = start.month - 1 + months
    year = start.year + zero_based // 12
    month = zero_based % 12 + 1
    day = min(start.day, calendar.monthrange(year, month)[1])
    return date(year, month, day)


def _slugify(name: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return slug or "plan"


def _net_amount(
    base: Decimal, discount_type: DiscountType, discount_value: Decimal
) -> Decimal:
    """Apply the discount to `base`, never dropping below zero."""
    if discount_type is DiscountType.PERCENT:
        net = base * (Decimal(1) - discount_value / Decimal(100))
    elif discount_type is DiscountType.FIXED:
        net = base - discount_value
    else:
        net = base
    return max(net, Decimal(0)).quantize(Decimal("0.01"))


class SubscriptionService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------- plans ------------------------------- #

    async def list_plans(self, include_archived: bool = False) -> list[SubscriptionPlan]:
        stmt = select(SubscriptionPlan).order_by(SubscriptionPlan.price)
        if not include_archived:
            stmt = stmt.where(SubscriptionPlan.is_active.is_(True))
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_plan(self, plan_id: uuid.UUID) -> SubscriptionPlan:
        plan = await self.db.get(SubscriptionPlan, plan_id)
        if plan is None:
            raise not_found("Subscription plan not found")
        return plan

    async def _unique_code(self, name: str) -> str:
        base = _slugify(name)
        code = base
        i = 2
        while await self.db.scalar(
            select(SubscriptionPlan).where(SubscriptionPlan.code == code)
        ):
            code = f"{base}-{i}"
            i += 1
        return code

    async def create_plan(self, data: schemas.PlanCreate) -> SubscriptionPlan:
        plan = SubscriptionPlan(
            code=await self._unique_code(data.name),
            name=data.name,
            description=data.description,
            price=Decimal(str(data.price)),
            billing_period=data.billing_period.value,
            modules=data.modules,
            max_students=data.max_students,
            storage_quota_mb=data.storage_quota_mb,
        )
        self.db.add(plan)
        await self.db.flush()
        await self.db.refresh(plan)
        return plan

    async def update_plan(
        self, plan_id: uuid.UUID, data: schemas.PlanUpdate
    ) -> SubscriptionPlan:
        plan = await self.get_plan(plan_id)
        payload = data.model_dump(exclude_unset=True)
        if "price" in payload and payload["price"] is not None:
            payload["price"] = Decimal(str(payload["price"]))
        if "billing_period" in payload and payload["billing_period"] is not None:
            payload["billing_period"] = payload["billing_period"].value
        for field, value in payload.items():
            setattr(plan, field, value)
        await self.db.flush()
        await self.db.refresh(plan)
        return plan

    async def archive_plan(self, plan_id: uuid.UUID) -> SubscriptionPlan:
        plan = await self.get_plan(plan_id)
        plan.is_active = False
        await self.db.flush()
        await self.db.refresh(plan)
        return plan

    # --------------------------- subscriptions --------------------------- #

    async def _expire_past_due(self) -> None:
        """Flip any `active` subscription whose end date has passed to `expired`."""
        await self.db.execute(
            update(SchoolSubscription)
            .where(
                SchoolSubscription.status == SubscriptionStatus.ACTIVE.value,
                SchoolSubscription.end_date < date.today(),
            )
            .values(status=SubscriptionStatus.EXPIRED.value)
        )

    async def _lock_idempotency_key(self, scope: bytes, key: uuid.UUID) -> None:
        """Serialize retries for a durable ledger/request identity.

        The row identity alone prevents duplicate records after commit.  The
        advisory transaction lock also closes the check-then-insert window for
        overlapping requests before either transaction has committed.
        """
        lock_key = int.from_bytes(
            hashlib.sha256(scope + key.bytes).digest()[:8], "big", signed=True
        )
        await self.db.execute(
            text("SELECT pg_advisory_xact_lock(:key)"), {"key": lock_key}
        )

    @staticmethod
    def _same_assignment(
        subscription: SchoolSubscription,
        data: schemas.SubscriptionCreate,
        start: date,
    ) -> bool:
        """Check immutable assignment inputs when a request key is retried."""
        return (
            subscription.school_id == data.school_id
            and subscription.plan_id == data.plan_id
            and subscription.start_date == start
            and subscription.discount_type == data.discount_type.value
            and subscription.discount_value == Decimal(str(data.discount_value))
            # A missing override means "use the plan cap". That cap is
            # deliberately snapshotted, so a later plan edit must not make an
            # otherwise identical retry conflict with its original request.
            and (
                data.max_students is None
                or subscription.max_students == data.max_students
            )
        )

    async def assign(
        self,
        data: schemas.SubscriptionCreate,
        *,
        idempotency_key: uuid.UUID | None = None,
    ) -> SchoolSubscription:
        start = data.start_date or date.today()
        if idempotency_key is not None:
            await self._lock_idempotency_key(b"subscription-assignment:", idempotency_key)
            existing = await self.db.get(SchoolSubscription, idempotency_key)
            if existing is not None:
                if not self._same_assignment(existing, data, start):
                    raise AppHTTPException(
                        409,
                        "Subscription request key was already used for different details",
                        ErrorCode.CONFLICT,
                    )
                return await self._load_out(existing.id)

        # Serializing assignments on the school makes the active-subscription
        # replacement and the corresponding initial ledger entry one atomic
        # state transition.
        school = await self.db.scalar(
            select(School).where(School.id == data.school_id).with_for_update()
        )
        if school is None:
            raise not_found("School not found")
        plan = await self.get_plan(data.plan_id)
        if not plan.is_active:
            raise bad_request("Cannot assign an archived plan")

        period = BillingPeriod(plan.billing_period)
        end = _add_months(start, period.months)
        base = Decimal(str(plan.price))
        net = _net_amount(base, data.discount_type, Decimal(str(data.discount_value)))
        status = (
            SubscriptionStatus.ACTIVE if data.activate else SubscriptionStatus.PENDING
        )

        # Only one active subscription per school: retire any current active one.
        if status is SubscriptionStatus.ACTIVE:
            await self.db.execute(
                update(SchoolSubscription)
                .where(
                    SchoolSubscription.school_id == school.id,
                    SchoolSubscription.status == SubscriptionStatus.ACTIVE.value,
                )
                .values(status=SubscriptionStatus.CANCELLED.value)
            )

        # Snapshot the student cap from the plan unless the admin overrode it.
        max_students = (
            data.max_students if data.max_students is not None else plan.max_students
        )
        sub = SchoolSubscription(
            id=idempotency_key or uuid.uuid4(),
            school_id=school.id,
            plan_id=plan.id,
            status=status.value,
            start_date=start,
            end_date=end,
            billing_period=plan.billing_period,
            base_price=base,
            discount_type=data.discount_type.value,
            discount_value=Decimal(str(data.discount_value)),
            net_amount=net,
            max_students=max_students,
        )
        self.db.add(sub)
        await self.db.flush()

        if status is SubscriptionStatus.ACTIVE:
            self.db.add(
                SubscriptionPayment(
                    subscription_id=sub.id,
                    school_id=school.id,
                    amount=net,
                    period_start=start,
                    period_end=end,
                )
            )
            school.subscription_plan_id = plan.id
            school.status = "active"

        await self.db.flush()
        await cache.invalidate(cache.tenant_status_key(school.id))
        return await self._load_out(sub.id)

    async def renew(
        self,
        subscription_id: uuid.UUID,
        data: schemas.SubscriptionRenew,
        *,
        idempotency_key: uuid.UUID | None = None,
    ) -> SchoolSubscription:
        if idempotency_key is not None:
            await self._lock_idempotency_key(b"subscription-renewal:", idempotency_key)
            existing = await self.db.get(SubscriptionPayment, idempotency_key)
            if existing is not None:
                if existing.subscription_id != subscription_id:
                    raise AppHTTPException(
                        409,
                        "Subscription request key was already used for a different renewal",
                        ErrorCode.CONFLICT,
                    )
                return await self._load_out(subscription_id)

        sub = await self.db.scalar(
            select(SchoolSubscription)
            .where(SchoolSubscription.id == subscription_id)
            .with_for_update()
        )
        if sub is None:
            raise not_found("Subscription not found")

        # Continue from the later of today or the current end date.
        new_start = max(sub.end_date, date.today())
        period = BillingPeriod(sub.billing_period)
        new_end = _add_months(new_start, period.months)

        sub.status = SubscriptionStatus.ACTIVE.value
        sub.end_date = new_end
        self.db.add(
            SubscriptionPayment(
                id=idempotency_key or uuid.uuid4(),
                subscription_id=sub.id,
                school_id=sub.school_id,
                amount=sub.net_amount,
                period_start=new_start,
                period_end=new_end,
            )
        )
        await self.db.flush()
        await cache.invalidate(cache.tenant_status_key(sub.school_id))
        return await self._load_out(sub.id)

    async def cancel(self, subscription_id: uuid.UUID) -> SchoolSubscription:
        sub = await self.db.scalar(
            select(SchoolSubscription)
            .where(SchoolSubscription.id == subscription_id)
            .with_for_update()
        )
        if sub is None:
            raise not_found("Subscription not found")
        sub.status = SubscriptionStatus.CANCELLED.value
        await self.db.flush()
        await cache.invalidate(cache.tenant_status_key(sub.school_id))
        return await self._load_out(sub.id)

    async def _load_out(self, subscription_id: uuid.UUID) -> schemas.SubscriptionOut:
        row = (
            await self.db.execute(
                select(SchoolSubscription, School.name, SubscriptionPlan.name)
                .join(School, School.id == SchoolSubscription.school_id)
                .join(SubscriptionPlan, SubscriptionPlan.id == SchoolSubscription.plan_id)
                .where(SchoolSubscription.id == subscription_id)
            )
        ).one()
        return self._to_out(*row)

    @staticmethod
    def _to_out(
        sub: SchoolSubscription, school_name: str, plan_name: str
    ) -> schemas.SubscriptionOut:
        return schemas.SubscriptionOut(
            id=sub.id,
            school_id=sub.school_id,
            school_name=school_name,
            plan_id=sub.plan_id,
            plan_name=plan_name,
            status=sub.status,
            start_date=sub.start_date,
            end_date=sub.end_date,
            billing_period=sub.billing_period,
            base_price=float(sub.base_price),
            discount_type=sub.discount_type,
            discount_value=float(sub.discount_value),
            net_amount=float(sub.net_amount),
            max_students=sub.max_students,
            created_at=sub.created_at,
        )

    async def list_subscriptions(
        self, status_filter: str = "all"
    ) -> list[schemas.SubscriptionOut]:
        await self._expire_past_due()
        stmt = (
            select(SchoolSubscription, School.name, SubscriptionPlan.name)
            .join(School, School.id == SchoolSubscription.school_id)
            .join(SubscriptionPlan, SubscriptionPlan.id == SchoolSubscription.plan_id)
            .order_by(SchoolSubscription.created_at.desc())
        )
        active = SubscriptionStatus.ACTIVE.value
        pending = SubscriptionStatus.PENDING.value
        history = (SubscriptionStatus.EXPIRED.value, SubscriptionStatus.CANCELLED.value)
        if status_filter == "active":
            stmt = stmt.where(SchoolSubscription.status == active)
        elif status_filter == "pending":
            stmt = stmt.where(SchoolSubscription.status == pending)
        elif status_filter == "history":
            stmt = stmt.where(SchoolSubscription.status.in_(history))
        rows = (await self.db.execute(stmt)).all()
        return [self._to_out(*row) for row in rows]

    async def list_school_payments(
        self, school_id: uuid.UUID
    ) -> list[schemas.PaymentOut]:
        """The school's payment ledger (newest first), with the plan name of the
        subscription each payment was recorded against."""
        stmt = (
            select(SubscriptionPayment, SubscriptionPlan.name)
            .join(
                SchoolSubscription,
                SchoolSubscription.id == SubscriptionPayment.subscription_id,
            )
            .join(
                SubscriptionPlan,
                SubscriptionPlan.id == SchoolSubscription.plan_id,
            )
            .where(SubscriptionPayment.school_id == school_id)
            .order_by(SubscriptionPayment.paid_at.desc())
        )
        rows = (await self.db.execute(stmt)).all()
        return [
            schemas.PaymentOut(
                id=payment.id,
                amount=float(payment.amount),
                paid_at=payment.paid_at,
                period_start=payment.period_start,
                period_end=payment.period_end,
                status=payment.status,
                plan_name=plan_name,
            )
            for payment, plan_name in rows
        ]

    async def get_school_status(
        self, school_id: uuid.UUID
    ) -> schemas.SubscriptionStatusOut:
        await self._expire_past_due()
        # Prefer the active subscription; otherwise the most recent one.
        sub = await self.db.scalar(
            select(SchoolSubscription)
            .where(SchoolSubscription.school_id == school_id)
            .order_by(
                (SchoolSubscription.status == SubscriptionStatus.ACTIVE.value).desc(),
                SchoolSubscription.end_date.desc(),
            )
            .limit(1)
        )
        if sub is None:
            return schemas.SubscriptionStatusOut(has_subscription=False)

        plan_name = await self.db.scalar(
            select(SubscriptionPlan.name).where(SubscriptionPlan.id == sub.plan_id)
        )
        days_remaining = (sub.end_date - date.today()).days
        is_expired = sub.status == SubscriptionStatus.EXPIRED.value or days_remaining < 0
        is_expiring_soon = is_expired or (0 <= days_remaining <= EXPIRY_WARNING_DAYS)
        return schemas.SubscriptionStatusOut(
            has_subscription=True,
            status=sub.status,
            plan_name=plan_name,
            start_date=sub.start_date,
            end_date=sub.end_date,
            days_remaining=days_remaining,
            is_expiring_soon=is_expiring_soon,
            net_amount=float(sub.net_amount),
            max_students=sub.max_students,
            current_students=await active_student_count(self.db, school_id),
        )
