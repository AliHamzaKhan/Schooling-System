"""Communication Center endpoints, gated by the MESSAGING module.

Broadcasts, templates, and notification configs require create/view. Device
token registration is a self-action available to any school user with MESSAGING
view (students/guardians register their own device).
"""
import uuid

from fastapi import APIRouter, Depends, Header, Query, status

from app.core.deps import CurrentUser, DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.core.pagination import OffsetPage
from app.modules.communication import schemas
from app.modules.communication.service import CommunicationService

router = APIRouter(prefix="/schools/{school_id}/communication", tags=["Communication"])

_view = Depends(require_school_permission(Module.MESSAGING, PA.VIEW))
_create = Depends(require_school_permission(Module.MESSAGING, PA.CREATE))


# ------------------------------ templates ------------------------------- #


@router.post("/templates", response_model=schemas.TemplateOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_template(school_id: uuid.UUID, data: schemas.TemplateCreate, db: DbDep) -> schemas.TemplateOut:
    return await CommunicationService(db).create_template(school_id, data)


@router.get("/templates", response_model=list[schemas.TemplateOut], dependencies=[_view])
async def list_templates(school_id: uuid.UUID, db: DbDep) -> list[schemas.TemplateOut]:
    return await CommunicationService(db).list_templates(school_id)


# --------------------------- notification config --------------------------- #


@router.put("/configs", response_model=schemas.NotificationConfigOut, dependencies=[_create])
async def set_config(school_id: uuid.UUID, data: schemas.NotificationConfigSet, db: DbDep) -> schemas.NotificationConfigOut:
    return await CommunicationService(db).set_config(school_id, data)


@router.get("/configs", response_model=list[schemas.NotificationConfigOut], dependencies=[_view])
async def list_configs(school_id: uuid.UUID, db: DbDep) -> list[schemas.NotificationConfigOut]:
    return await CommunicationService(db).list_configs(school_id)


# ----------------------------- device tokens ---------------------------- #


@router.post("/device-tokens", response_model=schemas.DeviceTokenOut, status_code=status.HTTP_201_CREATED, dependencies=[_view])
async def register_device_token(
    school_id: uuid.UUID, data: schemas.DeviceTokenRegister, db: DbDep, current_user: CurrentUser
) -> schemas.DeviceTokenOut:
    return await CommunicationService(db).register_token(school_id, current_user.id, data)


# ------------------------------ broadcasts ------------------------------ #


@router.post("/broadcasts", response_model=schemas.MessageOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_broadcast(
    school_id: uuid.UUID, data: schemas.BroadcastCreate, db: DbDep, current_user: CurrentUser,
    idempotency_key: uuid.UUID | None = Header(default=None, alias="Idempotency-Key"),
) -> schemas.MessageOut:
    return await CommunicationService(db).create_broadcast(school_id, data, current_user.id, idempotency_key=idempotency_key)


@router.get("/broadcasts", response_model=list[schemas.MessageOut], dependencies=[_view])
async def list_broadcasts(
    school_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
    page: OffsetPage = Depends(),
) -> list[schemas.MessageOut]:
    """A bounded, visibility-filtered broadcast history page, newest first."""
    return await CommunicationService(db).list_messages(school_id, current_user, page)


@router.get("/broadcasts/{message_id}", response_model=schemas.MessageOut, dependencies=[_view])
async def get_broadcast(school_id: uuid.UUID, message_id: uuid.UUID, db: DbDep, current_user: CurrentUser) -> schemas.MessageOut:
    return await CommunicationService(db).get_visible_message(school_id, message_id, current_user)


@router.get("/broadcasts/{message_id}/deliveries", response_model=list[schemas.DeliveryOut], dependencies=[_view])
async def list_deliveries(school_id: uuid.UUID, message_id: uuid.UUID, db: DbDep, current_user: CurrentUser) -> list[schemas.DeliveryOut]:
    await CommunicationService(db).require_review_access(school_id, message_id, current_user)
    return await CommunicationService(db).list_deliveries(school_id, message_id)


@router.get("/broadcasts/{message_id}/summary", response_model=schemas.DeliverySummary, dependencies=[_view])
async def delivery_summary(school_id: uuid.UUID, message_id: uuid.UUID, db: DbDep, current_user: CurrentUser) -> schemas.DeliverySummary:
    await CommunicationService(db).require_review_access(school_id, message_id, current_user)
    return await CommunicationService(db).delivery_summary(school_id, message_id)


@router.get("/broadcasts/{message_id}/review", response_model=schemas.BroadcastReview, dependencies=[_view])
async def review_broadcast(
    school_id: uuid.UUID, message_id: uuid.UUID, db: DbDep, current_user: CurrentUser,
    limit: int = Query(default=25, ge=1, le=100), offset: int = Query(default=0, ge=0),
) -> schemas.BroadcastReview:
    await CommunicationService(db).require_review_access(school_id, message_id, current_user)
    return await CommunicationService(db).review_broadcast(school_id, message_id, limit, offset)


@router.post("/process-due", response_model=list[schemas.MessageOut], dependencies=[_create])
async def process_due(school_id: uuid.UUID, db: DbDep, current_user: CurrentUser) -> list[schemas.MessageOut]:
    """List due scheduled outbox messages; an independent worker sends them."""
    return await CommunicationService(db).process_due(school_id, current_user)
