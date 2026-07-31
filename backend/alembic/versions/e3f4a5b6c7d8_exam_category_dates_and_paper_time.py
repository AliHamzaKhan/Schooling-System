"""exam category dates + paper time

Adds ``start_date`` / ``end_date`` / ``announced_at`` to ``exam_categories`` (so a
term has a window and can be announced to the school once it starts) and an
optional ``exam_time`` clock time to ``exam_subjects`` (the per-subject timetable).

Revision ID: e3f4a5b6c7d8
Revises: d2e3f4a5b6c7
Create Date: 2026-07-30 12:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'e3f4a5b6c7d8'
down_revision: Union[str, None] = 'd2e3f4a5b6c7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('exam_categories', sa.Column('start_date', sa.Date(), nullable=True))
    op.add_column('exam_categories', sa.Column('end_date', sa.Date(), nullable=True))
    op.add_column(
        'exam_categories',
        sa.Column('announced_at', sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column('exam_subjects', sa.Column('exam_time', sa.String(length=20), nullable=True))


def downgrade() -> None:
    op.drop_column('exam_subjects', 'exam_time')
    op.drop_column('exam_categories', 'announced_at')
    op.drop_column('exam_categories', 'end_date')
    op.drop_column('exam_categories', 'start_date')
