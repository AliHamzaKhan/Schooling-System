"""Communication Center endpoints, gated by the MESSAGING module.

Broadcasts, templates, and notification configs require create/view. Device
token registration is a self-action available to any school user with MESSAGING
view (students/guardians register their own device).
"""
import uuid

from fastapi import APIRouter, Depends, status

from app.core.deps import CurrentUser, DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
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
    school_id: uuid.UUID, data: schemas.BroadcastCreate, db: DbDep, current_user: CurrentUser
) -> schemas.MessageOut:
    return await CommunicationService(db).create_broadcast(school_id, data, current_user.id)


@router.get("/broadcasts", response_model=list[schemas.MessageOut], dependencies=[_view])
async def list_broadcasts(school_id: uuid.UUID, db: DbDep) -> list[schemas.MessageOut]:
    return await CommunicationService(db).list_messages(school_id)


@router.get("/broadcasts/{message_id}", response_model=schemas.MessageOut, dependencies=[_view])
async def get_broadcast(school_id: uuid.UUID, message_id: uuid.UUID, db: DbDep) -> schemas.MessageOut:
    return await CommunicationService(db).get_message(school_id, message_id)


@router.get("/broadcasts/{message_id}/deliveries", response_model=list[schemas.DeliveryOut], dependencies=[_view])
async def list_deliveries(school_id: uuid.UUID, message_id: uuid.UUID, db: DbDep) -> list[schemas.DeliveryOut]:
    return await CommunicationService(db).list_deliveries(school_id, message_id)


@router.get("/broadcasts/{message_id}/summary", response_model=schemas.DeliverySummary, dependencies=[_view])
async def delivery_summary(school_id: uuid.UUID, message_id: uuid.UUID, db: DbDep) -> schemas.DeliverySummary:
    return await CommunicationService(db).delivery_summary(school_id, message_id)


@router.post("/process-due", response_model=list[schemas.MessageOut], dependencies=[_create])
async def process_due(school_id: uuid.UUID, db: DbDep) -> list[schemas.MessageOut]:
    """Dispatch scheduled messages whose time has arrived (call from a scheduler)."""
    return await CommunicationService(db).process_due(school_id)
