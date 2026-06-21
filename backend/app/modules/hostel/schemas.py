"""Hostel schemas."""
import uuid
from datetime import date

from pydantic import BaseModel, ConfigDict, Field, computed_field


class BlockCreate(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    warden_name: str | None = Field(default=None, max_length=150)
    warden_phone: str | None = Field(default=None, max_length=50)


class BlockOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    name: str
    warden_name: str | None = None
    warden_phone: str | None = None


class RoomCreate(BaseModel):
    room_no: str = Field(min_length=1, max_length=50)
    capacity: int = Field(default=1, ge=1)


class RoomOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    block_id: uuid.UUID
    room_no: str
    capacity: int
    occupied: int

    @computed_field
    @property
    def is_full(self) -> bool:
        return self.occupied >= self.capacity


class AllocationCreate(BaseModel):
    student_id: uuid.UUID
    room_id: uuid.UUID
    allocated_on: date | None = None


class AllocationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    student_id: uuid.UUID
    room_id: uuid.UUID
    allocated_on: date
    vacated_on: date | None = None
    status: str
