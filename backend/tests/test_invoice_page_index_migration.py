"""Rehearse the invoice-page performance index in a disposable schema."""

import importlib.util
from pathlib import Path
from uuid import uuid4

from alembic.migration import MigrationContext
from alembic.operations import Operations
from sqlalchemy import inspect, text
from sqlalchemy.ext.asyncio import create_async_engine

from tests.conftest import TEST_URL


async def test_invoice_page_index_migration_round_trips_on_disposable_schema():
    engine = create_async_engine(TEST_URL)
    schema = "invoice_page_index_" + uuid4().hex
    migration_path = (
        Path(__file__).parents[1]
        / "alembic/versions/0a1b2c3d4e5f_invoice_page_index.py"
    )
    spec = importlib.util.spec_from_file_location("invoice_page_index", migration_path)
    migration = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(migration)

    def exercise(connection) -> None:
        connection.execute(text(f'CREATE SCHEMA "{schema}"'))
        connection.execute(text(f'SET LOCAL search_path TO "{schema}"'))
        connection.execute(
            text(
                "CREATE TABLE invoices ("
                "id UUID PRIMARY KEY, school_id UUID NOT NULL, due_date DATE NOT NULL)"
            )
        )
        migration.op = Operations(MigrationContext.configure(connection))
        migration.upgrade()
        indexes = {
            index["name"]: index["column_names"]
            for index in inspect(connection).get_indexes("invoices")
        }
        assert indexes["ix_invoices_school_due_id"] == ["school_id", "due_date", "id"]

        migration.downgrade()
        assert "ix_invoices_school_due_id" not in {
            index["name"] for index in inspect(connection).get_indexes("invoices")
        }

    try:
        async with engine.connect() as connection:
            transaction = await connection.begin()
            try:
                await connection.run_sync(exercise)
            finally:
                await transaction.rollback()
    finally:
        await engine.dispose()
