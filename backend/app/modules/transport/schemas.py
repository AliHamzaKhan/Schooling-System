"""Transport schemas."""
import uuid
from datetime import datetime, time

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class VehicleCreate(BaseModel):
    registration_no: str = Field(min_length=1, max_length=50)
    model: str | None = Field(default=None, max_length=100)
    capacity: int = Field(ge=0)
    driver_name: str | None = Field(default=None, max_length=150)
    driver_phone: str | None = Field(default=None, max_length=50)


class VehicleUpdate(BaseModel):
    model: str | None = Field(default=None, max_length=100)
    capacity: int | None = Field(default=None, ge=0)
    driver_name: str | None = Field(default=None, max_length=150)
    driver_phone: str | None = Field(default=None, max_length=50)


class VehicleOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    registration_no: str
    model: str | None = None
    capacity: int
    driver_name: str | None = None
    driver_phone: str | None = None


class RouteCreate(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    vehicle_id: uuid.UUID | None = None
    description: str | None = Field(default=None, max_length=255)


class RouteUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=150)
    vehicle_id: uuid.UUID | None = None
    description: str | None = Field(default=None, max_length=255)


class RouteOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    name: str
    vehicle_id: uuid.UUID | None = None
    description: str | None = None


class StopCreate(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    sequence: int = Field(default=0, ge=0)
    pickup_time: time | None = None
    dropoff_time: time | None = None
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    address: str | None = Field(default=None, max_length=255)


class StopOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    route_id: uuid.UUID
    name: str
    sequence: int
    pickup_time: time | None = None
    dropoff_time: time | None = None
    latitude: float | None = None
    longitude: float | None = None
    address: str | None = None


class AssignmentCreate(BaseModel):
    # Either supply an approved request to copy the student + pickup location
    # from, or pass student_id + coordinates directly.
    request_id: uuid.UUID | None = None
    student_id: uuid.UUID | None = None
    route_id: uuid.UUID
    stop_id: uuid.UUID | None = None
    driver_id: uuid.UUID | None = None
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    address: str | None = Field(default=None, max_length=255)


class AssignmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    student_id: uuid.UUID
    route_id: uuid.UUID
    stop_id: uuid.UUID | None = None
    driver_id: uuid.UUID | None = None
    latitude: float | None = None
    longitude: float | None = None
    address: str | None = None
    status: str


# ------------------------------- drivers -------------------------------- #


class DriverCreate(BaseModel):
    """Create a driver login + profile in one call."""

    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=2, max_length=200)
    phone: str | None = Field(default=None, max_length=50)
    license_no: str | None = Field(default=None, max_length=100)
    assigned_vehicle_id: uuid.UUID | None = None


class DriverUpdate(BaseModel):
    license_no: str | None = Field(default=None, max_length=100)
    phone: str | None = Field(default=None, max_length=50)
    assigned_vehicle_id: uuid.UUID | None = None
    status: str | None = Field(default=None, pattern="^(active|inactive)$")


class DriverOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    user_id: uuid.UUID
    full_name: str | None = None
    email: str | None = None
    license_no: str | None = None
    phone: str | None = None
    assigned_vehicle_id: uuid.UUID | None = None
    status: str


class DriverLocationOut(BaseModel):
    """A driver in the Headmaster's fleet view (P1: online = has an active trip)."""

    driver_id: uuid.UUID
    full_name: str | None = None
    trip_id: uuid.UUID | None = None
    online: bool = False


# ------------------------------ requests -------------------------------- #


class TransportRequestCreate(BaseModel):
    # Guardians pass the child's id; a student may omit it (defaults to self).
    student_id: uuid.UUID | None = None
    pickup_address: str = Field(min_length=1, max_length=255)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    notes: str | None = Field(default=None, max_length=500)


class TransportRequestReject(BaseModel):
    reason: str | None = Field(default=None, max_length=255)


class TransportRequestOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    student_id: uuid.UUID
    requested_by: uuid.UUID
    pickup_address: str
    latitude: float | None = None
    longitude: float | None = None
    notes: str | None = None
    status: str
    reject_reason: str | None = None


# -------------------------------- trips --------------------------------- #


class TripStart(BaseModel):
    route_id: uuid.UUID
    trip_type: str = Field(pattern="^(pickup|dropoff)$")


class TripStudentStatusUpdate(BaseModel):
    status: str = Field(pattern="^(pending|boarded|absent|dropped)$")
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)


class StopOrderUpdate(BaseModel):
    stop_order: list[uuid.UUID] = Field(min_length=1)


class TripStudentEventOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    student_id: uuid.UUID
    status: str


class TripOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    route_id: uuid.UUID
    driver_id: uuid.UUID
    vehicle_id: uuid.UUID | None = None
    trip_type: str
    status: str
    stop_order: list[uuid.UUID] | None = None
    optimized: bool = False
    next_student_id: uuid.UUID | None = None
    events: list[TripStudentEventOut] = []


# ---------------------------- location / ETA ---------------------------- #


class LocationPing(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    address: str | None = Field(default=None, max_length=255)
    speed: float | None = Field(default=None, ge=0)
    heading: float | None = Field(default=None, ge=0, le=360)


class LocationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    trip_id: uuid.UUID
    latitude: float
    longitude: float
    address: str | None = None
    speed: float | None = None
    heading: float | None = None
    recorded_at: datetime


class ActiveTripOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    route_id: uuid.UUID
    driver_id: uuid.UUID
    trip_type: str
    status: str
    next_student_id: uuid.UUID | None = None
    # Resolved so students/guardians (who can't read the drivers list) can see
    # and contact the driver.
    driver_name: str | None = None
    driver_phone: str | None = None


class EtaOut(BaseModel):
    trip_id: uuid.UUID
    student_id: uuid.UUID
    distance_m: float | None = None
    eta_minutes: float | None = None
    based_on: datetime | None = None
