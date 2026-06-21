"""Transport schemas."""
import uuid
from datetime import time

from pydantic import BaseModel, ConfigDict, Field


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


class StopOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    route_id: uuid.UUID
    name: str
    sequence: int
    pickup_time: time | None = None
    dropoff_time: time | None = None


class AssignmentCreate(BaseModel):
    student_id: uuid.UUID
    route_id: uuid.UUID
    stop_id: uuid.UUID | None = None


class AssignmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    student_id: uuid.UUID
    route_id: uuid.UUID
    stop_id: uuid.UUID | None = None
    status: str
