"""Transport Service: vehicles, routes, stops, drivers, requests, assignments,
and trip lifecycle."""
import uuid
from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import (
    Module,
    NotificationEvent,
    PermissionAction,
    SystemRole,
    TransportRequestStatus,
    TripStatus,
    TripStudentStatus,
)
from app.core.exceptions import bad_request, forbidden, not_found
from app.models.associations import guardian_students
from app.models.role import Role
from app.models.transport import (
    Driver,
    Route,
    RouteStop,
    TransportAssignment,
    TransportRequest,
    TransportTrip,
    TripStudentEvent,
    Vehicle,
    VehicleLocation,
)
from app.models.user import User
from app.modules.permissions.service import PermissionService
from app.modules.transport import schemas


def _now() -> datetime:
    return datetime.now(timezone.utc)


# Straight-line distance in metres between two lat/lng points (no maps API).
def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    import math

    r = 6_371_000.0  # Earth radius, metres
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlambda / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


# Proximity radius (metres) for the "bus approaching" alert.
PROXIMITY_M = 500.0
# Nominal speed (km/h) used for a rough ETA when the ping has no speed.
_NOMINAL_KMH = 30.0


def optimize_order(
    ordered_ids: list[uuid.UUID],
    coords: dict[uuid.UUID, tuple[float, float]],
) -> list[uuid.UUID]:
    """Nearest-neighbour ordering of students by pickup coordinate.

    Students with coordinates are sequenced greedily from the first one; those
    without coordinates keep their original relative order and follow at the end.
    """
    with_coords = [sid for sid in ordered_ids if sid in coords]
    without = [sid for sid in ordered_ids if sid not in coords]
    if len(with_coords) <= 2:
        return with_coords + without

    remaining = with_coords[1:]
    route = [with_coords[0]]
    while remaining:
        lat, lon = coords[route[-1]]
        nxt = min(remaining, key=lambda s: haversine_m(lat, lon, coords[s][0], coords[s][1]))
        route.append(nxt)
        remaining.remove(nxt)
    return route + without


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

        # Resolve the student + pickup location: from an approved request, or
        # directly from the payload.
        student_id = data.student_id
        latitude, longitude, address = data.latitude, data.longitude, data.address
        if data.request_id is not None:
            req = await self._get_scoped(TransportRequest, school_id, data.request_id, "Request")
            if req.status != TransportRequestStatus.APPROVED.value:
                raise bad_request("Transport request must be approved before assignment")
            student_id = req.student_id
            latitude = latitude if latitude is not None else req.latitude
            longitude = longitude if longitude is not None else req.longitude
            address = address if address is not None else req.pickup_address
        if student_id is None:
            raise bad_request("student_id or an approved request_id is required")

        student = await self.db.scalar(
            select(User).where(User.id == student_id, User.school_id == school_id)
            .join(User.roles).where(Role.code == SystemRole.STUDENT.value)
        )
        if student is None:
            raise bad_request("User is not a student in this school")

        if data.driver_id is not None:
            await self._get_driver_by_user(school_id, data.driver_id)

        existing = await self.db.scalar(
            select(TransportAssignment).where(TransportAssignment.student_id == student_id)
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
            school_id=school_id, student_id=student_id, route_id=data.route_id,
            stop_id=data.stop_id, driver_id=data.driver_id,
            latitude=latitude, longitude=longitude, address=address, status="active",
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

    # ------------------------------ helpers ------------------------------ #

    @staticmethod
    def _has_role(user: User, code: str) -> bool:
        return any(r.code == code for r in user.roles)

    async def _require_transport_enabled(self, user: User) -> None:
        modules = await PermissionService(self.db).get_effective_modules(user)
        if Module.TRANSPORT.value not in modules:
            raise forbidden("Transport is not enabled for this school")

    async def _guardian_children(self, guardian_id: uuid.UUID, school_id: uuid.UUID) -> set[uuid.UUID]:
        rows = await self.db.execute(
            select(guardian_students.c.student_id).where(
                guardian_students.c.guardian_id == guardian_id,
                guardian_students.c.school_id == school_id,
            )
        )
        return {r[0] for r in rows.all()}

    async def _get_driver_by_user(self, school_id: uuid.UUID, user_id: uuid.UUID) -> Driver:
        driver = await self.db.scalar(
            select(Driver).where(Driver.school_id == school_id, Driver.user_id == user_id)
        )
        if driver is None:
            raise bad_request("User is not a driver in this school")
        return driver

    @staticmethod
    def _driver_out(driver: Driver, user: User | None) -> dict:
        return {
            "id": driver.id,
            "school_id": driver.school_id,
            "user_id": driver.user_id,
            "full_name": user.full_name if user else None,
            "email": user.email if user else None,
            "license_no": driver.license_no,
            "phone": driver.phone,
            "assigned_vehicle_id": driver.assigned_vehicle_id,
            "status": driver.status,
        }

    # ------------------------------ drivers ------------------------------ #

    async def create_driver(
        self, actor: User, school_id: uuid.UUID, data: schemas.DriverCreate
    ) -> dict:
        # Reuse UserService for the login (role provisioning, hashing, auth).
        from app.modules.users.service import UserService

        if data.assigned_vehicle_id is not None:
            await self._get_scoped(Vehicle, school_id, data.assigned_vehicle_id, "Vehicle")

        user = await UserService(self.db).create_user(
            actor=actor,
            school_id=school_id,
            email=data.email,
            password=data.password,
            full_name=data.full_name,
            phone=data.phone,
            role_codes=[SystemRole.DRIVER.value],
        )
        driver = Driver(
            school_id=school_id, user_id=user.id, license_no=data.license_no,
            phone=data.phone, assigned_vehicle_id=data.assigned_vehicle_id, status="active",
        )
        self.db.add(driver)
        await self.db.flush()
        return self._driver_out(driver, user)

    async def list_drivers(self, school_id: uuid.UUID) -> list[dict]:
        rows = await self.db.execute(
            select(Driver, User).join(User, User.id == Driver.user_id)
            .where(Driver.school_id == school_id).order_by(User.full_name)
        )
        return [self._driver_out(d, u) for d, u in rows.all()]

    async def update_driver(
        self, school_id: uuid.UUID, driver_id: uuid.UUID, data: schemas.DriverUpdate
    ) -> dict:
        driver = await self._get_scoped(Driver, school_id, driver_id, "Driver")
        payload = data.model_dump(exclude_unset=True)
        if payload.get("assigned_vehicle_id") is not None:
            await self._get_scoped(Vehicle, school_id, payload["assigned_vehicle_id"], "Vehicle")
        for field, value in payload.items():
            setattr(driver, field, value)
        await self.db.flush()
        user = await self.db.get(User, driver.user_id)
        return self._driver_out(driver, user)

    async def online_drivers(self, school_id: uuid.UUID) -> list[dict]:
        """Drivers of this school with an in-progress trip (P1 'online')."""
        active = await self.db.execute(
            select(TransportTrip.driver_id, TransportTrip.id)
            .where(
                TransportTrip.school_id == school_id,
                TransportTrip.status == TripStatus.IN_PROGRESS.value,
            )
        )
        trip_by_driver = {driver_id: trip_id for driver_id, trip_id in active.all()}
        rows = await self.db.execute(
            select(Driver, User).join(User, User.id == Driver.user_id)
            .where(Driver.school_id == school_id).order_by(User.full_name)
        )
        out: list[dict] = []
        for driver, user in rows.all():
            trip_id = trip_by_driver.get(driver.user_id)
            out.append({
                "driver_id": driver.user_id,
                "full_name": user.full_name,
                "trip_id": trip_id,
                "online": trip_id is not None,
            })
        return out

    # ------------------------------ requests ----------------------------- #

    async def create_request(
        self, school_id: uuid.UUID, actor: User, data: schemas.TransportRequestCreate
    ) -> TransportRequest:
        await self._require_transport_enabled(actor)

        if self._has_role(actor, SystemRole.STUDENT.value):
            student_id = data.student_id or actor.id
            if student_id != actor.id:
                raise forbidden("A student can only request transport for themselves")
        elif self._has_role(actor, SystemRole.GUARDIAN.value):
            if data.student_id is None:
                raise bad_request("student_id is required")
            if data.student_id not in await self._guardian_children(actor.id, school_id):
                raise forbidden("You can only request transport for your own children")
            student_id = data.student_id
        else:
            raise forbidden("Only students or guardians can raise a transport request")

        req = TransportRequest(
            school_id=school_id, student_id=student_id, requested_by=actor.id,
            pickup_address=data.pickup_address, latitude=data.latitude,
            longitude=data.longitude, notes=data.notes,
            status=TransportRequestStatus.PENDING.value,
        )
        self.db.add(req)
        await self.db.flush()
        return req

    async def list_own_requests(self, school_id: uuid.UUID, user_id: uuid.UUID) -> list[TransportRequest]:
        rows = await self.db.execute(
            select(TransportRequest).where(
                TransportRequest.school_id == school_id,
                TransportRequest.requested_by == user_id,
            ).order_by(TransportRequest.created_at.desc())
        )
        return list(rows.scalars().all())

    async def list_requests(
        self, school_id: uuid.UUID, status: str | None = None
    ) -> list[TransportRequest]:
        stmt = select(TransportRequest).where(TransportRequest.school_id == school_id)
        if status is not None:
            stmt = stmt.where(TransportRequest.status == status)
        stmt = stmt.order_by(TransportRequest.created_at.desc())
        return list((await self.db.execute(stmt)).scalars().all())

    async def review_request(
        self, school_id: uuid.UUID, actor: User, request_id: uuid.UUID,
        approve: bool, reason: str | None = None,
    ) -> TransportRequest:
        if not await PermissionService(self.db).has_permission(
            actor, Module.TRANSPORT, PermissionAction.APPROVE
        ):
            raise forbidden("You are not allowed to review transport requests")
        req = await self._get_scoped(TransportRequest, school_id, request_id, "Request")
        if req.status != TransportRequestStatus.PENDING.value:
            raise bad_request("This request has already been reviewed")
        req.status = (
            TransportRequestStatus.APPROVED.value if approve
            else TransportRequestStatus.REJECTED.value
        )
        req.reviewed_by = actor.id
        req.reviewed_at = _now()
        req.reject_reason = None if approve else reason
        await self.db.flush()
        return req

    # ------------------------------- trips ------------------------------- #

    async def my_assignments(self, school_id: uuid.UUID, driver_user_id: uuid.UUID) -> list[TransportAssignment]:
        rows = await self.db.execute(
            select(TransportAssignment).where(
                TransportAssignment.school_id == school_id,
                TransportAssignment.driver_id == driver_user_id,
                TransportAssignment.status == "active",
            )
        )
        return list(rows.scalars().all())

    async def start_trip(
        self, school_id: uuid.UUID, actor: User, data: schemas.TripStart
    ) -> TransportTrip:
        if not self._has_role(actor, SystemRole.DRIVER.value):
            raise forbidden("Only a driver can start a trip")
        route = await self._get_scoped(Route, school_id, data.route_id, "Route")

        rows = await self.db.execute(
            select(TransportAssignment).where(
                TransportAssignment.school_id == school_id,
                TransportAssignment.route_id == route.id,
                TransportAssignment.driver_id == actor.id,
                TransportAssignment.status == "active",
            )
        )
        assignments = list(rows.scalars().all())
        if not assignments:
            raise bad_request("No students are assigned to you on this route")

        # Guard against a second concurrent active trip for this driver.
        existing = await self.db.scalar(
            select(TransportTrip).where(
                TransportTrip.driver_id == actor.id,
                TransportTrip.status == TripStatus.IN_PROGRESS.value,
            )
        )
        if existing is not None:
            raise bad_request("You already have a trip in progress")

        # Backend route optimization (haversine nearest-neighbour) from the
        # assigned students' pickup coordinates. Students without coordinates
        # keep their order and follow at the end.
        student_ids = [a.student_id for a in assignments]
        coords = {
            a.student_id: (a.latitude, a.longitude)
            for a in assignments
            if a.latitude is not None and a.longitude is not None
        }
        ordered = optimize_order(student_ids, coords)

        trip = TransportTrip(
            school_id=school_id, route_id=route.id, driver_id=actor.id,
            vehicle_id=route.vehicle_id, trip_type=data.trip_type,
            status=TripStatus.IN_PROGRESS.value, started_at=_now(),
            stop_order=[str(s) for s in ordered], optimized=bool(coords),
        )
        trip.events = [
            TripStudentEvent(
                school_id=school_id, student_id=s,
                status=TripStudentStatus.PENDING.value,
            )
            for s in ordered
        ]
        self.db.add(trip)
        await self.db.flush()

        for sid in student_ids:
            await self._notify(
                school_id, sid, actor.id,
                NotificationEvent.TRANSPORT_TRIP_STARTED.value,
                "Transport started",
                "The school transport has started its trip.",
            )
        return await self.get_trip(school_id, trip.id)

    async def _get_trip_for_driver(
        self, school_id: uuid.UUID, actor: User, trip_id: uuid.UUID
    ) -> TransportTrip:
        trip = await self._get_scoped(TransportTrip, school_id, trip_id, "Trip")
        is_admin = self._has_role(actor, SystemRole.HEADMASTER.value) or PermissionService.is_super_admin(actor)
        if trip.driver_id != actor.id and not is_admin:
            raise forbidden("This trip belongs to another driver")
        return trip

    async def end_trip(self, school_id: uuid.UUID, actor: User, trip_id: uuid.UUID) -> TransportTrip:
        trip = await self._get_trip_for_driver(school_id, actor, trip_id)
        if trip.status != TripStatus.IN_PROGRESS.value:
            raise bad_request("Trip is not in progress")
        trip.status = TripStatus.COMPLETED.value
        trip.ended_at = _now()
        await self.db.flush()
        return await self.get_trip(school_id, trip_id)

    async def set_student_status(
        self, school_id: uuid.UUID, actor: User, trip_id: uuid.UUID,
        student_id: uuid.UUID, data: schemas.TripStudentStatusUpdate,
    ) -> TransportTrip:
        trip = await self._get_trip_for_driver(school_id, actor, trip_id)
        event = await self.db.scalar(
            select(TripStudentEvent).where(
                TripStudentEvent.trip_id == trip.id,
                TripStudentEvent.student_id == student_id,
            )
        )
        if event is None:
            raise not_found("Student is not on this trip's manifest")
        event.status = data.status
        event.event_time = _now()
        event.latitude = data.latitude
        event.longitude = data.longitude
        await self.db.flush()

        if data.status == TripStudentStatus.BOARDED.value:
            await self._notify(
                school_id, student_id, actor.id,
                NotificationEvent.STUDENT_BOARDED.value,
                "Boarded", "Your child has boarded the school transport.",
            )
        elif data.status == TripStudentStatus.DROPPED.value:
            await self._notify(
                school_id, student_id, actor.id,
                NotificationEvent.STUDENT_DROPPED.value,
                "Dropped off", "Your child has been dropped off.",
            )
        return await self.get_trip(school_id, trip_id)

    async def update_stop_order(
        self, school_id: uuid.UUID, actor: User, trip_id: uuid.UUID,
        data: schemas.StopOrderUpdate,
    ) -> TransportTrip:
        trip = await self._get_trip_for_driver(school_id, actor, trip_id)
        current = {str(s) for s in (trip.stop_order or [])}
        incoming = {str(s) for s in data.stop_order}
        if current != incoming:
            raise bad_request("Reordered list must contain exactly the trip's students")
        trip.stop_order = [str(s) for s in data.stop_order]
        await self.db.flush()
        return await self.get_trip(school_id, trip_id)

    async def get_trip(self, school_id: uuid.UUID, trip_id: uuid.UUID) -> TransportTrip:
        from sqlalchemy.orm import selectinload

        trip = await self.db.scalar(
            select(TransportTrip)
            .where(TransportTrip.id == trip_id, TransportTrip.school_id == school_id)
            .options(selectinload(TransportTrip.events))
        )
        if trip is None:
            raise not_found("Trip not found in this school")
        return trip

    async def list_trips(
        self, school_id: uuid.UUID, route_id: uuid.UUID | None = None,
        driver_id: uuid.UUID | None = None, status: str | None = None,
    ) -> list[TransportTrip]:
        from sqlalchemy.orm import selectinload

        stmt = (
            select(TransportTrip)
            .where(TransportTrip.school_id == school_id)
            .options(selectinload(TransportTrip.events))
            .order_by(TransportTrip.created_at.desc())
        )
        if route_id is not None:
            stmt = stmt.where(TransportTrip.route_id == route_id)
        if driver_id is not None:
            stmt = stmt.where(TransportTrip.driver_id == driver_id)
        if status is not None:
            stmt = stmt.where(TransportTrip.status == status)
        return list((await self.db.execute(stmt)).scalars().all())

    # ------------------------ notifications (P3) ------------------------- #

    async def _notify(
        self, school_id: uuid.UUID, student_id: uuid.UUID,
        actor_id: uuid.UUID | None, event: str, title: str, body: str,
    ) -> None:
        """Best-effort guardian notification, gated by the school's config."""
        from app.modules.communication.service import CommunicationService

        try:
            await CommunicationService(self.db).notify_student_guardians(
                school_id, student_id, event=event, title=title, body=body,
                created_by=actor_id,
            )
        except Exception:  # noqa: BLE001 — notifications must never break the trip
            pass

    # ---------------------- location + tracking (P2/P3) ------------------ #

    async def record_location(
        self, school_id: uuid.UUID, actor: User, trip_id: uuid.UUID,
        data: schemas.LocationPing,
    ) -> VehicleLocation:
        trip = await self._get_scoped(TransportTrip, school_id, trip_id, "Trip")
        if trip.driver_id != actor.id:
            raise forbidden("Only the trip's driver can post its location")
        if trip.status != TripStatus.IN_PROGRESS.value:
            raise bad_request("Trip is not in progress")

        ping = VehicleLocation(
            school_id=school_id, trip_id=trip.id, latitude=data.latitude,
            longitude=data.longitude, address=data.address, speed=data.speed,
            heading=data.heading, recorded_at=_now(),
        )
        self.db.add(ping)
        await self.db.flush()
        await self._check_proximity(school_id, trip, data.latitude, data.longitude, actor.id)
        return ping

    async def _check_proximity(
        self, school_id: uuid.UUID, trip: TransportTrip,
        lat: float, lon: float, actor_id: uuid.UUID,
    ) -> None:
        """Fire a one-shot 'bus approaching' alert when within PROXIMITY_M of
        the next pending student's pickup point."""
        trip = await self.get_trip(school_id, trip.id)  # load events
        next_id = trip.next_student_id
        if next_id is None:
            return
        event = next((e for e in trip.events if e.student_id == next_id), None)
        if event is None or event.approach_notified:
            return
        assignment = await self.db.scalar(
            select(TransportAssignment).where(TransportAssignment.student_id == next_id)
        )
        if assignment is None or assignment.latitude is None or assignment.longitude is None:
            return
        if haversine_m(lat, lon, assignment.latitude, assignment.longitude) <= PROXIMITY_M:
            event.approach_notified = True
            await self.db.flush()
            await self._notify(
                school_id, next_id, actor_id,
                NotificationEvent.BUS_NEAR_PICKUP.value,
                "Bus approaching",
                "The school transport is approaching the pickup point.",
            )

    async def latest_location(
        self, school_id: uuid.UUID, actor: User, trip_id: uuid.UUID
    ) -> VehicleLocation:
        trip = await self._get_scoped(TransportTrip, school_id, trip_id, "Trip")
        await self._assert_trip_view_access(school_id, actor, trip)
        ping = await self.db.scalar(
            select(VehicleLocation)
            .where(VehicleLocation.trip_id == trip.id)
            .order_by(VehicleLocation.recorded_at.desc())
            .limit(1)
        )
        if ping is None:
            raise not_found("No location recorded for this trip yet")
        return ping

    async def _student_ids_for(self, actor: User, school_id: uuid.UUID) -> set[uuid.UUID]:
        """The students this actor may track: themselves, or their children."""
        if self._has_role(actor, SystemRole.STUDENT.value):
            return {actor.id}
        if self._has_role(actor, SystemRole.GUARDIAN.value):
            return await self._guardian_children(actor.id, school_id)
        return set()

    async def _assert_trip_view_access(
        self, school_id: uuid.UUID, actor: User, trip: TransportTrip
    ) -> None:
        if PermissionService.is_super_admin(actor):
            return
        if self._has_role(actor, SystemRole.HEADMASTER.value) or trip.driver_id == actor.id:
            return
        # A student/guardian may view only if their student is on this trip.
        allowed = await self._student_ids_for(actor, school_id)
        if not allowed:
            raise forbidden("You do not have access to this trip")
        on_trip = await self.db.scalar(
            select(TripStudentEvent.student_id).where(
                TripStudentEvent.trip_id == trip.id,
                TripStudentEvent.student_id.in_(allowed),
            )
        )
        if on_trip is None:
            raise forbidden("You do not have access to this trip")

    async def active_trips_for(self, school_id: uuid.UUID, actor: User) -> list[schemas.ActiveTripOut]:
        """In-progress trips the actor may see (their child's, their own, or all
        for a headmaster), each enriched with the driver's name + phone."""
        from sqlalchemy.orm import selectinload

        base = (
            select(TransportTrip)
            .where(
                TransportTrip.school_id == school_id,
                TransportTrip.status == TripStatus.IN_PROGRESS.value,
            )
            .options(selectinload(TransportTrip.events))
            .order_by(TransportTrip.started_at.desc())
        )
        if PermissionService.is_super_admin(actor) or self._has_role(actor, SystemRole.HEADMASTER.value):
            trips = list((await self.db.execute(base)).scalars().all())
        elif self._has_role(actor, SystemRole.DRIVER.value):
            trips = list((await self.db.execute(
                base.where(TransportTrip.driver_id == actor.id)
            )).scalars().all())
        else:
            allowed = await self._student_ids_for(actor, school_id)
            if not allowed:
                return []
            trip_ids = await self.db.execute(
                select(TripStudentEvent.trip_id).where(TripStudentEvent.student_id.in_(allowed))
            )
            ids = {t[0] for t in trip_ids.all()}
            if not ids:
                return []
            trips = list((await self.db.execute(base.where(TransportTrip.id.in_(ids)))).scalars().all())

        return [await self._active_trip_out(t) for t in trips]

    async def _active_trip_out(self, trip: TransportTrip) -> schemas.ActiveTripOut:
        user = await self.db.get(User, trip.driver_id)
        driver = await self.db.scalar(
            select(Driver).where(Driver.user_id == trip.driver_id)
        )
        phone = (driver.phone if driver and driver.phone else None) or (user.phone if user else None)
        return schemas.ActiveTripOut(
            id=trip.id, route_id=trip.route_id, driver_id=trip.driver_id,
            trip_type=trip.trip_type, status=trip.status,
            next_student_id=trip.next_student_id,
            driver_name=user.full_name if user else None,
            driver_phone=phone,
        )

    async def eta_for(
        self, school_id: uuid.UUID, actor: User, trip_id: uuid.UUID
    ) -> schemas.EtaOut:
        trip = await self._get_scoped(TransportTrip, school_id, trip_id, "Trip")
        await self._assert_trip_view_access(school_id, actor, trip)

        # Which student on this trip belongs to the caller?
        allowed = await self._student_ids_for(actor, school_id)
        student_id = None
        if allowed:
            student_id = await self.db.scalar(
                select(TripStudentEvent.student_id).where(
                    TripStudentEvent.trip_id == trip.id,
                    TripStudentEvent.student_id.in_(allowed),
                )
            )
        # Headmaster/driver without an own-student fall back to the next stop.
        if student_id is None:
            full = await self.get_trip(school_id, trip.id)
            student_id = full.next_student_id
        if student_id is None:
            raise not_found("No pending stop to estimate")

        ping = await self.db.scalar(
            select(VehicleLocation).where(VehicleLocation.trip_id == trip.id)
            .order_by(VehicleLocation.recorded_at.desc()).limit(1)
        )
        assignment = await self.db.scalar(
            select(TransportAssignment).where(TransportAssignment.student_id == student_id)
        )
        distance_m = eta_minutes = based_on = None
        if (
            ping is not None and assignment is not None
            and assignment.latitude is not None and assignment.longitude is not None
        ):
            distance_m = haversine_m(
                ping.latitude, ping.longitude, assignment.latitude, assignment.longitude
            )
            speed_kmh = ping.speed if ping.speed and ping.speed > 0 else _NOMINAL_KMH
            eta_minutes = round((distance_m / 1000) / speed_kmh * 60, 1)
            based_on = ping.recorded_at
        return schemas.EtaOut(
            trip_id=trip.id, student_id=student_id, distance_m=distance_m,
            eta_minutes=eta_minutes, based_on=based_on,
        )
