"""Student document endpoints, gated by the STUDENT_MANAGEMENT module.

Listing a student's documents also passes the per-student access check so a
guardian/student can read their own documents, while staff manage them.
"""
import uuid

from fastapi import APIRouter, Depends, status

from app.core.deps import (
    CurrentUser,
    DbDep,
    require_school_permission,
    verify_student_access,
)
from app.core.enums import Module, PermissionAction as PA
from app.modules.documents import schemas
from app.modules.documents.service import DocumentService

router = APIRouter(prefix="/schools/{school_id}/students/{student_id}/documents", tags=["Student Documents"])

_create = Depends(require_school_permission(Module.STUDENT_MANAGEMENT, PA.CREATE))
_delete = Depends(require_school_permission(Module.STUDENT_MANAGEMENT, PA.DELETE))


@router.post("", response_model=schemas.DocumentOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def add_document(
    school_id: uuid.UUID,
    student_id: uuid.UUID,
    data: schemas.DocumentCreate,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.DocumentOut:
    return await DocumentService(db).add(school_id, student_id, data, current_user.id)


@router.get("", response_model=list[schemas.DocumentOut], dependencies=[Depends(verify_student_access)])
async def list_documents(
    school_id: uuid.UUID, student_id: uuid.UUID, db: DbDep
) -> list[schemas.DocumentOut]:
    return await DocumentService(db).list_for_student(school_id, student_id)


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_document(
    school_id: uuid.UUID, student_id: uuid.UUID, document_id: uuid.UUID, db: DbDep
) -> None:
    await DocumentService(db).delete(school_id, document_id)
