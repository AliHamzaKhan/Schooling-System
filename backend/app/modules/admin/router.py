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


@router.get("/transactions", response_model=schemas.TransactionsReport)
async def transactions(
    db: DbDep, _: SuperAdmin, range: str = "all"
) -> schemas.TransactionsReport:
    """Payment ledger filtered by range (month | year | all) with a chart series."""
    return await AdminMetricsService(db).transactions(range_=range)


@router.get("/metrics", response_model=schemas.MetricsReport)
async def metrics(db: DbDep, _: SuperAdmin) -> schemas.MetricsReport:
    return await AdminMetricsService(db).metrics()


@router.get("/operations", response_model=schemas.OperationsStatus)
async def operations(db: DbDep, _: SuperAdmin) -> schemas.OperationsStatus:
    """Platform-only aggregate view of the durable delivery worker and outbox."""
    return await AdminMetricsService(db).operations()
