"""Reporting & Analytics endpoints, gated by the REPORTS module.

JSON reports require REPORTS view; the CSV export requires REPORTS export.
"""
import csv
import io
import uuid
from datetime import date

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse

from app.core.deps import DbDep, require_school_permission
from app.modules.academic.access import verify_academic_student
from app.core.enums import Module, PermissionAction as PA
from app.modules.reports import schemas
from app.modules.reports.service import ReportingService

router = APIRouter(prefix="/schools/{school_id}/reports", tags=["Reports & Analytics"])

_view = Depends(require_school_permission(Module.REPORTS, PA.VIEW))
_export = Depends(require_school_permission(Module.REPORTS, PA.EXPORT))


@router.get(
    "/students/{student_id}",
    response_model=schemas.StudentReport,
    dependencies=[Depends(verify_academic_student)],
)
async def student_report(
    school_id: uuid.UUID, student_id: uuid.UUID, db: DbDep
) -> schemas.StudentReport:
    """A 360-degree report for one student (attendance, exams, assignments,
    quizzes, points, guardians). Accessible to the managing staff
    (teacher/headmaster), the student's guardian, or the student."""
    return await ReportingService(db).student_report(school_id, student_id)


@router.get("/overview", response_model=schemas.SchoolOverview, dependencies=[_view])
async def overview(school_id: uuid.UUID, db: DbDep) -> schemas.SchoolOverview:
    return await ReportingService(db).overview(school_id)


@router.get("/attendance", response_model=schemas.AttendanceReport, dependencies=[_view])
async def attendance(
    school_id: uuid.UUID,
    db: DbDep,
    section_id: uuid.UUID | None = Query(default=None),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
) -> schemas.AttendanceReport:
    return await ReportingService(db).attendance(school_id, section_id, date_from, date_to)


@router.get("/academic", response_model=schemas.AcademicReport, dependencies=[_view])
async def academic(school_id: uuid.UUID, db: DbDep) -> schemas.AcademicReport:
    return await ReportingService(db).academic(school_id)


@router.get("/finance", response_model=schemas.FinanceReport, dependencies=[_view])
async def finance(school_id: uuid.UUID, db: DbDep) -> schemas.FinanceReport:
    return await ReportingService(db).finance(school_id)


@router.get("/enrollment", response_model=schemas.EnrollmentReport, dependencies=[_view])
async def enrollment(school_id: uuid.UUID, db: DbDep) -> schemas.EnrollmentReport:
    return await ReportingService(db).enrollment(school_id)


@router.get("/attendance/export", dependencies=[_export])
async def export_attendance(
    school_id: uuid.UUID,
    db: DbDep,
    section_id: uuid.UUID | None = Query(default=None),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
) -> StreamingResponse:
    report = await ReportingService(db).attendance(school_id, section_id, date_from, date_to)
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(["status", "count"])
    for status_val, n in report.counts.items():
        writer.writerow([status_val, n])
    writer.writerow(["total", report.total_records])
    writer.writerow(["present_rate", report.present_rate])
    buffer.seek(0)
    return StreamingResponse(
        iter([buffer.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=attendance_report.csv"},
    )
