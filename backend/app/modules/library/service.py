"""Library Service: book catalogue and loans."""
import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import LoanStatus
from app.core.exceptions import bad_request, not_found
from app.models.library import Book, BookLoan
from app.models.user import User
from app.modules.library import schemas


class LibraryService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------ helpers ------------------------------ #

    async def _get_book(self, school_id: uuid.UUID, book_id: uuid.UUID) -> Book:
        book = await self.db.get(Book, book_id)
        if book is None or book.school_id != school_id:
            raise not_found("Book not found in this school")
        return book

    async def _validate_member(self, school_id: uuid.UUID, member_id: uuid.UUID) -> None:
        member = await self.db.get(User, member_id)
        if member is None or member.school_id != school_id:
            raise bad_request("Member is not a user of this school")

    # ------------------------------- books ------------------------------- #

    async def create_book(self, school_id: uuid.UUID, data: schemas.BookCreate) -> Book:
        book = Book(
            school_id=school_id,
            title=data.title,
            author=data.author,
            isbn=data.isbn,
            category=data.category,
            total_copies=data.total_copies,
            available_copies=data.total_copies,
        )
        self.db.add(book)
        await self.db.flush()
        return book

    async def list_books(self, school_id: uuid.UUID) -> list[Book]:
        result = await self.db.execute(
            select(Book).where(Book.school_id == school_id).order_by(Book.title)
        )
        return list(result.scalars().all())

    async def update_book(
        self, school_id: uuid.UUID, book_id: uuid.UUID, data: schemas.BookUpdate
    ) -> Book:
        book = await self._get_book(school_id, book_id)
        payload = data.model_dump(exclude_unset=True)
        if "total_copies" in payload:
            new_total = payload["total_copies"]
            on_loan = book.total_copies - book.available_copies
            if new_total < on_loan:
                raise bad_request(
                    f"total_copies ({new_total}) cannot be less than copies on loan ({on_loan})"
                )
            book.available_copies = new_total - on_loan
        for field, value in payload.items():
            setattr(book, field, value)
        await self.db.flush()
        return book

    async def delete_book(self, school_id: uuid.UUID, book_id: uuid.UUID) -> None:
        book = await self._get_book(school_id, book_id)
        if book.available_copies != book.total_copies:
            raise bad_request("Cannot delete a book that has copies on loan")
        await self.db.delete(book)
        await self.db.flush()

    # ------------------------------- loans ------------------------------- #

    async def issue(self, school_id: uuid.UUID, book_id: uuid.UUID, data: schemas.IssueRequest) -> BookLoan:
        book = await self._get_book(school_id, book_id)
        await self._validate_member(school_id, data.member_id)
        if book.available_copies <= 0:
            raise bad_request("No copies available to issue")

        loan = BookLoan(
            school_id=school_id,
            book_id=book_id,
            member_id=data.member_id,
            borrowed_on=data.borrowed_on or date.today(),
            due_date=data.due_date,
            status=LoanStatus.BORROWED.value,
        )
        book.available_copies -= 1
        self.db.add(loan)
        await self.db.flush()
        return loan

    async def return_loan(
        self, school_id: uuid.UUID, loan_id: uuid.UUID, data: schemas.ReturnRequest
    ) -> BookLoan:
        loan = await self.db.get(BookLoan, loan_id)
        if loan is None or loan.school_id != school_id:
            raise not_found("Loan not found in this school")
        if loan.status == LoanStatus.RETURNED.value:
            raise bad_request("This loan has already been returned")

        returned_on = data.returned_on or date.today()
        loan.returned_on = returned_on
        loan.status = LoanStatus.RETURNED.value
        if data.fine is not None:
            loan.fine = data.fine
        elif returned_on > loan.due_date:
            # default fine: flag late return with 0 unless caller sets one
            loan.fine = loan.fine or 0.0

        book = await self.db.get(Book, loan.book_id)
        if book is not None:
            book.available_copies = min(book.total_copies, book.available_copies + 1)
        await self.db.flush()
        return loan

    async def list_loans(
        self, school_id: uuid.UUID, member_id: uuid.UUID | None = None,
        outstanding_only: bool = False,
    ) -> list[BookLoan]:
        stmt = select(BookLoan).where(BookLoan.school_id == school_id)
        if member_id is not None:
            stmt = stmt.where(BookLoan.member_id == member_id)
        if outstanding_only:
            stmt = stmt.where(BookLoan.status == LoanStatus.BORROWED.value)
        stmt = stmt.order_by(BookLoan.borrowed_on.desc())
        return list((await self.db.execute(stmt)).scalars().all())
