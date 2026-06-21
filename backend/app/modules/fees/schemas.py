"""Fee Management schemas."""
import uuid
from datetime import date

from pydantic import BaseModel, ConfigDict, Field, computed_field

from app.core.enums import PaymentMethod

# --------------------------------------------------------------------------- #
# Fee structure
# --------------------------------------------------------------------------- #


class FeeStructureCreate(BaseModel):
    name: str = Field(min_length=2, max_length=150)
    amount: float = Field(gt=0)
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
    amount: float = Field(gt=0)
    due_date: date
    fee_structure_id: uuid.UUID | None = None
    session_id: uuid.UUID | None = None


class BulkInvoiceCreate(BaseModel):
    class_id: uuid.UUID
    title: str = Field(min_length=2, max_length=150)
    amount: float = Field(gt=0)
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
    amount: float = Field(gt=0)
    method: PaymentMethod
    paid_on: date
    reference: str | None = Field(default=None, max_length=100)
    note: str | None = Field(default=None, max_length=255)


class PaymentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    invoice_id: uuid.UUID
    amount: float
    method: str
    reference: str | None = None
    paid_on: date
    note: str | None = None
    recorded_by: uuid.UUID | None = None


class Receipt(BaseModel):
    invoice: InvoiceOut
    payments: list[PaymentOut]
    total_paid: float


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
