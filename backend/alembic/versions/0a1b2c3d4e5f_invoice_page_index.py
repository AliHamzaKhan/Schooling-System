"""Index the stable school-scoped invoice page query.

Revision ID: 0a1b2c3d4e5f
Revises: fc3d4e5f6a7b
"""

from alembic import op


revision = "0a1b2c3d4e5f"
down_revision = "fc3d4e5f6a7b"
branch_labels = None
depends_on = None


def upgrade():
    op.create_index(
        "ix_invoices_school_due_id",
        "invoices",
        ["school_id", "due_date", "id"],
        unique=False,
    )


def downgrade():
    op.drop_index("ix_invoices_school_due_id", table_name="invoices")
