"""Transport models: vehicles, routes, stops, student assignments."""
import uuid
from datetime import time

from sqlalchemy import ForeignKey, Integer, String, Time, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

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
    """A pickup/drop point on a route."""

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

    route: Mapped["Route"] = relationship(back_populates="stops")


class TransportAssignment(Base, UUIDMixin, TimestampMixin):
    """A student's assignment to a route/stop."""

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
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)
