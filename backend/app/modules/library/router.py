"""Library endpoints, gated by the LIBRARY module."""
import uuid

from fastapi import APIRouter, Depends, Query, status

from app.core.deps import DbDep, require_school_permission
from app.core.enums import Module, PermissionAction as PA
from app.modules.library import schemas
from app.modules.library.service import LibraryService

router = APIRouter(prefix="/schools/{school_id}/library", tags=["Library"])

_view = Depends(require_school_permission(Module.LIBRARY, PA.VIEW))
_create = Depends(require_school_permission(Module.LIBRARY, PA.CREATE))
_edit = Depends(require_school_permission(Module.LIBRARY, PA.EDIT))
_delete = Depends(require_school_permission(Module.LIBRARY, PA.DELETE))


# -------------------------------- books --------------------------------- #


@router.post("/books", response_model=schemas.BookOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def create_book(school_id: uuid.UUID, data: schemas.BookCreate, db: DbDep) -> schemas.BookOut:
    return await LibraryService(db).create_book(school_id, data)


@router.get("/books", response_model=list[schemas.BookOut], dependencies=[_view])
async def list_books(school_id: uuid.UUID, db: DbDep) -> list[schemas.BookOut]:
    return await LibraryService(db).list_books(school_id)


@router.patch("/books/{book_id}", response_model=schemas.BookOut, dependencies=[_edit])
async def update_book(school_id: uuid.UUID, book_id: uuid.UUID, data: schemas.BookUpdate, db: DbDep) -> schemas.BookOut:
    return await LibraryService(db).update_book(school_id, book_id, data)


@router.delete("/books/{book_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[_delete])
async def delete_book(school_id: uuid.UUID, book_id: uuid.UUID, db: DbDep) -> None:
    await LibraryService(db).delete_book(school_id, book_id)


# -------------------------------- loans --------------------------------- #


@router.post("/books/{book_id}/issue", response_model=schemas.LoanOut, status_code=status.HTTP_201_CREATED, dependencies=[_create])
async def issue_book(school_id: uuid.UUID, book_id: uuid.UUID, data: schemas.IssueRequest, db: DbDep) -> schemas.LoanOut:
    return await LibraryService(db).issue(school_id, book_id, data)


@router.post("/loans/{loan_id}/return", response_model=schemas.LoanOut, dependencies=[_edit])
async def return_loan(school_id: uuid.UUID, loan_id: uuid.UUID, data: schemas.ReturnRequest, db: DbDep) -> schemas.LoanOut:
    return await LibraryService(db).return_loan(school_id, loan_id, data)


@router.get("/loans", response_model=list[schemas.LoanOut], dependencies=[_view])
async def list_loans(
    school_id: uuid.UUID,
    db: DbDep,
    member_id: uuid.UUID | None = Query(default=None),
    outstanding_only: bool = Query(default=False),
) -> list[schemas.LoanOut]:
    return await LibraryService(db).list_loans(school_id, member_id, outstanding_only)
