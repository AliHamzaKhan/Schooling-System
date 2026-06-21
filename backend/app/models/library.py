"""Library models: books and loans."""
import uuid
from datetime import date

from sqlalchemy import Date, Float, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.enums import LoanStatus
from app.models.base import Base, TimestampMixin, UUIDMixin


class Book(Base, UUIDMixin, TimestampMixin):
    """A library book title with copy tracking."""

    __tablename__ = "books"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(250), nullable=False)
    author: Mapped[str | None] = mapped_column(String(200), nullable=True)
    isbn: Mapped[str | None] = mapped_column(String(20), nullable=True)
    category: Mapped[str | None] = mapped_column(String(100), nullable=True)
    total_copies: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    available_copies: Mapped[int] = mapped_column(Integer, default=1, nullable=False)


class BookLoan(Base, UUIDMixin, TimestampMixin):
    """A book issued to a member (any school user)."""

    __tablename__ = "book_loans"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    book_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("books.id", ondelete="CASCADE"), nullable=False, index=True
    )
    member_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    borrowed_on: Mapped[date] = mapped_column(Date, nullable=False)
    due_date: Mapped[date] = mapped_column(Date, nullable=False)
    returned_on: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default=LoanStatus.BORROWED.value, nullable=False)
    fine: Mapped[float | None] = mapped_column(Float, nullable=True)
