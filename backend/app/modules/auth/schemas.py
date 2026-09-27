"""Auth request/response schemas."""
import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, EmailStr, Field


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


class SessionOut(BaseModel):
    """Safe self-service view of one live login session.

    Refresh hashes, IP addresses and user-agent strings stay server-only: they
    are credentials/tracking data, not required to let a user revoke a login.
    """

    id: uuid.UUID
    created_at: datetime
    last_used_at: datetime | None = None
    expires_at: datetime
    is_current: bool


# ── Password reset (forgot-password OTP flow) ─────────────────────────────────
class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class VerifyOtpRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=4, max_length=10)


class ResetTokenOut(BaseModel):
    """Returned by /auth/verify-otp; authorizes the subsequent /reset-password."""

    reset_token: str


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(min_length=8, max_length=128)


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8, max_length=128)


class MessageOut(BaseModel):
    """A neutral acknowledgement (kept deliberately uninformative for the reset
    endpoints so they don't reveal whether an email is registered)."""

    message: str
