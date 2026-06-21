"""Auth request/response schemas."""
import uuid

from pydantic import BaseModel, ConfigDict, EmailStr


class RoleOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    code: str
    name: str
    is_system: bool


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    full_name: str
    phone: str | None = None
    is_active: bool
    school_id: uuid.UUID | None = None
    roles: list[RoleOut] = []


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str
