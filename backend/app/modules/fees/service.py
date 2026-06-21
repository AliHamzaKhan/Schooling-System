"""Fee Management Service: fee structures, invoices, payments, reports."""
import uuid
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import EnrollmentStatus, InvoiceStatus, SystemRole
from app.core.exceptions import bad_request, not_found
from app.models.academic import Section, SchoolClass, StudentEnrollment
from app.models.fees import FeeStructure, Invoice, Payment
from app.models.role import Role
from app.models.user import User
from app.modules.fees import schemas


class FeeService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

    async def _get_scoped(self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    async def _validate_student(self, school_id: uuid.UUID, student_id: uuid.UUID) -> None:
        user = await self.db.scalar(
            select(User)
            .where(User.id == student_id, User.school_id == school_id)
            .join(User.roles)
            .where(Role.code == SystemRole.STUDENT.value)
        )
        if user is None:
            raise bad_request("User is not a student in this school")

    @staticmethod
    def _status_for(amount: float, amount_paid: float) -> str:
        if amount_paid >= amount:
            return InvoiceStatus.PAID.value
        if amount_paid > 0:
            return InvoiceStatus.PARTIAL.value
        return InvoiceStatus.UNPAID.value

    # -------------------------- fee structures --------------------------- #

    async def create_structure(
        self, school_id: uuid.UUID, data: schemas.FeeStructureCreate
    ) -> FeeStructure:
        if data.class_id is not None:
            await self._get_scoped(SchoolClass, school_id, data.class_id, "Class")
        dupe = await self.db.scalar(
            select(FeeStructure).where(
                FeeStructure.school_id == school_id, FeeStructure.name == data.name
            )
        )
        if dupe is not None:
            raise bad_request(f"A fee structure named '{data.name}' already exists")
        obj = FeeStructure(
            school_id=school_id,
            class_id=data.class_id,
            session_id=data.session_id,
            name=data.name,
            amount=data.amount,
            description=data.description,
        )
        self.db.add(obj)
        await self.db.flush()
        return obj

    async def list_structures(self, school_id: uuid.UUID) -> list[FeeStructure]:
        result = await self.db.execute(
            select(FeeStructure).where(FeeStructure.school_id == school_id).order_by(FeeStructure.name)
        )
        return list(result.scalars().all())

    # ------------------------------ invoices ----------------------------- #

    async def create_invoice(self, school_id: uuid.UUID, data: schemas.InvoiceCreate) -> Invoice:
        await self._validate_student(school_id, data.student_id)
        if data.fee_structure_id is not None:
            await self._get_scoped(FeeStructure, school_id, data.fee_structure_id, "Fee structure")
        invoice = Invoice(
            school_id=school_id,
            student_id=data.student_id,
            fee_structure_id=data.fee_structure_id,
            session_id=data.session_id,
            title=data.title,
            amount=data.amount,
            amount_paid=0.0,
            due_date=data.due_date,
            status=InvoiceStatus.UNPAID.value,
        )
        self.db.add(invoice)
        await self.db.flush()
        return invoice

    async def bulk_create_invoices(
        self, school_id: uuid.UUID, data: schemas.BulkInvoiceCreate
    ) -> list[Invoice]:
        await self._get_scoped(SchoolClass, school_id, data.class_id, "Class")
        if data.fee_structure_id is not None:
            await self._get_scoped(FeeStructure, school_id, data.fee_structure_id, "Fee structure")

        student_ids = list(
            (
                await self.db.execute(
                    select(StudentEnrollment.student_id)
                    .join(Section, Section.id == StudentEnrollment.section_id)
                    .where(
                        Section.class_id == data.class_id,
                        StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                    )
                )
            )
            .scalars()
            .all()
        )
        if not student_ids:
            raise bad_request("No enrolled students found for this class")

        invoices: list[Invoice] = []
        for student_id in set(student_ids):
            invoice = Invoice(
                school_id=school_id,
                student_id=student_id,
                fee_structure_id=data.fee_structure_id,
                session_id=data.session_id,
                title=data.title,
                amount=data.amount,
                amount_paid=0.0,
                due_date=data.due_date,
                status=InvoiceStatus.UNPAID.value,
            )
            self.db.add(invoice)
            invoices.append(invoice)
        await self.db.flush()
        return invoices

    async def get_invoice(self, school_id: uuid.UUID, invoice_id: uuid.UUID) -> Invoice:
        return await self._get_scoped(Invoice, school_id, invoice_id, "Invoice")

    async def list_invoices(
        self,
        school_id: uuid.UUID,
        student_id: uuid.UUID | None = None,
        status: str | None = None,
    ) -> list[Invoice]:
        stmt = select(Invoice).where(Invoice.school_id == school_id)
        if student_id is not None:
            stmt = stmt.where(Invoice.student_id == student_id)
        if status is not None:
            stmt = stmt.where(Invoice.status == status)
        stmt = stmt.order_by(Invoice.due_date)
        return list((await self.db.execute(stmt)).scalars().all())

    # ------------------------------ payments ----------------------------- #

    async def record_payment(
        self, school_id: uuid.UUID, invoice_id: uuid.UUID, data: schemas.PaymentCreate,
        recorded_by: uuid.UUID,
    ) -> Payment:
        invoice = await self._get_scoped(Invoice, school_id, invoice_id, "Invoice")
        remaining = round(invoice.amount - invoice.amount_paid, 2)
        if remaining <= 0:
            raise bad_request("Invoice is already fully paid")
        if data.amount > remaining:
            raise bad_request(f"Payment ({data.amount}) exceeds the remaining balance ({remaining})")

        payment = Payment(
            school_id=school_id,
            invoice_id=invoice_id,
            amount=data.amount,
            method=data.method.value,
            reference=data.reference,
            paid_on=data.paid_on,
            note=data.note,
            recorded_by=recorded_by,
        )
        self.db.add(payment)

        # Recompute amount_paid from all payments to stay authoritative.
        await self.db.flush()
        total_paid = await self.db.scalar(
            select(func.coalesce(func.sum(Payment.amount), 0.0)).where(
                Payment.invoice_id == invoice_id
            )
        )
        invoice.amount_paid = round(float(total_paid), 2)
        invoice.status = self._status_for(invoice.amount, invoice.amount_paid)
        await self.db.flush()
        return payment

    async def get_receipt(self, school_id: uuid.UUID, invoice_id: uuid.UUID) -> schemas.Receipt:
        invoice = await self._get_scoped(Invoice, school_id, invoice_id, "Invoice")
        payments = list(
            (await self.db.execute(select(Payment).where(Payment.invoice_id == invoice_id).order_by(Payment.paid_on)))
            .scalars()
            .all()
        )
        return schemas.Receipt(
            invoice=schemas.InvoiceOut.model_validate(invoice),
            payments=[schemas.PaymentOut.model_validate(p) for p in payments],
            total_paid=invoice.amount_paid,
        )

    # ------------------------------ reports ------------------------------ #

    async def report(self, school_id: uuid.UUID) -> schemas.FeeReport:
        invoices = list(
            (await self.db.execute(select(Invoice).where(Invoice.school_id == school_id)))
            .scalars()
            .all()
        )
        today = date.today()
        billed = sum(i.amount for i in invoices)
        collected = sum(i.amount_paid for i in invoices)
        status_counts = {s.value: 0 for s in InvoiceStatus}
        overdue = 0
        for i in invoices:
            status_counts[i.status] = status_counts.get(i.status, 0) + 1
            if i.status != InvoiceStatus.PAID.value and i.due_date < today:
                overdue += 1
        return schemas.FeeReport(
            school_id=school_id,
            total_invoices=len(invoices),
            total_billed=round(billed, 2),
            total_collected=round(collected, 2),
            total_outstanding=round(billed - collected, 2),
            overdue_count=overdue,
            status_counts=status_counts,
        )
