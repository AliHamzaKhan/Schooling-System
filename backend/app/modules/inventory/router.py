"""Inventory endpoints, gated by the INVENTORY module."""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import CurrentUser, DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.inventory import schemas
from app.modules.inventory.service import InventoryService

router = APIRouter(prefix="/schools/{school_id}/inventory", tags=["Inventory"])

_view = Depends(require_school_permission(Module.INVENTORY, PA.VIEW))
_create = Depends(require_school_permission(Module.INVENTORY, PA.CREATE))
_edit = Depends(require_school_permission(Module.INVENTORY, PA.EDIT))
_delete = Depends(require_school_permission(Module.INVENTORY, PA.DELETE))


@router.post("/items", response_model=schemas.ItemOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_item(school_id: uuid.UUID, data: schemas.ItemCreate, db: DbDep) -> schemas.ItemOut:
    return await InventoryService(db).create_item(school_id, data)


@router.get("/items", response_model=list[schemas.ItemOut], dependencies=[_view])
async def list_items(
    school_id: uuid.UUID, db: DbDep, low_stock_only: bool = Query(default=False)
) -> list[schemas.ItemOut]:
    return await InventoryService(db).list_items(school_id, low_stock_only)


@router.patch("/items/{item_id}", response_model=schemas.ItemOut, dependencies=[_edit])
async def update_item(school_id: uuid.UUID, item_id: uuid.UUID, data: schemas.ItemUpdate, db: DbDep) -> schemas.ItemOut:
    return await InventoryService(db).update_item(school_id, item_id, data)


@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_item(school_id: uuid.UUID, item_id: uuid.UUID, db: DbDep) -> None:
    await InventoryService(db).delete_item(school_id, item_id)


@router.post("/items/{item_id}/movements", response_model=schemas.TransactionOut, status_code=status.HTTP_201_CREATED, dependencies=[_edit])
async def move_stock(
    school_id: uuid.UUID, item_id: uuid.UUID, data: schemas.StockMovement, db: DbDep, current_user: CurrentUser
) -> schemas.TransactionOut:
    return await InventoryService(db).move_stock(school_id, item_id, data, current_user.id)


@router.get("/items/{item_id}/transactions", response_model=list[schemas.TransactionOut], dependencies=[_view])
async def list_transactions(school_id: uuid.UUID, item_id: uuid.UUID, db: DbDep) -> list[schemas.TransactionOut]:
    return await InventoryService(db).list_transactions(school_id, item_id)
