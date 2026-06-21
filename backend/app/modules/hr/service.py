"""HR & Payroll Service: staff profiles and payslips."""
import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import bad_request, not_found
from app.models.hr import Payslip, StaffProfile
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
        gross = round(profile.base_salary + data.allowances, 2)
        net = round(gross - data.deductions, 2)
        if net < 0:
            raise bad_request("Deductions exceed gross salary")
        payslip = Payslip(
            school_id=school_id,
            staff_profile_id=profile_id,
            period_month=data.period_month,
            period_year=data.period_year,
            gross=gross,
            deductions=data.deductions,
            net=net,
            status="unpaid",
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
