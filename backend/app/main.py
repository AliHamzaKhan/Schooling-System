"""FastAPI application entrypoint."""
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from sqlalchemy import text

from app.core import cache
from app.core.config import settings
from app.core.database import engine
from app.core.deps import enforce_school_context
from app.core.errors import install_error_handling
from app.core.middleware import SecurityHeadersMiddleware
from app.core.observability import RequestContextMiddleware, metrics_endpoint
from app.core.queue import close_pool
from app.core.ratelimit import limiter, rate_limit_exceeded_handler
from app.modules.academic.router import router as academic_router
from app.modules.ai.router import router as ai_router
from app.modules.attendance.router import router as attendance_router
from app.modules.calendar.router import router as calendar_router
from app.modules.auth.router import router as auth_router
from app.modules.communication.router import router as communication_router
from app.modules.courses.router import router as courses_router
from app.modules.schoolinfo.router import router as schoolinfo_router
from app.modules.documents.router import router as documents_router
from app.modules.examination.router import router as examination_router
from app.modules.fees.router import router as fees_router
from app.modules.homework.router import router as homework_router
from app.modules.hr.router import router as hr_router
from app.modules.inventory.router import router as inventory_router
from app.modules.jobs.router import router as jobs_router
from app.modules.leave.router import router as leave_router
from app.modules.lessons.router import router as lessons_router
from app.modules.guardians.router import router as guardians_router
from app.modules.meetings.router import router as meetings_router
from app.modules.messages.router import router as messages_router
from app.modules.transport.router import router as transport_router
from app.modules.uploads.router import router as uploads_router
from app.modules.uploads.downloads import router as downloads_router
from app.modules.uploads.public_media import router as public_media_router
from app.modules.permissions.router import router as permissions_router
from app.modules.promotion.router import router as promotion_router
from app.modules.quiz.router import router as quiz_router
from app.modules.reports.router import router as reports_router
from app.modules.roles.router import router as roles_router
from app.modules.schools.router import router as schools_router
from app.modules.subscriptions.router import router as subscriptions_router
from app.modules.admin.router import router as admin_router
from app.modules.users.router import router as users_router

@asynccontextmanager
async def lifespan(_app: FastAPI):
    # Startup: nothing eager — the background-queue pool is opened lazily on the
    # first enqueue so a deploy without Redis (dev) never dials out.
    yield
    # Shutdown: release the shared arq connection pool + cache client if opened.
    await close_pool()
    await cache.close()


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json",
    docs_url="/docs",
    lifespan=lifespan,
)

# Error handling. Added FIRST so it ends up the innermost middleware: an
# unhandled exception is converted to a JSON 500 *before* it can escape past
# CORS, which is what turns a server-side bug into an unreadable "Failed to
# fetch" in the browser. See app/core/errors.py.
install_error_handling(app)

# Rate limiting (per-IP). Routers opt in via `@limiter.limit(...)`; the
# middleware + handler turn breaches into HTTP 429.
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Observability + security headers. `add_middleware` prepends, so these — added
# last — sit OUTERMOST: every response (success, error, CORS preflight) gets a
# correlation id, is timed/counted, and carries the security headers.
app.add_middleware(RequestContextMiddleware)
app.add_middleware(SecurityHeadersMiddleware)

# Platform / self-service routers — NOT tenant-gated here. Each enforces its own
# access rules (Super Admin, or self-scoped to the caller's own school), and some
# have no `{school_id}` path parameter for a tenant guard to read.
#   • auth/permissions   — operate on the caller themselves
#   • schools            — Super Admin CRUD + Headmaster self-service profile
#   • subscriptions      — Super Admin plan/instance management + the per-school
#                          status route (must stay readable when expired so the
#                          Headmaster still sees the renewal alert)
#   • admin/jobs         — Super Admin platform metrics + cron
for _router in (
    auth_router,
    permissions_router,
    schools_router,
    subscriptions_router,
    admin_router,
    jobs_router,
    downloads_router,
):
    app.include_router(_router, prefix=settings.API_V1_PREFIX)

# School-scoped feature routers — every route lives under `/schools/{school_id}/…`
# and is gated by `enforce_school_context`, which enforces tenant isolation,
# account status, and subscription/school-active status on ALL of their endpoints
# (the Super Admin bypasses; per-endpoint permission checks still apply on top).
_tenant_dep = [Depends(enforce_school_context)]
for _router in (
    users_router,
    roles_router,
    academic_router,
    attendance_router,
    examination_router,
    fees_router,
    homework_router,
    courses_router,
    schoolinfo_router,
    communication_router,
    reports_router,
    transport_router,
    hr_router,
    inventory_router,
    ai_router,
    leave_router,
    meetings_router,
    messages_router,
    guardians_router,
    quiz_router,
    promotion_router,
    calendar_router,
    documents_router,
    lessons_router,
    uploads_router,
):
    app.include_router(_router, prefix=settings.API_V1_PREFIX, dependencies=_tenant_dep)

# Never mount the storage root. Private and legacy document/submission paths
# must go through record authorization, including when their old URL is known.
app.include_router(public_media_router)


@app.get("/health", tags=["Health"])
async def health() -> dict[str, str]:
    """Liveness: the process is up and serving. Cheap, no dependencies — used by
    the container/orchestrator to decide whether to restart the instance."""
    return {"status": "ok", "environment": settings.ENVIRONMENT}


@app.get("/health/ready", tags=["Health"])
async def readiness() -> JSONResponse:
    """Readiness: can this instance actually serve traffic *right now*? Checks the
    dependencies a request needs — Postgres, and Redis when configured — so a load
    balancer can pull an instance that's up but can't reach its backing services.
    Returns 503 with per-dependency detail when anything is down."""
    checks: dict[str, str] = {}
    ok = True

    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        checks["database"] = "ok"
    except Exception as exc:  # noqa: BLE001 — report, don't raise
        checks["database"] = f"error: {type(exc).__name__}"
        ok = False

    if settings.REDIS_URL:
        try:
            import redis.asyncio as aioredis

            client = aioredis.from_url(settings.REDIS_URL)
            try:
                await client.ping()
                checks["redis"] = "ok"
            finally:
                await client.aclose()
        except Exception as exc:  # noqa: BLE001
            checks["redis"] = f"error: {type(exc).__name__}"
            ok = False
    else:
        checks["redis"] = "not_configured"

    return JSONResponse(
        status_code=200 if ok else 503,
        content={"status": "ready" if ok else "not_ready", "checks": checks},
    )


# Prometheus metrics (request counts/latency + process CPU/memory). Scrape at
# GET /metrics; unauthenticated but should be firewalled to the monitoring net.
app.add_route("/metrics", metrics_endpoint)
