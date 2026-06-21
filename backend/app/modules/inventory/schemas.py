"""Inventory schemas."""
import uuid
from datetime import date
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, computed_field


class ItemCreate(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    category: str | None = Field(default=None, max_length=100)
    unit: str | None = Field(default=None, max_length=30)
    reorder_level: int = Field(default=0, ge=0)


class ItemUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=150)
    category: str | None = Field(default=None, max_length=100)
    unit: str | None = Field(default=None, max_length=30)
    reorder_level: int | None = Field(default=None, ge=0)


class ItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    name: str
    category: str | None = None
    unit: str | None = None
    quantity: int
    reorder_level: int

    @computed_field
    @property
    def is_low_stock(self) -> bool:
        return self.quantity <= self.reorder_level


class StockMovement(BaseModel):
    type: Literal["in", "out"]
    quantity: int = Field(gt=0)
    reason: str | None = Field(default=None, max_length=255)
    occurred_on: date | None = None


class TransactionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    item_id: uuid.UUID
    type: str
    quantity: int
    reason: str | None = None
    occurred_on: date
    recorded_by: uuid.UUID | None = None
