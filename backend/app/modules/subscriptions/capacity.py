"""Student-capacity helpers shared by the subscription status read and the
user-creation enforcement.

The cap lives on a school's active subscription (`max_students`, NULL =
unlimited). "Current students" is counted live from active student accounts, so
deleting or deactivating a student frees a slot automatically — there is no
stored counter to keep in sync.
"""
import uuid
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import SubscriptionStatus, SystemRole
from app.core.exceptions import forbidden
from app.models.role import Role
from app.models.subscription import SchoolSubscription
from app.models.user import User


async def active_student_count(db: AsyncSession, school_id: uuid.UUID) -> int:
    """Number of active student accounts in the school. Deactivated/deleted
    students are not counted, so a freed slot is reflected immediately."""
    return int(
        await db.scalar(
            select(func.count(func.distinct(User.id)))
            .select_from(User)
            .join(User.roles)
            .where(
                User.school_id == school_id,
                User.is_active.is_(True),
                Role.code == SystemRole.STUDENT.value,
            )
        )
        or 0
    )


async def active_student_cap(db: AsyncSession, school_id: uuid.UUID) -> int | None:
    """The student cap from the school's current active subscription, or None
    when there is no active subscription or the plan is uncapped (unlimited)."""
    sub = await db.scalar(
        select(SchoolSubscription)
        .where(
            SchoolSubscription.school_id == school_id,
            SchoolSubscription.status == SubscriptionStatus.ACTIVE.value,
            SchoolSubscription.end_date >= date.today(),
        )
        .order_by(SchoolSubscription.end_date.desc())
        .limit(1)
    )
    return sub.max_students if sub is not None else None


async def enforce_student_capacity(db: AsyncSession, school_id: uuid.UUID) -> None:
    """Raise 403 when the school is already at its subscription's student cap.

    No cap (unlimited plan, or no active subscription) never blocks — the
    subscription's active/expired state is enforced separately.
    """
    cap = await active_student_cap(db, school_id)
    if cap is None:
        return
    current = await active_student_count(db, school_id)
    if current >= cap:
        raise forbidden(
            f"Student limit reached for this subscription "
            f"({current}/{cap}). Remove a student or upgrade the plan to add more."
        )
