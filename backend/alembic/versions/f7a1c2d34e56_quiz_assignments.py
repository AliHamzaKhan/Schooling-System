"""quiz per-student assignments

Revision ID: f7a1c2d34e56
Revises: 025b3c6c2a76
Create Date: 2026-07-08 05:20:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "f7a1c2d34e56"
down_revision: Union[str, None] = "025b3c6c2a76"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "quiz_assignments",
        sa.Column("school_id", sa.UUID(), nullable=False),
        sa.Column("quiz_id", sa.UUID(), nullable=False),
        sa.Column("student_id", sa.UUID(), nullable=False),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["quiz_id"], ["quizzes.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["school_id"], ["schools.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["student_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("quiz_id", "student_id", name="uq_quiz_assignment_student"),
    )
    op.create_index(op.f("ix_quiz_assignments_school_id"), "quiz_assignments", ["school_id"], unique=False)
    op.create_index(op.f("ix_quiz_assignments_quiz_id"), "quiz_assignments", ["quiz_id"], unique=False)
    op.create_index(op.f("ix_quiz_assignments_student_id"), "quiz_assignments", ["student_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_quiz_assignments_student_id"), table_name="quiz_assignments")
    op.drop_index(op.f("ix_quiz_assignments_quiz_id"), table_name="quiz_assignments")
    op.drop_index(op.f("ix_quiz_assignments_school_id"), table_name="quiz_assignments")
    op.drop_table("quiz_assignments")
