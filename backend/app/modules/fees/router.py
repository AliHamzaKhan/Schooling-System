"""Fee Management endpoints, gated by the FEE_MANAGEMENT module."""

import csv
import io
import uuid
from datetime import date

from fastapi import APIRouter, Depends, Header, Query, status
from fastapi.responses import StreamingResponse

from app.core.deps import (
    CurrentUser,
    DbDep,
    require_school_admin,
    require_school_permission,
)
from app.core.enums import Module, PermissionAction as PA
from app.core.pagination import OffsetPage
from app.modules.fees import schemas
from app.modules.fees.service import FeeService

router = APIRouter(prefix="/schools/{school_id}/fees", tags=["Fee Management"])

_view = Depends(require_school_permission(Module.FEE_MANAGEMENT, PA.VIEW))
_create = Depends(require_school_permission(Module.FEE_MANAGEMENT, PA.CREATE))
_export = Depends(require_school_permission(Module.FEE_MANAGEMENT, PA.EXPORT))
_admin = Depends(require_school_admin)


def _csv_cell(value: object | None) -> str:
    """Prevent spreadsheet formula execution for every exported cell.

    CSV quoting preserves the file syntax, but Excel and similar spreadsheet
    programs still evaluate cells whose first significant character is a
    formula prefix.  A leading apostrophe keeps the value visible as text.
    """
    text = "" if value is None else str(value)
    if text.lstrip(" \t\r\n")[:1] in {"=", "+", "-", "@"}:
        return "'" + text
    return text


# --------------------------- fee structures ----------------------------- #


@router.post(
    "/structures",
    response_model=schemas.FeeStructureOut,
    status_code=status.HTTP_201_CREATED,
    dependencies=[_create],
)
async def create_structure(
    school_id: uuid.UUID, data: schemas.FeeStructureCreate, db: DbDep
) -> schemas.FeeStructureOut:
    return await FeeService(db).create_structure(school_id, data)


@router.get(
    "/structures", response_model=list[schemas.FeeStructureOut], dependencies=[_view]
)
async def list_structures(
    school_id: uuid.UUID, db: DbDep
) -> list[schemas.FeeStructureOut]:
    return await FeeService(db).list_structures(school_id)


# ------------------------------- invoices ------------------------------- #


@router.post(
    "/invoices",
    response_model=schemas.InvoiceOut,
    status_code=status.HTTP_201_CREATED,
    dependencies=[_create],
)
async def create_invoice(
    school_id: uuid.UUID, data: schemas.InvoiceCreate, db: DbDep
) -> schemas.InvoiceOut:
    return await FeeService(db).create_invoice(school_id, data)


@router.post(
    "/invoices/bulk",
    response_model=list[schemas.InvoiceOut],
    status_code=status.HTTP_201_CREATED,
    dependencies=[_create],
)
async def bulk_create_invoices(
    school_id: uuid.UUID, data: schemas.BulkInvoiceCreate, db: DbDep
) -> list[schemas.InvoiceOut]:
    return await FeeService(db).bulk_create_invoices(school_id, data)


@router.get("/invoices", response_model=list[schemas.InvoiceOut], dependencies=[_view])
async def list_invoices(
    school_id: uuid.UUID,
    db: DbDep,
    page: OffsetPage = Depends(),
    student_id: uuid.UUID | None = Query(default=None),
    status: str | None = Query(default=None),
    class_id: uuid.UUID | None = Query(default=None),
) -> list[schemas.InvoiceOut]:
    items, _ = await FeeService(db).list_invoices(
        school_id, student_id, status, class_id, page.limit, page.offset
    )
    return items


@router.get("/students", response_model=schemas.StudentFeePage, dependencies=[_view])
async def search_student_fees(
    school_id: uuid.UUID,
    db: DbDep,
    q: str = Query(default="", max_length=100),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    class_id: uuid.UUID | None = Query(default=None),
    fee_status: str | None = Query(
        default=None,
        pattern="^(overdue|pending|paid|no_dues)$",
    ),
) -> schemas.StudentFeePage:
    items, total = await FeeService(db).search_student_fees(
        school_id,
        q,
        limit,
        offset,
        class_id,
        fee_status,
    )
    return schemas.StudentFeePage(total=total, items=items)


