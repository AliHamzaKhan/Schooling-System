"""courses: scope to section + subject

Adds ``section_id`` (class+section a course is offered to) and ``subject_id``
(the school subject catalog entry it teaches) to ``courses``. Both nullable so
pre-existing school-wide courses are unaffected.

Revision ID: c1a2b3d4e5f6
Revises: 411ef2731df4
Create Date: 2026-07-30 00:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'c1a2b3d4e5f6'
down_revision: Union[str, None] = '411ef2731df4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('courses', sa.Column('section_id', sa.UUID(), nullable=True))
    op.add_column('courses', sa.Column('subject_id', sa.UUID(), nullable=True))
    op.create_index(op.f('ix_courses_section_id'), 'courses', ['section_id'], unique=False)
    op.create_foreign_key(
        'fk_courses_section_id', 'courses', 'sections', ['section_id'], ['id'], ondelete='CASCADE'
    )
    op.create_foreign_key(
        'fk_courses_subject_id', 'courses', 'subjects', ['subject_id'], ['id'], ondelete='SET NULL'
    )


def downgrade() -> None:
    op.drop_constraint('fk_courses_subject_id', 'courses', type_='foreignkey')
    op.drop_constraint('fk_courses_section_id', 'courses', type_='foreignkey')
    op.drop_index(op.f('ix_courses_section_id'), table_name='courses')
    op.drop_column('courses', 'subject_id')
    op.drop_column('courses', 'section_id')
