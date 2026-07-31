"""FastAPI application entrypoint."""
from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.core.config import settings
from app.core.deps import enforce_school_context
from app.core.ratelimit import limiter
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
from app.modules.hostel.router import router as hostel_router
from app.modules.hr.router import router as hr_router
from app.modules.inventory.router import router as inventory_router
from app.modules.jobs.router import router as jobs_router
from app.modules.leave.router import router as leave_router
from app.modules.lessons.router import router as lessons_router
from app.modules.guardians.router import router as guardians_router
from app.modules.meetings.router import router as meetings_router
from app.modules.messages.router import router as messages_router
from app.modules.online_classes.router import router as online_classes_router
from app.modules.library.router import router as library_router
from app.modules.transport.router import router as transport_router
from app.modules.uploads.router import router as uploads_router
from app.modules.permissions.router import router as permissions_router
from app.modules.promotion.router import router as promotion_router
from app.modules.quiz.router import router as quiz_router
from app.modules.reports.router import router as reports_router
from app.modules.roles.router import router as roles_router
from app.modules.schools.router import router as schools_router
from app.modules.subscriptions.router import router as subscriptions_router
from app.modules.admin.router import router as admin_router
from app.modules.users.router import router as users_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json",
    docs_url="/docs",
)

# Rate limiting (per-IP). Routers opt in via `@limiter.limit(...)`; the
# middleware + handler turn breaches into HTTP 429.
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
    library_router,
    transport_router,
    hostel_router,
    hr_router,
    inventory_router,
    online_classes_router,
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

# Serve locally-stored uploads (STORAGE_BACKEND=local, i.e. development). Cloud
# backends return their own provider URLs, so this static mount is skipped.
if settings.STORAGE_BACKEND.lower() == "local":
    from pathlib import Path

    from fastapi.staticfiles import StaticFiles

    _media_dir = Path(settings.STORAGE_LOCAL_DIR)
    _media_dir.mkdir(parents=True, exist_ok=True)
    app.mount("/media", StaticFiles(directory=str(_media_dir)), name="media")


@app.get("/health", tags=["Health"])
async def health() -> dict[str, str]:
    return {"status": "ok", "environment": settings.ENVIRONMENT}
