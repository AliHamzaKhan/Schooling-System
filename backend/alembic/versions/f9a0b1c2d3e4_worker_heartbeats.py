"""Add coalesced notification-worker heartbeat visibility.

Revision ID: f9a0b1c2d3e4
Revises: e1f2a3b4c5d6
"""
import sqlalchemy as sa
from alembic import op

revision = "f9a0b1c2d3e4"
down_revision = "e1f2a3b4c5d6"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "worker_heartbeats",
        sa.Column("worker_name", sa.String(80), primary_key=True),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )


def downgrade():
    # Heartbeats are disposable observations, not business or delivery records.
    op.drop_table("worker_heartbeats")
