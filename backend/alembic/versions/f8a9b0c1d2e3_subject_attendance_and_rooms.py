"""subject/period attendance + room numbers on classes and sections

Splits attendance into a daily register (subject_id IS NULL) and per-subject
period attendance (subject_id set). The old single unique constraint is replaced
by two partial unique indexes, because a plain UNIQUE over a nullable column
would stop constraining the daily rows entirely (NULLs compare as distinct).

Revision ID: f8a9b0c1d2e3
Revises: e7f8a9b0c1d2
Create Date: 2026-07-20 10:00:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "f8a9b0c1d2e3"
down_revision: Union[str, None] = "e7f8a9b0c1d2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ----------------------- subject/period attendance ---------------------- #
    op.add_column(
        "attendance_records",
        sa.Column("subject_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.add_column(
        "attendance_records",
        sa.Column("timetable_slot_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.add_column(
        "attendance_records", sa.Column("period_label", sa.String(length=50), nullable=True)
    )
    op.create_foreign_key(
        "fk_attendance_subject", "attendance_records", "subjects",
        ["subject_id"], ["id"], ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_attendance_timetable_slot", "attendance_records", "timetable_slots",
        ["timetable_slot_id"], ["id"], ondelete="SET NULL",
    )
    op.create_index(
        "ix_attendance_records_subject_id", "attendance_records", ["subject_id"]
    )

    # Existing rows are all daily-register rows, so the partial daily index is
    # exactly as strict as the constraint it replaces — no data can conflict.
    op.drop_constraint("uq_attendance_student_date", "attendance_records", type_="unique")
    op.create_index(
        "uq_attendance_student_date_daily",
        "attendance_records",
        ["student_id", "attendance_date"],
        unique=True,
        postgresql_where=sa.text("subject_id IS NULL"),
    )
    op.create_index(
        "uq_attendance_student_date_subject",
        "attendance_records",
        ["student_id", "attendance_date", "subject_id"],
        unique=True,
        postgresql_where=sa.text("subject_id IS NOT NULL"),
    )

    # ------------------------------- room numbers --------------------------- #
    op.add_column("classes", sa.Column("room_no", sa.String(length=50), nullable=True))
    op.add_column("sections", sa.Column("room_no", sa.String(length=50), nullable=True))


def downgrade() -> None:
    op.drop_column("sections", "room_no")
    op.drop_column("classes", "room_no")

    # Per-subject rows would violate the restored constraint, so drop them.
    op.execute("DELETE FROM attendance_records WHERE subject_id IS NOT NULL")
    op.drop_index("uq_attendance_student_date_subject", table_name="attendance_records")
    op.drop_index("uq_attendance_student_date_daily", table_name="attendance_records")
    op.create_unique_constraint(
        "uq_attendance_student_date", "attendance_records", ["student_id", "attendance_date"]
    )

    op.drop_index("ix_attendance_records_subject_id", table_name="attendance_records")
    op.drop_constraint("fk_attendance_timetable_slot", "attendance_records", type_="foreignkey")
    op.drop_constraint("fk_attendance_subject", "attendance_records", type_="foreignkey")
    op.drop_column("attendance_records", "period_label")
    op.drop_column("attendance_records", "timetable_slot_id")
    op.drop_column("attendance_records", "subject_id")
