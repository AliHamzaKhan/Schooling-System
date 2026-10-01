"""Deterministic O03 data for tenant-fair pagination checks.

This module deliberately lives in ``tests``: it is only for an isolated,
disposable database.  Run its executable proof with::

    python scripts/run_isolated_tests.py --from-local-config -- -q \
        tests/test_o03_representative_fixture.py

The isolated runner creates a restricted role and a fresh database, then
removes both after pytest exits.  Do not call this helper against a school
database containing real data.
"""
from dataclasses import dataclass
from datetime import date, timedelta
from uuid import UUID

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.models.fees import Invoice
from tests.conftest import TEST_URL
from tests.test_broadcast_isolation import another_school
from tests.utils import create_user


REPRESENTATIVE_PAGE_SIZE = 50
REPRESENTATIVE_VISIBLE_INVOICES = 105
REPRESENTATIVE_FOREIGN_INVOICES = 7


@dataclass(frozen=True)
class RepresentativeInvoiceFixture:
    """Stable fixture metadata, ordered exactly as the invoice endpoint reads."""

    local_school_id: str
    foreign_school_id: str
    local_invoice_ids: tuple[str, ...]
    foreign_invoice_ids: tuple[str, ...]
    page_size: int = REPRESENTATIVE_PAGE_SIZE


async def seed_representative_invoice_fixture(
    client,
    school: dict,
    *,
    visible_invoices: int = REPRESENTATIVE_VISIBLE_INVOICES,
    foreign_invoices: int = REPRESENTATIVE_FOREIGN_INVOICES,
    page_size: int = REPRESENTATIVE_PAGE_SIZE,
) -> RepresentativeInvoiceFixture:
    """Seed realistic invoice pages for one school plus competing tenant rows.

    Invoice due dates are deterministic and distinct, so the returned ID order
    matches ``FeeService.list_invoices`` without relying on generated UUID
    ordering.  Foreign rows deliberately share local dates; they exercise the
    tenant predicate before the page window is applied.
    """
    if visible_invoices <= page_size * 2:
        raise ValueError("visible_invoices must span more than two full pages")
    if foreign_invoices < 1:
        raise ValueError("foreign_invoices must be positive")

    school_id = school["id"]
    foreign_school_id = await another_school(client, school["sa"])
    local_students = [
        await create_user(client, school_id, school["hm"], "student", full_name=f"Fixture Student {index:02d}")
        for index in range(1, 6)
    ]
    foreign_students = [
        await create_user(
            client,
            foreign_school_id,
            school["sa"],
            "student",
            full_name=f"Foreign Fixture Student {index:02d}",
        )
        for index in range(1, 3)
    ]

    local_ids: list[str] = []
    foreign_ids: list[str] = []
    first_due_date = date(2030, 1, 1)
    engine = create_async_engine(TEST_URL)
    try:
        sessionmaker = async_sessionmaker(engine, expire_on_commit=False)
        async with sessionmaker() as db, db.begin():
            for index in range(visible_invoices):
                invoice = Invoice(
                    school_id=UUID(school_id),
                    student_id=UUID(local_students[index % len(local_students)]["id"]),
                    title=f"Representative monthly tuition {index + 1:03d}",
                    amount=10_000.0 + (index % 3) * 500.0,
                    amount_paid=0.0,
                    due_date=first_due_date + timedelta(days=index),
                    status="unpaid",
                )
                db.add(invoice)
                await db.flush()
                local_ids.append(str(invoice.id))

            for index in range(foreign_invoices):
                # These dates overlap local pages on purpose.  Their presence
                # must never shift a local page's offset or content.
                invoice = Invoice(
                    school_id=UUID(foreign_school_id),
                    student_id=UUID(foreign_students[index % len(foreign_students)]["id"]),
                    title=f"Foreign tenant invoice {index + 1:03d}",
                    amount=9_500.0,
                    amount_paid=0.0,
                    due_date=first_due_date + timedelta(days=index * 15),
                    status="unpaid",
                )
                db.add(invoice)
                await db.flush()
                foreign_ids.append(str(invoice.id))
    finally:
        await engine.dispose()

    return RepresentativeInvoiceFixture(
        local_school_id=school_id,
        foreign_school_id=foreign_school_id,
        local_invoice_ids=tuple(local_ids),
        foreign_invoice_ids=tuple(foreign_ids),
        page_size=page_size,
    )
