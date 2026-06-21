"""Hostel models: blocks, rooms, student allocations."""
import uuid
from datetime import date

from sqlalchemy import Date, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDMixin


class HostelBlock(Base, UUIDMixin, TimestampMixin):
    """A hostel block/building."""

    __tablename__ = "hostel_blocks"
    __table_args__ = (UniqueConstraint("school_id", "name", name="uq_hostel_block_school_name"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    warden_name: Mapped[str | None] = mapped_column(String(150), nullable=True)
    warden_phone: Mapped[str | None] = mapped_column(String(50), nullable=True)

    rooms: Mapped[list["HostelRoom"]] = relationship(
        back_populates="block", cascade="all, delete-orphan"
    )


class HostelRoom(Base, UUIDMixin, TimestampMixin):
    """A room within a block with capacity/occupancy tracking."""

    __tablename__ = "hostel_rooms"
    __table_args__ = (UniqueConstraint("block_id", "room_no", name="uq_hostel_room_block_no"),)

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    block_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("hostel_blocks.id", ondelete="CASCADE"), nullable=False, index=True
    )
    room_no: Mapped[str] = mapped_column(String(50), nullable=False)
    capacity: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    occupied: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    block: Mapped["HostelBlock"] = relationship(back_populates="rooms")


class HostelAllocation(Base, UUIDMixin, TimestampMixin):
    """A student's allocation to a room."""

    __tablename__ = "hostel_allocations"

    school_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    room_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("hostel_rooms.id", ondelete="CASCADE"), nullable=False, index=True
    )
    allocated_on: Mapped[date] = mapped_column(Date, nullable=False)
    vacated_on: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)
