"""School Service request/response schemas."""
import uuid
from datetime import date

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.core.enums import Module, PlanCode, SchoolStatus

# --------------------------------------------------------------------------- #
# School
# --------------------------------------------------------------------------- #


class SchoolCreate(BaseModel):
    name: str = Field(min_length=2, max_length=200)
    code: str = Field(min_length=2, max_length=50)
    contact_email: EmailStr | None = None
    contact_phone: str | None = Field(default=None, max_length=50)
    address: str | None = Field(default=None, max_length=500)
    subscription_plan_code: PlanCode | None = None
    settings: dict = Field(default_factory=dict)


class SchoolUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=200)
    contact_email: EmailStr | None = None
    contact_phone: str | None = Field(default=None, max_length=50)
    address: str | None = Field(default=None, max_length=500)
    settings: dict | None = None


class SubscriptionPlanOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    code: str
    name: str
    modules: list[str]


class SchoolOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    code: str
    status: str
    contact_email: str | None = None
    contact_phone: str | None = None
    address: str | None = None
    settings: dict = {}
    subscription_plan: SubscriptionPlanOut | None = None


# --------------------------------------------------------------------------- #
# Subscription / status
# --------------------------------------------------------------------------- #


class SchoolStatsOut(BaseModel):
    """Active-user counts for the school detail screen."""

    students: int
    teachers: int
    guardians: int
    total_users: int


class SubscriptionAssign(BaseModel):
    plan_code: PlanCode


class StatusUpdate(BaseModel):
    status: SchoolStatus


# --------------------------------------------------------------------------- #
# Module toggles
# --------------------------------------------------------------------------- #


class ModuleToggle(BaseModel):
    module: Module
    enabled: bool


class ModuleTogglesUpdate(BaseModel):
    toggles: list[ModuleToggle] = Field(min_length=1)


class ModuleStatus(BaseModel):
    module: str
    in_plan: bool
    toggle_enabled: bool  # explicit toggle (defaults True when no row)
    effective: bool  # in_plan AND toggle_enabled


class SchoolModulesView(BaseModel):
    """Super Admin view: what this school can actually access (plan ∩ toggles)."""

    school_id: uuid.UUID
    plan_code: str | None = None
    effective_modules: list[str]
    modules: list[ModuleStatus]


# --------------------------------------------------------------------------- #
# Academic sessions
# --------------------------------------------------------------------------- #


class AcademicSessionCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    start_date: date | None = None
    end_date: date | None = None
    is_active: bool = False


class AcademicSessionUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    start_date: date | None = None
    end_date: date | None = None


class AcademicSessionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    name: str
    start_date: date | None = None
    end_date: date | None = None
    is_active: bool
