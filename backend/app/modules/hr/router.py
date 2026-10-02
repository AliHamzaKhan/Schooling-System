"""HR & Payroll endpoints, gated by the HR_PAYROLL module."""
import uuid
from datetime import date as date_type

from fastapi import APIRouter, Depends, Header, Query, status

from app.core.deps import CurrentUser, DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.hr import schemas
from app.modules.hr.service import HRService

router = APIRouter(prefix="/schools/{school_id}/hr", tags=["HR & Payroll"])

_view = Depends(require_school_permission(Module.HR_PAYROLL, PA.VIEW))
_create = Depends(require_school_permission(Module.HR_PAYROLL, PA.CREATE))
_edit = Depends(require_school_permission(Module.HR_PAYROLL, PA.EDIT))


@router.post("/staff", response_model=schemas.StaffProfileOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_staff(school_id: uuid.UUID, data: schemas.StaffProfileCreate, db: DbDep) -> schemas.StaffProfileOut:
    return await HRService(db).create_profile(school_id, data)


@router.get("/staff", response_model=list[schemas.StaffProfileOut], dependencies=[_view])
async def list_staff(school_id: uuid.UUID, db: DbDep) -> list[schemas.StaffProfileOut]:
    return await HRService(db).list_profiles(school_id)


@router.patch("/staff/{profile_id}", response_model=schemas.StaffProfileOut, dependencies=[_edit])
async def update_staff(school_id: uuid.UUID, profile_id: uuid.UUID, data: schemas.StaffProfileUpdate, db: DbDep) -> schemas.StaffProfileOut:
    return await HRService(db).update_profile(school_id, profile_id, data)


@router.post("/staff/{profile_id}/payslips", response_model=schemas.PayslipOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def generate_payslip(school_id: uuid.UUID, profile_id: uuid.UUID, data: schemas.PayslipGenerate, db: DbDep) -> schemas.PayslipOut:
    return await HRService(db).generate_payslip(school_id, profile_id, data)


@router.post("/payslips/{payslip_id}/pay", response_model=schemas.PayslipOut, dependencies=[_edit])
async def mark_paid(
    school_id: uuid.UUID,
    payslip_id: uuid.UUID,
    db: DbDep,
    idempotency_key: uuid.UUID | None = Header(default=None, alias="Idempotency-Key"),
) -> schemas.PayslipOut:
    return await HRService(db).mark_paid(school_id, payslip_id, idempotency_key=idempotency_key)


@router.get("/payslips", response_model=list[schemas.PayslipOut], dependencies=[_view])
async def list_payslips(
    school_id: uuid.UUID,
    db: DbDep,
    profile_id: uuid.UUID | None = Query(default=None),
    year: int | None = Query(default=None),
    month: int | None = Query(default=None),
) -> list[schemas.PayslipOut]:
    return await HRService(db).list_payslips(school_id, profile_id, year, month)


@router.get(
    "/teachers/{teacher_id}/attendance-summary",
    response_model=schemas.MonthlyAttendanceSummary,
    dependencies=[_view],
)
async def teacher_attendance_summary(
    school_id: uuid.UUID,
    teacher_id: uuid.UUID,
    db: DbDep,
    month: int = Query(ge=1, le=12),
    year: int = Query(ge=2000, le=2100),
) -> schemas.MonthlyAttendanceSummary:
    """Monthly attendance roll-up for one teacher, plus the absence deduction
    a payslip would apply. Drives the Generate Payslip screen."""
    return await HRService(db).monthly_attendance_summary(
        school_id, teacher_id, month, year
    )


# --------------------------- teacher attendance -------------------------- #


@router.get("/attendance", response_model=schemas.TeacherAttendanceDay, dependencies=[_view])
async def teacher_attendance_day(
    school_id: uuid.UUID,
    db: DbDep,
    day: date_type = Query(alias="date"),
    status: str | None = Query(
        default=None,
        pattern="^(present|absent|late|on_leave|unmarked)$",
    ),
) -> schemas.TeacherAttendanceDay:
    return await HRService(db).attendance_day(school_id, day, status)


@router.post(
    "/attendance",
    response_model=list[schemas.TeacherAttendanceOut],
    dependencies=[_create],
)
async def mark_teacher_attendance(
    school_id: uuid.UUID,
    data: schemas.TeacherAttendanceBulkMark,
    db: DbDep,
    current_user: CurrentUser,
) -> list[schemas.TeacherAttendanceOut]:
    rows = await HRService(db).bulk_upsert_attendance(school_id, data, current_user.id)
    return [schemas.TeacherAttendanceOut.model_validate(r) for r in rows]
