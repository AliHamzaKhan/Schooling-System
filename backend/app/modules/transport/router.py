"""Transport endpoints, gated by the TRANSPORT module."""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import CurrentUser, DbDep, require_school_member, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.core.pagination import OffsetPage
from app.modules.transport import schemas
from app.modules.transport.service import TransportService

router = APIRouter(prefix="/schools/{school_id}/transport", tags=["Transport"])

_member = Depends(require_school_member)
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
    school_id: uuid.UUID,
    db: DbDep,
    route_id: uuid.UUID | None = Query(default=None),
    page: OffsetPage = Depends(),
) -> list[schemas.AssignmentOut]:
    return await TransportService(db).list_assignments(school_id, route_id, page)


@router.delete("/assignments/{assignment_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def unassign(school_id: uuid.UUID, assignment_id: uuid.UUID, db: DbDep) -> None:
    await TransportService(db).unassign(school_id, assignment_id)


# -------------------------------- drivers ------------------------------- #


@router.post("/drivers", response_model=schemas.DriverOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_driver(
    school_id: uuid.UUID, data: schemas.DriverCreate, db: DbDep, current_user: CurrentUser
) -> schemas.DriverOut:
    return await TransportService(db).create_driver(current_user, school_id, data)


@router.get("/drivers", response_model=list[schemas.DriverOut], dependencies=[_view])
async def list_drivers(school_id: uuid.UUID, db: DbDep) -> list[schemas.DriverOut]:
    return await TransportService(db).list_drivers(school_id)


@router.get("/drivers/online", response_model=list[schemas.DriverLocationOut], dependencies=[_view])
async def online_drivers(school_id: uuid.UUID, db: DbDep) -> list[schemas.DriverLocationOut]:
    return await TransportService(db).online_drivers(school_id)


@router.patch("/drivers/{driver_id}", response_model=schemas.DriverOut, dependencies=[_edit])
async def update_driver(
    school_id: uuid.UUID, driver_id: uuid.UUID, data: schemas.DriverUpdate, db: DbDep
) -> schemas.DriverOut:
    return await TransportService(db).update_driver(school_id, driver_id, data)


# ------------------------- transport requests --------------------------- #


@router.post("/requests", response_model=schemas.TransportRequestOut, status_code=status.HTTP_201_CREATED, dependencies=[_member])
async def create_request(
    school_id: uuid.UUID, data: schemas.TransportRequestCreate, db: DbDep, current_user: CurrentUser
) -> schemas.TransportRequestOut:
    return await TransportService(db).create_request(school_id, current_user, data)


@router.get("/requests/mine", response_model=list[schemas.TransportRequestOut], dependencies=[_member])
async def my_requests(school_id: uuid.UUID, db: DbDep, current_user: CurrentUser) -> list[schemas.TransportRequestOut]:
    return await TransportService(db).list_own_requests(school_id, current_user.id)


@router.get("/requests", response_model=list[schemas.TransportRequestOut], dependencies=[_view])
async def list_requests(
    school_id: uuid.UUID, db: DbDep, request_status: str | None = Query(default=None, alias="status")
) -> list[schemas.TransportRequestOut]:
    return await TransportService(db).list_requests(school_id, request_status)


@router.post("/requests/{request_id}/approve", response_model=schemas.TransportRequestOut, dependencies=[_member])
async def approve_request(
    school_id: uuid.UUID, request_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.TransportRequestOut:
    return await TransportService(db).review_request(school_id, current_user, request_id, True)


@router.post("/requests/{request_id}/reject", response_model=schemas.TransportRequestOut, dependencies=[_member])
async def reject_request(
    school_id: uuid.UUID, request_id: uuid.UUID, data: schemas.TransportRequestReject,
    db: DbDep, current_user: CurrentUser,
) -> schemas.TransportRequestOut:
    return await TransportService(db).review_request(school_id, current_user, request_id, False, data.reason)


# --------------------------------- trips -------------------------------- #


@router.get("/me/assignments", response_model=list[schemas.AssignmentOut], dependencies=[_member])
async def my_assignments(school_id: uuid.UUID, db: DbDep, current_user: CurrentUser) -> list[schemas.AssignmentOut]:
    return await TransportService(db).my_assignments(school_id, current_user.id)


@router.post("/trips/start", response_model=schemas.TripOut, status_code=status.HTTP_201_CREATED, dependencies=[_member])
async def start_trip(
    school_id: uuid.UUID, data: schemas.TripStart, db: DbDep, current_user: CurrentUser
) -> schemas.TripOut:
    return await TransportService(db).start_trip(school_id, current_user, data)


@router.get("/trips", response_model=list[schemas.TripOut], dependencies=[_view])
async def list_trips(
    school_id: uuid.UUID, db: DbDep,
    route_id: uuid.UUID | None = Query(default=None),
    driver_id: uuid.UUID | None = Query(default=None),
    trip_status: str | None = Query(default=None, alias="status"),
) -> list[schemas.TripOut]:
    return await TransportService(db).list_trips(school_id, route_id, driver_id, trip_status)


@router.get("/trips/active", response_model=list[schemas.ActiveTripOut], dependencies=[_member])
async def active_trips(
    school_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
    page: OffsetPage = Depends(),
) -> list[schemas.ActiveTripOut]:
    """The actor's bounded, visibility-scoped active-trip page."""
    return await TransportService(db).active_trips_for(school_id, current_user, page)


@router.get("/trips/{trip_id}", response_model=schemas.TripOut, dependencies=[_member])
async def get_trip(
    school_id: uuid.UUID, trip_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.TripOut:
    # Access control (driver owns it, or headmaster/super admin) lives in the service.
    svc = TransportService(db)
    await svc._get_trip_for_driver(school_id, current_user, trip_id)
    return await svc.get_trip(school_id, trip_id)


@router.post("/trips/{trip_id}/location", response_model=schemas.LocationOut, status_code=status.HTTP_201_CREATED, dependencies=[_member])
async def post_location(
    school_id: uuid.UUID, trip_id: uuid.UUID, data: schemas.LocationPing,
    db: DbDep, current_user: CurrentUser,
) -> schemas.LocationOut:
    return await TransportService(db).record_location(school_id, current_user, trip_id, data)


@router.get("/trips/{trip_id}/location", response_model=schemas.LocationOut, dependencies=[_member])
async def get_location(
    school_id: uuid.UUID, trip_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.LocationOut:
    return await TransportService(db).latest_location(school_id, current_user, trip_id)


@router.get("/trips/{trip_id}/eta", response_model=schemas.EtaOut, dependencies=[_member])
async def get_eta(
    school_id: uuid.UUID, trip_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.EtaOut:
    return await TransportService(db).eta_for(school_id, current_user, trip_id)


@router.post("/trips/{trip_id}/end", response_model=schemas.TripOut, dependencies=[_member])
async def end_trip(
    school_id: uuid.UUID, trip_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.TripOut:
    return await TransportService(db).end_trip(school_id, current_user, trip_id)


@router.post("/trips/{trip_id}/students/{student_id}/status", response_model=schemas.TripOut, dependencies=[_member])
async def set_student_status(
    school_id: uuid.UUID, trip_id: uuid.UUID, student_id: uuid.UUID,
    data: schemas.TripStudentStatusUpdate, db: DbDep, current_user: CurrentUser,
) -> schemas.TripOut:
    return await TransportService(db).set_student_status(school_id, current_user, trip_id, student_id, data)


@router.put("/trips/{trip_id}/stop-order", response_model=schemas.TripOut, dependencies=[_member])
async def update_stop_order(
    school_id: uuid.UUID, trip_id: uuid.UUID, data: schemas.StopOrderUpdate,
    db: DbDep, current_user: CurrentUser,
) -> schemas.TripOut:
    return await TransportService(db).update_stop_order(school_id, current_user, trip_id, data)
