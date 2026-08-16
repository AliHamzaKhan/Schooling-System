"""Auth request/response schemas."""
import uuid
from typing import Any

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
    # Extended profile captured at registration (avatar_url, gender, address, …).
    # `/auth/me` is the only place a signed-in user can read their own profile,
    # so without this their photo — stored here by the registration form — has no
    # way of reaching their portal.
    profile_metadata: dict[str, Any] | None = None


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str
