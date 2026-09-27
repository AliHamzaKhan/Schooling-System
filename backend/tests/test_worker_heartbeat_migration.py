"""Exercise the additive worker-heartbeat migration in a rolled-back schema."""
import importlib.util
from pathlib import Path
from uuid import uuid4

from alembic.migration import MigrationContext
from alembic.operations import Operations
from sqlalchemy import inspect, text
from sqlalchemy.ext.asyncio import create_async_engine

from tests.conftest import TEST_URL


async def test_worker_heartbeat_migration_round_trips_on_disposable_schema():
    engine = create_async_engine(TEST_URL)
    schema = "heartbeat_migration_" + uuid4().hex
    migration_path = (
        Path(__file__).parents[1]
        / "alembic/versions/f9a0b1c2d3e4_worker_heartbeats.py"
    )
    spec = importlib.util.spec_from_file_location("heartbeat_migration", migration_path)
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)

    def exercise(connection):
        connection.execute(text(f'CREATE SCHEMA "{schema}"'))
        connection.execute(text(f'SET LOCAL search_path TO "{schema}"'))
        migration.op = Operations(MigrationContext.configure(connection))
        migration.upgrade()
        assert inspect(connection).has_table("worker_heartbeats")
        connection.execute(
            text(
                "INSERT INTO worker_heartbeats (worker_name, last_seen_at) "
                "VALUES ('notification_outbox', now())"
            )
        )
        assert connection.scalar(text("SELECT count(*) FROM worker_heartbeats")) == 1
        migration.downgrade()
        assert not inspect(connection).has_table("worker_heartbeats")

    try:
        async with engine.connect() as connection:
            transaction = await connection.begin()
            try:
                await connection.run_sync(exercise)
            finally:
                await transaction.rollback()
    finally:
        await engine.dispose()
