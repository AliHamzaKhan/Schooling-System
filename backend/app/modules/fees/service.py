"""Fee Management Service: fee structures, invoices, payments, reports."""

import hashlib
import uuid
from datetime import date

from sqlalchemy import func, or_, select, text, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import EnrollmentStatus, InvoiceStatus, SystemRole
from app.core.exceptions import AppHTTPException, ErrorCode, bad_request, not_found
from app.core.quotas import BULK_INVOICE_MAX_STUDENTS
from app.models.academic import Section, SchoolClass, StudentEnrollment
from app.models.fees import FeeStructure, Invoice, Payment, StudentBillingContact
from app.models.finance import FinancialAdjustment, FinancialAdjustmentDecision
from app.models.hr import Payslip
from app.models.associations import guardian_students
from app.models.school import AcademicSession
from app.models.role import Role
from app.models.user import User
from app.modules.fees import schemas
from app.modules.academic.access import role_ids, valid_classes


class FeeService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

    async def _get_scoped(
        self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str
    ):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    async def _validate_student(
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> None:
        user = await self.db.scalar(
            select(User)
            .where(User.id == student_id, User.school_id == school_id)
            .join(User.roles)
            .where(Role.code == SystemRole.STUDENT.value)
        )
        if user is None:
            raise bad_request("User is not a student in this school")

    @staticmethod
    def _adjustment_out(
        adjustment: FinancialAdjustment,
        decision: FinancialAdjustmentDecision | None = None,
    ) -> schemas.FinancialAdjustmentOut:
        return schemas.FinancialAdjustmentOut(
            id=adjustment.id,
            school_id=adjustment.school_id,
            kind=adjustment.kind,
            target_type=adjustment.target_type,
            target_id=adjustment.target_id,
            proposed_amount=adjustment.proposed_amount,
            currency_code=adjustment.currency_code,
            reason=adjustment.reason,
            requested_by=adjustment.requested_by,
            created_at=adjustment.created_at,
            decision=decision.decision if decision else None,
            decision_reason=decision.reason if decision else None,
            decided_by=decision.decided_by if decision else None,
            decided_at=decision.created_at if decision else None,
        )

    async def _validate_adjustment_target(
        self, school_id: uuid.UUID, kind: str, target_id: uuid.UUID
    ) -> str:
        if kind == "payroll_correction":
            payslip = await self.db.scalar(
                select(Payslip).where(
                    Payslip.id == target_id, Payslip.school_id == school_id
                )
            )
            if payslip is None:
                raise not_found("Payslip not found in this school")
            return "payslip"
        await self._get_scoped(Invoice, school_id, target_id, "Invoice")
        return "invoice"

    async def _validated_fee_structure(
        self, school_id: uuid.UUID, structure_id: uuid.UUID
    ) -> FeeStructure:
        """Return a fee structure only when all of its optional scopes are valid.

        Fee structures can be limited to a class and/or academic session.  An
        invoice must never inherit a stale or cross-school scope from such a
        structure, even when the structure row itself still has the right
        ``school_id``.
        """
        structure = await self._get_scoped(
            FeeStructure, school_id, structure_id, "Fee structure"
        )
        school_class = None
        if structure.class_id is not None:
            school_class = await self._get_scoped(
                SchoolClass, school_id, structure.class_id, "Class"
            )
            if school_class.session_id is not None:
                await self._get_scoped(
                    AcademicSession,
                    school_id,
                    school_class.session_id,
                    "Academic session",
                )
        if structure.session_id is not None:
            await self._get_scoped(
                AcademicSession, school_id, structure.session_id, "Academic session"
            )
        if (
            school_class is not None
            and school_class.session_id is not None
            and structure.session_id is not None
            and school_class.session_id != structure.session_id
        ):
            raise bad_request("Fee structure class and academic session do not match")
        return structure

    async def _invoice_session_id(
        self,
        school_id: uuid.UUID,
        requested_session_id: uuid.UUID | None,
        fee_structure_id: uuid.UUID | None,
        *,
        class_id: uuid.UUID | None = None,
    ) -> uuid.UUID | None:
        """Resolve an invoice session without allowing fee scopes to drift.

        A session-specific structure supplies its session when the caller does
        not repeat it.  When a session is supplied, it must agree with the
        structure and (for bulk issuance) the requested class.  This keeps
        fee reports and later reconciliation from mixing academic years.
        """
        if requested_session_id is not None:
            await self._get_scoped(
                AcademicSession, school_id, requested_session_id, "Academic session"
            )

        structure = None
        if fee_structure_id is not None:
            structure = await self._validated_fee_structure(school_id, fee_structure_id)
            if (
                structure.session_id is not None
                and requested_session_id is not None
                and structure.session_id != requested_session_id
            ):
                raise bad_request(
                    "Fee structure and invoice must use the same academic session"
                )
            if (
                class_id is not None
                and structure.class_id is not None
                and structure.class_id != class_id
            ):
                raise bad_request("Fee structure is restricted to a different class")

        if class_id is not None:
            school_class = await self._get_scoped(
                SchoolClass, school_id, class_id, "Class"
            )
            if (
                requested_session_id is not None
                and school_class.session_id is not None
                and school_class.session_id != requested_session_id
            ):
                raise bad_request(
                    "Class and invoice must use the same academic session"
                )

        return requested_session_id or (
            structure.session_id if structure is not None else None
        )

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
        school_class = None
        if data.class_id is not None:
            school_class = await self._get_scoped(
                SchoolClass, school_id, data.class_id, "Class"
            )
        if data.session_id is not None:
            await self._get_scoped(
                AcademicSession, school_id, data.session_id, "Academic session"
            )
        if (
            school_class is not None
            and school_class.session_id is not None
            and data.session_id is not None
            and school_class.session_id != data.session_id
        ):
            raise bad_request("Fee structure class and academic session do not match")
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
            select(FeeStructure)
            .where(FeeStructure.school_id == school_id)
            .order_by(FeeStructure.name)
        )
        return list(result.scalars().all())

    # ------------------------------ invoices ----------------------------- #

    async def _reject_duplicate_invoice(
        self,
        school_id: uuid.UUID,
        student_id: uuid.UUID,
        *,
        fee_structure_id: uuid.UUID | None,
        session_id: uuid.UUID | None,
        title: str,
        due_date: date,
    ) -> None:
        existing = await self.db.scalar(
            select(Invoice.id).where(
                Invoice.school_id == school_id,
                Invoice.student_id == student_id,
                Invoice.fee_structure_id == fee_structure_id,
                Invoice.session_id == session_id,
                Invoice.title == title,
                Invoice.due_date == due_date,
            )
        )
        if existing is not None:
            raise bad_request(
                "An invoice with the same student, fee, session and due date already exists"
            )

    async def create_invoice(
        self, school_id: uuid.UUID, data: schemas.InvoiceCreate
    ) -> Invoice:
        await self._validate_student(school_id, data.student_id)
        session_id = await self._invoice_session_id(
            school_id, data.session_id, data.fee_structure_id
        )
        await self._reject_duplicate_invoice(
            school_id,
            data.student_id,
            fee_structure_id=data.fee_structure_id,
            session_id=session_id,
            title=data.title,
            due_date=data.due_date,
        )
        invoice = Invoice(
            school_id=school_id,
            student_id=data.student_id,
            fee_structure_id=data.fee_structure_id,
            session_id=session_id,
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
        session_id = await self._invoice_session_id(
            school_id, data.session_id, data.fee_structure_id, class_id=data.class_id
        )

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

        unique_student_ids = set(student_ids)
        if len(unique_student_ids) > BULK_INVOICE_MAX_STUDENTS:
            raise bad_request(
                f"Bulk issuance is limited to {BULK_INVOICE_MAX_STUDENTS} students per request"
            )
        duplicate = await self.db.scalar(
            select(Invoice.id).where(
                Invoice.school_id == school_id,
                Invoice.student_id.in_(unique_student_ids),
                Invoice.fee_structure_id == data.fee_structure_id,
                Invoice.session_id == session_id,
                Invoice.title == data.title,
                Invoice.due_date == data.due_date,
            )
        )
        if duplicate is not None:
            raise bad_request(
                "A matching invoice already exists for at least one student; bulk issuance was not applied"
            )

        invoices: list[Invoice] = []
        for student_id in unique_student_ids:
            invoice = Invoice(
                school_id=school_id,
                student_id=student_id,
                fee_structure_id=data.fee_structure_id,
                session_id=session_id,
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

    async def student_names(
        self, school_id: uuid.UUID, student_ids: set[uuid.UUID]
    ) -> dict[uuid.UUID, str]:
        """One batched lookup of student display names for a list page."""
        if not student_ids:
            return {}
        return dict((await self.db.execute(
            select(User.id, User.full_name).where(
                User.school_id == school_id, User.id.in_(student_ids)
            )
        )).all())

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
        with_total: bool = True,
        visible_student_ids: set[uuid.UUID] | None = None,
    ) -> tuple[list[Invoice], int | None]:
        """Return (invoices, total_count) — page window + full match total.

        Pass ``with_total=False`` when the caller discards the total; the full
        count scan is then skipped and ``None`` is returned in its place.
        """
        filters = [Invoice.school_id == school_id]
        if visible_student_ids is not None:
            # Family readers: only their own or linked children's invoices,
            # applied before any page window.
            filters.append(Invoice.student_id.in_(visible_student_ids))
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
            await self._get_scoped(SchoolClass, school_id, class_id, "Class")
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

        total = None
        if with_total:
            count_stmt = select(func.count()).select_from(Invoice).where(*filters)
            total = int(await self.db.scalar(count_stmt) or 0)

        page_stmt = (
            select(Invoice)
            .where(*filters)
            .order_by(Invoice.due_date, Invoice.id)
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
        if class_id is not None:
            await self._get_scoped(SchoolClass, school_id, class_id, "Class")
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
                    func.coalesce(User.profile_metadata["father_name"].astext, "")
                ).like(like)
            )

        if class_id is not None:
            base = base.where(SchoolClass.id == class_id)

        # Status filter needs the invoice roll-up, so we compute totals AFTER
        # loading the page window. To keep pagination honest under status
        # filtering, we scan candidates in windows and re-page.
        want_status = fee_status
        page_rows = (await self.db.execute(base.order_by(User.full_name))).all()

        if not page_rows:
            return [], 0

        student_ids = [row.id for row in page_rows]
        invoices_by_student: dict[uuid.UUID, list[Invoice]] = {
            sid: [] for sid in student_ids
        }
        invoices = (
            (
                await self.db.execute(
                    select(Invoice)
                    .where(
                        Invoice.school_id == school_id,
                        Invoice.student_id.in_(student_ids),
                    )
                    .order_by(Invoice.due_date)
                )
            )
            .scalars()
            .all()
        )
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

    async def list_billing_contacts(
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> list[StudentBillingContact]:
        await self._validate_student(school_id, student_id)
        rows = await self.db.execute(
            select(StudentBillingContact)
            .where(
                StudentBillingContact.school_id == school_id,
                StudentBillingContact.student_id == student_id,
            )
            .order_by(
                StudentBillingContact.is_primary.desc(),
                StudentBillingContact.created_at,
            )
        )
        return list(rows.scalars().all())

    async def list_billing_guardian_candidates(
        self, school_id: uuid.UUID, student_id: uuid.UUID
    ) -> list[schemas.BillingGuardianCandidate]:
        await self._validate_student(school_id, student_id)
        rows = await self.db.execute(
            select(
                User.id,
                User.full_name,
                User.email,
                User.phone,
                guardian_students.c.relationship,
            )
            .join(
                guardian_students,
                guardian_students.c.guardian_id == User.id,
            )
            .join(User.roles)
            .where(
                guardian_students.c.school_id == school_id,
                guardian_students.c.student_id == student_id,
                User.school_id == school_id,
                Role.code == SystemRole.GUARDIAN.value,
            )
            .order_by(User.full_name)
        )
        return [
            schemas.BillingGuardianCandidate(
                guardian_id=guardian_id,
                full_name=full_name,
                email=email,
                phone=phone,
                relationship=relationship,
            )
            for guardian_id, full_name, email, phone, relationship in rows.all()
        ]

    async def upsert_billing_contact(
        self,
        school_id: uuid.UUID,
        student_id: uuid.UUID,
        guardian_id: uuid.UUID,
        data: schemas.BillingContactUpsert,
    ) -> StudentBillingContact:
        # The student row is the serialization point for a primary-payer
        # change, so two administrators cannot leave competing primary records.
        student = await self.db.scalar(
            select(User)
            .where(User.id == student_id, User.school_id == school_id)
            .with_for_update()
        )
        if student is None:
            raise not_found("Student not found in this school")
        await self._validate_student(school_id, student_id)
        guardian = await self.db.scalar(
            select(User)
            .where(User.id == guardian_id, User.school_id == school_id)
            .join(User.roles)
            .where(Role.code == SystemRole.GUARDIAN.value)
        )
        if guardian is None:
            raise bad_request("User is not a guardian in this school")
        linked = await self.db.scalar(
            select(guardian_students.c.guardian_id).where(
                guardian_students.c.school_id == school_id,
                guardian_students.c.student_id == student_id,
                guardian_students.c.guardian_id == guardian_id,
            )
        )
        if linked is None:
            raise bad_request(
                "Guardian must be linked to this student before billing can be configured"
            )

        if data.is_primary:
            await self.db.execute(
                update(StudentBillingContact)
                .where(
                    StudentBillingContact.school_id == school_id,
                    StudentBillingContact.student_id == student_id,
                    StudentBillingContact.guardian_id != guardian_id,
                )
                .values(is_primary=False)
            )
        contact = await self.db.scalar(
            select(StudentBillingContact).where(
                StudentBillingContact.school_id == school_id,
                StudentBillingContact.student_id == student_id,
                StudentBillingContact.guardian_id == guardian_id,
            )
        )
        values = data.model_dump()
        if contact is None:
            contact = StudentBillingContact(
                school_id=school_id,
                student_id=student_id,
                guardian_id=guardian_id,
                **values,
            )
            self.db.add(contact)
        else:
            for field, value in values.items():
                setattr(contact, field, value)
        await self.db.flush()
        return contact

    async def record_payment(
        self,
        school_id: uuid.UUID,
        invoice_id: uuid.UUID,
        data: schemas.PaymentCreate,
        recorded_by: uuid.UUID,
        *,
        idempotency_key: uuid.UUID | None = None,
    ) -> Payment:
        # A proof for a newly recorded manual payment must be a managed private
        # upload made by this recorder. A pasted external URL cannot become an
        # accounting attachment.
        from app.modules.uploads.access import validate_new_reference

        validate_new_reference(
            data.proof_url,
            school_id,
            recorded_by,
            "payment_proofs",
            allow_external=False,
        )
        if idempotency_key is not None:
            # Authorize the target before consulting the globally unique key.
            await self._get_scoped(Invoice, school_id, invoice_id, "Invoice")
            # Every keyed request takes key → invoice locks in that order.
            # The existing payment UUID is the durable deduplication identity;
            # no separate cache, expiring key table or schema migration needed.
            lock_key = int.from_bytes(
                hashlib.sha256(b"fee-payment:" + idempotency_key.bytes).digest()[:8],
                "big",
                signed=True,
            )
            await self.db.execute(
                text("SELECT pg_advisory_xact_lock(:key)"), {"key": lock_key}
            )
            existing = await self.db.get(Payment, idempotency_key)
            if existing is not None:
                same_request = (
                    existing.school_id == school_id
                    and existing.invoice_id == invoice_id
                    and existing.recorded_by == recorded_by
                    and existing.amount == data.amount
                    and existing.method == data.method.value
                    and existing.paid_on == data.paid_on
                    and existing.reference == data.reference
                    and existing.note == data.note
                    and existing.proof_url == data.proof_url
                )
                if not same_request:
                    raise AppHTTPException(
                        409,
                        "Payment request key was already used for different details",
                        ErrorCode.CONFLICT,
                    )
                return existing  # Before the now-paid invoice's balance check.
        # Serialize balance validation and payment recording on this invoice.
        # The request transaction holds this lock through commit/rollback.
        invoice = await self.db.scalar(
            select(Invoice)
            .where(Invoice.id == invoice_id, Invoice.school_id == school_id)
            .with_for_update()
            .execution_options(populate_existing=True)
        )
        if invoice is None:
            raise not_found("Invoice not found in this school")
        total_before = await self.db.scalar(
            select(func.coalesce(func.sum(Payment.amount), 0.0)).where(
                Payment.invoice_id == invoice_id,
                Payment.school_id == school_id,
            )
        )
        # The ledger, not a possibly stale cached total, determines availability.
        remaining = round(invoice.amount - float(total_before), 2)
        if remaining <= 0:
            raise bad_request("Invoice is already fully paid")
        if data.amount > remaining:
            raise bad_request(
                f"Payment ({data.amount}) exceeds the remaining balance ({remaining})"
            )

        payment = Payment(
            id=idempotency_key or uuid.uuid4(),
            school_id=school_id,
            invoice_id=invoice_id,
            amount=data.amount,
            method=data.method.value,
            reference=data.reference,
            paid_on=data.paid_on,
            note=data.note,
            proof_url=data.proof_url,
            recorded_by=recorded_by,
        )
        self.db.add(payment)

        # Recompute amount_paid from all payments to stay authoritative.
        await self.db.flush()
        total_paid = await self.db.scalar(
            select(func.coalesce(func.sum(Payment.amount), 0.0)).where(
                Payment.invoice_id == invoice_id,
                Payment.school_id == school_id,
            )
        )
        invoice.amount_paid = round(float(total_paid), 2)
        invoice.status = self._status_for(invoice.amount, invoice.amount_paid)
        await self.db.flush()
        return payment

    async def get_receipt(
        self, school_id: uuid.UUID, invoice_id: uuid.UUID
    ) -> schemas.Receipt:
        invoice = await self._get_scoped(Invoice, school_id, invoice_id, "Invoice")
        payments = list(
            (
                await self.db.execute(
                    select(Payment)
                    .where(Payment.invoice_id == invoice_id)
                    .order_by(Payment.paid_on)
                )
            )
            .scalars()
            .all()
        )
        # A receipt must reconcile with its listed payments even if a historical
        # cached invoice total drifted. This is a read-only projection, not a
        # silent database repair; historical reconciliation remains explicit.
        total_paid = round(sum(payment.amount for payment in payments), 2)
        snapshot = schemas.InvoiceOut.model_validate(invoice).model_copy(
            update={
                "amount_paid": total_paid,
                "status": self._status_for(invoice.amount, total_paid),
            }
        )
        return schemas.Receipt(
            invoice=snapshot,
            payments=[schemas.PaymentOut.model_validate(p) for p in payments],
            total_paid=total_paid,
        )

    # ------------------------------ reports ------------------------------ #

    async def report(self, school_id: uuid.UUID) -> schemas.FeeReport:
        sessions = select(AcademicSession.id).where(
            AcademicSession.school_id == school_id
        )
        structures = select(FeeStructure.id).where(
            FeeStructure.school_id == school_id,
            or_(
                FeeStructure.class_id.is_(None),
                FeeStructure.class_id.in_(valid_classes(school_id)),
            ),
            or_(
                FeeStructure.session_id.is_(None), FeeStructure.session_id.in_(sessions)
            ),
        )
        invoices_query = select(Invoice).where(
            Invoice.school_id == school_id,
            Invoice.student_id.in_(role_ids(school_id, SystemRole.STUDENT.value)),
            or_(Invoice.session_id.is_(None), Invoice.session_id.in_(sessions)),
            or_(
                Invoice.fee_structure_id.is_(None),
                Invoice.fee_structure_id.in_(structures),
            ),
        )
        # A single read statement keeps invoice and ledger projections consistent
        # within the database snapshot without repairing cached historical fields.
        payments = (
            select(
                Payment.invoice_id,
                func.sum(Payment.amount).label("paid"),
            )
            .where(Payment.school_id == school_id)
            .group_by(Payment.invoice_id)
            .subquery()
        )
        rows = (
            await self.db.execute(
                invoices_query.add_columns(
                    func.coalesce(payments.c.paid, 0),
                ).outerjoin(payments, payments.c.invoice_id == Invoice.id)
            )
        ).all()
        today = date.today()
        billed = sum(invoice.amount for invoice, _ in rows)
        collected = sum(paid for _, paid in rows)
        status_counts = {s.value: 0 for s in InvoiceStatus}
        overdue = 0
        for invoice, paid in rows:
            invoice_status = self._status_for(invoice.amount, paid)
            status_counts[invoice_status] += 1
            if invoice_status != InvoiceStatus.PAID.value and invoice.due_date < today:
                overdue += 1
        return schemas.FeeReport(
            school_id=school_id,
            total_invoices=len(rows),
            total_billed=round(billed, 2),
            total_collected=round(collected, 2),
            total_outstanding=round(billed - collected, 2),
            overdue_count=overdue,
            status_counts=status_counts,
        )

    async def aging_report(
        self, school_id: uuid.UUID, as_of: date
    ) -> schemas.FeeAgingReport:
        """Project ledger-derived outstanding balances into stable aging buckets.

        This is deliberately read-only.  It derives each balance from the payment
        ledger instead of trusting ``Invoice.amount_paid``, so an aging report can
        expose reconciliation drift without altering a historical invoice.
        """
        sessions = select(AcademicSession.id).where(
            AcademicSession.school_id == school_id
        )
        structures = select(FeeStructure.id).where(
            FeeStructure.school_id == school_id,
            or_(
                FeeStructure.class_id.is_(None),
                FeeStructure.class_id.in_(valid_classes(school_id)),
            ),
            or_(
                FeeStructure.session_id.is_(None), FeeStructure.session_id.in_(sessions)
            ),
        )
        invoices_query = select(Invoice).where(
            Invoice.school_id == school_id,
            Invoice.student_id.in_(role_ids(school_id, SystemRole.STUDENT.value)),
            or_(Invoice.session_id.is_(None), Invoice.session_id.in_(sessions)),
            or_(
                Invoice.fee_structure_id.is_(None),
                Invoice.fee_structure_id.in_(structures),
            ),
        )
        payments = (
            select(
                Payment.invoice_id,
                func.sum(Payment.amount).label("paid"),
            )
            .where(Payment.school_id == school_id)
            .group_by(Payment.invoice_id)
            .subquery()
        )
        rows = (
            await self.db.execute(
                invoices_query.add_columns(
                    func.coalesce(payments.c.paid, 0),
                ).outerjoin(payments, payments.c.invoice_id == Invoice.id)
            )
        ).all()

        labels = ("Current", "1–30 days", "31–60 days", "61–90 days", "91+ days")
        buckets = {
            label: {"invoice_count": 0, "outstanding_total": 0.0} for label in labels
        }
        for invoice, paid in rows:
            balance = round(invoice.amount - float(paid), 2)
            if balance <= 0:
                continue
            overdue_days = (as_of - invoice.due_date).days
            if overdue_days <= 0:
                label = "Current"
            elif overdue_days <= 30:
                label = "1–30 days"
            elif overdue_days <= 60:
                label = "31–60 days"
            elif overdue_days <= 90:
                label = "61–90 days"
            else:
                label = "91+ days"
            buckets[label]["invoice_count"] += 1
            buckets[label]["outstanding_total"] += balance

        output = [
            schemas.FeeAgingBucket(
                label=label,
                invoice_count=buckets[label]["invoice_count"],
                outstanding_total=round(buckets[label]["outstanding_total"], 2),
            )
            for label in labels
        ]
        return schemas.FeeAgingReport(
            school_id=school_id,
            as_of_date=as_of,
            total_outstanding=round(
                sum(bucket.outstanding_total for bucket in output), 2
            ),
            buckets=output,
        )

    async def reconciliation_report(
        self, school_id: uuid.UUID, limit: int
    ) -> schemas.FeeReconciliationReport:
        """Expose payment-ledger/cache drift for Headmaster review without repair."""
        sessions = select(AcademicSession.id).where(
            AcademicSession.school_id == school_id
        )
        structures = select(FeeStructure.id).where(
            FeeStructure.school_id == school_id,
            or_(
                FeeStructure.class_id.is_(None),
                FeeStructure.class_id.in_(valid_classes(school_id)),
            ),
            or_(
                FeeStructure.session_id.is_(None), FeeStructure.session_id.in_(sessions)
            ),
        )
        invoices_query = select(Invoice).where(
            Invoice.school_id == school_id,
            Invoice.student_id.in_(role_ids(school_id, SystemRole.STUDENT.value)),
            or_(Invoice.session_id.is_(None), Invoice.session_id.in_(sessions)),
            or_(
                Invoice.fee_structure_id.is_(None),
                Invoice.fee_structure_id.in_(structures),
            ),
        )
        payments = (
            select(Payment.invoice_id, func.sum(Payment.amount).label("paid"))
            .where(Payment.school_id == school_id)
            .group_by(Payment.invoice_id)
            .subquery()
        )
        rows = (
            await self.db.execute(
                invoices_query.add_columns(func.coalesce(payments.c.paid, 0))
                .outerjoin(payments, payments.c.invoice_id == Invoice.id)
                .order_by(Invoice.due_date, Invoice.id)
            )
        ).all()
        issues: list[schemas.FeeReconciliationIssue] = []
        for invoice, paid in rows:
            ledger_paid = round(float(paid), 2)
            ledger_status = self._status_for(invoice.amount, ledger_paid)
            codes = []
            if round(invoice.amount_paid, 2) != ledger_paid:
                codes.append("cached_total_mismatch")
            if invoice.status != ledger_status:
                codes.append("cached_status_mismatch")
            if ledger_paid > invoice.amount:
                codes.append("overpaid")
            if codes:
                issues.append(
                    schemas.FeeReconciliationIssue(
                        invoice_id=invoice.id,
                        cached_amount_paid=invoice.amount_paid,
                        ledger_amount_paid=ledger_paid,
                        cached_status=invoice.status,
                        ledger_status=ledger_status,
                        issue_codes=codes,
                    )
                )
        return schemas.FeeReconciliationReport(
            school_id=school_id,
            invoices_scanned=len(rows),
            reconciled_count=len(rows) - len(issues),
            mismatch_count=len(issues),
            issues=issues[:limit],
        )

    # ------------------------ adjustment proposals ----------------------- #

    async def create_adjustment(
        self,
        school_id: uuid.UUID,
        data: schemas.FinancialAdjustmentCreate,
        requested_by: uuid.UUID,
    ) -> schemas.FinancialAdjustmentOut:
        target_type = await self._validate_adjustment_target(
            school_id, data.kind, data.target_id
        )
        adjustment = FinancialAdjustment(
            school_id=school_id,
            kind=data.kind,
            target_type=target_type,
            target_id=data.target_id,
            proposed_amount=data.proposed_amount,
            currency_code=data.currency_code,
            reason=data.reason,
            requested_by=requested_by,
        )
        self.db.add(adjustment)
        await self.db.flush()
        return self._adjustment_out(adjustment)

    async def list_adjustments(
        self,
        school_id: uuid.UUID,
        limit: int,
        offset: int,
        kind: schemas.AdjustmentKind | None = None,
        target_type: schemas.AdjustmentTargetType | None = None,
        decision: schemas.AdjustmentListDecision | None = None,
    ) -> list[schemas.FinancialAdjustmentOut]:
        statement = (
            select(FinancialAdjustment, FinancialAdjustmentDecision)
            .outerjoin(
                FinancialAdjustmentDecision,
                FinancialAdjustmentDecision.adjustment_id == FinancialAdjustment.id,
            )
            .where(FinancialAdjustment.school_id == school_id)
        )
        if kind is not None:
            statement = statement.where(FinancialAdjustment.kind == kind)
        if target_type is not None:
            statement = statement.where(FinancialAdjustment.target_type == target_type)
        if decision == "pending":
            statement = statement.where(FinancialAdjustmentDecision.id.is_(None))
        elif decision is not None:
            statement = statement.where(
                FinancialAdjustmentDecision.decision == decision
            )
        rows = (
            await self.db.execute(
                statement.order_by(
                    FinancialAdjustment.created_at.desc(), FinancialAdjustment.id
                )
                .offset(offset)
                .limit(limit)
            )
        ).all()
        return [
            self._adjustment_out(adjustment, decision) for adjustment, decision in rows
        ]

    async def export_adjustments(
        self,
        school_id: uuid.UUID,
        limit: int,
        offset: int,
        kind: schemas.AdjustmentKind | None = None,
        target_type: schemas.AdjustmentTargetType | None = None,
        decision: schemas.AdjustmentListDecision | None = None,
    ) -> list[tuple[FinancialAdjustment, FinancialAdjustmentDecision | None]]:
        """Return a bounded, tenant-scoped audit export source.

        The router formats these rows as CSV.  Keeping the query here makes the
        school constraint identical to the review queue and prevents an export
        endpoint from accidentally bypassing that boundary.
        """
        statement = (
            select(FinancialAdjustment, FinancialAdjustmentDecision)
            .outerjoin(
                FinancialAdjustmentDecision,
                FinancialAdjustmentDecision.adjustment_id == FinancialAdjustment.id,
            )
            .where(FinancialAdjustment.school_id == school_id)
        )
        if kind is not None:
            statement = statement.where(FinancialAdjustment.kind == kind)
        if target_type is not None:
            statement = statement.where(FinancialAdjustment.target_type == target_type)
        if decision == "pending":
            statement = statement.where(FinancialAdjustmentDecision.id.is_(None))
        elif decision is not None:
            statement = statement.where(
                FinancialAdjustmentDecision.decision == decision
            )
        return (
            await self.db.execute(
                statement.order_by(
                    FinancialAdjustment.created_at.desc(), FinancialAdjustment.id
                )
                .offset(offset)
                .limit(limit)
            )
        ).all()

    async def decide_adjustment(
        self,
        school_id: uuid.UUID,
        adjustment_id: uuid.UUID,
        data: schemas.FinancialAdjustmentDecisionCreate,
        decided_by: uuid.UUID,
    ) -> schemas.FinancialAdjustmentOut:
        adjustment = await self.db.scalar(
            select(FinancialAdjustment)
            .where(
                FinancialAdjustment.id == adjustment_id,
                FinancialAdjustment.school_id == school_id,
            )
            .with_for_update()
        )
        if adjustment is None:
            raise not_found("Financial adjustment not found in this school")
        existing = await self.db.scalar(
            select(FinancialAdjustmentDecision).where(
                FinancialAdjustmentDecision.adjustment_id == adjustment_id
            )
        )
        if existing is not None:
            raise bad_request("This financial adjustment already has a decision")
        decision = FinancialAdjustmentDecision(
            school_id=school_id,
            adjustment_id=adjustment.id,
            decision=data.decision,
            reason=data.reason,
            decided_by=decided_by,
        )
        self.db.add(decision)
        await self.db.flush()
        return self._adjustment_out(adjustment, decision)

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
