"""Attendance Service endpoints.

Enrollment is gated by STUDENT_MANAGEMENT; attendance marking/viewing by the
ATTENDANCE module. School scoping via require_school_permission.
"""
import uuid
from datetime import date

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import CurrentUser, DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.attendance import schemas
from app.modules.attendance.service import AttendanceService

router = APIRouter(prefix="/schools/{school_id}", tags=["Attendance"])

# Enrollment = managing students
_enroll = Depends(require_school_permission(Module.STUDENT_MANAGEMENT, PA.CREATE))
_enroll_view = Depends(require_school_permission(Module.STUDENT_MANAGEMENT, PA.VIEW))
_enroll_edit = Depends(require_school_permission(Module.STUDENT_MANAGEMENT, PA.EDIT))
# Attendance module
_att_mark = Depends(require_school_permission(Module.ATTENDANCE, PA.CREATE))
_att_view = Depends(require_school_permission(Module.ATTENDANCE, PA.VIEW))


# ----------------------------- enrollment ------------------------------- #


@router.post(
    "/sections/{section_id}/students",
    response_model=schemas.EnrollmentOut,
    status_code=status.HTTP_201_CREATED,
    dependencies=[_enroll],
)
async def enroll_student(
    school_id: uuid.UUID, section_id: uuid.UUID, data: schemas.EnrollIn, db: DbDep
) -> schemas.EnrollmentOut:
    return await AttendanceService(db).enroll(school_id, section_id, data)


@router.get(
    "/sections/{section_id}/students",
    response_model=list[schemas.EnrollmentOut],
    dependencies=[_enroll_view],
)
async def list_enrollments(
    school_id: uuid.UUID, section_id: uuid.UUID, db: DbDep
) -> list[schemas.EnrollmentOut]:
    return await AttendanceService(db).list_enrollments(school_id, section_id)


@router.delete(
    "/sections/{section_id}/students/{student_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[_enroll_edit],
)
async def unenroll_student(
    school_id: uuid.UUID, section_id: uuid.UUID, student_id: uuid.UUID, db: DbDep
) -> None:
    await AttendanceService(db).unenroll(school_id, section_id, student_id)


# ----------------------------- attendance ------------------------------- #


@router.post(
    "/attendance",
    response_model=list[schemas.AttendanceRecordOut],
    status_code=status.HTTP_201_CREATED,
    dependencies=[_att_mark],
)
async def mark_attendance(
    school_id: uuid.UUID,
    data: schemas.AttendanceMarkRequest,
    db: DbDep,
    current_user: CurrentUser,
) -> list[schemas.AttendanceRecordOut]:
    return await AttendanceService(db).mark(school_id, data, current_user.id)


@router.get(
    "/attendance",
    response_model=list[schemas.AttendanceRecordOut],
    dependencies=[_att_view],
)
async def list_section_attendance(
    school_id: uuid.UUID,
    db: DbDep,
    section_id: uuid.UUID = Query(...),
    attendance_date: date = Query(...),
) -> list[schemas.AttendanceRecordOut]:
    return await AttendanceService(db).list_for_section_date(school_id, section_id, attendance_date)


@router.get(
    "/attendance/summary",
    response_model=schemas.AttendanceSummary,
    dependencies=[_att_view],
)
async def attendance_summary(
    school_id: uuid.UUID,
    db: DbDep,
    section_id: uuid.UUID = Query(...),
    attendance_date: date = Query(...),
) -> schemas.AttendanceSummary:
    return await AttendanceService(db).summary(school_id, section_id, attendance_date)


@router.get(
    "/students/{student_id}/attendance",
    response_model=list[schemas.AttendanceRecordOut],
    dependencies=[_att_view],
)
async def student_attendance(
    school_id: uuid.UUID,
    student_id: uuid.UUID,
    db: DbDep,
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
) -> list[schemas.AttendanceRecordOut]:
    return await AttendanceService(db).list_for_student(school_id, student_id, date_from, date_to)
