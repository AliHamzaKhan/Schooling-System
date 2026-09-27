"""Add school-managed guardian billing contacts.

Revision ID: fa1b2c3d4e5f
Revises: f0a1b2c3d4e5
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql


revision = "fa1b2c3d4e5f"
down_revision = "f0a1b2c3d4e5"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "student_billing_contacts",
        sa.Column("school_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("guardian_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("billing_email", sa.String(length=255), nullable=True),
        sa.Column("billing_phone", sa.String(length=50), nullable=True),
        sa.Column("payer_reference", sa.String(length=100), nullable=True),
        sa.Column("is_primary", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("note", sa.String(length=255), nullable=True),
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["school_id"], ["schools.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["student_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["guardian_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("student_id", "guardian_id", name="uq_billing_contact_student_guardian"),
    )
    op.create_index("ix_student_billing_contacts_school_id", "student_billing_contacts", ["school_id"])
    op.create_index("ix_student_billing_contacts_student_id", "student_billing_contacts", ["student_id"])
    op.create_index("ix_student_billing_contacts_guardian_id", "student_billing_contacts", ["guardian_id"])


def downgrade():
    op.drop_index("ix_student_billing_contacts_guardian_id", table_name="student_billing_contacts")
    op.drop_index("ix_student_billing_contacts_student_id", table_name="student_billing_contacts")
    op.drop_index("ix_student_billing_contacts_school_id", table_name="student_billing_contacts")
    op.drop_table("student_billing_contacts")
