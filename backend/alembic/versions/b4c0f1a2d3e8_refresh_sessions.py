"""refresh sessions (revocable, rotating refresh tokens)

Revision ID: b4c0f1a2d3e8
Revises: a3b9d1e45f77
Create Date: 2026-07-09 05:10:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "b4c0f1a2d3e8"
down_revision: Union[str, None] = "a3b9d1e45f77"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "refresh_sessions",
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("user_agent", sa.String(length=255), nullable=True),
        sa.Column("ip_address", sa.String(length=45), nullable=True),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_refresh_sessions_user_id"), "refresh_sessions", ["user_id"], unique=False
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_refresh_sessions_user_id"), table_name="refresh_sessions")
    op.drop_table("refresh_sessions")
