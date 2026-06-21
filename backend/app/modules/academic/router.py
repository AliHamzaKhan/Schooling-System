"""Academic Service endpoints, gated by the TIMETABLE module permission.

Writes require create/edit/delete; reads require view. School scoping is enforced
by require_school_permission (caller must belong to the path school, or be Super
Admin).
"""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.academic import schemas
from app.modules.academic.service import AcademicService

router = APIRouter(prefix="/schools/{school_id}/academic", tags=["Academic"])

_view = Depends(require_school_permission(Module.TIMETABLE, PA.VIEW))
_create = Depends(require_school_permission(Module.TIMETABLE, PA.CREATE))
_edit = Depends(require_school_permission(Module.TIMETABLE, PA.EDIT))
_delete = Depends(require_school_permission(Module.TIMETABLE, PA.DELETE))


# -------------------------------- classes ------------------------------- #


@router.post("/classes", response_model=schemas.ClassOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_class(school_id: uuid.UUID, data: schemas.ClassCreate, db: DbDep) -> schemas.ClassOut:
    return await AcademicService(db).create_class(school_id, data)


@router.get("/classes", response_model=list[schemas.ClassOut], dependencies=[_view])
async def list_classes(school_id: uuid.UUID, db: DbDep) -> list[schemas.ClassOut]:
    return await AcademicService(db).list_classes(school_id)


@router.patch("/classes/{class_id}", response_model=schemas.ClassOut, dependencies=[_edit])
async def update_class(
    school_id: uuid.UUID, class_id: uuid.UUID, data: schemas.ClassUpdate, db: DbDep
) -> schemas.ClassOut:
    return await AcademicService(db).update_class(school_id, class_id, data)


@router.delete("/classes/{class_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_class(school_id: uuid.UUID, class_id: uuid.UUID, db: DbDep) -> None:
    await AcademicService(db).delete_class(school_id, class_id)


# -------------------------------- sections ------------------------------ #


@router.post("/classes/{class_id}/sections", response_model=schemas.SectionOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_section(
    school_id: uuid.UUID, class_id: uuid.UUID, data: schemas.SectionCreate, db: DbDep
) -> schemas.SectionOut:
    return await AcademicService(db).create_section(school_id, class_id, data)


@router.get("/classes/{class_id}/sections", response_model=list[schemas.SectionOut], dependencies=[_view])
async def list_sections(
    school_id: uuid.UUID, class_id: uuid.UUID, db: DbDep
) -> list[schemas.SectionOut]:
    return await AcademicService(db).list_sections(school_id, class_id)


@router.patch("/sections/{section_id}", response_model=schemas.SectionOut, dependencies=[_edit])
async def update_section(
    school_id: uuid.UUID, section_id: uuid.UUID, data: schemas.SectionUpdate, db: DbDep
) -> schemas.SectionOut:
    return await AcademicService(db).update_section(school_id, section_id, data)


@router.delete("/sections/{section_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_section(school_id: uuid.UUID, section_id: uuid.UUID, db: DbDep) -> None:
    await AcademicService(db).delete_section(school_id, section_id)


# -------------------------------- subjects ------------------------------ #


@router.post("/subjects", response_model=schemas.SubjectOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_subject(school_id: uuid.UUID, data: schemas.SubjectCreate, db: DbDep) -> schemas.SubjectOut:
    return await AcademicService(db).create_subject(school_id, data)


@router.get("/subjects", response_model=list[schemas.SubjectOut], dependencies=[_view])
async def list_subjects(school_id: uuid.UUID, db: DbDep) -> list[schemas.SubjectOut]:
    return await AcademicService(db).list_subjects(school_id)


@router.patch("/subjects/{subject_id}", response_model=schemas.SubjectOut, dependencies=[_edit])
async def update_subject(
    school_id: uuid.UUID, subject_id: uuid.UUID, data: schemas.SubjectUpdate, db: DbDep
) -> schemas.SubjectOut:
    return await AcademicService(db).update_subject(school_id, subject_id, data)


@router.delete("/subjects/{subject_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_subject(school_id: uuid.UUID, subject_id: uuid.UUID, db: DbDep) -> None:
    await AcademicService(db).delete_subject(school_id, subject_id)


# -------------------------------- timetable ----------------------------- #


@router.post("/timetable", response_model=schemas.TimetableSlotOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_slot(school_id: uuid.UUID, data: schemas.TimetableSlotCreate, db: DbDep) -> schemas.TimetableSlotOut:
    return await AcademicService(db).create_slot(school_id, data)


@router.get("/timetable", response_model=list[schemas.TimetableSlotOut], dependencies=[_view])
async def list_slots(
    school_id: uuid.UUID, db: DbDep, section_id: uuid.UUID | None = Query(default=None)
) -> list[schemas.TimetableSlotOut]:
    return await AcademicService(db).list_slots(school_id, section_id)


@router.patch("/timetable/{slot_id}", response_model=schemas.TimetableSlotOut, dependencies=[_edit])
async def update_slot(
    school_id: uuid.UUID, slot_id: uuid.UUID, data: schemas.TimetableSlotUpdate, db: DbDep
) -> schemas.TimetableSlotOut:
    return await AcademicService(db).update_slot(school_id, slot_id, data)


@router.delete("/timetable/{slot_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_slot(school_id: uuid.UUID, slot_id: uuid.UUID, db: DbDep) -> None:
    await AcademicService(db).delete_slot(school_id, slot_id)
