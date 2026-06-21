"""Role & Permission Management schemas (docs/permissions/03, 06)."""
import uuid

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.enums import Module, PermissionAction


class ModulePermissionIn(BaseModel):
    module: Module
    actions: list[PermissionAction] = Field(default_factory=list)

    @field_validator("actions")
    @classmethod
    def _dedupe(cls, v: list[PermissionAction]) -> list[PermissionAction]:
        return list(dict.fromkeys(v))


class RoleCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    # Optional explicit code; otherwise slugified from name (e.g. "Vice Principal" -> "vice_principal").
    code: str | None = Field(default=None, max_length=50)
    permissions: list[ModulePermissionIn] = Field(default_factory=list)


class RoleRename(BaseModel):
    name: str = Field(min_length=2, max_length=100)


class RolePermissionsUpdate(BaseModel):
    permissions: list[ModulePermissionIn] = Field(default_factory=list)


class ModulePermissionOut(BaseModel):
    module: str
    actions: list[str]


class RoleDetailOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID | None = None
    code: str
    name: str
    is_system: bool
    permissions: list[ModulePermissionOut] = []
