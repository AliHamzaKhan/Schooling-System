# Schooling System — Backend

FastAPI + PostgreSQL backend for the multi-tenant School Management SaaS.
Built as a **modular monolith** (one app, isolated `app/modules/<service>/`
packages) per [docs/permissions/09](../docs/permissions/09-architecture-and-dev-flow.md)
and the roadmap in [docs/permissions/10](../docs/permissions/10-development-process-and-roadmap.md).

## Foundation status (Steps 3–5 of the roadmap)

| Layer | Status |
|-------|--------|
| Project skeleton + config | ✅ |
| Async SQLAlchemy 2.0 + Alembic | ✅ |
| Core models (School, Subscription, Module toggles, User, Role, RolePermission) | ✅ |
| Auth Service (JWT + refresh, login, `/me`) | ✅ |
| Permission Service (RBAC cascade) + `require_permission` | ✅ |
| Seed (plans, system roles, super admin) | ✅ |
| Feature modules (school, users, academic, attendance, …) | ⏳ next |

## Layout

```
app/
  core/        config, database, security, enums, constants, exceptions, deps
  models/      SQLAlchemy models (the permission cascade is data-driven)
  modules/
    auth/        login / refresh / me
    permissions/ effective-access resolver + inspection endpoints
  main.py      FastAPI app
alembic/       async migration environment
seed.py        idempotent dev seed
```

## Quick start (Docker)

```bash
cp .env.example .env
docker compose up -d db redis
docker compose build api
docker compose run --rm api python -m app.seed   # create tables + seed
docker compose up api
```

API: http://localhost:8000 — Swagger UI at `/docs`.

## Quick start (local)

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env            # point DATABASE_URL at your Postgres
python -m app.seed              # creates tables + seeds plans/roles/admin
uvicorn app.main:app --reload
```

## Tests

```bash
pip install -r requirements-dev.txt
createdb schooling_system_test     # one-time
python -m pytest                   # 32 tests, ~30s
```

Tests run against a dedicated `schooling_system_test` database (schema created
and seeded fresh on each run). Each test gets an isolated premium school via the
`school` fixture, so tests don't collide. Coverage spans auth, the permission
cascade, and a happy-path + key guard for every feature module.

## Migrations

The seed auto-creates tables for dev. For staging/prod use Alembic:

```bash
alembic revision --autogenerate -m "initial schema"
alembic upgrade head
```

## The permission cascade

Enforcement lives in `app/modules/permissions/service.py` and implements
[docs/permissions/07](../docs/permissions/07-permission-flow.md):

```
Effective Access =
    School Module Toggle (Super Admin)
  ∩ Subscription Plan Feature
  ∩ Role / Staff Permission
```

Protect any future endpoint with:

```python
from app.core.deps import require_permission
from app.core.enums import Module, PermissionAction

@router.post("/exams", dependencies=[Depends(require_permission(Module.EXAMS, PermissionAction.CREATE))])
async def create_exam(...): ...
```

Default super admin credentials come from `.env`
(`FIRST_SUPERADMIN_EMAIL` / `FIRST_SUPERADMIN_PASSWORD`) — change them.
