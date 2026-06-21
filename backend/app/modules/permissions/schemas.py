"""Permission read schemas."""
from pydantic import BaseModel


class EffectivePermissions(BaseModel):
    """A user's effective access after the full cascade."""

    school_id: str | None = None
    is_super_admin: bool
    modules: list[str]
    # module -> {action: allowed}
    matrix: dict[str, dict[str, bool]]


class ModuleInfo(BaseModel):
    code: str
    name: str
