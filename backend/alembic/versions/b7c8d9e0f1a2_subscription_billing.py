"""subscription billing: plan pricing + per-school subscriptions + payment ledger

Extends ``subscription_plans`` with pricing/duration fields (``price``,
``billing_period``, ``description``, ``is_active``) and adds two new tables:
``school_subscriptions`` (a school's running subscription instance, with an
optional discount and a net amount) and ``subscription_payments`` (the revenue
ledger that admin dashboard / revenue reports read from).

Revision ID: b7c8d9e0f1a2
Revises: e3f4a5b6c7d8
Create Date: 2026-07-31 00:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = 'b7c8d9e0f1a2'
down_revision: Union[str, None] = 'e3f4a5b6c7d8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- subscription_plans: pricing + duration + archive flag ---
    op.add_column(
        'subscription_plans',
        sa.Column('description', sa.String(length=500), nullable=True),
    )
    op.add_column(
        'subscription_plans',
        sa.Column(
            'price',
            sa.Numeric(precision=10, scale=2),
            nullable=False,
            server_default='0',
        ),
    )
    op.add_column(
        'subscription_plans',
        sa.Column(
            'billing_period',
            sa.String(length=20),
            nullable=False,
            server_default='monthly',
        ),
    )
    op.add_column(
        'subscription_plans',
        sa.Column(
            'is_active',
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        ),
    )

    # --- school_subscriptions ---
    op.create_table(
        'school_subscriptions',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('school_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('plan_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='active'),
        sa.Column('start_date', sa.Date(), nullable=False),
        sa.Column('end_date', sa.Date(), nullable=False),
        sa.Column('billing_period', sa.String(length=20), nullable=False),
        sa.Column('base_price', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('discount_type', sa.String(length=20), nullable=False, server_default='none'),
        sa.Column(
            'discount_value',
            sa.Numeric(precision=10, scale=2),
            nullable=False,
            server_default='0',
        ),
        sa.Column('net_amount', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(['school_id'], ['schools.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['plan_id'], ['subscription_plans.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_school_subscriptions_school_id', 'school_subscriptions', ['school_id'])
    op.create_index('ix_school_subscriptions_status', 'school_subscriptions', ['status'])
    op.create_index('ix_school_subscriptions_end_date', 'school_subscriptions', ['end_date'])

    # --- subscription_payments (revenue ledger) ---
    op.create_table(
        'subscription_payments',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('subscription_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('school_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('amount', sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column('paid_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('period_start', sa.Date(), nullable=False),
        sa.Column('period_end', sa.Date(), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='paid'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(['subscription_id'], ['school_subscriptions.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['school_id'], ['schools.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_subscription_payments_subscription_id', 'subscription_payments', ['subscription_id'])
    op.create_index('ix_subscription_payments_school_id', 'subscription_payments', ['school_id'])
    op.create_index('ix_subscription_payments_paid_at', 'subscription_payments', ['paid_at'])


def downgrade() -> None:
    op.drop_index('ix_subscription_payments_paid_at', table_name='subscription_payments')
    op.drop_index('ix_subscription_payments_school_id', table_name='subscription_payments')
    op.drop_index('ix_subscription_payments_subscription_id', table_name='subscription_payments')
    op.drop_table('subscription_payments')

    op.drop_index('ix_school_subscriptions_end_date', table_name='school_subscriptions')
    op.drop_index('ix_school_subscriptions_status', table_name='school_subscriptions')
    op.drop_index('ix_school_subscriptions_school_id', table_name='school_subscriptions')
    op.drop_table('school_subscriptions')

    op.drop_column('subscription_plans', 'is_active')
    op.drop_column('subscription_plans', 'billing_period')
    op.drop_column('subscription_plans', 'price')
    op.drop_column('subscription_plans', 'description')
