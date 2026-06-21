"""Hostel Service: blocks, rooms, student allocations."""
import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import SystemRole
from app.core.exceptions import bad_request, not_found
from app.models.hostel import HostelAllocation, HostelBlock, HostelRoom
from app.models.role import Role
from app.models.user import User
from app.modules.hostel import schemas


class HostelService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _get_scoped(self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    # ------------------------------ blocks ------------------------------- #

    async def create_block(self, school_id: uuid.UUID, data: schemas.BlockCreate) -> HostelBlock:
        dupe = await self.db.scalar(
            select(HostelBlock).where(HostelBlock.school_id == school_id, HostelBlock.name == data.name)
        )
        if dupe is not None:
            raise bad_request(f"Block '{data.name}' already exists")
        block = HostelBlock(school_id=school_id, **data.model_dump())
        self.db.add(block)
        await self.db.flush()
        return block

    async def list_blocks(self, school_id: uuid.UUID) -> list[HostelBlock]:
        result = await self.db.execute(select(HostelBlock).where(HostelBlock.school_id == school_id))
        return list(result.scalars().all())

    # ------------------------------- rooms ------------------------------- #

    async def add_room(self, school_id: uuid.UUID, block_id: uuid.UUID, data: schemas.RoomCreate) -> HostelRoom:
        await self._get_scoped(HostelBlock, school_id, block_id, "Block")
        dupe = await self.db.scalar(
            select(HostelRoom).where(HostelRoom.block_id == block_id, HostelRoom.room_no == data.room_no)
        )
        if dupe is not None:
            raise bad_request(f"Room '{data.room_no}' already exists in this block")
        room = HostelRoom(
            school_id=school_id, block_id=block_id, room_no=data.room_no,
            capacity=data.capacity, occupied=0,
        )
        self.db.add(room)
        await self.db.flush()
        return room

    async def list_rooms(self, school_id: uuid.UUID, block_id: uuid.UUID) -> list[HostelRoom]:
        await self._get_scoped(HostelBlock, school_id, block_id, "Block")
        result = await self.db.execute(
            select(HostelRoom).where(HostelRoom.block_id == block_id).order_by(HostelRoom.room_no)
        )
        return list(result.scalars().all())

    # ---------------------------- allocations ---------------------------- #

    async def allocate(self, school_id: uuid.UUID, data: schemas.AllocationCreate) -> HostelAllocation:
        room = await self._get_scoped(HostelRoom, school_id, data.room_id, "Room")
        student = await self.db.scalar(
            select(User).where(User.id == data.student_id, User.school_id == school_id)
            .join(User.roles).where(Role.code == SystemRole.STUDENT.value)
        )
        if student is None:
            raise bad_request("User is not a student in this school")

        active = await self.db.scalar(
            select(HostelAllocation).where(
                HostelAllocation.student_id == data.student_id, HostelAllocation.status == "active"
            )
        )
        if active is not None:
            raise bad_request("Student already has an active hostel allocation")
        if room.occupied >= room.capacity:
            raise bad_request("Room is full")

        allocation = HostelAllocation(
            school_id=school_id, student_id=data.student_id, room_id=data.room_id,
            allocated_on=data.allocated_on or date.today(), status="active",
        )
        room.occupied += 1
        self.db.add(allocation)
        await self.db.flush()
        return allocation

    async def vacate(self, school_id: uuid.UUID, allocation_id: uuid.UUID) -> HostelAllocation:
        allocation = await self._get_scoped(HostelAllocation, school_id, allocation_id, "Allocation")
        if allocation.status != "active":
            raise bad_request("Allocation is already vacated")
        allocation.status = "vacated"
        allocation.vacated_on = date.today()
        room = await self.db.get(HostelRoom, allocation.room_id)
        if room is not None and room.occupied > 0:
            room.occupied -= 1
        await self.db.flush()
        return allocation

    async def list_allocations(
        self, school_id: uuid.UUID, room_id: uuid.UUID | None = None, active_only: bool = False
    ) -> list[HostelAllocation]:
        stmt = select(HostelAllocation).where(HostelAllocation.school_id == school_id)
        if room_id is not None:
            stmt = stmt.where(HostelAllocation.room_id == room_id)
        if active_only:
            stmt = stmt.where(HostelAllocation.status == "active")
        return list((await self.db.execute(stmt)).scalars().all())
