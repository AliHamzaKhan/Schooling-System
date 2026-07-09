"""School Service: school lifecycle, subscriptions, module toggles, sessions.

All operations here are Super Admin scoped (enforced at the router). The module
toggle + subscription logic is the top of the permission cascade described in
docs/permissions/04 and 07.
"""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import Module, PlanCode, SchoolStatus
from app.core.exceptions import bad_request, not_found
from app.models.school import AcademicSession, School, SchoolModule
from app.models.subscription import SubscriptionPlan
from app.modules.schools import schemas


class SchoolService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ----------------------------- helpers ------------------------------- #

    async def _get_school(self, school_id: uuid.UUID) -> School:
        school = await self.db.get(School, school_id)
        if school is None:
            raise not_found("School not found")
        return school

    async def _get_plan(self, plan_code: PlanCode) -> SubscriptionPlan:
        plan = await self.db.scalar(
            select(SubscriptionPlan).where(SubscriptionPlan.code == plan_code.value)
        )
        if plan is None:
            raise bad_request(f"Subscription plan '{plan_code.value}' is not configured")
        return plan

    # ------------------------------ schools ------------------------------ #

    async def create_school(self, data: schemas.SchoolCreate) -> School:
        existing = await self.db.scalar(select(School).where(School.code == data.code))
        if existing is not None:
            raise bad_request(f"School code '{data.code}' already exists")

        school = School(
            name=data.name,
            code=data.code,
            contact_email=data.contact_email,
            contact_phone=data.contact_phone,
            address=data.address,
            settings=data.settings or {},
            status=SchoolStatus.PENDING.value,
        )
        if data.subscription_plan_code is not None:
            school.subscription_plan = await self._get_plan(data.subscription_plan_code)

        self.db.add(school)
        await self.db.flush()
        await self.db.refresh(school)
        return school

    async def list_schools(self, limit: int = 50, offset: int = 0) -> list[School]:
        result = await self.db.execute(
            select(School).order_by(School.created_at.desc()).limit(limit).offset(offset)
        )
        return list(result.scalars().all())

    async def get_school(self, school_id: uuid.UUID) -> School:
        return await self._get_school(school_id)

    async def update_school(self, school_id: uuid.UUID, data: schemas.SchoolUpdate) -> School:
        school = await self._get_school(school_id)
        payload = data.model_dump(exclude_unset=True)
        for field, value in payload.items():
            setattr(school, field, value)
        await self.db.flush()
        await self.db.refresh(school)
        return school

    async def update_school_profile(
        self, school_id: uuid.UUID, data: schemas.SchoolUpdate
    ) -> School:
        """Like [update_school] but *merges* `settings` into the existing blob
        instead of replacing it, so a partial branding update (logo / uniform /
        fee day) never clobbers unrelated settings keys."""
        school = await self._get_school(school_id)
        payload = data.model_dump(exclude_unset=True)
        incoming_settings = payload.pop("settings", None)
        for field, value in payload.items():
            setattr(school, field, value)
        if incoming_settings is not None:
            merged = {**(school.settings or {}), **incoming_settings}
            school.settings = merged
        await self.db.flush()
        await self.db.refresh(school)
        return school

    async def set_status(self, school_id: uuid.UUID, status: SchoolStatus) -> School:
        school = await self._get_school(school_id)
        school.status = status.value
        await self.db.flush()
        await self.db.refresh(school)
        return school

    # --------------------------- subscription ---------------------------- #

    async def assign_subscription(self, school_id: uuid.UUID, plan_code: PlanCode) -> School:
        school = await self._get_school(school_id)
        school.subscription_plan = await self._get_plan(plan_code)
        await self.db.flush()
        await self.db.refresh(school)
        return school

    # ----------------------------- modules ------------------------------- #

    async def set_module_toggles(
        self, school_id: uuid.UUID, toggles: list[schemas.ModuleToggle]
    ) -> School:
        school = await self._get_school(school_id)
        existing = {sm.module: sm for sm in school.modules}
        for toggle in toggles:
            module_val = toggle.module.value
            if module_val in existing:
                existing[module_val].enabled = toggle.enabled
            else:
                self.db.add(
                    SchoolModule(
                        school_id=school.id, module=module_val, enabled=toggle.enabled
                    )
                )
        await self.db.flush()
        await self.db.refresh(school)
        return school

    async def get_modules_view(self, school_id: uuid.UUID) -> schemas.SchoolModulesView:
        school = await self._get_school(school_id)
        plan = school.subscription_plan
        plan_modules = set(plan.modules) if plan else set()
        toggles = {sm.module: sm.enabled for sm in school.modules}

        statuses: list[schemas.ModuleStatus] = []
        effective: list[str] = []
        for module in Module:
            mv = module.value
            in_plan = mv in plan_modules
            toggle_enabled = toggles.get(mv, True)
            is_effective = in_plan and toggle_enabled
            if is_effective:
                effective.append(mv)
            statuses.append(
                schemas.ModuleStatus(
                    module=mv,
                    in_plan=in_plan,
                    toggle_enabled=toggle_enabled,
                    effective=is_effective,
                )
            )

        return schemas.SchoolModulesView(
            school_id=school.id,
            plan_code=plan.code if plan else None,
            effective_modules=effective,
            modules=statuses,
        )

    # --------------------------- academic sessions ----------------------- #

    async def create_session(
        self, school_id: uuid.UUID, data: schemas.AcademicSessionCreate
    ) -> AcademicSession:
        await self._get_school(school_id)  # ensure exists
        dupe = await self.db.scalar(
            select(AcademicSession).where(
                AcademicSession.school_id == school_id, AcademicSession.name == data.name
            )
        )
        if dupe is not None:
            raise bad_request(f"Session '{data.name}' already exists for this school")

        session = AcademicSession(
            school_id=school_id,
            name=data.name,
            start_date=data.start_date,
            end_date=data.end_date,
            is_active=data.is_active,
        )
        self.db.add(session)
        await self.db.flush()
        if data.is_active:
            await self._deactivate_other_sessions(school_id, keep=session.id)
        await self.db.refresh(session)
        return session

    async def list_sessions(self, school_id: uuid.UUID) -> list[AcademicSession]:
        await self._get_school(school_id)
        result = await self.db.execute(
            select(AcademicSession)
            .where(AcademicSession.school_id == school_id)
            .order_by(AcademicSession.start_date.desc().nullslast())
        )
        return list(result.scalars().all())

    async def update_session(
        self, session_id: uuid.UUID, data: schemas.AcademicSessionUpdate
    ) -> AcademicSession:
        session = await self.db.get(AcademicSession, session_id)
        if session is None:
            raise not_found("Academic session not found")
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(session, field, value)
        await self.db.flush()
        await self.db.refresh(session)
        return session

    async def activate_session(self, session_id: uuid.UUID) -> AcademicSession:
        session = await self.db.get(AcademicSession, session_id)
        if session is None:
            raise not_found("Academic session not found")
        session.is_active = True
        await self.db.flush()
        await self._deactivate_other_sessions(session.school_id, keep=session.id)
        await self.db.refresh(session)
        return session

    async def _deactivate_other_sessions(
        self, school_id: uuid.UUID, keep: uuid.UUID
    ) -> None:
        result = await self.db.execute(
            select(AcademicSession).where(
                AcademicSession.school_id == school_id,
                AcademicSession.id != keep,
                AcademicSession.is_active.is_(True),
            )
        )
        for other in result.scalars().all():
            other.is_active = False
        await self.db.flush()
