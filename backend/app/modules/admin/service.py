"""Platform metrics for the Super Admin dashboard and revenue report.

Reads live counts from `schools` / `school_subscriptions` and sums the
`subscription_payments` ledger. Revenue is grouped by the calendar month a
payment was recorded (`paid_at`)."""
from datetime import date, datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import SubscriptionStatus
from app.models.school import School
from app.models.communication import NotificationOutbox, WorkerHeartbeat
from app.models.subscription import (
    SchoolSubscription,
    SubscriptionPayment,
    SubscriptionPlan,
)
from app.models.user import User
from app.modules.admin import schemas


class AdminMetricsService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

    async def _active_subscription_count(self) -> int:
        return (
            await self.db.scalar(
                select(func.count())
                .select_from(SchoolSubscription)
                .where(
                    SchoolSubscription.status == SubscriptionStatus.ACTIVE.value,
                    SchoolSubscription.end_date >= date.today(),
                )
            )
        ) or 0

    async def _revenue_buckets(self, months: int = 12) -> list[schemas.RevenueMonth]:
        """Monthly revenue from the payment ledger, chronological (oldest→newest)."""
        bucket = func.to_char(
            func.date_trunc("month", SubscriptionPayment.paid_at), "YYYY-MM"
        ).label("month")
        rows = (
            await self.db.execute(
                select(
                    bucket,
                    func.coalesce(func.sum(SubscriptionPayment.amount), 0).label("total"),
                    func.count().label("count"),
                )
                .group_by(bucket)
                .order_by(bucket.desc())
                .limit(months)
            )
        ).all()
        return [
            schemas.RevenueMonth(month=r.month, total=float(r.total), count=r.count)
            for r in reversed(rows)
        ]

    async def _month_start_revenue(self) -> float:
        month_start = date.today().replace(day=1)
        return float(
            (
                await self.db.scalar(
                    select(func.coalesce(func.sum(SubscriptionPayment.amount), 0)).where(
                        SubscriptionPayment.paid_at >= month_start
                    )
                )
            )
            or 0
        )

    # ------------------------------ dashboard ---------------------------- #

    async def dashboard(self) -> schemas.AdminDashboard:
        total_schools = (
            await self.db.scalar(select(func.count()).select_from(School))
        ) or 0
        return schemas.AdminDashboard(
            total_schools=total_schools,
            active_subscriptions=await self._active_subscription_count(),
            monthly_revenue=await self._month_start_revenue(),
        )

    async def revenue(self, months: int = 12) -> schemas.RevenueReport:
        buckets = await self._revenue_buckets(months)
        return schemas.RevenueReport(
            total=float(sum(b.total for b in buckets)), months=buckets
        )

    # ------------------------------ billing ------------------------------ #

    async def billing(self, recent_limit: int = 10) -> schemas.BillingReport:
        total_revenue = float(
            (
                await self.db.scalar(
                    select(func.coalesce(func.sum(SubscriptionPayment.amount), 0))
                )
            )
            or 0
        )
        payment_count = (
            await self.db.scalar(select(func.count()).select_from(SubscriptionPayment))
        ) or 0
        pending_amount = float(
            (
                await self.db.scalar(
                    select(func.coalesce(func.sum(SchoolSubscription.net_amount), 0)).where(
                        SchoolSubscription.status == SubscriptionStatus.PENDING.value
                    )
                )
            )
            or 0
        )

        rows = (
            await self.db.execute(
                select(SubscriptionPayment, School.name, SubscriptionPlan.name)
                .join(School, School.id == SubscriptionPayment.school_id)
                .join(
                    SchoolSubscription,
                    SchoolSubscription.id == SubscriptionPayment.subscription_id,
                )
                .join(
                    SubscriptionPlan,
                    SubscriptionPlan.id == SchoolSubscription.plan_id,
                )
                .order_by(SubscriptionPayment.paid_at.desc())
                .limit(recent_limit)
            )
        ).all()
        recent = [
            schemas.PaymentRow(
                id=p.id,
                school_name=school_name,
                plan_name=plan_name,
                amount=float(p.amount),
                paid_at=p.paid_at,
            )
            for p, school_name, plan_name in rows
        ]

        return schemas.BillingReport(
            total_revenue=total_revenue,
            this_month_revenue=await self._month_start_revenue(),
            payment_count=payment_count,
            pending_amount=pending_amount,
            recent=recent,
            months=await self._revenue_buckets(6),
        )

    # --------------------------- transactions ---------------------------- #

    @staticmethod
    def _range_start(range_: str) -> date | None:
        """First day included in the range, or None for all-time."""
        today = date.today()
        if range_ == "month":
            return today.replace(day=1)
        if range_ == "year":
            return today.replace(month=1, day=1)
        return None  # "all"

    async def transactions(
        self, range_: str = "all", limit: int = 500
    ) -> schemas.TransactionsReport:
        """Payments in the selected range plus a bucketed series for the chart.

        `month` buckets by day, `year` and `all` bucket by calendar month.
        """
        if range_ not in ("month", "year", "all"):
            range_ = "all"
        start = self._range_start(range_)
        fmt = "YYYY-MM-DD" if range_ == "month" else "YYYY-MM"

        def _scoped(stmt):  # apply the range's lower bound when there is one
            return stmt if start is None else stmt.where(
                SubscriptionPayment.paid_at >= start
            )

        # Chart buckets (chronological).
        bucket = func.to_char(SubscriptionPayment.paid_at, fmt).label("label")
        bucket_rows = (
            await self.db.execute(
                _scoped(
                    select(
                        bucket,
                        func.coalesce(
                            func.sum(SubscriptionPayment.amount), 0
                        ).label("total"),
                        func.count().label("count"),
                    )
                )
                .group_by(bucket)
                .order_by(bucket.asc())
            )
        ).all()
        buckets = [
            schemas.TransactionBucket(
                label=r.label, total=float(r.total), count=r.count
            )
            for r in bucket_rows
        ]

        total = sum(b.total for b in buckets)
        count = sum(b.count for b in buckets)

        # Full listing (newest first, capped).
        rows = (
            await self.db.execute(
                _scoped(
                    select(SubscriptionPayment, School.name, SubscriptionPlan.name)
                    .join(School, School.id == SubscriptionPayment.school_id)
                    .join(
                        SchoolSubscription,
                        SchoolSubscription.id == SubscriptionPayment.subscription_id,
                    )
                    .join(
                        SubscriptionPlan,
                        SubscriptionPlan.id == SchoolSubscription.plan_id,
                    )
                )
                .order_by(SubscriptionPayment.paid_at.desc())
                .limit(limit)
            )
        ).all()
        transactions = [
            schemas.PaymentRow(
                id=p.id,
                school_name=school_name,
                plan_name=plan_name,
                amount=float(p.amount),
                paid_at=p.paid_at,
            )
            for p, school_name, plan_name in rows
        ]

        return schemas.TransactionsReport(
            range=range_,
            total=float(total),
            count=count,
            buckets=buckets,
            transactions=transactions,
        )

    # ------------------------------ metrics ------------------------------ #

    async def metrics(self) -> schemas.MetricsReport:
        total_schools = (
            await self.db.scalar(select(func.count()).select_from(School))
        ) or 0
        total_users = (
            await self.db.scalar(select(func.count()).select_from(User))
        ) or 0
        active = await self._active_subscription_count()

        total_subs = (
            await self.db.scalar(select(func.count()).select_from(SchoolSubscription))
        ) or 0
        ended = (
            await self.db.scalar(
                select(func.count())
                .select_from(SchoolSubscription)
                .where(
                    SchoolSubscription.status.in_(
                        [
                            SubscriptionStatus.EXPIRED.value,
                            SubscriptionStatus.CANCELLED.value,
                        ]
                    )
                )
            )
        ) or 0
        churn_rate = round((ended / total_subs) * 100, 1) if total_subs else 0.0

        # Active subscriptions grouped by plan → distribution shares.
        dist_rows = (
            await self.db.execute(
                select(SubscriptionPlan.name, func.count().label("count"))
                .select_from(SchoolSubscription)
                .join(SubscriptionPlan, SubscriptionPlan.id == SchoolSubscription.plan_id)
                .where(
                    SchoolSubscription.status == SubscriptionStatus.ACTIVE.value,
                    SchoolSubscription.end_date >= date.today(),
                )
                .group_by(SubscriptionPlan.name)
                .order_by(func.count().desc())
            )
        ).all()
        dist_total = sum(r.count for r in dist_rows) or 1
        plan_distribution = [
            schemas.PlanShare(
                plan_name=r.name,
                count=r.count,
                percent=round((r.count / dist_total) * 100, 1),
            )
            for r in dist_rows
        ]

        return schemas.MetricsReport(
            total_schools=total_schools,
            active_subscriptions=active,
            total_users=total_users,
            monthly_revenue=await self._month_start_revenue(),
            churn_rate=churn_rate,
            plan_distribution=plan_distribution,
            revenue_by_month=await self._revenue_buckets(6),
        )

    async def operations(self) -> schemas.OperationsStatus:
        """Return bounded worker/outbox health without exposing message content."""
        from app.core.config import settings
        from app.worker import OUTBOX_WORKER_NAME

        checked_at = datetime.now(timezone.utc)
        rows = (
            await self.db.execute(
                select(NotificationOutbox.state, func.count())
                .group_by(NotificationOutbox.state)
            )
        ).all()
        counts = {state: int(count) for state, count in rows}
        due_filter = (
            (NotificationOutbox.state == "pending")
            & (NotificationOutbox.available_at <= checked_at)
        )
        expired_lease_filter = (
            (NotificationOutbox.state == "processing")
            & (NotificationOutbox.lease_until.is_not(None))
            & (NotificationOutbox.lease_until <= checked_at)
        )
        oldest_due_at = await self.db.scalar(
            select(func.min(NotificationOutbox.available_at)).where(due_filter)
        )
        due = await self.db.scalar(
            select(func.count()).select_from(NotificationOutbox).where(due_filter)
        ) or 0
        expired_leases = await self.db.scalar(
            select(func.count()).select_from(NotificationOutbox).where(expired_lease_filter)
        ) or 0
        heartbeat = await self.db.get(WorkerHeartbeat, OUTBOX_WORKER_NAME)
        age_seconds = (
            max(0, int((checked_at - heartbeat.last_seen_at).total_seconds()))
            if heartbeat is not None
            else None
        )
        worker_status = (
            "not_seen"
            if heartbeat is None
            else "healthy"
            if age_seconds is not None
            and age_seconds <= settings.OUTBOX_WORKER_STALE_AFTER_SECONDS
            else "stale"
        )
        oldest_due_age_seconds = (
            max(0, int((checked_at - oldest_due_at).total_seconds()))
            if oldest_due_at is not None
            else None
        )
        return schemas.OperationsStatus(
            outbox=schemas.OutboxOperationsStatus(
                pending=counts.get("pending", 0),
                due=int(due),
                processing=counts.get("processing", 0),
                expired_leases=int(expired_leases),
                needs_review=counts.get("needs_review", 0),
                oldest_due_at=oldest_due_at,
                oldest_due_age_seconds=oldest_due_age_seconds,
            ),
            worker=schemas.WorkerOperationsStatus(
                name=OUTBOX_WORKER_NAME,
                status=worker_status,
                last_seen_at=heartbeat.last_seen_at if heartbeat else None,
                age_seconds=age_seconds,
                stale_after_seconds=settings.OUTBOX_WORKER_STALE_AFTER_SECONDS,
            ),
            providers=schemas.ProviderOperationsStatus(
                whatsapp=(
                    "configured"
                    if settings.TWILIO_ACCOUNT_SID
                    and settings.TWILIO_AUTH_TOKEN
                    and settings.TWILIO_WHATSAPP_FROM
                    else "simulated"
                ),
                sms=(
                    "configured"
                    if settings.TWILIO_ACCOUNT_SID
                    and settings.TWILIO_AUTH_TOKEN
                    and settings.TWILIO_SMS_FROM
                    else "simulated"
                ),
                push=(
                    "configured"
                    if settings.FIREBASE_CREDENTIALS_FILE
                    or settings.FIREBASE_CREDENTIALS_JSON
                    else "simulated"
                ),
                email="simulated",
            ),
        )
