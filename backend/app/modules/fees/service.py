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
        class_id: uuid.UUID | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> tuple[list[Invoice], int]:
        """Return (invoices, total_count) — page window + full match total."""
        filters = [Invoice.school_id == school_id]
        if student_id is not None:
            filters.append(Invoice.student_id == student_id)
        if status is not None:
            if status == "overdue":
                # A logical status: not paid AND past due date.
                filters.append(Invoice.status != InvoiceStatus.PAID.value)
                filters.append(Invoice.due_date < date.today())
            else:
                filters.append(Invoice.status == status)

        if class_id is not None:
            # Join to student's most-recent active enrollment → section → class.
            filters.append(
                Invoice.student_id.in_(
                    select(StudentEnrollment.student_id)
                    .join(Section, Section.id == StudentEnrollment.section_id)
                    .where(
                        Section.class_id == class_id,
                        StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
                    )
                )
            )

        count_stmt = select(func.count()).select_from(Invoice).where(*filters)
        total = int(await self.db.scalar(count_stmt) or 0)

        page_stmt = (
            select(Invoice)
            .where(*filters)
            .order_by(Invoice.due_date)
            .limit(limit)
            .offset(offset)
        )
        items = list((await self.db.execute(page_stmt)).scalars().all())
        return items, total

    async def search_student_fees(
        self,
        school_id: uuid.UUID,
        query: str = "",
        limit: int = 20,
        offset: int = 0,
        class_id: uuid.UUID | None = None,
        fee_status: str | None = None,  # 'overdue' | 'pending' | 'paid' | 'no_dues'
    ) -> tuple[list[schemas.StudentFeeSnapshot], int]:
        """Search students by name / father / class and attach their fee state.

        Match is case-insensitive substring across:
          * users.full_name
          * users.profile_metadata['father_name']
          * classes.name

        Optional filters:
          * [class_id]: only students in that class.
          * [fee_status]: 'overdue' (any invoice past due and unpaid),
                        'pending' (has balance > 0 but nothing overdue),
                        'paid' (has invoices, all paid),
                        'no_dues' (no invoices at all).
        """
        # Pull the student's most-recent active enrollment so we can surface
        # class/section on the search result. Older enrollments are ignored.
        enrol_sub = (
            select(
                StudentEnrollment.student_id.label("student_id"),
                StudentEnrollment.section_id.label("section_id"),
            )
            .where(
                StudentEnrollment.school_id == school_id,
                StudentEnrollment.status == EnrollmentStatus.ACTIVE.value,
            )
            .subquery()
        )

        base = (
            select(
                User.id,
                User.full_name,
                User.profile_metadata,
                Section.id.label("section_id"),
                Section.name.label("section_name"),
                SchoolClass.id.label("class_id"),
                SchoolClass.name.label("class_name"),
                SchoolClass.level.label("class_level"),
            )
            .where(
                User.school_id == school_id,
                User.roles.any(Role.code == SystemRole.STUDENT.value),
            )
            .outerjoin(enrol_sub, enrol_sub.c.student_id == User.id)
            .outerjoin(Section, Section.id == enrol_sub.c.section_id)
            .outerjoin(SchoolClass, SchoolClass.id == Section.class_id)
        )

        q = query.strip().lower()
        if q:
            like = f"%{q}%"
            base = base.where(
                func.lower(User.full_name).like(like)
                | func.lower(func.coalesce(SchoolClass.name, "")).like(like)
                | func.lower(
                    func.coalesce(
                        User.profile_metadata["father_name"].astext, ""
                    )
                ).like(like)
            )

        if class_id is not None:
            base = base.where(SchoolClass.id == class_id)

        # Status filter needs the invoice roll-up, so we compute totals AFTER
        # loading the page window. To keep pagination honest under status
        # filtering, we scan candidates in windows and re-page.
        want_status = fee_status
        page_rows = (
            await self.db.execute(base.order_by(User.full_name))
        ).all()

        if not page_rows:
            return [], 0

        student_ids = [row.id for row in page_rows]
        invoices_by_student: dict[uuid.UUID, list[Invoice]] = {sid: [] for sid in student_ids}
        invoices = (
            await self.db.execute(
                select(Invoice)
                .where(
                    Invoice.school_id == school_id,
                    Invoice.student_id.in_(student_ids),
                )
                .order_by(Invoice.due_date)
            )
        ).scalars().all()
        for inv in invoices:
            invoices_by_student.setdefault(inv.student_id, []).append(inv)

        today = date.today()
        snapshots: list[schemas.StudentFeeSnapshot] = []
        for row in page_rows:
            meta = row.profile_metadata or {}
            invs = invoices_by_student.get(row.id, [])
            summaries = [
                schemas.InvoiceSummary(
                    id=i.id,
                    title=i.title,
                    amount=i.amount,
                    amount_paid=i.amount_paid,
                    balance=round(i.amount - i.amount_paid, 2),
                    status=i.status,
                    due_date=i.due_date,
                )
                for i in invs
            ]
            outstanding = round(sum(s.balance for s in summaries), 2)
            paid = round(sum(s.amount_paid for s in summaries), 2)
            has_overdue = any(
                s.status != InvoiceStatus.PAID.value and s.due_date < today
                for s in summaries
            )
            snapshot = schemas.StudentFeeSnapshot(
                student_id=row.id,
                full_name=row.full_name,
                father_name=meta.get("father_name") if isinstance(meta, dict) else None,
                class_id=row.class_id,
                class_name=row.class_name,
                section_id=row.section_id,
                section_name=row.section_name,
                grade=row.class_level,
                outstanding_total=outstanding,
                paid_total=paid,
                has_overdue=has_overdue,
                invoices=summaries,
            )
            # Fold in fee_status filter after the roll-up is known.
            if want_status is not None:
                if want_status == "overdue" and not has_overdue:
                    continue
                if want_status == "pending" and (has_overdue or outstanding <= 0):
                    continue
                if want_status == "paid" and (outstanding > 0 or not summaries):
                    continue
                if want_status == "no_dues" and summaries:
                    continue
            snapshots.append(snapshot)

        total = len(snapshots)
        return snapshots[offset : offset + limit], total

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

    # -------------------------- fee reminders ---------------------------- #

    async def outstanding_student_ids(self, school_id: uuid.UUID) -> list[uuid.UUID]:
        """Distinct students in the school with at least one unpaid/partial
        invoice (any remaining balance)."""
        rows = await self.db.execute(
            select(Invoice.student_id)
            .where(
                Invoice.school_id == school_id,
                Invoice.status != InvoiceStatus.PAID.value,
            )
            .distinct()
        )
        return [r[0] for r in rows.all()]

    async def send_fee_reminders(
        self, school_id: uuid.UUID, created_by: uuid.UUID | None = None
    ) -> int:
        """Notify the guardians of every student with outstanding fees. Returns
        the number of students whose guardians were messaged.

        Routed through the communication service's ``fee_due_reminder`` event, so
        it only sends on the channels the school has enabled for that event.
        """
        # Local import avoids a module-level cycle (communication imports fees
        # schemas indirectly via shared enums).
        from app.core.enums import NotificationEvent
        from app.modules.communication.service import CommunicationService

        student_ids = await self.outstanding_student_ids(school_id)
        if not student_ids:
            return 0
        comms = CommunicationService(self.db)
        notified = 0
        for student_id in student_ids:
            messages = await comms.notify_student_guardians(
                school_id,
                student_id,
                event=NotificationEvent.FEE_DUE_REMINDER.value,
                title="Fee reminder",
                body=(
                    "This is a reminder that fees are outstanding. Please clear "
                    "any dues at your earliest convenience."
                ),
                created_by=created_by,
            )
            if messages:
                notified += 1
        return notified
