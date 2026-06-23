"""guardian-student linkage

Revision ID: a1b2c3d4e5f6
Revises: d0ccdfef790d
Create Date: 2026-06-23 00:00:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, None] = "d0ccdfef790d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "guardian_students",
        sa.Column("guardian_id", sa.UUID(), nullable=False),
        sa.Column("student_id", sa.UUID(), nullable=False),
        sa.Column("school_id", sa.UUID(), nullable=False),
        sa.Column("relationship", sa.String(length=50), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["guardian_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["student_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["school_id"], ["schools.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("guardian_id", "student_id"),
    )
    op.create_index(
        op.f("ix_guardian_students_school_id"),
        "guardian_students",
        ["school_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_guardian_students_school_id"), table_name="guardian_students"
    )
    op.drop_table("guardian_students")
