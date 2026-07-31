"""Platform (Super Admin) dashboard + revenue endpoints."""
from fastapi import APIRouter

from app.core.deps import DbDep, SuperAdmin
from app.modules.admin import schemas
from app.modules.admin.service import AdminMetricsService

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/dashboard", response_model=schemas.AdminDashboard)
async def dashboard(db: DbDep, _: SuperAdmin) -> schemas.AdminDashboard:
    return await AdminMetricsService(db).dashboard()


@router.get("/revenue", response_model=schemas.RevenueReport)
async def revenue(db: DbDep, _: SuperAdmin, months: int = 12) -> schemas.RevenueReport:
    return await AdminMetricsService(db).revenue(months=months)


@router.get("/billing", response_model=schemas.BillingReport)
async def billing(db: DbDep, _: SuperAdmin) -> schemas.BillingReport:
    return await AdminMetricsService(db).billing()


@router.get("/metrics", response_model=schemas.MetricsReport)
async def metrics(db: DbDep, _: SuperAdmin) -> schemas.MetricsReport:
    return await AdminMetricsService(db).metrics()
