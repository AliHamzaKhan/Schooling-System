"""Small, reusable offset-pagination contract for bounded list endpoints.

The contract intentionally keeps existing list response shapes intact.  New
endpoints can depend on :class:`OffsetPage` and apply it to an already scoped,
ordered SQLAlchemy statement.
"""
from typing import Any

from fastapi import Query


class OffsetPage:
    """Validated bounded page request with a conservative default page size."""

    def __init__(
        self,
        limit: int = Query(default=50, ge=1, le=100),
        offset: int = Query(default=0, ge=0),
    ) -> None:
        self.limit = limit
        self.offset = offset

    def apply(self, statement: Any) -> Any:
        """Apply pagination after the caller has enforced scope and ordering."""
        return statement.offset(self.offset).limit(self.limit)
