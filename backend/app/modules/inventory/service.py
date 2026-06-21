"""Inventory Service: items and stock movements."""
import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import bad_request, not_found
from app.models.inventory import InventoryItem, StockTransaction
from app.modules.inventory import schemas


class InventoryService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _get_item(self, school_id: uuid.UUID, item_id: uuid.UUID) -> InventoryItem:
        item = await self.db.get(InventoryItem, item_id)
        if item is None or item.school_id != school_id:
            raise not_found("Item not found in this school")
        return item

    # ------------------------------- items ------------------------------- #

    async def create_item(self, school_id: uuid.UUID, data: schemas.ItemCreate) -> InventoryItem:
        dupe = await self.db.scalar(
            select(InventoryItem).where(
                InventoryItem.school_id == school_id, InventoryItem.name == data.name
            )
        )
        if dupe is not None:
            raise bad_request(f"Item '{data.name}' already exists")
        item = InventoryItem(school_id=school_id, quantity=0, **data.model_dump())
        self.db.add(item)
        await self.db.flush()
        return item

    async def list_items(self, school_id: uuid.UUID, low_stock_only: bool = False) -> list[InventoryItem]:
        result = await self.db.execute(
            select(InventoryItem).where(InventoryItem.school_id == school_id).order_by(InventoryItem.name)
        )
        items = list(result.scalars().all())
        if low_stock_only:
            items = [i for i in items if i.quantity <= i.reorder_level]
        return items

    async def update_item(self, school_id: uuid.UUID, item_id: uuid.UUID, data: schemas.ItemUpdate) -> InventoryItem:
        item = await self._get_item(school_id, item_id)
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(item, field, value)
        await self.db.flush()
        return item

    async def delete_item(self, school_id: uuid.UUID, item_id: uuid.UUID) -> None:
        item = await self._get_item(school_id, item_id)
        await self.db.delete(item)
        await self.db.flush()

    # ----------------------------- movements ----------------------------- #

    async def move_stock(
        self, school_id: uuid.UUID, item_id: uuid.UUID, data: schemas.StockMovement, recorded_by: uuid.UUID
    ) -> StockTransaction:
        item = await self._get_item(school_id, item_id)
        if data.type == "out":
            if data.quantity > item.quantity:
                raise bad_request(
                    f"Insufficient stock: requested {data.quantity}, available {item.quantity}"
                )
            item.quantity -= data.quantity
        else:  # "in"
            item.quantity += data.quantity

        txn = StockTransaction(
            school_id=school_id,
            item_id=item_id,
            type=data.type,
            quantity=data.quantity,
            reason=data.reason,
            occurred_on=data.occurred_on or date.today(),
            recorded_by=recorded_by,
        )
        self.db.add(txn)
        await self.db.flush()
        return txn

    async def list_transactions(self, school_id: uuid.UUID, item_id: uuid.UUID) -> list[StockTransaction]:
        await self._get_item(school_id, item_id)
        result = await self.db.execute(
            select(StockTransaction).where(StockTransaction.item_id == item_id).order_by(StockTransaction.occurred_on.desc())
        )
        return list(result.scalars().all())
