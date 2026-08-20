"""Transport P2/P3: vehicle location pings + proximity-alert flag.

Revision ID: b8c9d0e1f2a3
Revises: a7b8c9d0e1f2
Create Date: 2026-08-18
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = "b8c9d0e1f2a3"
down_revision = "a7b8c9d0e1f2"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "trip_student_events",
        sa.Column("approach_notified", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.create_table(
        "vehicle_locations",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("school_id", UUID(as_uuid=True), sa.ForeignKey("schools.id", ondelete="CASCADE"), nullable=False),
        sa.Column("trip_id", UUID(as_uuid=True), sa.ForeignKey("transport_trips.id", ondelete="CASCADE"), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=False),
        sa.Column("longitude", sa.Float(), nullable=False),
        sa.Column("address", sa.String(255), nullable=True),
        sa.Column("speed", sa.Float(), nullable=True),
        sa.Column("heading", sa.Float(), nullable=True),
        sa.Column("recorded_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_vehicle_locations_school_id", "vehicle_locations", ["school_id"])
    op.create_index(
        "ix_vehicle_locations_trip_recorded", "vehicle_locations", ["trip_id", "recorded_at"]
    )


def downgrade() -> None:
    op.drop_table("vehicle_locations")
    op.drop_column("trip_student_events", "approach_notified")
