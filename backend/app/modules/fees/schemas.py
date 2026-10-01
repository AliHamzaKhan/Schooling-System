"""Fee Management schemas."""

import uuid
from datetime import date, datetime
from decimal import Decimal, InvalidOperation
from typing import Literal

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    computed_field,
    field_validator,
    model_validator,
)

from app.core.enums import PaymentMethod

# --------------------------------------------------------------------------- #
# Fee structure
# --------------------------------------------------------------------------- #


class FeeStructureCreate(BaseModel):
    name: str = Field(min_length=2, max_length=150)
    amount: float = Field(gt=0, allow_inf_nan=False)
    class_id: uuid.UUID | None = None
    session_id: uuid.UUID | None = None
    description: str | None = Field(default=None, max_length=255)


class FeeStructureOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    class_id: uuid.UUID | None = None
    session_id: uuid.UUID | None = None
    name: str
    amount: float
    description: str | None = None


# --------------------------------------------------------------------------- #
# Invoice
# --------------------------------------------------------------------------- #


class InvoiceCreate(BaseModel):
    student_id: uuid.UUID
    title: str = Field(min_length=2, max_length=150)
    amount: float = Field(gt=0, allow_inf_nan=False)
    due_date: date
    fee_structure_id: uuid.UUID | None = None
    session_id: uuid.UUID | None = None


class BulkInvoiceCreate(BaseModel):
    class_id: uuid.UUID
    title: str = Field(min_length=2, max_length=150)
    amount: float = Field(gt=0, allow_inf_nan=False)
    due_date: date
    fee_structure_id: uuid.UUID | None = None
    session_id: uuid.UUID | None = None


class InvoiceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    student_id: uuid.UUID
    fee_structure_id: uuid.UUID | None = None
    session_id: uuid.UUID | None = None
    title: str
    amount: float
    amount_paid: float
    due_date: date
    status: str
    # Resolved for list views so staff screens can name the student.
    student_name: str | None = None

    @computed_field
    @property
    def balance(self) -> float:
        return round(self.amount - self.amount_paid, 2)

    @computed_field
    @property
    def is_overdue(self) -> bool:
        return self.status != "paid" and self.due_date < date.today()


# --------------------------------------------------------------------------- #
# Payment / receipt
# --------------------------------------------------------------------------- #


class PaymentCreate(BaseModel):
    amount: float = Field(gt=0, allow_inf_nan=False)
    method: PaymentMethod
    paid_on: date
    reference: str | None = Field(default=None, max_length=100)
    note: str | None = Field(default=None, max_length=255)
    proof_url: str | None = Field(default=None, max_length=500)

    @model_validator(mode="after")
    def _reject_future_payment_date(self) -> "PaymentCreate":
        if self.paid_on > date.today():
            raise ValueError("paid_on cannot be in the future")
        return self


class PaymentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    invoice_id: uuid.UUID
    amount: float
    method: str
    reference: str | None = None
    paid_on: date
    note: str | None = None
    proof_url: str | None = None
    recorded_by: uuid.UUID | None = None


class Receipt(BaseModel):
    invoice: InvoiceOut
    payments: list[PaymentOut]
    total_paid: float


# --------------------------------------------------------------------------- #
# Billing contacts
# --------------------------------------------------------------------------- #


class BillingContactUpsert(BaseModel):
    billing_email: str | None = Field(default=None, max_length=255)
    billing_phone: str | None = Field(default=None, max_length=50)
    payer_reference: str | None = Field(default=None, max_length=100)
    is_primary: bool = False
    note: str | None = Field(default=None, max_length=255)


class BillingContactOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    student_id: uuid.UUID
    guardian_id: uuid.UUID
    billing_email: str | None = None
    billing_phone: str | None = None
    payer_reference: str | None = None
    is_primary: bool
    note: str | None = None


class BillingGuardianCandidate(BaseModel):
    guardian_id: uuid.UUID
    full_name: str
    email: str
    phone: str | None = None
    relationship: str | None = None


# --------------------------------------------------------------------------- #
# Reports
# --------------------------------------------------------------------------- #


