"""Hostel endpoints, gated by the HOSTEL module."""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.hostel import schemas
from app.modules.hostel.service import HostelService

router = APIRouter(prefix="/schools/{school_id}/hostel", tags=["Hostel"])

_view = Depends(require_school_permission(Module.HOSTEL, PA.VIEW))
_create = Depends(require_school_permission(Module.HOSTEL, PA.CREATE))
_edit = Depends(require_school_permission(Module.HOSTEL, PA.EDIT))


@router.post("/blocks", response_model=schemas.BlockOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_block(school_id: uuid.UUID, data: schemas.BlockCreate, db: DbDep) -> schemas.BlockOut:
    return await HostelService(db).create_block(school_id, data)


@router.get("/blocks", response_model=list[schemas.BlockOut], dependencies=[_view])
async def list_blocks(school_id: uuid.UUID, db: DbDep) -> list[schemas.BlockOut]:
    return await HostelService(db).list_blocks(school_id)


@router.post("/blocks/{block_id}/rooms", response_model=schemas.RoomOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def add_room(school_id: uuid.UUID, block_id: uuid.UUID, data: schemas.RoomCreate, db: DbDep) -> schemas.RoomOut:
    return await HostelService(db).add_room(school_id, block_id, data)


@router.get("/blocks/{block_id}/rooms", response_model=list[schemas.RoomOut], dependencies=[_view])
async def list_rooms(school_id: uuid.UUID, block_id: uuid.UUID, db: DbDep) -> list[schemas.RoomOut]:
    return await HostelService(db).list_rooms(school_id, block_id)


@router.post("/allocations", response_model=schemas.AllocationOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def allocate(school_id: uuid.UUID, data: schemas.AllocationCreate, db: DbDep) -> schemas.AllocationOut:
    return await HostelService(db).allocate(school_id, data)


@router.post("/allocations/{allocation_id}/vacate", response_model=schemas.AllocationOut, dependencies=[_edit])
async def vacate(school_id: uuid.UUID, allocation_id: uuid.UUID, db: DbDep) -> schemas.AllocationOut:
    return await HostelService(db).vacate(school_id, allocation_id)


@router.get("/allocations", response_model=list[schemas.AllocationOut], dependencies=[_view])
async def list_allocations(
    school_id: uuid.UUID,
    db: DbDep,
    room_id: uuid.UUID | None = Query(default=None),
    active_only: bool = Query(default=False),
) -> list[schemas.AllocationOut]:
    return await HostelService(db).list_allocations(school_id, room_id, active_only)
