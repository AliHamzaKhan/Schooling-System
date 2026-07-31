"""exam categories

Adds the ``exam_categories`` table (reusable terms like Mid Term / Final Term)
and an optional ``category_id`` on ``exams``.

Revision ID: d2e3f4a5b6c7
Revises: c1a2b3d4e5f6
Create Date: 2026-07-30 00:30:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = 'd2e3f4a5b6c7'
down_revision: Union[str, None] = 'c1a2b3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'exam_categories',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('school_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['school_id'], ['schools.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('school_id', 'name', name='uq_exam_category_school_name'),
    )
    op.create_index(op.f('ix_exam_categories_school_id'), 'exam_categories', ['school_id'], unique=False)

    op.add_column('exams', sa.Column('category_id', postgresql.UUID(as_uuid=True), nullable=True))
    op.create_index(op.f('ix_exams_category_id'), 'exams', ['category_id'], unique=False)
    op.create_foreign_key(
        'fk_exams_category_id', 'exams', 'exam_categories', ['category_id'], ['id'], ondelete='SET NULL'
    )


def downgrade() -> None:
    op.drop_constraint('fk_exams_category_id', 'exams', type_='foreignkey')
    op.drop_index(op.f('ix_exams_category_id'), table_name='exams')
    op.drop_column('exams', 'category_id')
    op.drop_index(op.f('ix_exam_categories_school_id'), table_name='exam_categories')
    op.drop_table('exam_categories')
