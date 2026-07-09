"""direct messages (teacher/headmaster <-> guardian, incl. complaints)

Revision ID: a3b9d1e45f77
Revises: f7a1c2d34e56
Create Date: 2026-07-09 04:40:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "a3b9d1e45f77"
down_revision: Union[str, None] = "f7a1c2d34e56"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "direct_messages",
        sa.Column("school_id", sa.UUID(), nullable=False),
        sa.Column("sender_id", sa.UUID(), nullable=False),
        sa.Column("recipient_id", sa.UUID(), nullable=False),
        sa.Column("student_id", sa.UUID(), nullable=True),
        sa.Column("kind", sa.String(length=20), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["school_id"], ["schools.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["sender_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["recipient_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["student_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_direct_messages_school_id"), "direct_messages", ["school_id"], unique=False)
    op.create_index(op.f("ix_direct_messages_sender_id"), "direct_messages", ["sender_id"], unique=False)
    op.create_index(op.f("ix_direct_messages_recipient_id"), "direct_messages", ["recipient_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_direct_messages_recipient_id"), table_name="direct_messages")
    op.drop_index(op.f("ix_direct_messages_sender_id"), table_name="direct_messages")
    op.drop_index(op.f("ix_direct_messages_school_id"), table_name="direct_messages")
    op.drop_table("direct_messages")
