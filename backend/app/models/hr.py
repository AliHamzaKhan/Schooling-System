"""HR & Payroll models: staff profiles and payslips."""
import uuid
from datetime import date

from sqlalchemy import Date, Float, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class StaffProfile(Base, UUIDMixin, TimestampMixin):
    """HR profile for a school staff member (one per user)."""

    __tablename__ = "staff_profiles"
    __table_args__ = (UniqueConstraint("user_id", name="uq_staff_profile_user"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    designation: Mapped[str] = mapped_column(String(120), nullable=False)
    department: Mapped[str | None] = mapped_column(String(120), nullable=True)
    joining_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    base_salary: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)


class Payslip(Base, UUIDMixin, TimestampMixin):
    """A monthly payslip for a staff member."""

    __tablename__ = "payslips"
    __table_args__ = (
        UniqueConstraint("staff_profile_id", "period_year", "period_month", name="uq_payslip_staff_period"),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    staff_profile_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("staff_profiles.id", ondelete="CASCADE"), nullable=False, index=True
    )
    period_month: Mapped[int] = mapped_column(Integer, nullable=False)  # 1-12
    period_year: Mapped[int] = mapped_column(Integer, nullable=False)
    gross: Mapped[float] = mapped_column(Float, nullable=False)
    deductions: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    net: Mapped[float] = mapped_column(Float, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="unpaid", nullable=False)
    paid_on: Mapped[date | None] = mapped_column(Date, nullable=True)

    # Attendance snapshot captured at generation time (for the payslip PDF and
    # to show how the absence deduction was derived). Counts cover the payslip
    # period_month/period_year; absence_deduction is the amount already folded
    # into [deductions].
    allowances: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    present_days: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    absent_days: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    late_days: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    leave_days: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    absence_deduction: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    # Client request key of the "mark paid" call, so a retried request after a
    # lost response is answered with the same result instead of an error.
    payment_request_key: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), unique=True, nullable=True
    )
