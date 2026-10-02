"""Payslip payment request key for retry-safe "mark paid".

Revision ID: 3d4e5f6a7b8c
Revises: 2c3d4e5f6a7b
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "3d4e5f6a7b8c"
down_revision = "2c3d4e5f6a7b"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("payslips", sa.Column("payment_request_key", postgresql.UUID(as_uuid=True), nullable=True))
    op.create_unique_constraint("uq_payslips_payment_request_key", "payslips", ["payment_request_key"])


def downgrade():
    op.drop_constraint("uq_payslips_payment_request_key", "payslips", type_="unique")
    op.drop_column("payslips", "payment_request_key")
