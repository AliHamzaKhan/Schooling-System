"""Subscription plans, per-school subscriptions, and status request/response schemas."""
import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field

from app.core.enums import BillingPeriod, DiscountType, SubscriptionStatus

# --------------------------------------------------------------------------- #
# Plans
# --------------------------------------------------------------------------- #


class PlanCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    description: str | None = Field(default=None, max_length=500)
    price: float = Field(ge=0)
    billing_period: BillingPeriod = BillingPeriod.MONTHLY
    modules: list[str] = Field(default_factory=list)


class PlanUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    description: str | None = Field(default=None, max_length=500)
    price: float | None = Field(default=None, ge=0)
    billing_period: BillingPeriod | None = None
    modules: list[str] | None = None
    is_active: bool | None = None


class PlanOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    code: str
    name: str
    description: str | None = None
    price: float
    billing_period: str
    modules: list[str]
    is_active: bool


# --------------------------------------------------------------------------- #
# Subscriptions (per-school instances)
# --------------------------------------------------------------------------- #


class SubscriptionCreate(BaseModel):
    school_id: uuid.UUID
    plan_id: uuid.UUID
    discount_type: DiscountType = DiscountType.NONE
    discount_value: float = Field(default=0, ge=0)
    start_date: date | None = None
    # When True the subscription starts active and an initial payment is
    # recorded; when False it is created as `pending` (no payment yet).
    activate: bool = True


class SubscriptionRenew(BaseModel):
    # Optional overrides for the renewal term; default keeps the current plan
    # and discount and extends from the current end date.
    activate: bool = True


class SubscriptionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    school_name: str | None = None
    plan_id: uuid.UUID
    plan_name: str | None = None
    status: str
    start_date: date
    end_date: date
    billing_period: str
    base_price: float
    discount_type: str
    discount_value: float
    net_amount: float
    created_at: datetime


class PaymentOut(BaseModel):
    """One recorded payment in a school's billing ledger."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    amount: float
    paid_at: datetime
    period_start: date
    period_end: date
    status: str
    plan_name: str | None = None


class SubscriptionStatusOut(BaseModel):
    """Lightweight status for a school (consumed by the headmaster expiry alert)."""

    has_subscription: bool
    status: str | None = None
    plan_name: str | None = None
    start_date: date | None = None
    end_date: date | None = None
    days_remaining: int | None = None
    is_expiring_soon: bool = False
    net_amount: float | None = None
