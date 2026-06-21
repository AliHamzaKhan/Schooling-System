"""AI Features endpoints, gated by the AI_FEATURES module."""
import uuid

from fastapi import APIRouter, Depends, status

from app.core.deps import CurrentUser, DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.ai import schemas
from app.modules.ai.service import AIService

router = APIRouter(prefix="/schools/{school_id}/ai", tags=["AI Features"])

_view = Depends(require_school_permission(Module.AI_FEATURES, PA.VIEW))
_create = Depends(require_school_permission(Module.AI_FEATURES, PA.CREATE))


@router.post("/generate", response_model=schemas.GenerateResponse, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def generate(school_id: uuid.UUID, data: schemas.GenerateRequest, db: DbDep, current_user: CurrentUser) -> schemas.GenerateResponse:
    interaction = await AIService(db).generate(school_id, data, current_user.id)
    return schemas.GenerateResponse(
        id=interaction.id, feature=interaction.feature,
        response=interaction.response, provider=interaction.provider,
    )


@router.get("/interactions", response_model=list[schemas.InteractionOut], dependencies=[_view])
async def list_interactions(school_id: uuid.UUID, db: DbDep) -> list[schemas.InteractionOut]:
    return await AIService(db).list_interactions(school_id)