@router.get(
    "/invoices/{invoice_id}", response_model=schemas.InvoiceOut, dependencies=[_view]
)
async def get_invoice(
    school_id: uuid.UUID, invoice_id: uuid.UUID, db: DbDep
) -> schemas.InvoiceOut:
    return await FeeService(db).get_invoice(school_id, invoice_id)


@router.get(
    "/invoices/{invoice_id}/receipt",
    response_model=schemas.Receipt,
    dependencies=[_view],
)
async def get_receipt(
    school_id: uuid.UUID, invoice_id: uuid.UUID, db: DbDep
) -> schemas.Receipt:
    return await FeeService(db).get_receipt(school_id, invoice_id)


# --------------------------- billing contacts --------------------------- #


@router.get(
    "/students/{student_id}/billing-contacts",
    response_model=list[schemas.BillingContactOut],
    dependencies=[_admin],
)
async def list_billing_contacts(
    school_id: uuid.UUID, student_id: uuid.UUID, db: DbDep
) -> list[schemas.BillingContactOut]:
    return await FeeService(db).list_billing_contacts(school_id, student_id)


@router.get(
    "/students/{student_id}/billing-contacts/candidates",
    response_model=list[schemas.BillingGuardianCandidate],
    dependencies=[_admin],
)
async def list_billing_guardian_candidates(
    school_id: uuid.UUID, student_id: uuid.UUID, db: DbDep
) -> list[schemas.BillingGuardianCandidate]:
    return await FeeService(db).list_billing_guardian_candidates(school_id, student_id)


@router.put(
    "/students/{student_id}/billing-contacts/{guardian_id}",
    response_model=schemas.BillingContactOut,
    dependencies=[_admin],
)
async def upsert_billing_contact(
    school_id: uuid.UUID,
    student_id: uuid.UUID,
    guardian_id: uuid.UUID,
    data: schemas.BillingContactUpsert,
    db: DbDep,
) -> schemas.BillingContactOut:
    return await FeeService(db).upsert_billing_contact(
        school_id, student_id, guardian_id, data
    )


# ------------------------------- payments ------------------------------- #


@router.post(
    "/invoices/{invoice_id}/payments",
    response_model=schemas.PaymentOut,
    status_code=status.HTTP_201_CREATED,
    dependencies=[_create],
)
async def record_payment(
    school_id: uuid.UUID,
    invoice_id: uuid.UUID,
    data: schemas.PaymentCreate,
    db: DbDep,
    current_user: CurrentUser,
    idempotency_key: uuid.UUID | None = Header(default=None, alias="Idempotency-Key"),
) -> schemas.PaymentOut:
    return await FeeService(db).record_payment(
        school_id,
        invoice_id,
        data,
        current_user.id,
        idempotency_key=idempotency_key,
    )


# -------------------------------- reports ------------------------------- #


@router.get("/report", response_model=schemas.FeeReport, dependencies=[_export])
async def fee_report(school_id: uuid.UUID, db: DbDep) -> schemas.FeeReport:
    return await FeeService(db).report(school_id)


@router.get("/aging", response_model=schemas.FeeAgingReport, dependencies=[_admin])
async def fee_aging_report(
    school_id: uuid.UUID,
    db: DbDep,
    as_of: date | None = Query(default=None),
) -> schemas.FeeAgingReport:
    """Return current/overdue outstanding balances grouped by due-age."""
    return await FeeService(db).aging_report(school_id, as_of or date.today())


@router.get(
    "/reconciliation",
    response_model=schemas.FeeReconciliationReport,
    dependencies=[_admin],
)
async def fee_reconciliation_report(
    school_id: uuid.UUID,
    db: DbDep,
    limit: int = Query(default=50, ge=1, le=200),
) -> schemas.FeeReconciliationReport:
    """List ledger/cache discrepancies; this endpoint never repairs them."""
    return await FeeService(db).reconciliation_report(school_id, limit)


# ------------------------- adjustment proposals ------------------------- #


