"""School Service endpoints. Most routes require Super Admin
(docs/permissions/01); the `/{id}/profile` routes are Headmaster self-service."""
import uuid

from fastapi import APIRouter, Depends, status

from app.core.deps import DbDep, SuperAdmin, require_school_admin, require_school_admin_or_finance
from app.modules.schools import schemas
from app.modules.schools.service import SchoolService

# SuperAdmin dependency is applied router-wide so every endpoint is gated.
router = APIRouter(prefix="/schools", tags=["Schools"])


@router.post("", response_model=schemas.SchoolOut, status_code=status.HTTP_201_CREATED)
async def create_school(
    data: schemas.SchoolCreate, db: DbDep, _: SuperAdmin
) -> schemas.SchoolOut:
    return await SchoolService(db).create_school(data)


@router.get("", response_model=list[schemas.SchoolOut])
async def list_schools(
    db: DbDep,
    _: SuperAdmin,
    limit: int = 50,
    offset: int = 0,
    search: str | None = None,
) -> list[schemas.SchoolOut]:
    return await SchoolService(db).list_schools(
        limit=limit, offset=offset, search=search
    )


@router.get("/{school_id}", response_model=schemas.SchoolOut)
async def get_school(school_id: uuid.UUID, db: DbDep, _: SuperAdmin) -> schemas.SchoolOut:
    return await SchoolService(db).get_school(school_id)


@router.patch("/{school_id}", response_model=schemas.SchoolOut)
async def update_school(
    school_id: uuid.UUID, data: schemas.SchoolUpdate, db: DbDep, _: SuperAdmin
) -> schemas.SchoolOut:
    return await SchoolService(db).update_school(school_id, data)


# ── Headmaster self-service: read + edit own school profile / branding ──


@router.get(
    "/{school_id}/profile",
    response_model=schemas.SchoolOut,
    dependencies=[Depends(require_school_admin_or_finance)],
)
async def get_school_profile(school_id: uuid.UUID, db: DbDep) -> schemas.SchoolOut:
    """The school's own Headmaster or Accountant (or Super Admin) reads it;
    only the Headmaster changes it."""
    return await SchoolService(db).get_school(school_id)


@router.patch(
    "/{school_id}/profile",
    response_model=schemas.SchoolOut,
    dependencies=[Depends(require_school_admin)],
)
async def update_school_profile(
    school_id: uuid.UUID, data: schemas.SchoolUpdate, db: DbDep
) -> schemas.SchoolOut:
    """Headmaster updates their school name, contact details and branding
    settings (logo, uniform colour, monthly fee due day live in `settings`)."""
    return await SchoolService(db).update_school_profile(school_id, data)


@router.get("/{school_id}/stats", response_model=schemas.SchoolStatsOut)
async def get_school_stats(
    school_id: uuid.UUID, db: DbDep, _: SuperAdmin
) -> schemas.SchoolStatsOut:
    return await SchoolService(db).get_school_stats(school_id)


@router.post("/{school_id}/status", response_model=schemas.SchoolOut)
async def set_status(
    school_id: uuid.UUID, data: schemas.StatusUpdate, db: DbDep, _: SuperAdmin
) -> schemas.SchoolOut:
    return await SchoolService(db).set_status(school_id, data.status)


@router.post("/{school_id}/subscription", response_model=schemas.SchoolOut)
async def assign_subscription(
    school_id: uuid.UUID, data: schemas.SubscriptionAssign, db: DbDep, _: SuperAdmin
) -> schemas.SchoolOut:
    return await SchoolService(db).assign_subscription(school_id, data.plan_code)


@router.put("/{school_id}/modules", response_model=schemas.SchoolModulesView)
async def set_module_toggles(
    school_id: uuid.UUID, data: schemas.ModuleTogglesUpdate, db: DbDep, _: SuperAdmin
) -> schemas.SchoolModulesView:
    service = SchoolService(db)
    await service.set_module_toggles(school_id, data.toggles)
    return await service.get_modules_view(school_id)


@router.get("/{school_id}/modules", response_model=schemas.SchoolModulesView)
async def get_modules(
    school_id: uuid.UUID, db: DbDep, _: SuperAdmin
) -> schemas.SchoolModulesView:
    return await SchoolService(db).get_modules_view(school_id)


# ------------------------------ sessions -------------------------------- #


@router.post(
    "/{school_id}/sessions",
    response_model=schemas.AcademicSessionOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_session(
    school_id: uuid.UUID, data: schemas.AcademicSessionCreate, db: DbDep, _: SuperAdmin
) -> schemas.AcademicSessionOut:
    return await SchoolService(db).create_session(school_id, data)


@router.get("/{school_id}/sessions", response_model=list[schemas.AcademicSessionOut])
async def list_sessions(
    school_id: uuid.UUID, db: DbDep, _: SuperAdmin
) -> list[schemas.AcademicSessionOut]:
    return await SchoolService(db).list_sessions(school_id)


@router.patch("/sessions/{session_id}", response_model=schemas.AcademicSessionOut)
async def update_session(
    session_id: uuid.UUID, data: schemas.AcademicSessionUpdate, db: DbDep, _: SuperAdmin
) -> schemas.AcademicSessionOut:
    return await SchoolService(db).update_session(session_id, data)


@router.post("/sessions/{session_id}/activate", response_model=schemas.AcademicSessionOut)
async def activate_session(
    session_id: uuid.UUID, db: DbDep, _: SuperAdmin
) -> schemas.AcademicSessionOut:
    return await SchoolService(db).activate_session(session_id)
