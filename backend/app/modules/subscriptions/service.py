"""Subscription plan CRUD, per-school subscription lifecycle, and status.

Plan/instance writes are Super Admin scoped (enforced at the router). The status
read is available to any school member (for the Headmaster expiry alert). Expiry
is *soft*: subscriptions past their end date are lazily flipped to `expired` and
reflected in status/lists, but no API access is blocked here.
"""
import calendar
import re
import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import BillingPeriod, DiscountType, SubscriptionStatus
from app.core.exceptions import bad_request, not_found
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

    async def assign(self, data: schemas.SubscriptionCreate) -> SchoolSubscription:
        school = await self.db.get(School, data.school_id)
        if school is None:
            raise not_found("School not found")
        plan = await self.get_plan(data.plan_id)
        if not plan.is_active:
            raise bad_request("Cannot assign an archived plan")

        start = data.start_date or date.today()
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

        sub = SchoolSubscription(
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
        return await self._load_out(sub.id)

    async def renew(
        self, subscription_id: uuid.UUID, data: schemas.SubscriptionRenew
    ) -> SchoolSubscription:
        sub = await self.db.get(SchoolSubscription, subscription_id)
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
                subscription_id=sub.id,
                school_id=sub.school_id,
                amount=sub.net_amount,
                period_start=new_start,
                period_end=new_end,
            )
        )
        await self.db.flush()
        return await self._load_out(sub.id)

    async def cancel(self, subscription_id: uuid.UUID) -> SchoolSubscription:
        sub = await self.db.get(SchoolSubscription, subscription_id)
        if sub is None:
            raise not_found("Subscription not found")
        sub.status = SubscriptionStatus.CANCELLED.value
        await self.db.flush()
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
        )
