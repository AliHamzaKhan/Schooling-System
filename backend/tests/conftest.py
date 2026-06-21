"""Pytest fixtures: isolated test DB, ASGI client, and a ready-to-use school.

The schema is created and seeded once when this module is imported. Each test
gets its own engine/session (created inside the test's event loop) and an
isolated premium, active school with a fresh Headmaster, so tests don't collide.
"""
import asyncio
import os
from uuid import uuid4

# Point the app at the dedicated test database BEFORE importing app modules.
os.environ["DATABASE_URL"] = "postgresql+asyncpg://aliawan@localhost:5432/schooling_system_test"
os.environ["ENVIRONMENT"] = "test"

import pytest_asyncio  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine  # noqa: E402

from app.core.config import settings  # noqa: E402
from app.core.database import get_db  # noqa: E402
from app.main import app  # noqa: E402
from app.models import Base  # noqa: E402
from app.seed import _seed_plans, _seed_super_admin, _seed_system_roles  # noqa: E402

API = settings.API_V1_PREFIX
TEST_URL = settings.DATABASE_URL


def _prepare_database() -> None:
    """Create a fresh schema and seed plans/roles/super-admin once."""
    async def go() -> None:
        engine = create_async_engine(TEST_URL)
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
            await conn.run_sync(Base.metadata.create_all)
        sm = async_sessionmaker(engine, expire_on_commit=False)
        async with sm() as db:
            await _seed_plans(db)
            await _seed_system_roles(db)
            await db.flush()
            await _seed_super_admin(db)
            await db.commit()
        await engine.dispose()

    asyncio.run(go())


_prepare_database()


@pytest_asyncio.fixture
async def client() -> AsyncClient:
    """An ASGI client whose get_db is backed by the test database."""
    engine = create_async_engine(TEST_URL)
    sessionmaker = async_sessionmaker(engine, expire_on_commit=False)

    async def override_get_db():
        async with sessionmaker() as session:
            try:
                yield session
                await session.commit()
            except Exception:
                await session.rollback()
                raise

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()
    await engine.dispose()


async def _login(client: AsyncClient, email: str, password: str) -> dict[str, str]:
    resp = await client.post(f"{API}/auth/login", data={"username": email, "password": password})
    assert resp.status_code == 200, resp.text
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


@pytest_asyncio.fixture
async def sa_headers(client: AsyncClient) -> dict[str, str]:
    return await _login(client, settings.FIRST_SUPERADMIN_EMAIL, settings.FIRST_SUPERADMIN_PASSWORD)


@pytest_asyncio.fixture
async def school(client: AsyncClient, sa_headers: dict[str, str]) -> dict:
    """A premium, active school with a provisioned Headmaster (full perms)."""
    code = "T-" + uuid4().hex[:8]
    r = await client.post(f"{API}/schools", headers=sa_headers, json={"name": "Test School", "code": code})
    assert r.status_code == 201, r.text
    sid = r.json()["id"]
    await client.post(f"{API}/schools/{sid}/subscription", headers=sa_headers, json={"plan_code": "premium"})
    await client.post(f"{API}/schools/{sid}/status", headers=sa_headers, json={"status": "active"})
    email = f"head-{uuid4().hex[:8]}@test.edu"
    rh = await client.post(
        f"{API}/schools/{sid}/headmaster", headers=sa_headers,
        json={"email": email, "password": "HeadPass123", "full_name": "Head Master"},
    )
    assert rh.status_code == 201, rh.text
    hm = await _login(client, email, "HeadPass123")
    return {"id": sid, "code": code, "hm": hm, "sa": sa_headers, "hm_email": email}
