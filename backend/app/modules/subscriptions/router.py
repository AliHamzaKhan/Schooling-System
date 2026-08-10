"""Subscription endpoints.

Plan CRUD and subscription assignment/lifecycle are Super Admin only. The
per-school status route is available to any member of that school (it feeds the
Headmaster's subscription-expiry alert)."""
import uuid

from fastapi import APIRouter, Depends, status

from app.core.deps import DbDep, SuperAdmin, require_school_member
from app.modules.subscriptions import schemas
from app.modules.subscriptions.service import SubscriptionService

router = APIRouter(tags=["Subscriptions"])

# --------------------------------------------------------------------------- #
# Plans (Super Admin)
# --------------------------------------------------------------------------- #


@router.get("/subscription-plans", response_model=list[schemas.PlanOut])
async def list_plans(
    db: DbDep, _: SuperAdmin, include_archived: bool = False
) -> list[schemas.PlanOut]:
    return await SubscriptionService(db).list_plans(include_archived=include_archived)


@router.post(
    "/subscription-plans",
    response_model=schemas.PlanOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_plan(
    data: schemas.PlanCreate, db: DbDep, _: SuperAdmin
) -> schemas.PlanOut:
    return await SubscriptionService(db).create_plan(data)


@router.get("/subscription-plans/{plan_id}", response_model=schemas.PlanOut)
async def get_plan(plan_id: uuid.UUID, db: DbDep, _: SuperAdmin) -> schemas.PlanOut:
    return await SubscriptionService(db).get_plan(plan_id)


@router.patch("/subscription-plans/{plan_id}", response_model=schemas.PlanOut)
async def update_plan(
    plan_id: uuid.UUID, data: schemas.PlanUpdate, db: DbDep, _: SuperAdmin
) -> schemas.PlanOut:
    return await SubscriptionService(db).update_plan(plan_id, data)


@router.delete("/subscription-plans/{plan_id}", response_model=schemas.PlanOut)
async def archive_plan(
    plan_id: uuid.UUID, db: DbDep, _: SuperAdmin
) -> schemas.PlanOut:
    """Archives (soft-deletes) a plan so it stays for history but is hidden from
    new assignments."""
    return await SubscriptionService(db).archive_plan(plan_id)


# --------------------------------------------------------------------------- #
# Subscriptions (Super Admin)
# --------------------------------------------------------------------------- #


@router.post(
    "/subscriptions",
    response_model=schemas.SubscriptionOut,
    status_code=status.HTTP_201_CREATED,
)
async def assign_subscription(
    data: schemas.SubscriptionCreate, db: DbDep, _: SuperAdmin
) -> schemas.SubscriptionOut:
    return await SubscriptionService(db).assign(data)


@router.get("/subscriptions", response_model=list[schemas.SubscriptionOut])
async def list_subscriptions(
    db: DbDep, _: SuperAdmin, status_filter: str = "all"
) -> list[schemas.SubscriptionOut]:
    """`status_filter` = all | active | pending | history (expired + cancelled)."""
    return await SubscriptionService(db).list_subscriptions(status_filter)


@router.post("/subscriptions/{subscription_id}/renew", response_model=schemas.SubscriptionOut)
async def renew_subscription(
    subscription_id: uuid.UUID,
    data: schemas.SubscriptionRenew,
    db: DbDep,
    _: SuperAdmin,
) -> schemas.SubscriptionOut:
    return await SubscriptionService(db).renew(subscription_id, data)


@router.post("/subscriptions/{subscription_id}/cancel", response_model=schemas.SubscriptionOut)
async def cancel_subscription(
    subscription_id: uuid.UUID, db: DbDep, _: SuperAdmin
) -> schemas.SubscriptionOut:
    return await SubscriptionService(db).cancel(subscription_id)


# --------------------------------------------------------------------------- #
# Per-school status (any school member)
# --------------------------------------------------------------------------- #


@router.get(
    "/schools/{school_id}/subscription/status",
    response_model=schemas.SubscriptionStatusOut,
    dependencies=[Depends(require_school_member)],
)
async def school_subscription_status(
    school_id: uuid.UUID, db: DbDep
) -> schemas.SubscriptionStatusOut:
    return await SubscriptionService(db).get_school_status(school_id)


@router.get(
    "/schools/{school_id}/payments",
    response_model=list[schemas.PaymentOut],
)
async def school_payments(
    school_id: uuid.UUID, db: DbDep, _: SuperAdmin
) -> list[schemas.PaymentOut]:
    """Super Admin: a school's full payment ledger (newest first)."""
    return await SubscriptionService(db).list_school_payments(school_id)
