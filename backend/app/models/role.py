"""Role and per-module permission models.

A Role is either a system role (school_id NULL, is_system True) or a custom
school role (docs/permissions/06-dynamic-roles.md). Each RolePermission row
grants action levels for one module (docs/permissions/03 and 05).
"""
import uuid

from sqlalchemy import Boolean, ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.associations import user_roles
from app.models.base import Base, TenantMixin, TimestampMixin, UUIDMixin


class Role(Base, UUIDMixin, TenantMixin, TimestampMixin):
    __tablename__ = "roles"
    __table_args__ = (UniqueConstraint("school_id", "code", name="uq_role_school_code"),)

    code: Mapped[str] = mapped_column(String(50), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    is_system: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    permissions: Mapped[list["RolePermission"]] = relationship(
        back_populates="role", cascade="all, delete-orphan", lazy="selectin"
    )
    users: Mapped[list["User"]] = relationship(  # noqa: F821
        secondary=user_roles, back_populates="roles"
    )


class RolePermission(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "role_permissions"
    __table_args__ = (UniqueConstraint("role_id", "module", name="uq_roleperm_role_module"),)

    role_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("roles.id", ondelete="CASCADE"), nullable=False, index=True
    )
    module: Mapped[str] = mapped_column(String(50), nullable=False)

    can_view: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    can_create: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    can_edit: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    can_delete: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    can_approve: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    can_export: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    role: Mapped["Role"] = relationship(back_populates="permissions")
