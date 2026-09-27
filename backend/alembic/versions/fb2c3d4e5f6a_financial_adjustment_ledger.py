"""Add immutable proposed finance adjustments and Headmaster decisions.

Revision ID: fb2c3d4e5f6a
Revises: fa1b2c3d4e5f
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "fb2c3d4e5f6a"
down_revision = "fa1b2c3d4e5f"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "financial_adjustments",
        sa.Column("school_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("kind", sa.String(length=30), nullable=False),
        sa.Column("target_type", sa.String(length=20), nullable=False),
        sa.Column("target_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("proposed_amount", sa.String(length=64), nullable=False),
        sa.Column("currency_code", sa.String(length=3), nullable=False),
        sa.Column("reason", sa.String(length=500), nullable=False),
        sa.Column("requested_by", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["school_id"], ["schools.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["requested_by"], ["users.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_financial_adjustments_school_id", "financial_adjustments", ["school_id"]
    )
    op.create_index("ix_financial_adjustments_kind", "financial_adjustments", ["kind"])
    op.create_index(
        "ix_financial_adjustments_target_id", "financial_adjustments", ["target_id"]
    )
    op.create_table(
        "financial_adjustment_decisions",
        sa.Column("school_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("adjustment_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("decision", sa.String(length=10), nullable=False),
        sa.Column("reason", sa.String(length=500), nullable=False),
        sa.Column("decided_by", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["adjustment_id"], ["financial_adjustments.id"], ondelete="RESTRICT"
        ),
        sa.ForeignKeyConstraint(["decided_by"], ["users.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["school_id"], ["schools.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("adjustment_id", name="uq_financial_adjustment_decision"),
    )
    op.create_index(
        "ix_financial_adjustment_decisions_school_id",
        "financial_adjustment_decisions",
        ["school_id"],
    )


def downgrade():
    op.drop_index(
        "ix_financial_adjustment_decisions_school_id",
        table_name="financial_adjustment_decisions",
    )
    op.drop_table("financial_adjustment_decisions")
    op.drop_index(
        "ix_financial_adjustments_target_id", table_name="financial_adjustments"
    )
    op.drop_index("ix_financial_adjustments_kind", table_name="financial_adjustments")
    op.drop_index(
        "ix_financial_adjustments_school_id", table_name="financial_adjustments"
    )
    op.drop_table("financial_adjustments")
