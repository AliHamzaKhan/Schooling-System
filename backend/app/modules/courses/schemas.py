"""Course content schemas: courses, books, chapters, notes, reading progress."""
import uuid

from pydantic import BaseModel, ConfigDict, Field


# ------------------------------- courses -------------------------------- #


class CourseCreate(BaseModel):
    title: str = Field(min_length=2, max_length=200)
    description: str | None = None
    subject: str | None = Field(default=None, max_length=120)
    cover_url: str | None = Field(default=None, max_length=500)
    # A course is a subject offered to one class+section. Provided by the
    # authoring UI (class → section → subject); optional for backward compat.
    section_id: uuid.UUID | None = None
    subject_id: uuid.UUID | None = None


class CourseUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=2, max_length=200)
    description: str | None = None
    subject: str | None = Field(default=None, max_length=120)
    cover_url: str | None = Field(default=None, max_length=500)
    is_active: bool | None = None
    section_id: uuid.UUID | None = None
    subject_id: uuid.UUID | None = None


class CourseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    title: str
    description: str | None = None
    subject: str | None = None
    cover_url: str | None = None
    is_active: bool
    section_id: uuid.UUID | None = None
    subject_id: uuid.UUID | None = None


class CourseListOut(CourseOut):
    """Course enriched for the listing: how many books / notes it carries,
    plus the class/section/subject it is offered to (for grouping)."""

    book_count: int = 0
    note_count: int = 0
    class_name: str | None = None
    section_name: str | None = None
    subject_name: str | None = None


# -------------------------------- books --------------------------------- #


class BookCreate(BaseModel):
    title: str = Field(min_length=2, max_length=200)
    description: str | None = None
    order_index: int = 0


class BookOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    course_id: uuid.UUID
    title: str
    description: str | None = None
    order_index: int


class BookListOut(BookOut):
    chapter_count: int = 0


# ------------------------------- chapters ------------------------------- #


class ChapterCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    content: str = ""
    order_index: int = 0


class ChapterBrief(BaseModel):
    """Chapter without its body — for the chapter list / table of contents."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    book_id: uuid.UUID
    title: str
    order_index: int


class ChapterOut(ChapterBrief):
    content: str


# -------------------------------- notes --------------------------------- #


class NoteCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    content: str = ""
    order_index: int = 0


class NoteBrief(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    course_id: uuid.UUID
    title: str
    order_index: int


class NoteOut(NoteBrief):
    content: str


# --------------------------- reading progress --------------------------- #


class ReadingProgressSet(BaseModel):
    resource_type: str = Field(pattern="^(book|note)$")
    resource_id: uuid.UUID
    chapter_id: uuid.UUID | None = None
    page: int = Field(default=0, ge=0)


class ReadingProgressOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    resource_type: str
    resource_id: uuid.UUID
    chapter_id: uuid.UUID | None = None
    page: int
