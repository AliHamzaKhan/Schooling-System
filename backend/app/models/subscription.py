"""Subscription plans, per-school subscription instances, and the payment ledger.

A [SubscriptionPlan] is an admin-editable product (name, price, billing period,
and the feature [modules] it unlocks). A [SchoolSubscription] is one school's
running instance of a plan — with a start/end window, an optional discount, and
a net amount. Every payment against a subscription is recorded as a
[SubscriptionPayment]; revenue reports read straight from that ledger.
"""
import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    func,
)
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import BillingPeriod, DiscountType, SubscriptionStatus
from app.models.base import Base, TimestampMixin, UUIDMixin


class SubscriptionPlan(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "subscription_plans"

    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    # Recurring price for one billing term, in the platform currency.
    price: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0, nullable=False)
    billing_period: Mapped[str] = mapped_column(
        String(20), default=BillingPeriod.MONTHLY.value, nullable=False
    )
    # Module values (app.core.enums.Module) unlocked by this plan.
    modules: Mapped[list[str]] = mapped_column(ARRAY(String(50)), default=list, nullable=False)
    # Cap on active students a school on this plan may have. NULL = unlimited.
    max_students: Mapped[int | None] = mapped_column(Integer, nullable=True)
    # File-storage quota for schools on this plan, in MB. None = unlimited.
    storage_quota_mb: Mapped[int | None] = mapped_column(Integer, nullable=True)
    # Archived plans (is_active=False) stay for history but are hidden from new
    # assignments instead of being hard-deleted.
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    schools: Mapped[list["School"]] = relationship(back_populates="subscription_plan")  # noqa: F821
    subscriptions: Mapped[list["SchoolSubscription"]] = relationship(
        back_populates="plan"
    )


class SchoolSubscription(Base, UUIDMixin, TimestampMixin):
    """A single school's subscription to a plan for one billing window."""

    __tablename__ = "school_subscriptions"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("schools.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    plan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("subscription_plans.id"), nullable=False
    )
    status: Mapped[str] = mapped_column(
        String(20), default=SubscriptionStatus.ACTIVE.value, nullable=False, index=True
    )
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)

    # Snapshots taken at assignment time so later plan edits don't rewrite history.
    billing_period: Mapped[str] = mapped_column(String(20), nullable=False)
    base_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    discount_type: Mapped[str] = mapped_column(
        String(20), default=DiscountType.NONE.value, nullable=False
    )
    discount_value: Mapped[Decimal] = mapped_column(Numeric(10, 2), default=0, nullable=False)
    # Final amount owed for the term after the discount is applied.
    net_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    # Student cap for this subscription, snapshot from the plan at assignment
    # time (an admin may override it). NULL = unlimited.
    max_students: Mapped[int | None] = mapped_column(Integer, nullable=True)

    school: Mapped["School"] = relationship(back_populates="subscriptions")  # noqa: F821
    plan: Mapped["SubscriptionPlan"] = relationship(
        back_populates="subscriptions", lazy="selectin"
    )
    payments: Mapped[list["SubscriptionPayment"]] = relationship(
        back_populates="subscription", cascade="all, delete-orphan"
    )


class SubscriptionPayment(Base, UUIDMixin, TimestampMixin):
    """One recorded payment against a subscription term (the revenue ledger)."""

    __tablename__ = "subscription_payments"

    subscription_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("school_subscriptions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # Denormalized so revenue queries never need to join back to the school.
    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("schools.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    paid_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False, index=True
    )
    period_start: Mapped[date] = mapped_column(Date, nullable=False)
    period_end: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="paid", nullable=False)

    subscription: Mapped["SchoolSubscription"] = relationship(back_populates="payments")
