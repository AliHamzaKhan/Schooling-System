"""subscription max students

Revision ID: d3e4f5a6b7c8
Revises: c1d2e3f4a5b6
Create Date: 2026-08-17 01:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'd3e4f5a6b7c8'
down_revision: Union[str, None] = 'c1d2e3f4a5b6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Student cap on the plan catalog (NULL = unlimited) …
    op.add_column(
        'subscription_plans',
        sa.Column('max_students', sa.Integer(), nullable=True),
    )
    # … snapshot onto each per-school subscription at assignment time.
    op.add_column(
        'school_subscriptions',
        sa.Column('max_students', sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column('school_subscriptions', 'max_students')
    op.drop_column('subscription_plans', 'max_students')
