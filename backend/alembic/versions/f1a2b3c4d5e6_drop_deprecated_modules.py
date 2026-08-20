"""Drop deprecated modules: library, hostel, online classes.

These modules were removed from scope. Transport and HR & Payroll are retained
(both are built, user-facing features). Mobile App / API Access were
platform-toggle-only (no tables), so they need no schema change here.

Revision ID: f1a2b3c4d5e6
Revises: d3e4f5a6b7c8
Create Date: 2026-08-18
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = "f1a2b3c4d5e6"
down_revision = "d3e4f5a6b7c8"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Drop child tables before their parents to respect FK constraints.
    op.drop_table("book_loans")
    op.drop_table("books")
    op.drop_table("hostel_allocations")
    op.drop_table("hostel_rooms")
    op.drop_table("hostel_blocks")
    op.drop_table("online_classes")


def downgrade() -> None:
    # Recreate the tables as they were before removal (structure only; data is
    # not restored).
    op.create_table(
        "books",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("school_id", UUID(as_uuid=True), sa.ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("title", sa.String(250), nullable=False),
        sa.Column("author", sa.String(200), nullable=True),
        sa.Column("isbn", sa.String(20), nullable=True),
        sa.Column("category", sa.String(100), nullable=True),
        sa.Column("total_copies", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("available_copies", sa.Integer(), nullable=False, server_default="1"),
    )
    op.create_table(
        "book_loans",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("school_id", UUID(as_uuid=True), sa.ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("book_id", UUID(as_uuid=True), sa.ForeignKey("books.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("member_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("borrowed_on", sa.Date(), nullable=False),
        sa.Column("due_date", sa.Date(), nullable=False),
        sa.Column("returned_on", sa.Date(), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="borrowed"),
        sa.Column("fine", sa.Float(), nullable=True),
    )
    op.create_table(
        "hostel_blocks",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("school_id", UUID(as_uuid=True), sa.ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("name", sa.String(150), nullable=False),
        sa.Column("warden_name", sa.String(150), nullable=True),
        sa.Column("warden_phone", sa.String(50), nullable=True),
        sa.UniqueConstraint("school_id", "name", name="uq_hostel_block_school_name"),
    )
    op.create_table(
        "hostel_rooms",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("school_id", UUID(as_uuid=True), sa.ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("block_id", UUID(as_uuid=True), sa.ForeignKey("hostel_blocks.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("room_no", sa.String(50), nullable=False),
        sa.Column("capacity", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("occupied", sa.Integer(), nullable=False, server_default="0"),
        sa.UniqueConstraint("block_id", "room_no", name="uq_hostel_room_block_no"),
    )
    op.create_table(
        "hostel_allocations",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("school_id", UUID(as_uuid=True), sa.ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("student_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("room_id", UUID(as_uuid=True), sa.ForeignKey("hostel_rooms.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("allocated_on", sa.Date(), nullable=False),
        sa.Column("vacated_on", sa.Date(), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="active"),
    )
    op.create_table(
        "online_classes",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("school_id", UUID(as_uuid=True), sa.ForeignKey("schools.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("section_id", UUID(as_uuid=True), sa.ForeignKey("sections.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("subject_id", UUID(as_uuid=True), sa.ForeignKey("subjects.id", ondelete="SET NULL"), nullable=True),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("meeting_url", sa.String(500), nullable=False),
        sa.Column("scheduled_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("scheduled_end", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="scheduled"),
        sa.Column("host_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
    )
