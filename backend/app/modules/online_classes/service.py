"""Online Classes Service."""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import bad_request, not_found
from app.models.academic import Section, Subject
from app.models.online_class import OnlineClass
from app.modules.online_classes import schemas


class OnlineClassService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _get_scoped(self, model, school_id: uuid.UUID, obj_id: uuid.UUID, label: str):
        obj = await self.db.get(model, obj_id)
        if obj is None or obj.school_id != school_id:
            raise not_found(f"{label} not found in this school")
        return obj

    async def schedule(self, school_id: uuid.UUID, data: schemas.OnlineClassCreate, host_id: uuid.UUID) -> OnlineClass:
        await self._get_scoped(Section, school_id, data.section_id, "Section")
        if data.subject_id is not None:
            await self._get_scoped(Subject, school_id, data.subject_id, "Subject")
        oc = OnlineClass(
            school_id=school_id,
            section_id=data.section_id,
            subject_id=data.subject_id,
            title=data.title,
            meeting_url=data.meeting_url,
            scheduled_start=data.scheduled_start,
            scheduled_end=data.scheduled_end,
            status="scheduled",
            host_id=host_id,
        )
        self.db.add(oc)
        await self.db.flush()
        return oc

    async def list_classes(self, school_id: uuid.UUID, section_id: uuid.UUID | None = None) -> list[OnlineClass]:
        stmt = select(OnlineClass).where(OnlineClass.school_id == school_id)
        if section_id is not None:
            stmt = stmt.where(OnlineClass.section_id == section_id)
        stmt = stmt.order_by(OnlineClass.scheduled_start.desc())
        return list((await self.db.execute(stmt)).scalars().all())

    async def update(self, school_id: uuid.UUID, class_id: uuid.UUID, data: schemas.OnlineClassUpdate) -> OnlineClass:
        oc = await self._get_scoped(OnlineClass, school_id, class_id, "Online class")
        payload = data.model_dump(exclude_unset=True)
        start = payload.get("scheduled_start", oc.scheduled_start)
        end = payload.get("scheduled_end", oc.scheduled_end)
        if end <= start:
            raise bad_request("scheduled_end must be after scheduled_start")
        for field, value in payload.items():
            setattr(oc, field, value)
        await self.db.flush()
        return oc

    async def delete(self, school_id: uuid.UUID, class_id: uuid.UUID) -> None:
        oc = await self._get_scoped(OnlineClass, school_id, class_id, "Online class")
        await self.db.delete(oc)
        await self.db.flush()
