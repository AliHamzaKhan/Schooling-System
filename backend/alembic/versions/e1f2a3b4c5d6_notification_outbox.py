"""Durable notification outbox; historical sends are not requeued.

Revision ID: e1f2a3b4c5d6
Revises: c9d0e1f2a3b4
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "e1f2a3b4c5d6"
down_revision = "c9d0e1f2a3b4"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("message_deliveries", sa.Column("recipient_key", sa.String(64), nullable=True))
    op.create_unique_constraint("uq_delivery_recipient", "message_deliveries", ["message_id", "recipient_key"])
    op.create_table(
        "notification_outbox",
        sa.Column("message_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("messages.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("state", sa.String(20), nullable=False),
        sa.Column("available_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("prepared_at", sa.DateTime(timezone=True)),
        sa.Column("lease_token", postgresql.UUID(as_uuid=True)),
        sa.Column("lease_until", sa.DateTime(timezone=True)),
        sa.Column("attempts", sa.Integer(), server_default="0", nullable=False),
        sa.Column("last_error", sa.String(255)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_notification_outbox_due", "notification_outbox", ["state", "available_at"])


def downgrade():
    # Never discard unresolved work automatically during a rollback.
    connection = op.get_bind()
    if connection.scalar(sa.text("SELECT EXISTS (SELECT 1 FROM notification_outbox WHERE state != 'complete')")):
        raise RuntimeError("Resolve or archive outstanding notification work before downgrade")
    op.drop_table("notification_outbox")
    op.drop_constraint("uq_delivery_recipient", "message_deliveries", type_="unique")
    op.drop_column("message_deliveries", "recipient_key")
