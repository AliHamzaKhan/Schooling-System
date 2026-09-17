"""Rehearse only the new migration in a rolled-back isolated test schema."""
import importlib.util
from pathlib import Path
from uuid import uuid4

import pytest
from alembic.migration import MigrationContext
from alembic.operations import Operations
from sqlalchemy import inspect, text
from sqlalchemy.ext.asyncio import create_async_engine

from tests.conftest import TEST_URL


async def test_outbox_migration_preserves_history_and_blocks_unsafe_downgrade():
    engine = create_async_engine(TEST_URL)
    schema = "migration_test_" + uuid4().hex
    migration_path = Path(__file__).parents[1] / "alembic/versions/e1f2a3b4c5d6_notification_outbox.py"
    spec = importlib.util.spec_from_file_location("outbox_migration", migration_path)
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)

    def exercise(connection):
        connection.execute(text(f'CREATE SCHEMA "{schema}"'))
        connection.execute(text(f'SET LOCAL search_path TO "{schema}"'))
        connection.execute(text("CREATE TABLE messages (id UUID PRIMARY KEY)"))
        connection.execute(text("CREATE TABLE message_deliveries (id UUID PRIMARY KEY, message_id UUID NOT NULL, status VARCHAR(20))"))
        message_id, delivery_id = uuid4(), uuid4()
        connection.execute(text("INSERT INTO messages VALUES (:id)"), {"id": message_id})
        connection.execute(text("INSERT INTO message_deliveries VALUES (:id, :message, 'sent')"), {"id": delivery_id, "message": message_id})
        migration.op = Operations(MigrationContext.configure(connection))
        migration.upgrade()
        assert connection.scalar(text("SELECT count(*) FROM notification_outbox")) == 0
        assert connection.execute(text("SELECT status, recipient_key FROM message_deliveries")).one() == ("sent", None)
        assert "uq_delivery_recipient" in {c["name"] for c in inspect(connection).get_unique_constraints("message_deliveries")}
        connection.execute(text("INSERT INTO notification_outbox (message_id, state, available_at) VALUES (:id, 'pending', now())"), {"id": message_id})
        with pytest.raises(RuntimeError, match="outstanding notification work"):
            migration.downgrade()
        connection.execute(text("UPDATE notification_outbox SET state = 'complete'"))
        migration.downgrade()
        assert not inspect(connection).has_table("notification_outbox")
        assert connection.scalar(text("SELECT status FROM message_deliveries")) == "sent"

    try:
        async with engine.connect() as connection:
            transaction = await connection.begin()
            try:
                await connection.run_sync(exercise)
            finally:
                await transaction.rollback()
    finally:
        await engine.dispose()
