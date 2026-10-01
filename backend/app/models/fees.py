"""Fee management models: fee structures, invoices, payments."""
import uuid
from datetime import date

from sqlalchemy import Boolean, Date, Float, ForeignKey, Index, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import InvoiceStatus
from app.models.base import Base, TimestampMixin, UUIDMixin


class FeeStructure(Base, UUIDMixin, TimestampMixin):
    """A reusable fee definition, optionally tied to a class."""

    __tablename__ = "fee_structures"
    __table_args__ = (UniqueConstraint("school_id", "name", name="uq_fee_structure_school_name"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    class_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("classes.id", ondelete="SET NULL"), nullable=True
    )
    session_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("academic_sessions.id", ondelete="SET NULL"), nullable=True
    )
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)


class Invoice(Base, UUIDMixin, TimestampMixin):
    """A fee charge issued to a student."""

    __tablename__ = "invoices"
    __table_args__ = (
        # Matches the stable school-scoped invoice page order.  The separate
        # single-column indexes remain useful for other predicates.
        Index("ix_invoices_school_due_id", "school_id", "due_date", "id"),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    fee_structure_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("fee_structures.id", ondelete="SET NULL"), nullable=True
    )
    session_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("academic_sessions.id", ondelete="SET NULL"), nullable=True
    )
    title: Mapped[str] = mapped_column(String(150), nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    amount_paid: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    due_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    status: Mapped[str] = mapped_column(String(20), default=InvoiceStatus.UNPAID.value, nullable=False)

    payments: Mapped[list["Payment"]] = relationship(
        back_populates="invoice", cascade="all, delete-orphan"
    )


class Payment(Base, UUIDMixin, TimestampMixin):
    """A payment recorded against an invoice (the receipt source)."""

    __tablename__ = "payments"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    invoice_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("invoices.id", ondelete="CASCADE"), nullable=False, index=True
    )
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    method: Mapped[str] = mapped_column(String(20), nullable=False)
    reference: Mapped[str | None] = mapped_column(String(100), nullable=True)
    paid_on: Mapped[date] = mapped_column(Date, nullable=False)
    note: Mapped[str | None] = mapped_column(String(255), nullable=True)
    # A private PDF/image supplied with a manually verified bank or cheque
    # payment. This is a storage reference, never a public file URL.
    proof_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    recorded_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    invoice: Mapped["Invoice"] = relationship(back_populates="payments")


class StudentBillingContact(Base, UUIDMixin, TimestampMixin):
    """A guardian selected to receive and reconcile one student's bills.

    Contact values are snapshots so a school can use a billing-specific email,
    phone number or payer reference without overwriting the guardian's account
    profile. A guardian must already be linked to the student.
    """

    __tablename__ = "student_billing_contacts"
    __table_args__ = (
        UniqueConstraint(
            "student_id", "guardian_id", name="uq_billing_contact_student_guardian"
        ),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    guardian_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    billing_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    billing_phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    payer_reference: Mapped[str | None] = mapped_column(String(100), nullable=True)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    note: Mapped[str | None] = mapped_column(String(255), nullable=True)
