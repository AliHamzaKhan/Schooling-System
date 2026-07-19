"""payslip attendance snapshot + allowances

Revision ID: e7f8a9b0c1d2
Revises: d6e7f8a9b0c1
Create Date: 2026-07-19 14:00:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "e7f8a9b0c1d2"
down_revision: Union[str, None] = "d6e7f8a9b0c1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_COLUMNS = (
    ("allowances", sa.Float(), "0"),
    ("present_days", sa.Integer(), "0"),
    ("absent_days", sa.Integer(), "0"),
    ("late_days", sa.Integer(), "0"),
    ("leave_days", sa.Integer(), "0"),
    ("absence_deduction", sa.Float(), "0"),
)


def upgrade() -> None:
    for name, type_, default in _COLUMNS:
        op.add_column(
            "payslips",
            sa.Column(name, type_, nullable=False, server_default=default),
        )


def downgrade() -> None:
    for name, _, _ in reversed(_COLUMNS):
        op.drop_column("payslips", name)
