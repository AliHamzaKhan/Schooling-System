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
