"""Course content endpoints.

Reading is open to any active school member (students consume the material);
authoring (create/update/delete of courses, books, chapters, notes) is limited
to the school's Headmaster. Reading progress is per-user self-service.
"""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import (
    CurrentUser,
    DbDep,
    require_school_admin,
    require_school_member,
)
from app.core.enums import SystemRole
from app.models.user import User
from app.modules.courses import schemas
from app.modules.courses.service import CourseService

router = APIRouter(prefix="/schools/{school_id}/courses", tags=["Courses"])

_member = Depends(require_school_member)
_admin = Depends(require_school_admin)


def _student_id(current_user: User) -> uuid.UUID | None:
    return (
        current_user.id
        if any(role.code == SystemRole.STUDENT.value for role in current_user.roles)
        else None
    )


# ------------------------------- courses -------------------------------- #


@router.get("", response_model=list[schemas.CourseListOut])
async def list_courses(
    school_id: uuid.UUID,
    db: DbDep,
    current_user: User = Depends(require_school_member),
    section_id: uuid.UUID | None = Query(default=None),
) -> list[schemas.CourseListOut]:
    """Courses in the school, optionally narrowed to one class+section.

    A student caller only sees courses offered to the section(s) they are
    enrolled in (plus legacy school-wide courses); staff/admins see all.
    """
    return await CourseService(db).list_courses(
        school_id,
        section_id,
        student_id=_student_id(current_user),
    )


@router.post("", response_model=schemas.CourseOut, status_code=status.HTTP_201_CREATED, dependencies=[_admin])
async def create_course(
    school_id: uuid.UUID, data: schemas.CourseCreate, db: DbDep, current_user: CurrentUser
) -> schemas.CourseOut:
    return await CourseService(db).create_course(school_id, data, current_user.id)


@router.get("/{course_id}", response_model=schemas.CourseOut, dependencies=[_member])
async def get_course(
    school_id: uuid.UUID, course_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.CourseOut:
    return await CourseService(db).get_course(school_id, course_id, _student_id(current_user))


@router.patch("/{course_id}", response_model=schemas.CourseOut, dependencies=[_admin])
async def update_course(
    school_id: uuid.UUID, course_id: uuid.UUID, data: schemas.CourseUpdate, db: DbDep
) -> schemas.CourseOut:
    return await CourseService(db).update_course(school_id, course_id, data)


@router.delete("/{course_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_admin])
async def delete_course(school_id: uuid.UUID, course_id: uuid.UUID, db: DbDep) -> None:
    await CourseService(db).delete_course(school_id, course_id)


# -------------------------------- books --------------------------------- #


@router.get("/{course_id}/books", response_model=list[schemas.BookListOut], dependencies=[_member])
async def list_books(
    school_id: uuid.UUID, course_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> list[schemas.BookListOut]:
    return await CourseService(db).list_books(school_id, course_id, _student_id(current_user))


@router.post("/{course_id}/books", response_model=schemas.BookOut, status_code=status.HTTP_201_CREATED, dependencies=[_admin])
async def add_book(
    school_id: uuid.UUID, course_id: uuid.UUID, data: schemas.BookCreate, db: DbDep
) -> schemas.BookOut:
    return await CourseService(db).add_book(school_id, course_id, data)


@router.get("/books/{book_id}/chapters", response_model=list[schemas.ChapterBrief], dependencies=[_member])
async def list_chapters(
    school_id: uuid.UUID, book_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> list[schemas.ChapterBrief]:
    """Chapter list (table of contents) for a book — titles only, no bodies."""
    chapters = await CourseService(db).list_chapters(
        school_id, book_id, _student_id(current_user)
    )
    return [schemas.ChapterBrief.model_validate(c) for c in chapters]


@router.post("/books/{book_id}/chapters", response_model=schemas.ChapterOut, status_code=status.HTTP_201_CREATED, dependencies=[_admin])
async def add_chapter(
    school_id: uuid.UUID, book_id: uuid.UUID, data: schemas.ChapterCreate, db: DbDep
) -> schemas.ChapterOut:
    chapter = await CourseService(db).add_chapter(school_id, book_id, data)
    return schemas.ChapterOut.model_validate(chapter)


@router.get("/chapters/{chapter_id}", response_model=schemas.ChapterOut, dependencies=[_member])
async def get_chapter(
    school_id: uuid.UUID, chapter_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.ChapterOut:
    """Full chapter with its text body (the reading screen)."""
    chapter = await CourseService(db).get_chapter(
        school_id, chapter_id, _student_id(current_user)
    )
    return schemas.ChapterOut.model_validate(chapter)


# -------------------------------- notes --------------------------------- #


@router.get("/{course_id}/notes", response_model=list[schemas.NoteBrief], dependencies=[_member])
async def list_notes(
    school_id: uuid.UUID, course_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> list[schemas.NoteBrief]:
    notes = await CourseService(db).list_notes(school_id, course_id, _student_id(current_user))
    return [schemas.NoteBrief.model_validate(n) for n in notes]


@router.post("/{course_id}/notes", response_model=schemas.NoteOut, status_code=status.HTTP_201_CREATED, dependencies=[_admin])
async def add_note(
    school_id: uuid.UUID, course_id: uuid.UUID, data: schemas.NoteCreate, db: DbDep
) -> schemas.NoteOut:
    note = await CourseService(db).add_note(school_id, course_id, data)
    return schemas.NoteOut.model_validate(note)


@router.get("/notes/{note_id}", response_model=schemas.NoteOut, dependencies=[_member])
async def get_note(
    school_id: uuid.UUID, note_id: uuid.UUID, db: DbDep, current_user: CurrentUser
) -> schemas.NoteOut:
    """Full note with its text body (the reading screen)."""
    note = await CourseService(db).get_note(school_id, note_id, _student_id(current_user))
    return schemas.NoteOut.model_validate(note)


# --------------------------- reading progress --------------------------- #


@router.get("/progress/lookup", response_model=schemas.ReadingProgressOut, dependencies=[_member])
async def get_progress(
    school_id: uuid.UUID,
    db: DbDep,
    current_user: CurrentUser,
    resource_type: str = Query(pattern="^(book|note)$"),
    resource_id: uuid.UUID = Query(...),
) -> schemas.ReadingProgressOut:
    """The caller's saved reading position for a book/note (page 0 if none)."""
    progress = await CourseService(db).get_progress(
        school_id, current_user.id, resource_type, resource_id, _student_id(current_user)
    )
    if progress is None:
        return schemas.ReadingProgressOut(
            resource_type=resource_type, resource_id=resource_id, chapter_id=None, page=0
        )
    return schemas.ReadingProgressOut.model_validate(progress)


@router.put("/progress", response_model=schemas.ReadingProgressOut, dependencies=[_member])
async def set_progress(
    school_id: uuid.UUID,
    data: schemas.ReadingProgressSet,
    db: DbDep,
    current_user: CurrentUser,
) -> schemas.ReadingProgressOut:
    """Save the caller's reading position for a book/note."""
    progress = await CourseService(db).set_progress(
        school_id, current_user.id, data, _student_id(current_user)
    )
    return schemas.ReadingProgressOut.model_validate(progress)
