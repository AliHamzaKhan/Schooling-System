"""HR & Payroll Service: staff profiles, payslips, teacher attendance."""
import calendar
import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import SystemRole
from app.core.exceptions import bad_request, not_found
from app.models.hr import Payslip, StaffProfile
from app.models.role import Role
from app.models.teacher_attendance import TeacherAttendance
from app.models.user import User
from app.modules.hr import schemas


class HRService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _get_profile(self, school_id: uuid.UUID, profile_id: uuid.UUID) -> StaffProfile:
        profile = await self.db.get(StaffProfile, profile_id)
        if profile is None or profile.school_id != school_id:
            raise not_found("Staff profile not found in this school")
        return profile

    # --------------------------- staff profiles -------------------------- #

    async def create_profile(self, school_id: uuid.UUID, data: schemas.StaffProfileCreate) -> StaffProfile:
        user = await self.db.get(User, data.user_id)
        if user is None or user.school_id != school_id:
            raise bad_request("User is not a member of this school")
        dupe = await self.db.scalar(select(StaffProfile).where(StaffProfile.user_id == data.user_id))
        if dupe is not None:
            raise bad_request("This user already has a staff profile")
        profile = StaffProfile(school_id=school_id, **data.model_dump())
        self.db.add(profile)
        await self.db.flush()
        return profile

    async def list_profiles(self, school_id: uuid.UUID) -> list[StaffProfile]:
        result = await self.db.execute(select(StaffProfile).where(StaffProfile.school_id == school_id))
        return list(result.scalars().all())

    async def update_profile(self, school_id: uuid.UUID, profile_id: uuid.UUID, data: schemas.StaffProfileUpdate) -> StaffProfile:
        profile = await self._get_profile(school_id, profile_id)
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(profile, field, value)
        await self.db.flush()
        return profile

    # ------------------------------ payslips ----------------------------- #

    @staticmethod
    def _period_bounds(month: int, year: int) -> tuple[date, date]:
        """First and last day of the given month."""
        start = date(year, month, 1)
        last_day = calendar.monthrange(year, month)[1]
        return start, date(year, month, last_day)

    async def _attendance_counts(
        self, school_id: uuid.UUID, teacher_id: uuid.UUID, month: int, year: int
    ) -> dict[str, int]:
        start, end = self._period_bounds(month, year)
        rows = list(
            (
                await self.db.execute(
                    select(TeacherAttendance.status).where(
                        TeacherAttendance.school_id == school_id,
                        TeacherAttendance.teacher_id == teacher_id,
                        TeacherAttendance.attendance_date >= start,
                        TeacherAttendance.attendance_date <= end,
                    )
                )
            )
            .scalars()
            .all()
        )
        counts = {"present": 0, "absent": 0, "late": 0, "on_leave": 0}
        for status in rows:
            if status in counts:
                counts[status] += 1
        counts["marked"] = len(rows)
        return counts

    async def monthly_attendance_summary(
        self, school_id: uuid.UUID, teacher_id: uuid.UUID, month: int, year: int
    ) -> schemas.MonthlyAttendanceSummary:
        """Attendance roll-up + the absence deduction the payslip WOULD apply."""
        counts = await self._attendance_counts(school_id, teacher_id, month, year)
        profile = await self.db.scalar(
            select(StaffProfile).where(
                StaffProfile.school_id == school_id,
                StaffProfile.user_id == teacher_id,
            )
        )
        projected = 0.0
        if profile is not None:
            projected = round((profile.base_salary / 30.0) * counts["absent"], 2)
        return schemas.MonthlyAttendanceSummary(
            teacher_id=teacher_id,
            period_month=month,
            period_year=year,
            present_days=counts["present"],
            absent_days=counts["absent"],
            late_days=counts["late"],
            leave_days=counts["on_leave"],
            marked_days=counts["marked"],
            projected_absence_deduction=projected,
        )

    async def generate_payslip(self, school_id: uuid.UUID, profile_id: uuid.UUID, data: schemas.PayslipGenerate) -> Payslip:
        profile = await self._get_profile(school_id, profile_id)
        dupe = await self.db.scalar(
            select(Payslip).where(
                Payslip.staff_profile_id == profile_id,
                Payslip.period_year == data.period_year,
                Payslip.period_month == data.period_month,
            )
        )
        if dupe is not None:
            raise bad_request("A payslip already exists for this staff member and period")

        # Snapshot the period's attendance regardless of the deduction toggle so
        # the payslip PDF can always show it.
        counts = await self._attendance_counts(
            school_id, profile.user_id, data.period_month, data.period_year
        )
        absence_deduction = 0.0
        if data.deduct_absences and counts["absent"] > 0:
            absence_deduction = round(
                (profile.base_salary / 30.0) * counts["absent"], 2
            )

        gross = round(profile.base_salary + data.allowances, 2)
        total_deductions = round(data.deductions + absence_deduction, 2)
        net = round(gross - total_deductions, 2)
        if net < 0:
            raise bad_request("Deductions exceed gross salary")
        payslip = Payslip(
            school_id=school_id,
            staff_profile_id=profile_id,
            period_month=data.period_month,
            period_year=data.period_year,
            gross=gross,
            allowances=data.allowances,
            deductions=total_deductions,
            net=net,
            status="unpaid",
            present_days=counts["present"],
            absent_days=counts["absent"],
            late_days=counts["late"],
            leave_days=counts["on_leave"],
            absence_deduction=absence_deduction,
        )
        self.db.add(payslip)
        await self.db.flush()
        return payslip

    async def mark_paid(self, school_id: uuid.UUID, payslip_id: uuid.UUID) -> Payslip:
        payslip = await self.db.get(Payslip, payslip_id)
        if payslip is None or payslip.school_id != school_id:
            raise not_found("Payslip not found in this school")
        if payslip.status == "paid":
            raise bad_request("Payslip is already paid")
        payslip.status = "paid"
        payslip.paid_on = date.today()
        await self.db.flush()
        return payslip

    async def list_payslips(
        self, school_id: uuid.UUID, profile_id: uuid.UUID | None = None,
        year: int | None = None, month: int | None = None,
    ) -> list[Payslip]:
        stmt = select(Payslip).where(Payslip.school_id == school_id)
        if profile_id is not None:
            stmt = stmt.where(Payslip.staff_profile_id == profile_id)
        if year is not None:
            stmt = stmt.where(Payslip.period_year == year)
        if month is not None:
            stmt = stmt.where(Payslip.period_month == month)
        return list((await self.db.execute(stmt)).scalars().all())

    # -------------------------- teacher attendance ----------------------- #

    async def _validate_teacher(self, school_id: uuid.UUID, teacher_id: uuid.UUID) -> User:
        user = await self.db.scalar(
            select(User).where(
                User.id == teacher_id,
                User.school_id == school_id,
                User.roles.any(Role.code == SystemRole.TEACHER.value),
            )
        )
        if user is None:
            raise bad_request("User is not a teacher in this school")
        return user

    async def upsert_attendance(
        self, school_id: uuid.UUID, entry: schemas.TeacherAttendanceMark,
        marked_by: uuid.UUID,
    ) -> TeacherAttendance:
        await self._validate_teacher(school_id, entry.teacher_id)
        existing = await self.db.scalar(
            select(TeacherAttendance).where(
                TeacherAttendance.teacher_id == entry.teacher_id,
                TeacherAttendance.attendance_date == entry.attendance_date,
            )
        )
        if existing is not None:
            existing.status = entry.status
            existing.arrival_time = entry.arrival_time
            existing.remarks = entry.remarks
            existing.marked_by = marked_by
            await self.db.flush()
            return existing
        row = TeacherAttendance(
            school_id=school_id,
            teacher_id=entry.teacher_id,
            attendance_date=entry.attendance_date,
            status=entry.status,
            arrival_time=entry.arrival_time,
            remarks=entry.remarks,
            marked_by=marked_by,
        )
        self.db.add(row)
        await self.db.flush()
        return row

    async def bulk_upsert_attendance(
        self, school_id: uuid.UUID,
        payload: schemas.TeacherAttendanceBulkMark,
        marked_by: uuid.UUID,
    ) -> list[TeacherAttendance]:
        rows: list[TeacherAttendance] = []
        for entry in payload.entries:
            rows.append(await self.upsert_attendance(school_id, entry, marked_by))
        return rows

    async def attendance_day(
        self, school_id: uuid.UUID, on: date,
        status: str | None = None,
    ) -> schemas.TeacherAttendanceDay:
        """All teachers for the school on [on] with their attendance entry.

        Filters the returned roster to a specific status when [status] is set;
        aggregate counts are always over the full roster.
        """
        teachers = list(
            (
                await self.db.execute(
                    select(User)
                    .where(
                        User.school_id == school_id,
                        User.roles.any(Role.code == SystemRole.TEACHER.value),
                    )
                    .order_by(User.full_name)
                )
            )
            .scalars()
            .all()
        )
        if not teachers:
            return schemas.TeacherAttendanceDay(
                attendance_date=on, total_teachers=0,
                present=0, absent=0, late=0, on_leave=0, unmarked=0,
                entries=[],
            )
        teacher_ids = [t.id for t in teachers]
        records = list(
            (
                await self.db.execute(
                    select(TeacherAttendance).where(
                        TeacherAttendance.school_id == school_id,
                        TeacherAttendance.teacher_id.in_(teacher_ids),
                        TeacherAttendance.attendance_date == on,
                    )
                )
            )
            .scalars()
            .all()
        )
        by_teacher = {r.teacher_id: r for r in records}

        counts = {"present": 0, "absent": 0, "late": 0, "on_leave": 0, "unmarked": 0}
        roster: list[schemas.TeacherAttendanceRosterRow] = []
        for t in teachers:
            r = by_teacher.get(t.id)
            s = r.status if r is not None else None
            counts[s if s is not None else "unmarked"] += 1
            if status is not None and (s or "unmarked") != status:
                continue
            roster.append(
                schemas.TeacherAttendanceRosterRow(
                    teacher_id=t.id,
                    teacher_name=t.full_name,
                    status=s,  # type: ignore[arg-type]
                    arrival_time=r.arrival_time if r else None,
                    remarks=r.remarks if r else None,
                )
            )
        return schemas.TeacherAttendanceDay(
            attendance_date=on,
            total_teachers=len(teachers),
            present=counts["present"],
            absent=counts["absent"],
            late=counts["late"],
            on_leave=counts["on_leave"],
            unmarked=counts["unmarked"],
            entries=roster,
        )
