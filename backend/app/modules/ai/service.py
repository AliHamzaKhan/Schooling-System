"""AI Features Service."""
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.ai import AIInteraction
from app.modules.ai import schemas
from app.modules.ai.providers import ai_provider


class AIService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def generate(self, school_id: uuid.UUID, data: schemas.GenerateRequest, created_by: uuid.UUID) -> AIInteraction:
        result = await ai_provider.generate(data.prompt, data.system)
        interaction = AIInteraction(
            school_id=school_id,
            feature=data.feature,
            prompt=data.prompt,
            response=result.text,
            provider=result.provider,
            created_by=created_by,
        )
        self.db.add(interaction)
        await self.db.flush()
        return interaction

    async def list_interactions(self, school_id: uuid.UUID, limit: int = 50) -> list[AIInteraction]:
        result = await self.db.execute(
            select(AIInteraction).where(AIInteraction.school_id == school_id)
            .order_by(AIInteraction.created_at.desc()).limit(limit)
        )
        return list(result.scalars().all())
