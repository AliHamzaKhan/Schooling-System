"""Rehearse the financial-adjustment checks in a disposable schema."""

import importlib.util
from pathlib import Path
from uuid import uuid4

import pytest
from alembic.migration import MigrationContext
from alembic.operations import Operations
from sqlalchemy import inspect, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import create_async_engine

from tests.conftest import TEST_URL


async def test_financial_adjustment_constraints_migration_blocks_invalid_rows():
    engine = create_async_engine(TEST_URL)
    schema = "finance_adjustment_migration_" + uuid4().hex
    migration_path = (
        Path(__file__).parents[1]
        / "alembic/versions/fc3d4e5f6a7b_financial_adjustment_constraints.py"
    )
    spec = importlib.util.spec_from_file_location(
        "financial_adjustment_constraints_migration", migration_path
    )
    migration = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(migration)

    def expect_check_violation(connection, statement: str) -> None:
        with pytest.raises(IntegrityError):
            with connection.begin_nested():
                connection.execute(text(statement))

    def exercise(connection) -> None:
        connection.execute(text(f'CREATE SCHEMA "{schema}"'))
        connection.execute(text(f'SET LOCAL search_path TO "{schema}"'))
        connection.execute(
            text(
                "CREATE TABLE financial_adjustments ("
                "kind VARCHAR(30) NOT NULL, "
                "target_type VARCHAR(20) NOT NULL, "
                "currency_code VARCHAR(3) NOT NULL)"
            )
        )
        connection.execute(
            text(
                "CREATE TABLE financial_adjustment_decisions (decision VARCHAR(10) NOT NULL)"
            )
        )
        migration.op = Operations(MigrationContext.configure(connection))
        migration.upgrade()

        checks = {
            check["name"]
            for check in inspect(connection).get_check_constraints(
                "financial_adjustments"
            )
        }
        assert {
            "ck_financial_adjustment_target_kind",
            "ck_financial_adjustment_currency",
        } <= checks
        decision_checks = {
            check["name"]
            for check in inspect(connection).get_check_constraints(
                "financial_adjustment_decisions"
            )
        }
        assert "ck_financial_adjustment_decision_value" in decision_checks

        connection.execute(
            text(
                "INSERT INTO financial_adjustments (kind, target_type, currency_code) "
                "VALUES ('payroll_correction', 'payslip', 'PKR')"
            )
        )
        expect_check_violation(
            connection,
            "INSERT INTO financial_adjustments (kind, target_type, currency_code) "
            "VALUES ('refund', 'payslip', 'PKR')",
        )
        expect_check_violation(
            connection,
            "INSERT INTO financial_adjustments (kind, target_type, currency_code) "
            "VALUES ('discount', 'invoice', 'PKR')",
        )
        expect_check_violation(
            connection,
            "INSERT INTO financial_adjustments (kind, target_type, currency_code) "
            "VALUES ('credit', 'invoice', 'PK1')",
        )
        expect_check_violation(
            connection,
            "INSERT INTO financial_adjustment_decisions (decision) VALUES ('pending')",
        )

        migration.downgrade()
        assert not inspect(connection).get_check_constraints("financial_adjustments")
        assert not inspect(connection).get_check_constraints(
            "financial_adjustment_decisions"
        )

    try:
        async with engine.connect() as connection:
            transaction = await connection.begin()
            try:
                await connection.run_sync(exercise)
            finally:
                await transaction.rollback()
    finally:
        await engine.dispose()
