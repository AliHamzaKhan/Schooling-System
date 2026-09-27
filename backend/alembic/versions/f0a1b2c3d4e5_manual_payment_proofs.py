"""Add private evidence references to manually recorded fee payments.

Revision ID: f0a1b2c3d4e5
Revises: f9a0b1c2d3e4
"""
import sqlalchemy as sa
from alembic import op


revision = "f0a1b2c3d4e5"
down_revision = "f9a0b1c2d3e4"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("payments", sa.Column("proof_url", sa.String(length=500), nullable=True))


def downgrade():
    op.drop_column("payments", "proof_url")
