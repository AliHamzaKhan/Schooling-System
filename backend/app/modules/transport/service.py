"""Transport Service: vehicles, routes, stops, student assignments."""
import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import SystemRole
from app.core.exceptions import bad_request, not_found
from app.models.role import Role
from app.models.transport import Route, RouteStop, TransportAssignment, Vehicle
from app.models.user import User
from app.modules.transport import schemas


class TransportService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _get_scoped(self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    # ----------------------------- vehicles ------------------------------ #

    async def create_vehicle(self, school_id: uuid.UUID, data: schemas.VehicleCreate) -> Vehicle:
        dupe = await self.db.scalar(
            select(Vehicle).where(
                Vehicle.school_id == school_id, Vehicle.registration_no == data.registration_no
            )
        )
        if dupe is not None:
            raise bad_request(f"Vehicle '{data.registration_no}' already exists")
        vehicle = Vehicle(school_id=school_id, **data.model_dump())
        self.db.add(vehicle)
        await self.db.flush()
        return vehicle

    async def list_vehicles(self, school_id: uuid.UUID) -> list[Vehicle]:
        result = await self.db.execute(select(Vehicle).where(Vehicle.school_id == school_id))
        return list(result.scalars().all())

    async def update_vehicle(self, school_id: uuid.UUID, vehicle_id: uuid.UUID, data: schemas.VehicleUpdate) -> Vehicle:
        vehicle = await self._get_scoped(Vehicle, school_id, vehicle_id, "Vehicle")
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(vehicle, field, value)
        await self.db.flush()
        return vehicle

    # ------------------------------ routes ------------------------------- #

    async def create_route(self, school_id: uuid.UUID, data: schemas.RouteCreate) -> Route:
        if data.vehicle_id is not None:
            await self._get_scoped(Vehicle, school_id, data.vehicle_id, "Vehicle")
        route = Route(school_id=school_id, **data.model_dump())
        self.db.add(route)
        await self.db.flush()
        return route

    async def list_routes(self, school_id: uuid.UUID) -> list[Route]:
        result = await self.db.execute(select(Route).where(Route.school_id == school_id).order_by(Route.name))
        return list(result.scalars().all())

    async def update_route(self, school_id: uuid.UUID, route_id: uuid.UUID, data: schemas.RouteUpdate) -> Route:
        route = await self._get_scoped(Route, school_id, route_id, "Route")
        payload = data.model_dump(exclude_unset=True)
        if payload.get("vehicle_id") is not None:
            await self._get_scoped(Vehicle, school_id, payload["vehicle_id"], "Vehicle")
        for field, value in payload.items():
            setattr(route, field, value)
        await self.db.flush()
        return route

    async def delete_route(self, school_id: uuid.UUID, route_id: uuid.UUID) -> None:
        route = await self._get_scoped(Route, school_id, route_id, "Route")
        await self.db.delete(route)
        await self.db.flush()

    # ------------------------------- stops ------------------------------- #

    async def add_stop(self, school_id: uuid.UUID, route_id: uuid.UUID, data: schemas.StopCreate) -> RouteStop:
        await self._get_scoped(Route, school_id, route_id, "Route")
        stop = RouteStop(school_id=school_id, route_id=route_id, **data.model_dump())
        self.db.add(stop)
        await self.db.flush()
        return stop

    async def list_stops(self, school_id: uuid.UUID, route_id: uuid.UUID) -> list[RouteStop]:
        await self._get_scoped(Route, school_id, route_id, "Route")
        result = await self.db.execute(
            select(RouteStop).where(RouteStop.route_id == route_id).order_by(RouteStop.sequence)
        )
        return list(result.scalars().all())

    async def delete_stop(self, school_id: uuid.UUID, stop_id: uuid.UUID) -> None:
        stop = await self._get_scoped(RouteStop, school_id, stop_id, "Stop")
        await self.db.delete(stop)
        await self.db.flush()

    # ---------------------------- assignments ---------------------------- #

    async def assign_student(self, school_id: uuid.UUID, data: schemas.AssignmentCreate) -> TransportAssignment:
        route = await self._get_scoped(Route, school_id, data.route_id, "Route")
        if data.stop_id is not None:
            stop = await self._get_scoped(RouteStop, school_id, data.stop_id, "Stop")
            if stop.route_id != route.id:
                raise bad_request("Stop does not belong to the selected route")

        student = await self.db.scalar(
            select(User).where(User.id == data.student_id, User.school_id == school_id)
            .join(User.roles).where(Role.code == SystemRole.STUDENT.value)
        )
        if student is None:
            raise bad_request("User is not a student in this school")

        existing = await self.db.scalar(
            select(TransportAssignment).where(TransportAssignment.student_id == data.student_id)
        )
        if existing is not None:
            raise bad_request("Student already has a transport assignment")

        # Capacity check against the route's vehicle.
        if route.vehicle_id is not None:
            vehicle = await self.db.get(Vehicle, route.vehicle_id)
            if vehicle is not None and vehicle.capacity > 0:
                assigned = await self.db.scalar(
                    select(func.count())
                    .select_from(TransportAssignment)
                    .join(Route, Route.id == TransportAssignment.route_id)
                    .where(Route.vehicle_id == vehicle.id, TransportAssignment.status == "active")
                ) or 0
                if assigned >= vehicle.capacity:
                    raise bad_request("Vehicle capacity reached for this route")

        assignment = TransportAssignment(
            school_id=school_id, student_id=data.student_id, route_id=data.route_id,
            stop_id=data.stop_id, status="active",
        )
        self.db.add(assignment)
        await self.db.flush()
        return assignment

    async def list_assignments(self, school_id: uuid.UUID, route_id: uuid.UUID | None = None) -> list[TransportAssignment]:
        stmt = select(TransportAssignment).where(TransportAssignment.school_id == school_id)
        if route_id is not None:
            stmt = stmt.where(TransportAssignment.route_id == route_id)
        return list((await self.db.execute(stmt)).scalars().all())

    async def unassign(self, school_id: uuid.UUID, assignment_id: uuid.UUID) -> None:
        assignment = await self._get_scoped(TransportAssignment, school_id, assignment_id, "Assignment")
        await self.db.delete(assignment)
        await self.db.flush()
