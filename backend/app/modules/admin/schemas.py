"""Platform-level (Super Admin) dashboard, revenue, billing + metrics schemas."""
import uuid
from datetime import datetime

from pydantic import BaseModel


class AdminDashboard(BaseModel):
    total_schools: int
    active_subscriptions: int
    monthly_revenue: float  # sum of payments in the current calendar month


class RevenueMonth(BaseModel):
    month: str  # "YYYY-MM"
    total: float
    count: int  # number of payments recorded in the month


class RevenueReport(BaseModel):
    total: float  # sum across the returned window
    months: list[RevenueMonth]


# --------------------------------------------------------------------------- #
# Billing
# --------------------------------------------------------------------------- #


class PaymentRow(BaseModel):
    id: uuid.UUID
    school_name: str | None = None
    plan_name: str | None = None
    amount: float
    paid_at: datetime


class BillingReport(BaseModel):
    total_revenue: float  # all-time sum of recorded payments
    this_month_revenue: float
    payment_count: int
    pending_amount: float  # net owed by subscriptions still in `pending`
    recent: list[PaymentRow]
    months: list[RevenueMonth]  # revenue trend (chronological)


# --------------------------------------------------------------------------- #
# Transactions (filtered ledger view for the "View All" screen)
# --------------------------------------------------------------------------- #


class TransactionBucket(BaseModel):
    """One point on the transactions progress chart."""

    label: str  # "YYYY-MM-DD" (month range) or "YYYY-MM" (year / all)
    total: float
    count: int


class TransactionsReport(BaseModel):
    range: str  # "month" | "year" | "all"
    total: float  # sum of payments in the range
    count: int  # number of payments in the range
    buckets: list[TransactionBucket]  # chart series, chronological
    transactions: list[PaymentRow]  # full listing, newest first


# --------------------------------------------------------------------------- #
# Metrics
# --------------------------------------------------------------------------- #


class PlanShare(BaseModel):
    plan_name: str
    count: int
    percent: float  # share of active subscriptions


class MetricsReport(BaseModel):
    total_schools: int
    active_subscriptions: int
    total_users: int
    monthly_revenue: float
    churn_rate: float  # % of subscriptions that are expired/cancelled
    plan_distribution: list[PlanShare]
    revenue_by_month: list[RevenueMonth]


# --------------------------------------------------------------------------- #
# Operations (platform-only, aggregate and content-free)
# --------------------------------------------------------------------------- #


class OutboxOperationsStatus(BaseModel):
    pending: int
    due: int
    processing: int
    expired_leases: int
    needs_review: int
    oldest_due_at: datetime | None = None
    oldest_due_age_seconds: int | None = None


class WorkerOperationsStatus(BaseModel):
    name: str
    status: str  # healthy | stale | not_seen
    last_seen_at: datetime | None = None
    age_seconds: int | None = None
    stale_after_seconds: int


class ProviderOperationsStatus(BaseModel):
    """Configuration modes only; this intentionally contains no credentials."""

    whatsapp: str  # configured | simulated
    sms: str  # configured | simulated
    push: str  # configured | simulated
    email: str  # simulated until a real adapter is added


class OperationsStatus(BaseModel):
    """Aggregate operational state; intentionally omits work and recipient data."""

    outbox: OutboxOperationsStatus
    worker: WorkerOperationsStatus
    providers: ProviderOperationsStatus
