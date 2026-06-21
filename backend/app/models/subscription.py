"""Subscription plan model (docs/permissions/02-subscription-plans.md)."""
from sqlalchemy import String
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDMixin


class SubscriptionPlan(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "subscription_plans"

    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    # Module values (app.core.enums.Module) unlocked by this plan.
    modules: Mapped[list[str]] = mapped_column(ARRAY(String(50)), default=list, nullable=False)

    schools: Mapped[list["School"]] = relationship(back_populates="subscription_plan")  # noqa: F821
