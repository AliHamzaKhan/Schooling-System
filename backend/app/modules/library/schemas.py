"""Library schemas."""
import uuid
from datetime import date

from pydantic import BaseModel, ConfigDict, Field, computed_field


class BookCreate(BaseModel):
    title: str = Field(min_length=1, max_length=250)
    author: str | None = Field(default=None, max_length=200)
    isbn: str | None = Field(default=None, max_length=20)
    category: str | None = Field(default=None, max_length=100)
    total_copies: int = Field(default=1, ge=1)


class BookUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=250)
    author: str | None = Field(default=None, max_length=200)
    category: str | None = Field(default=None, max_length=100)
    total_copies: int | None = Field(default=None, ge=1)


class BookOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    title: str
    author: str | None = None
    isbn: str | None = None
    category: str | None = None
    total_copies: int
    available_copies: int

    @computed_field
    @property
    def is_available(self) -> bool:
        return self.available_copies > 0


class IssueRequest(BaseModel):
    member_id: uuid.UUID
    due_date: date
    borrowed_on: date | None = None


class ReturnRequest(BaseModel):
    returned_on: date | None = None
    fine: float | None = Field(default=None, ge=0)


class LoanOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    school_id: uuid.UUID
    book_id: uuid.UUID
    member_id: uuid.UUID
    borrowed_on: date
    due_date: date
    returned_on: date | None = None
    status: str
    fine: float | None = None

    @computed_field
    @property
    def is_overdue(self) -> bool:
        return self.status == "borrowed" and self.due_date < date.today()
