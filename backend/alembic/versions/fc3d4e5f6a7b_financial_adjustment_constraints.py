"""Constrain adjustment kinds, targets, currency codes and decisions.

Revision ID: fc3d4e5f6a7b
Revises: fb2c3d4e5f6a
"""

from alembic import op

revision = "fc3d4e5f6a7b"
down_revision = "fb2c3d4e5f6a"
branch_labels = None
depends_on = None


def upgrade():
    op.create_check_constraint(
        "ck_financial_adjustment_target_kind",
        "financial_adjustments",
        "(kind IN ('refund', 'credit', 'waiver') AND target_type = 'invoice') "
        "OR (kind = 'payroll_correction' AND target_type = 'payslip')",
    )
    op.create_check_constraint(
        "ck_financial_adjustment_currency",
        "financial_adjustments",
        "currency_code ~ '^[A-Z]{3}$'",
    )
    op.create_check_constraint(
        "ck_financial_adjustment_decision_value",
        "financial_adjustment_decisions",
        "decision IN ('approved', 'rejected')",
    )


def downgrade():
    op.drop_constraint(
        "ck_financial_adjustment_decision_value",
        "financial_adjustment_decisions",
        type_="check",
    )
    op.drop_constraint(
        "ck_financial_adjustment_currency",
        "financial_adjustments",
        type_="check",
    )
    op.drop_constraint(
        "ck_financial_adjustment_target_kind",
        "financial_adjustments",
        type_="check",
    )
