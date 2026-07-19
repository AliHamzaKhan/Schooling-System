"""teacher attendance table

Revision ID: d6e7f8a9b0c1
Revises: c5d6e7f8a9b0
Create Date: 2026-07-19 12:00:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "d6e7f8a9b0c1"
down_revision: Union[str, None] = "c5d6e7f8a9b0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "teacher_attendance",
        sa.Column("school_id", sa.UUID(), nullable=False),
        sa.Column("teacher_id", sa.UUID(), nullable=False),
        sa.Column("attendance_date", sa.Date(), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("arrival_time", sa.Time(), nullable=True),
        sa.Column("remarks", sa.String(length=255), nullable=True),
        sa.Column("marked_by", sa.UUID(), nullable=True),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["school_id"], ["schools.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["teacher_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["marked_by"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("teacher_id", "attendance_date", name="uq_teacher_attendance_date"),
    )
    op.create_index(
        "ix_teacher_attendance_school_id", "teacher_attendance", ["school_id"],
    )
    op.create_index(
        "ix_teacher_attendance_teacher_id", "teacher_attendance", ["teacher_id"],
    )
    op.create_index(
        "ix_teacher_attendance_attendance_date",
        "teacher_attendance",
        ["attendance_date"],
    )


def downgrade() -> None:
    op.drop_index("ix_teacher_attendance_attendance_date", table_name="teacher_attendance")
    op.drop_index("ix_teacher_attendance_teacher_id", table_name="teacher_attendance")
    op.drop_index("ix_teacher_attendance_school_id", table_name="teacher_attendance")
    op.drop_table("teacher_attendance")
