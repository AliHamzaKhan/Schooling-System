"""User Management request/response schemas."""
import uuid

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class RoleOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    code: str
    name: str
    is_system: bool
    school_id: uuid.UUID | None = None


class UserDetailOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    full_name: str
    phone: str | None = None
    is_active: bool
    school_id: uuid.UUID | None = None
    roles: list[RoleOut] = []


class HeadmasterCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=2, max_length=200)
    phone: str | None = Field(default=None, max_length=50)


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=2, max_length=200)
    phone: str | None = Field(default=None, max_length=50)
    # School role codes to assign (e.g. ["teacher"], ["guardian"]). Must already
    # be provisioned for the school.
    role_codes: list[str] = Field(min_length=1)


class UserUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=2, max_length=200)
    phone: str | None = Field(default=None, max_length=50)
    is_active: bool | None = None


class RoleAssign(BaseModel):
    role_codes: list[str] = Field(min_length=1)
