"""HR & Payroll endpoints, gated by the HR_PAYROLL module."""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import DbDep, require_school_permission
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
async def mark_paid(school_id: uuid.UUID, payslip_id: uuid.UUID, db: DbDep) -> schemas.PayslipOut:
    return await HRService(db).mark_paid(school_id, payslip_id)


@router.get("/payslips", response_model=list[schemas.PayslipOut], dependencies=[_view])
async def list_payslips(
    school_id: uuid.UUID,
    db: DbDep,
    profile_id: uuid.UUID | None = Query(default=None),
    year: int | None = Query(default=None),
    month: int | None = Query(default=None),
) -> list[schemas.PayslipOut]:
    return await HRService(db).list_payslips(school_id, profile_id, year, month)
