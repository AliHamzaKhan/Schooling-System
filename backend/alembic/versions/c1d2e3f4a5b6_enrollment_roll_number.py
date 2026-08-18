"""enrollment roll number

Revision ID: c1d2e3f4a5b6
Revises: b7c8d9e0f1a2
Create Date: 2026-08-17 00:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'c1d2e3f4a5b6'
down_revision: Union[str, None] = 'b7c8d9e0f1a2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'student_enrollments',
        sa.Column('roll_number', sa.Integer(), nullable=True),
    )
    # Backfill sequential roll numbers per section for existing rows, ordered by
    # enrollment time so the earliest-enrolled student gets roll #1.
    op.execute(
        """
        UPDATE student_enrollments AS e
        SET roll_number = seq.rn
        FROM (
            SELECT id,
                   ROW_NUMBER() OVER (
                       PARTITION BY section_id
                       ORDER BY created_at, id
                   ) AS rn
            FROM student_enrollments
        ) AS seq
        WHERE e.id = seq.id
        """
    )
    op.create_unique_constraint(
        'uq_enrollment_section_roll',
        'student_enrollments',
        ['section_id', 'roll_number'],
    )


def downgrade() -> None:
    op.drop_constraint(
        'uq_enrollment_section_roll', 'student_enrollments', type_='unique'
    )
    op.drop_column('student_enrollments', 'roll_number')
