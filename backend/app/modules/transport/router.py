"""Transport endpoints, gated by the TRANSPORT module."""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.transport import schemas
from app.modules.transport.service import TransportService

router = APIRouter(prefix="/schools/{school_id}/transport", tags=["Transport"])

_view = Depends(require_school_permission(Module.TRANSPORT, PA.VIEW))
_create = Depends(require_school_permission(Module.TRANSPORT, PA.CREATE))
_edit = Depends(require_school_permission(Module.TRANSPORT, PA.EDIT))
_delete = Depends(require_school_permission(Module.TRANSPORT, PA.DELETE))


# ------------------------------- vehicles ------------------------------- #


@router.post("/vehicles", response_model=schemas.VehicleOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_vehicle(school_id: uuid.UUID, data: schemas.VehicleCreate, db: DbDep) -> schemas.VehicleOut:
    return await TransportService(db).create_vehicle(school_id, data)


@router.get("/vehicles", response_model=list[schemas.VehicleOut], dependencies=[_view])
async def list_vehicles(school_id: uuid.UUID, db: DbDep) -> list[schemas.VehicleOut]:
    return await TransportService(db).list_vehicles(school_id)


@router.patch("/vehicles/{vehicle_id}", response_model=schemas.VehicleOut, dependencies=[_edit])
async def update_vehicle(school_id: uuid.UUID, vehicle_id: uuid.UUID, data: schemas.VehicleUpdate, db: DbDep) -> schemas.VehicleOut:
    return await TransportService(db).update_vehicle(school_id, vehicle_id, data)


# -------------------------------- routes -------------------------------- #


@router.post("/routes", response_model=schemas.RouteOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_route(school_id: uuid.UUID, data: schemas.RouteCreate, db: DbDep) -> schemas.RouteOut:
    return await TransportService(db).create_route(school_id, data)


@router.get("/routes", response_model=list[schemas.RouteOut], dependencies=[_view])
async def list_routes(school_id: uuid.UUID, db: DbDep) -> list[schemas.RouteOut]:
    return await TransportService(db).list_routes(school_id)


@router.patch("/routes/{route_id}", response_model=schemas.RouteOut, dependencies=[_edit])
async def update_route(school_id: uuid.UUID, route_id: uuid.UUID, data: schemas.RouteUpdate, db: DbDep) -> schemas.RouteOut:
    return await TransportService(db).update_route(school_id, route_id, data)


@router.delete("/routes/{route_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_route(school_id: uuid.UUID, route_id: uuid.UUID, db: DbDep) -> None:
    await TransportService(db).delete_route(school_id, route_id)


# --------------------------------- stops -------------------------------- #


@router.post("/routes/{route_id}/stops", response_model=schemas.StopOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def add_stop(school_id: uuid.UUID, route_id: uuid.UUID, data: schemas.StopCreate, db: DbDep) -> schemas.StopOut:
    return await TransportService(db).add_stop(school_id, route_id, data)


@router.get("/routes/{route_id}/stops", response_model=list[schemas.StopOut], dependencies=[_view])
async def list_stops(school_id: uuid.UUID, route_id: uuid.UUID, db: DbDep) -> list[schemas.StopOut]:
    return await TransportService(db).list_stops(school_id, route_id)


@router.delete("/stops/{stop_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_stop(school_id: uuid.UUID, stop_id: uuid.UUID, db: DbDep) -> None:
    await TransportService(db).delete_stop(school_id, stop_id)


# ----------------------------- assignments ------------------------------ #


@router.post("/assignments", response_model=schemas.AssignmentOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def assign_student(school_id: uuid.UUID, data: schemas.AssignmentCreate, db: DbDep) -> schemas.AssignmentOut:
    return await TransportService(db).assign_student(school_id, data)


@router.get("/assignments", response_model=list[schemas.AssignmentOut], dependencies=[_view])
async def list_assignments(
    school_id: uuid.UUID, db: DbDep, route_id: uuid.UUID | None = Query(default=None)
) -> list[schemas.AssignmentOut]:
    return await TransportService(db).list_assignments(school_id, route_id)


@router.delete("/assignments/{assignment_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def unassign(school_id: uuid.UUID, assignment_id: uuid.UUID, db: DbDep) -> None:
    await TransportService(db).unassign(school_id, assignment_id)
