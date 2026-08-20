"""Idempotent seed script: subscription plans, system roles, and super admin.

Run with: python -m app.seed
For local/dev convenience it also creates tables if they don't exist. In
staging/production, use Alembic migrations instead.
"""
import asyncio

from sqlalchemy import select

from app.core.config import settings
from app.core.constants import PLAN_MAX_STUDENTS, PLAN_MODULES, PLAN_NAMES, PLAN_PRICES
from app.core.database import AsyncSessionLocal, engine
from app.core.enums import BillingPeriod, Module, PermissionAction, SystemRole
from app.core.security import hash_password
from app.models import Base
from app.models.role import Role, RolePermission
from app.models.subscription import SubscriptionPlan
from app.models.user import User

ALL_ACTIONS = [a.value for a in PermissionAction]


async def _create_tables() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def _seed_plans(db) -> None:
    for code, modules in PLAN_MODULES.items():
        existing = await db.scalar(select(SubscriptionPlan).where(SubscriptionPlan.code == code.value))
        module_values = [m.value for m in modules]
        price = PLAN_PRICES[code]
        if existing is None:
            db.add(
                SubscriptionPlan(
                    code=code.value,
                    name=PLAN_NAMES[code],
                    modules=module_values,
                    price=price,
                    billing_period=BillingPeriod.MONTHLY.value,
                    max_students=PLAN_MAX_STUDENTS.get(code),
                )
            )
        else:
            existing.modules = module_values
            existing.name = PLAN_NAMES[code]
            # Only seed a price if one hasn't been set yet (don't clobber admin edits).
            if not existing.price:
                existing.price = price
            # Backfill the student cap only when it was never set.
            if existing.max_students is None:
                existing.max_students = PLAN_MAX_STUDENTS.get(code)


def _full_permission(module: str) -> RolePermission:
    return RolePermission(
        module=module,
        can_view=True,
        can_create=True,
        can_edit=True,
        can_delete=True,
        can_approve=True,
        can_export=True,
    )


async def _seed_system_roles(db) -> None:
    """Create platform-level system roles (school_id NULL).

    SUPER_ADMIN is granted everything (it also bypasses checks in code). The
    other system roles are created as templates; schools clone/extend them.
    """
    super_admin = await db.scalar(
        select(Role).where(Role.code == SystemRole.SUPER_ADMIN.value, Role.school_id.is_(None))
    )
    if super_admin is None:
        super_admin = Role(
            code=SystemRole.SUPER_ADMIN.value,
            name="Super Admin",
            is_system=True,
            permissions=[_full_permission(m.value) for m in Module],
        )
        db.add(super_admin)

    for role_code, label in (
        (SystemRole.HEADMASTER, "Headmaster"),
        (SystemRole.TEACHER, "Teacher"),
        (SystemRole.GUARDIAN, "Guardian"),
        (SystemRole.STUDENT, "Student"),
        (SystemRole.DRIVER, "Driver"),
    ):
        existing = await db.scalar(
            select(Role).where(Role.code == role_code.value, Role.school_id.is_(None))
        )
        if existing is None:
            db.add(Role(code=role_code.value, name=label, is_system=True))


async def _seed_super_admin(db) -> None:
    email = settings.FIRST_SUPERADMIN_EMAIL.lower()
    existing = await db.scalar(select(User).where(User.email == email))
    if existing is not None:
        return
    role = await db.scalar(
        select(Role).where(Role.code == SystemRole.SUPER_ADMIN.value, Role.school_id.is_(None))
    )
    user = User(
        email=email,
        hashed_password=hash_password(settings.FIRST_SUPERADMIN_PASSWORD),
        full_name="Platform Super Admin",
        is_active=True,
        school_id=None,
        roles=[role] if role else [],
    )
    db.add(user)


async def main() -> None:
    await _create_tables()
    async with AsyncSessionLocal() as db:
        await _seed_plans(db)
        await _seed_system_roles(db)
        await db.flush()
        await _seed_super_admin(db)
        await db.commit()
    await engine.dispose()
    print("Seed complete.")


if __name__ == "__main__":
    asyncio.run(main())
