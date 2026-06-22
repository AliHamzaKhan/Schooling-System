"""FastAPI application entrypoint."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.core.config import settings
from app.core.ratelimit import limiter
from app.modules.academic.router import router as academic_router
from app.modules.ai.router import router as ai_router
from app.modules.attendance.router import router as attendance_router
from app.modules.auth.router import router as auth_router
from app.modules.communication.router import router as communication_router
from app.modules.examination.router import router as examination_router
from app.modules.fees.router import router as fees_router
from app.modules.homework.router import router as homework_router
from app.modules.hostel.router import router as hostel_router
from app.modules.hr.router import router as hr_router
from app.modules.inventory.router import router as inventory_router
from app.modules.leave.router import router as leave_router
from app.modules.meetings.router import router as meetings_router
from app.modules.online_classes.router import router as online_classes_router
from app.modules.library.router import router as library_router
from app.modules.transport.router import router as transport_router
from app.modules.permissions.router import router as permissions_router
from app.modules.reports.router import router as reports_router
from app.modules.roles.router import router as roles_router
from app.modules.schools.router import router as schools_router
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

app.include_router(auth_router, prefix=settings.API_V1_PREFIX)
app.include_router(permissions_router, prefix=settings.API_V1_PREFIX)
app.include_router(schools_router, prefix=settings.API_V1_PREFIX)
app.include_router(users_router, prefix=settings.API_V1_PREFIX)
app.include_router(roles_router, prefix=settings.API_V1_PREFIX)
app.include_router(academic_router, prefix=settings.API_V1_PREFIX)
app.include_router(attendance_router, prefix=settings.API_V1_PREFIX)
app.include_router(examination_router, prefix=settings.API_V1_PREFIX)
app.include_router(fees_router, prefix=settings.API_V1_PREFIX)
app.include_router(homework_router, prefix=settings.API_V1_PREFIX)
app.include_router(communication_router, prefix=settings.API_V1_PREFIX)
app.include_router(reports_router, prefix=settings.API_V1_PREFIX)
app.include_router(library_router, prefix=settings.API_V1_PREFIX)
app.include_router(transport_router, prefix=settings.API_V1_PREFIX)
app.include_router(hostel_router, prefix=settings.API_V1_PREFIX)
app.include_router(hr_router, prefix=settings.API_V1_PREFIX)
app.include_router(inventory_router, prefix=settings.API_V1_PREFIX)
app.include_router(online_classes_router, prefix=settings.API_V1_PREFIX)
app.include_router(ai_router, prefix=settings.API_V1_PREFIX)
app.include_router(leave_router, prefix=settings.API_V1_PREFIX)
app.include_router(meetings_router, prefix=settings.API_V1_PREFIX)


@app.get("/health", tags=["Health"])
async def health() -> dict[str, str]:
    return {"status": "ok", "environment": settings.ENVIRONMENT}
