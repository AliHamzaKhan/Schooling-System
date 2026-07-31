"""School information service — reads/writes the public school profile."""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import not_found
from app.models.school import School
from app.models.school_info import SchoolInfo
from app.modules.schoolinfo import schemas


class SchoolInfoService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _school(self, school_id: uuid.UUID) -> School:
        school = await self.db.get(School, school_id)
        if school is None:
            raise not_found("School not found")
        return school

    async def _info(self, school_id: uuid.UUID) -> SchoolInfo | None:
        return await self.db.scalar(
            select(SchoolInfo).where(SchoolInfo.school_id == school_id)
        )

    async def get(self, school_id: uuid.UUID) -> schemas.SchoolInfoOut:
        school = await self._school(school_id)
        info = await self._info(school_id)
        return schemas.SchoolInfoOut(
            name=school.name,
            address=school.address,
            contact_email=school.contact_email,
            contact_phone=school.contact_phone,
            about=info.about if info else None,
            achievements=[
                schemas.Achievement(**a) for a in (info.achievements if info else [])
            ],
            uniform_image_url=info.uniform_image_url if info else None,
        )

    async def upsert(
        self, school_id: uuid.UUID, data: schemas.SchoolInfoUpdate
    ) -> schemas.SchoolInfoOut:
        await self._school(school_id)
        info = await self._info(school_id)
        if info is None:
            info = SchoolInfo(school_id=school_id, achievements=[])
            self.db.add(info)
        if data.about is not None:
            info.about = data.about
        if data.achievements is not None:
            info.achievements = [a.model_dump() for a in data.achievements]
        if data.uniform_image_url is not None:
            info.uniform_image_url = data.uniform_image_url
        await self.db.flush()
        return await self.get(school_id)
