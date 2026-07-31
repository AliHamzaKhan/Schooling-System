"""School, per-school module toggle, and academic session models."""
import uuid
from datetime import date

from sqlalchemy import Boolean, Date, ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import SchoolStatus
from app.models.base import Base, TimestampMixin, UUIDMixin


class School(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "schools"

    name: Mapped[str] = mapped_column(String(200), nullable=False)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default=SchoolStatus.PENDING.value, nullable=False)

    contact_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    contact_phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    address: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # Flexible per-school settings (timezone, grading scheme, branding, etc.)
    settings: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)

    subscription_plan_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("subscription_plans.id"), nullable=True
    )

    subscription_plan: Mapped["SubscriptionPlan | None"] = relationship(  # noqa: F821
        back_populates="schools", lazy="selectin"
    )
    modules: Mapped[list["SchoolModule"]] = relationship(
        back_populates="school", cascade="all, delete-orphan", lazy="selectin"
    )
    sessions: Mapped[list["AcademicSession"]] = relationship(
        back_populates="school", cascade="all, delete-orphan"
    )
    subscriptions: Mapped[list["SchoolSubscription"]] = relationship(  # noqa: F821
        back_populates="school", cascade="all, delete-orphan"
    )


class SchoolModule(Base, UUIDMixin, TimestampMixin):
    """Super Admin's per-school enable/disable toggle for a module.

    Absence of a row means "follow the subscription" (treated as enabled if the
    plan includes it). A row with enabled=False hard-disables the module.
    """

    __tablename__ = "school_modules"
    __table_args__ = (UniqueConstraint("school_id", "module", name="uq_school_module"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    module: Mapped[str] = mapped_column(String(50), nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    school: Mapped["School"] = relationship(back_populates="modules")


class AcademicSession(Base, UUIDMixin, TimestampMixin):
    """An academic year/term for a school (e.g. "2025-2026")."""

    __tablename__ = "academic_sessions"
    __table_args__ = (UniqueConstraint("school_id", "name", name="uq_session_school_name"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    school: Mapped["School"] = relationship(back_populates="sessions")