class FeeReport(BaseModel):
    school_id: uuid.UUID
    total_invoices: int
    total_billed: float
    total_collected: float
    total_outstanding: float
    overdue_count: int
    status_counts: dict[str, int]


class FeeAgingBucket(BaseModel):
    """Outstanding invoice totals grouped by days overdue as of one date."""

    label: str
    invoice_count: int
    outstanding_total: float


class FeeAgingReport(BaseModel):
    """Read-only reconciliation view; it never rewrites invoice caches."""

    school_id: uuid.UUID
    as_of_date: date
    total_outstanding: float
    buckets: list[FeeAgingBucket]


class FeeReconciliationIssue(BaseModel):
    """A cached invoice value that differs from its immutable payment ledger."""

    invoice_id: uuid.UUID
    cached_amount_paid: float
    ledger_amount_paid: float
    cached_status: str
    ledger_status: str
    issue_codes: list[str]


class FeeReconciliationReport(BaseModel):
    """A bounded, read-only list of invoice cache/ledger discrepancies."""

    school_id: uuid.UUID
    invoices_scanned: int
    reconciled_count: int
    mismatch_count: int
    issues: list[FeeReconciliationIssue]


# --------------------------------------------------------------------------- #
# Adjustment proposals — no balance or payslip mutation until money policy.
# --------------------------------------------------------------------------- #

AdjustmentKind = Literal["refund", "credit", "waiver", "payroll_correction"]
AdjustmentDecision = Literal["approved", "rejected"]
AdjustmentListDecision = Literal["pending", "approved", "rejected"]
AdjustmentTargetType = Literal["invoice", "payslip"]


class FinancialAdjustmentCreate(BaseModel):
    kind: AdjustmentKind
    target_id: uuid.UUID
    proposed_amount: str = Field(min_length=1, max_length=64)
    currency_code: str = Field(min_length=3, max_length=3)
    reason: str = Field(min_length=3, max_length=500)

    @field_validator("proposed_amount")
    @classmethod
    def _positive_decimal_text(cls, value: str) -> str:
        try:
            amount = Decimal(value.strip())
        except (InvalidOperation, ValueError) as exc:
            raise ValueError("proposed_amount must be a decimal value") from exc
        if not amount.is_finite() or amount <= 0:
            raise ValueError("proposed_amount must be greater than zero")
        return format(amount, "f")

    @field_validator("currency_code")
    @classmethod
    def _currency_code(cls, value: str) -> str:
        code = value.strip().upper()
        if len(code) != 3 or not code.isalpha():
            raise ValueError("currency_code must be a three-letter code")
        return code


class FinancialAdjustmentDecisionCreate(BaseModel):
    decision: AdjustmentDecision
    reason: str = Field(min_length=3, max_length=500)


class FinancialAdjustmentOut(BaseModel):
    id: uuid.UUID
    school_id: uuid.UUID
    kind: str
    target_type: str
    target_id: uuid.UUID
    proposed_amount: str
    currency_code: str
    reason: str
    requested_by: uuid.UUID
    created_at: datetime
    decision: str | None = None
    decision_reason: str | None = None
    decided_by: uuid.UUID | None = None
    decided_at: datetime | None = None


# --------------------------------------------------------------------------- #
# Student fee snapshot (search for "record payment")
# --------------------------------------------------------------------------- #


class InvoiceSummary(BaseModel):
    """Compact invoice view used inside a StudentFeeSnapshot list."""

    id: uuid.UUID
    title: str
    amount: float
    amount_paid: float
    balance: float
    status: str
    due_date: date


class StudentFeeSnapshot(BaseModel):
    """One student + their live fee position, for the Record Payment screen."""

    student_id: uuid.UUID
    full_name: str
    father_name: str | None = None
    class_id: uuid.UUID | None = None
    class_name: str | None = None
    section_id: uuid.UUID | None = None
    section_name: str | None = None
    grade: int | None = None
    outstanding_total: float
    paid_total: float
    has_overdue: bool
    invoices: list[InvoiceSummary]


class StudentFeePage(BaseModel):
    """Paginated envelope for the student-fee search."""

    total: int
    items: list[StudentFeeSnapshot]