@router.get("/adjustments/export", dependencies=[_admin])
async def export_financial_adjustments(
    school_id: uuid.UUID,
    db: DbDep,
    limit: int = Query(default=1000, ge=1, le=5000),
    offset: int = Query(default=0, ge=0),
    kind: schemas.AdjustmentKind | None = Query(default=None),
    target_type: schemas.AdjustmentTargetType | None = Query(default=None),
    decision: schemas.AdjustmentListDecision | None = Query(default=None),
) -> StreamingResponse:
    """Export a bounded Headmaster audit view without posting any money."""
    rows = await FeeService(db).export_adjustments(
        school_id,
        limit,
        offset,
        kind=kind,
        target_type=target_type,
        decision=decision,
    )
    buffer = io.StringIO(newline="")
    writer = csv.writer(buffer)
    writer.writerow(
        [
            "adjustment_id",
            "kind",
            "target_type",
            "target_id",
            "proposed_amount",
            "currency_code",
            "reason",
            "requested_by",
            "requested_at",
            "decision",
            "decision_reason",
            "decided_by",
            "decided_at",
        ]
    )
    for adjustment, adjustment_decision in rows:
        writer.writerow(
            [
                _csv_cell(adjustment.id),
                _csv_cell(adjustment.kind),
                _csv_cell(adjustment.target_type),
                _csv_cell(adjustment.target_id),
                _csv_cell(adjustment.proposed_amount),
                _csv_cell(adjustment.currency_code),
                _csv_cell(adjustment.reason),
                _csv_cell(adjustment.requested_by),
                _csv_cell(adjustment.created_at.isoformat()),
                _csv_cell(
                    adjustment_decision.decision if adjustment_decision else None
                ),
                _csv_cell(
                    adjustment_decision.reason if adjustment_decision else None
                ),
                _csv_cell(
                    adjustment_decision.decided_by if adjustment_decision else None
                ),
                _csv_cell(
                    adjustment_decision.created_at.isoformat()
                    if adjustment_decision
                    else None
                ),
            ]
        )
    return StreamingResponse(
        iter([buffer.getvalue()]),
        media_type="text/csv",
        headers={
            "Content-Disposition": "attachment; filename=financial_adjustments.csv"
        },
    )


@router.post(
    "/adjustments",
    response_model=schemas.FinancialAdjustmentOut,
    status_code=status.HTTP_201_CREATED,
    dependencies=[_admin],
)
async def create_financial_adjustment(
    school_id: uuid.UUID,
    data: schemas.FinancialAdjustmentCreate,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.FinancialAdjustmentOut:
    return await FeeService(db).create_adjustment(school_id, data, current_user.id)


@router.get(
    "/adjustments",
    response_model=list[schemas.FinancialAdjustmentOut],
    dependencies=[_admin],
)
async def list_financial_adjustments(
    school_id: uuid.UUID,
    db: DbDep,
    page: OffsetPage = Depends(),
    kind: schemas.AdjustmentKind | None = Query(default=None),
    target_type: schemas.AdjustmentTargetType | None = Query(default=None),
    decision: schemas.AdjustmentListDecision | None = Query(default=None),
) -> list[schemas.FinancialAdjustmentOut]:
    """Return a scoped, bounded adjustment review queue without posting money."""
    return await FeeService(db).list_adjustments(
        school_id,
        page.limit,
        page.offset,
        kind=kind,
        target_type=target_type,
        decision=decision,
    )


@router.post(
    "/adjustments/{adjustment_id}/decision",
    response_model=schemas.FinancialAdjustmentOut,
    dependencies=[_admin],
)
async def decide_financial_adjustment(
    school_id: uuid.UUID,
    adjustment_id: uuid.UUID,
    data: schemas.FinancialAdjustmentDecisionCreate,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.FinancialAdjustmentOut:
    return await FeeService(db).decide_adjustment(
        school_id, adjustment_id, data, current_user.id
    )


# ----------------------------- fee reminders ---------------------------- #


@router.post("/send-reminders", dependencies=[_create])
async def send_fee_reminders(
    school_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> dict:
    """Manually notify guardians of every student with outstanding fees.

    The same reminder runs automatically 5 days before the salary payout day via
    the ``/jobs/fee-reminders`` cron endpoint; this lets a headmaster fire it on
    demand."""
    count = await FeeService(db).send_fee_reminders(school_id, current_user.id)
    return {"notified_students": count}
