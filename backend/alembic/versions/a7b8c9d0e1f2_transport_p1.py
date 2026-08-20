"""Transport P1: drivers, requests, trips, trip events, geo/driver on stops
and assignments.

Revision ID: a7b8c9d0e1f2
Revises: f1a2b3c4d5e6
Create Date: 2026-08-18
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB, UUID

revision = "a7b8c9d0e1f2"
down_revision = "f1a2b3c4d5e6"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # --- geo columns on route_stops ---
    op.add_column("route_stops", sa.Column("latitude", sa.Float(), nullable=True))
    op.add_column("route_stops", sa.Column("longitude", sa.Float(), nullable=True))
    op.add_column("route_stops", sa.Column("address", sa.String(255), nullable=True))

    # --- driver + geo columns on transport_assignments ---
    op.add_column(
        "transport_assignments",
        sa.Column("driver_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
    )
    op.add_column("transport_assignments", sa.Column("latitude", sa.Float(), nullable=True))
    op.add_column("transport_assignments", sa.Column("longitude", sa.Float(), nullable=True))
    op.add_column("transport_assignments", sa.Column("address", sa.String(255), nullable=True))
    op.create_index("ix_transport_assignments_driver_id", "transport_assignments", ["driver_id"])

    # --- drivers ---
    op.create_table(
        "drivers",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("school_id", UUID(as_uuid=True), sa.ForeignKey("schools.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("license_no", sa.String(100), nullable=True),
        sa.Column("phone", sa.String(50), nullable=True),
        sa.Column("assigned_vehicle_id", UUID(as_uuid=True), sa.ForeignKey("vehicles.id", ondelete="SET NULL"), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="active"),
        sa.UniqueConstraint("user_id", name="uq_driver_user"),
    )
    op.create_index("ix_drivers_school_id", "drivers", ["school_id"])
    op.create_index("ix_drivers_user_id", "drivers", ["user_id"])

    # --- transport_requests ---
    op.create_table(
        "transport_requests",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("school_id", UUID(as_uuid=True), sa.ForeignKey("schools.id", ondelete="CASCADE"), nullable=False),
        sa.Column("student_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("requested_by", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("pickup_address", sa.String(255), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=True),
        sa.Column("longitude", sa.Float(), nullable=True),
        sa.Column("notes", sa.String(500), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("reviewed_by", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("reject_reason", sa.String(255), nullable=True),
    )
    op.create_index("ix_transport_requests_school_id", "transport_requests", ["school_id"])
    op.create_index("ix_transport_requests_student_id", "transport_requests", ["student_id"])
    op.create_index("ix_transport_requests_requested_by", "transport_requests", ["requested_by"])

    # --- transport_trips ---
    op.create_table(
        "transport_trips",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("school_id", UUID(as_uuid=True), sa.ForeignKey("schools.id", ondelete="CASCADE"), nullable=False),
        sa.Column("route_id", UUID(as_uuid=True), sa.ForeignKey("routes.id", ondelete="CASCADE"), nullable=False),
        sa.Column("driver_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("vehicle_id", UUID(as_uuid=True), sa.ForeignKey("vehicles.id", ondelete="SET NULL"), nullable=True),
        sa.Column("trip_type", sa.String(20), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="scheduled"),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("stop_order", JSONB, nullable=True),
        sa.Column("optimized", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.create_index("ix_transport_trips_school_id", "transport_trips", ["school_id"])
    op.create_index("ix_transport_trips_route_id", "transport_trips", ["route_id"])
    op.create_index("ix_transport_trips_driver_id", "transport_trips", ["driver_id"])

    # --- trip_student_events ---
    op.create_table(
        "trip_student_events",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("school_id", UUID(as_uuid=True), sa.ForeignKey("schools.id", ondelete="CASCADE"), nullable=False),
        sa.Column("trip_id", UUID(as_uuid=True), sa.ForeignKey("transport_trips.id", ondelete="CASCADE"), nullable=False),
        sa.Column("student_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("event_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("latitude", sa.Float(), nullable=True),
        sa.Column("longitude", sa.Float(), nullable=True),
        sa.UniqueConstraint("trip_id", "student_id", name="uq_trip_student"),
    )
    op.create_index("ix_trip_student_events_school_id", "trip_student_events", ["school_id"])
    op.create_index("ix_trip_student_events_trip_id", "trip_student_events", ["trip_id"])
    op.create_index("ix_trip_student_events_student_id", "trip_student_events", ["student_id"])


def downgrade() -> None:
    op.drop_table("trip_student_events")
    op.drop_table("transport_trips")
    op.drop_table("transport_requests")
    op.drop_table("drivers")
    op.drop_index("ix_transport_assignments_driver_id", table_name="transport_assignments")
    op.drop_column("transport_assignments", "address")
    op.drop_column("transport_assignments", "longitude")
    op.drop_column("transport_assignments", "latitude")
    op.drop_column("transport_assignments", "driver_id")
    op.drop_column("route_stops", "address")
    op.drop_column("route_stops", "longitude")
    op.drop_column("route_stops", "latitude")
