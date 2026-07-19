"""Fee Management endpoints, gated by the FEE_MANAGEMENT module."""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import CurrentUser, DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.fees import schemas
from app.modules.fees.service import FeeService

router = APIRouter(prefix="/schools/{school_id}/fees", tags=["Fee Management"])

_view = Depends(require_school_permission(Module.FEE_MANAGEMENT, PA.VIEW))
_create = Depends(require_school_permission(Module.FEE_MANAGEMENT, PA.CREATE))
_export = Depends(require_school_permission(Module.FEE_MANAGEMENT, PA.EXPORT))


# --------------------------- fee structures ----------------------------- #


@router.post("/structures", response_model=schemas.FeeStructureOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_structure(school_id: uuid.UUID, data: schemas.FeeStructureCreate, db: DbDep) -> schemas.FeeStructureOut:
    return await FeeService(db).create_structure(school_id, data)


@router.get("/structures", response_model=list[schemas.FeeStructureOut], dependencies=[_view])
async def list_structures(school_id: uuid.UUID, db: DbDep) -> list[schemas.FeeStructureOut]:
    return await FeeService(db).list_structures(school_id)


# ------------------------------- invoices ------------------------------- #


@router.post("/invoices", response_model=schemas.InvoiceOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_invoice(school_id: uuid.UUID, data: schemas.InvoiceCreate, db: DbDep) -> schemas.InvoiceOut:
    return await FeeService(db).create_invoice(school_id, data)


@router.post("/invoices/bulk", response_model=list[schemas.InvoiceOut], status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def bulk_create_invoices(school_id: uuid.UUID, data: schemas.BulkInvoiceCreate, db: DbDep) -> list[schemas.InvoiceOut]:
    return await FeeService(db).bulk_create_invoices(school_id, data)


@router.get("/invoices", response_model=list[schemas.InvoiceOut], dependencies=[_view])
async def list_invoices(
    school_id: uuid.UUID,
    db: DbDep,
    student_id: uuid.UUID | None = Query(default=None),
    status: str | None = Query(default=None),
    class_id: uuid.UUID | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> list[schemas.InvoiceOut]:
    items, _ = await FeeService(db).list_invoices(
        school_id, student_id, status, class_id, limit, offset
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
        school_id, q, limit, offset, class_id, fee_status,
    )
    return schemas.StudentFeePage(total=total, items=items)


@router.get("/invoices/{invoice_id}", response_model=schemas.InvoiceOut, dependencies=[_view])
async def get_invoice(school_id: uuid.UUID, invoice_id: uuid.UUID, db: DbDep) -> schemas.InvoiceOut:
    return await FeeService(db).get_invoice(school_id, invoice_id)


@router.get("/invoices/{invoice_id}/receipt", response_model=schemas.Receipt, dependencies=[_view])
async def get_receipt(school_id: uuid.UUID, invoice_id: uuid.UUID, db: DbDep) -> schemas.Receipt:
    return await FeeService(db).get_receipt(school_id, invoice_id)


# ------------------------------- payments ------------------------------- #


@router.post("/invoices/{invoice_id}/payments", response_model=schemas.PaymentOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def record_payment(
    school_id: uuid.UUID,
    invoice_id: uuid.UUID,
    data: schemas.PaymentCreate,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.PaymentOut:
    return await FeeService(db).record_payment(school_id, invoice_id, data, current_user.id)


# -------------------------------- reports ------------------------------- #


@router.get("/report", response_model=schemas.FeeReport, dependencies=[_export])
async def fee_report(school_id: uuid.UUID, db: DbDep) -> schemas.FeeReport:
    return await FeeService(db).report(school_id)
