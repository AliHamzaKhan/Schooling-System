"""Per-plan storage quota and the stored-upload ledger.

Revision ID: 1b2c3d4e5f6a
Revises: 0a1b2c3d4e5f
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "1b2c3d4e5f6a"
down_revision = "0a1b2c3d4e5f"
branch_labels = None
depends_on = None

# Default quotas (MB) for the seeded plans; admin-editable afterwards.
_DEFAULTS = {"basic": 1024, "standard": 5120, "premium": 20480}


def upgrade():
    op.add_column("subscription_plans", sa.Column("storage_quota_mb", sa.Integer(), nullable=True))
    for code, mb in _DEFAULTS.items():
        op.execute(
            sa.text("UPDATE subscription_plans SET storage_quota_mb = :mb WHERE code = :code")
            .bindparams(mb=mb, code=code)
        )
    op.create_table(
        "stored_uploads",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("school_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("schools.id", ondelete="CASCADE"), nullable=False),
        sa.Column("uploaded_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("storage_key", sa.String(500), nullable=False, unique=True),
        sa.Column("url", sa.String(500), nullable=False),
        sa.Column("folder", sa.String(50), nullable=False),
        sa.Column("size_bytes", sa.BigInteger(), nullable=False),
        sa.Column("content_type", sa.String(100), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_stored_uploads_school_id", "stored_uploads", ["school_id"])


def downgrade():
    op.drop_index("ix_stored_uploads_school_id", table_name="stored_uploads")
    op.drop_table("stored_uploads")
    op.drop_column("subscription_plans", "storage_quota_mb")
