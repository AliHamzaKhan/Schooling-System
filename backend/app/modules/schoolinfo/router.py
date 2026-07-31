"""School information endpoints.

Any active school member (students, guardians, staff) can read the public
school info; only the Headmaster can edit the descriptive content.
"""
import uuid

from fastapi import APIRouter, Depends

from app.core.deps import DbDep, require_school_admin, require_school_member
from app.modules.schoolinfo import schemas
from app.modules.schoolinfo.service import SchoolInfoService

router = APIRouter(prefix="/schools/{school_id}/info", tags=["School Info"])


@router.get("", response_model=schemas.SchoolInfoOut, dependencies=[Depends(require_school_member)])
async def get_info(school_id: uuid.UUID, db: DbDep) -> schemas.SchoolInfoOut:
    return await SchoolInfoService(db).get(school_id)


@router.put("", response_model=schemas.SchoolInfoOut, dependencies=[Depends(require_school_admin)])
async def set_info(
    school_id: uuid.UUID, data: schemas.SchoolInfoUpdate, db: DbDep
) -> schemas.SchoolInfoOut:
    return await SchoolInfoService(db).upsert(school_id, data)
