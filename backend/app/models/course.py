"""Course content models: courses with a reading Book (chapters) and Notes.

Reading material authored by the headmaster and consumed by students. A course
holds one or more books (each a sequence of text chapters) and standalone notes.
``ReadingProgress`` remembers where each user left off, per book/note.
"""
import uuid

from sqlalchemy import ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDMixin


class Course(Base, UUIDMixin, TimestampMixin):
    """A course/subject offering with reading material, scoped to a school."""

    __tablename__ = "courses"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    # A course is a subject offered to one class+section. ``section_id`` scopes
    # it (the section knows its class); ``subject_id`` links the school's subject
    # catalog entry it teaches. Both are nullable so pre-existing school-wide
    # courses keep working.
    section_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("sections.id", ondelete="CASCADE"), nullable=True, index=True
    )
    subject_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("subjects.id", ondelete="SET NULL"), nullable=True
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    subject: Mapped[str | None] = mapped_column(String(120), nullable=True)
    cover_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_active: Mapped[bool] = mapped_column(default=True, nullable=False)
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    books: Mapped[list["CourseBook"]] = relationship(
        back_populates="course", cascade="all, delete-orphan"
    )
    notes: Mapped[list["CourseNote"]] = relationship(
        back_populates="course", cascade="all, delete-orphan"
    )


class CourseBook(Base, UUIDMixin, TimestampMixin):
    """A book within a course — an ordered set of text chapters."""

    __tablename__ = "course_books"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    course_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("courses.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    order_index: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    course: Mapped["Course"] = relationship(back_populates="books")
    chapters: Mapped[list["BookChapter"]] = relationship(
        back_populates="book", cascade="all, delete-orphan"
    )


class BookChapter(Base, UUIDMixin, TimestampMixin):
    """One chapter of a book: a title and its (text) body."""

    __tablename__ = "book_chapters"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    book_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("course_books.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False, default="")
    order_index: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    book: Mapped["CourseBook"] = relationship(back_populates="chapters")


class CourseNote(Base, UUIDMixin, TimestampMixin):
    """A standalone note within a course: a title and its (text) body."""

    __tablename__ = "course_notes"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    course_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("courses.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False, default="")
    order_index: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    course: Mapped["Course"] = relationship(back_populates="notes")


class ReadingProgress(Base, UUIDMixin, TimestampMixin):
    """Where a user left off in a book or note.

    ``resource_type`` is "book" or "note"; ``resource_id`` is that book/note id.
    For a book, ``chapter_id`` and ``page`` locate the exact spot; for a note,
    ``page`` is the scroll page. One row per (user, resource_type, resource_id).
    """

    __tablename__ = "reading_progress"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "resource_type", "resource_id", name="uq_reading_progress_user_resource"
        ),
    )

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    resource_type: Mapped[str] = mapped_column(String(10), nullable=False)
    resource_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    chapter_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    page: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
