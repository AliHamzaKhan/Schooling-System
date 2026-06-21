"""HR & Payroll schemas."""
import uuid
from datetime import date

from pydantic import BaseModel, ConfigDict, Field


class StaffProfileCreate(BaseModel):
    user_id: uuid.UUID
    designation: str = Field(min_length=1, max_length=120)
    department: str | None = Field(default=None, max_length=120)
    joining_date: date | None = None
    base_salary: float = Field(ge=0)


class StaffProfileUpdate(BaseModel):
    designation: str | None = Field(default=None, min_length=1, max_length=120)
    department: str | None = Field(default=None, max_length=120)
    joining_date: date | None = None
    base_salary: float | None = Field(default=None, ge=0)


class StaffProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    user_id: uuid.UUID
    designation: str
    department: str | None = None
    joining_date: date | None = None
    base_salary: float


class PayslipGenerate(BaseModel):
    period_month: int = Field(ge=1, le=12)
    period_year: int = Field(ge=2000, le=2100)
    allowances: float = Field(default=0.0, ge=0)
    deductions: float = Field(default=0.0, ge=0)


class PayslipOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    staff_profile_id: uuid.UUID
    period_month: int
    period_year: int
    gross: float
    deductions: float
    net: float
    status: str
    paid_on: date | None = None
