"""Scheduled-job endpoints, driven by an external cron (OS cron / CI schedule).

There is no in-process scheduler; instead a trusted external scheduler calls
these endpoints on a fixed cadence (e.g. daily) with the shared ``X-Cron-Secret``
header. Each endpoint is idempotent enough to run daily and decides internally
whether today is the day to act.
"""
from datetime import date

from fastapi import APIRouter, Header, HTTPException, status
from sqlalchemy import select

from app.core.config import settings
from app.core.deps import DbDep
from app.core.enums import SchoolStatus
from app.models.school import School
from app.modules.fees.service import FeeService

router = APIRouter(prefix="/jobs", tags=["Scheduled Jobs"])


def _authorize(secret: str | None) -> None:
    if not settings.CRON_SECRET:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Job endpoints are disabled (CRON_SECRET is not configured).",
        )
    if secret != settings.CRON_SECRET:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid cron secret"
        )


@router.post("/fee-reminders")
async def run_fee_reminders(
    db: DbDep,
    x_cron_secret: str | None = Header(default=None),
) -> dict:
    """For every active school, if today is ``FEE_REMINDER_LEAD_DAYS`` days before
    that school's configured salary payout day, remind guardians who owe fees.

    Meant to be called once per day. Schools without a ``salary_day`` setting, or
    where today isn't the trigger day, are skipped.
    """
    _authorize(x_cron_secret)

    lead = settings.FEE_REMINDER_LEAD_DAYS
    today = date.today()
    schools = list(
        (
            await db.execute(
                select(School).where(School.status == SchoolStatus.ACTIVE.value)
            )
        )
        .scalars()
        .all()
    )

    processed: list[dict] = []
    for school in schools:
        salary_day = (school.settings or {}).get("salary_day")
        if not isinstance(salary_day, int) or not (1 <= salary_day <= 31):
            continue
        # The reminder fires `lead` days before the salary day. Guard against
        # month-boundary underflow (e.g. salary_day 3, lead 5) by only matching
        # when the target day is a real day-of-month for the current run.
        target_day = salary_day - lead
        if target_day < 1 or today.day != target_day:
            continue
        count = await FeeService(db).send_fee_reminders(school.id)
        processed.append({"school_id": str(school.id), "notified_students": count})

    # The request-scoped session commits on success (see get_db).
    return {"date": today.isoformat(), "schools_processed": processed}
