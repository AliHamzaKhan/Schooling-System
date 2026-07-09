"""Lesson planning & teaching-progress endpoints, gated by the HOMEWORK module.

Lesson plans are teacher-owned coursework, so they share the HOMEWORK
permission surface that teachers already hold.
"""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import CurrentUser, DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.lessons import schemas
from app.modules.lessons.service import LessonService

router = APIRouter(prefix="/schools/{school_id}/lessons", tags=["Lesson Planning"])

_view = Depends(require_school_permission(Module.HOMEWORK, PA.VIEW))
_create = Depends(require_school_permission(Module.HOMEWORK, PA.CREATE))
_edit = Depends(require_school_permission(Module.HOMEWORK, PA.EDIT))
_delete = Depends(require_school_permission(Module.HOMEWORK, PA.DELETE))


@router.post("", response_model=schemas.LessonOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_lesson(
    school_id: uuid.UUID, data: schemas.LessonCreate, db: DbDep, current_user: CurrentUser
) -> schemas.LessonOut:
    return await LessonService(db).create(school_id, data, current_user.id)


@router.get("", response_model=list[schemas.LessonOut], dependencies=[_view])
async def list_lessons(
    school_id: uuid.UUID,
    db: DbDep,
    section_id: uuid.UUID | None = Query(default=None),
    subject_id: uuid.UUID | None = Query(default=None),
) -> list[schemas.LessonOut]:
    return await LessonService(db).list_lessons(school_id, section_id, subject_id)


@router.patch("/{lesson_id}", response_model=schemas.LessonOut, dependencies=[_edit])
async def update_lesson(
    school_id: uuid.UUID, lesson_id: uuid.UUID, data: schemas.LessonUpdate, db: DbDep
) -> schemas.LessonOut:
    return await LessonService(db).update(school_id, lesson_id, data)


@router.delete("/{lesson_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_lesson(school_id: uuid.UUID, lesson_id: uuid.UUID, db: DbDep) -> None:
    await LessonService(db).delete(school_id, lesson_id)


@router.get("/progress", response_model=schemas.TeachingProgress, dependencies=[_view])
async def teaching_progress(
    school_id: uuid.UUID,
    db: DbDep,
    section_id: uuid.UUID = Query(...),
    subject_id: uuid.UUID = Query(...),
) -> schemas.TeachingProgress:
    return await LessonService(db).progress(school_id, section_id, subject_id)
