"""Transport models: vehicles, routes, stops, drivers, student assignments,
requests, trips, and per-student trip events."""
import uuid
from datetime import datetime, time

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Time, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import TransportRequestStatus, TripStatus, TripStudentStatus
from app.models.base import Base, TimestampMixin, UUIDMixin


class Vehicle(Base, UUIDMixin, TimestampMixin):
    """A transport vehicle (bus/van)."""

    __tablename__ = "vehicles"
    __table_args__ = (UniqueConstraint("school_id", "registration_no", name="uq_vehicle_school_reg"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    registration_no: Mapped[str] = mapped_column(String(50), nullable=False)
    model: Mapped[str | None] = mapped_column(String(100), nullable=True)
    capacity: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    driver_name: Mapped[str | None] = mapped_column(String(150), nullable=True)
    driver_phone: Mapped[str | None] = mapped_column(String(50), nullable=True)


class Driver(Base, UUIDMixin, TimestampMixin):
    """A driver's profile, linked to a login user with the ``driver`` role.

    The login (email/password, name, phone) lives on the ``users`` row; this
    holds transport-specific fields and the vehicle currently assigned.
    """

    __tablename__ = "drivers"
    __table_args__ = (UniqueConstraint("user_id", name="uq_driver_user"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    license_no: Mapped[str | None] = mapped_column(String(100), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    assigned_vehicle_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="SET NULL"), nullable=True
    )
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)


class Route(Base, UUIDMixin, TimestampMixin):
    """A transport route, optionally served by a vehicle."""

    __tablename__ = "routes"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    vehicle_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="SET NULL"), nullable=True
    )
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)

    stops: Mapped[list["RouteStop"]] = relationship(
        back_populates="route", cascade="all, delete-orphan"
    )


class RouteStop(Base, UUIDMixin, TimestampMixin):
    """A pickup/drop point on a route, optionally geo-located."""

    __tablename__ = "route_stops"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    route_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("routes.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    sequence: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    pickup_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    dropoff_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    # Geo-coordinates + reverse-geocoded address (nullable until captured).
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    address: Mapped[str | None] = mapped_column(String(255), nullable=True)

    route: Mapped["Route"] = relationship(back_populates="stops")


class TransportAssignment(Base, UUIDMixin, TimestampMixin):
    """A student's assignment to a route/stop, with pickup location + driver.

    ``latitude``/``longitude``/``address`` are the student's pickup point,
    typically copied from the approved [TransportRequest].
    """

    __tablename__ = "transport_assignments"
    __table_args__ = (UniqueConstraint("student_id", name="uq_transport_student"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    route_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("routes.id", ondelete="CASCADE"), nullable=False, index=True
    )
    stop_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("route_stops.id", ondelete="SET NULL"), nullable=True
    )
    driver_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    address: Mapped[str | None] = mapped_column(String(255), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)


class TransportRequest(Base, UUIDMixin, TimestampMixin):
    """A transport support request raised by a student or their guardian.

    Carries the pickup location the school needs; on approval the Headmaster
    assigns the student to a route/driver, copying these coordinates onto the
    [TransportAssignment].
    """

    __tablename__ = "transport_requests"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    # The account that raised the request (the student themselves or a guardian).
    requested_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    pickup_address: Mapped[str] = mapped_column(String(255), nullable=False)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    notes: Mapped[str | None] = mapped_column(String(500), nullable=True)
    status: Mapped[str] = mapped_column(
        String(20), default=TransportRequestStatus.PENDING.value, nullable=False
    )
    reviewed_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    reject_reason: Mapped[str | None] = mapped_column(String(255), nullable=True)


class TransportTrip(Base, UUIDMixin, TimestampMixin):
    """One pickup or drop-off run by a driver on a route."""

    __tablename__ = "transport_trips"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    route_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("routes.id", ondelete="CASCADE"), nullable=False, index=True
    )
    driver_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    vehicle_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="SET NULL"), nullable=True
    )
    trip_type: Mapped[str] = mapped_column(String(20), nullable=False)
    status: Mapped[str] = mapped_column(
        String(20), default=TripStatus.SCHEDULED.value, nullable=False
    )
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # Ordered list of student ids (the active/optimized pickup order). Optimized
    # by the backend in a later phase; for now it's the assignment order.
    stop_order: Mapped[list | None] = mapped_column(JSONB, nullable=True)
    optimized: Mapped[bool] = mapped_column(default=False, nullable=False)

    events: Mapped[list["TripStudentEvent"]] = relationship(
        back_populates="trip", cascade="all, delete-orphan"
    )

    @property
    def next_student_id(self) -> uuid.UUID | None:
        """The next destination: first student in ``stop_order`` still pending.

        Requires ``events`` to be loaded. Returns None once all are handled.
        """
        pending = {
            str(e.student_id)
            for e in self.events
            if e.status == TripStudentStatus.PENDING.value
        }
        for sid in self.stop_order or []:
            if str(sid) in pending:
                return uuid.UUID(str(sid))
        return None


class TripStudentEvent(Base, UUIDMixin, TimestampMixin):
    """Per-student pickup/drop-off status within a trip (the trip manifest)."""

    __tablename__ = "trip_student_events"
    __table_args__ = (UniqueConstraint("trip_id", "student_id", name="uq_trip_student"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    trip_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("transport_trips.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    status: Mapped[str] = mapped_column(
        String(20), default=TripStudentStatus.PENDING.value, nullable=False
    )
    event_time: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    # True once a "bus approaching" alert has fired for this student on the trip,
    # so the 500 m proximity notification is one-shot.
    approach_notified: Mapped[bool] = mapped_column(default=False, nullable=False)

    trip: Mapped["TransportTrip"] = relationship(back_populates="events")


class VehicleLocation(Base, UUIDMixin, TimestampMixin):
    """A driver's device location ping during an active trip (~1/min)."""

    __tablename__ = "vehicle_locations"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    trip_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("transport_trips.id", ondelete="CASCADE"), nullable=False, index=True
    )
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    address: Mapped[str | None] = mapped_column(String(255), nullable=True)
    speed: Mapped[float | None] = mapped_column(Float, nullable=True)
    heading: Mapped[float | None] = mapped_column(Float, nullable=True)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
