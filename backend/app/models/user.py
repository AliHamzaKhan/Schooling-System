"""User model. A user belongs to one school (NULL for the platform Super Admin)."""
from typing import Any

from sqlalchemy import Boolean, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.associations import user_roles
from app.models.base import Base, TenantMixin, TimestampMixin, UUIDMixin


class User(Base, UUIDMixin, TenantMixin, TimestampMixin):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(200), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    # Free-form extended profile data (DOB, address, gender, education,
    # experience, etc.) captured on registration but not modelled as its own
    # column. Consumers should treat unknown keys as forward-compatible extras.
    profile_metadata: Mapped[dict[str, Any] | None] = mapped_column(JSONB, nullable=True)

    roles: Mapped[list["Role"]] = relationship(  # noqa: F821
        secondary=user_roles, back_populates="users", lazy="selectin"
    )
