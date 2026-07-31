"""School information schemas (about, achievements, uniform, contact)."""
from pydantic import BaseModel, Field


class Achievement(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = None
    year: str | None = Field(default=None, max_length=20)


class SchoolInfoOut(BaseModel):
    """Everything the student/guardian "School" screen needs, composed from the
    core school row plus the headmaster-authored info."""

    name: str
    address: str | None = None
    contact_email: str | None = None
    contact_phone: str | None = None
    about: str | None = None
    achievements: list[Achievement] = []
    uniform_image_url: str | None = None


class SchoolInfoUpdate(BaseModel):
    """Headmaster-editable fields. Name/address/contacts stay on the school
    profile endpoint; this covers the descriptive content."""

    about: str | None = None
    achievements: list[Achievement] | None = None
    uniform_image_url: str | None = Field(default=None, max_length=500)
