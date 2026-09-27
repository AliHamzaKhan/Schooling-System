"""Append-only finance adjustment proposals and Headmaster decisions."""

import uuid

from sqlalchemy import CheckConstraint, ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class FinancialAdjustment(Base, UUIDMixin, TimestampMixin):
    """A proposed fee/payroll change that never mutates its target record."""

    __tablename__ = "financial_adjustments"
    __table_args__ = (
        CheckConstraint(
            "(kind IN ('refund', 'credit', 'waiver') AND target_type = 'invoice') "
            "OR (kind = 'payroll_correction' AND target_type = 'payslip')",
            name="ck_financial_adjustment_target_kind",
        ),
        CheckConstraint(
            "currency_code ~ '^[A-Z]{3}$'", name="ck_financial_adjustment_currency"
        ),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("schools.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    kind: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    target_type: Mapped[str] = mapped_column(String(20), nullable=False)
    target_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, index=True
    )
    proposed_amount: Mapped[str] = mapped_column(String(64), nullable=False)
    currency_code: Mapped[str] = mapped_column(String(3), nullable=False)
    reason: Mapped[str] = mapped_column(String(500), nullable=False)
    requested_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=False
    )


class FinancialAdjustmentDecision(Base, UUIDMixin, TimestampMixin):
    """The single immutable approval or rejection for one adjustment."""

    __tablename__ = "financial_adjustment_decisions"
    __table_args__ = (
        UniqueConstraint("adjustment_id", name="uq_financial_adjustment_decision"),
        CheckConstraint(
            "decision IN ('approved', 'rejected')",
            name="ck_financial_adjustment_decision_value",
        ),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("schools.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    adjustment_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("financial_adjustments.id", ondelete="RESTRICT"),
        nullable=False,
    )
    decision: Mapped[str] = mapped_column(String(10), nullable=False)
    reason: Mapped[str] = mapped_column(String(500), nullable=False)
    decided_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=False
    )
