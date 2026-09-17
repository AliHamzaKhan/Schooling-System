"""Provision a unique, restricted test database, run pytest, then clean it up.

Use SCHOOLING_TEST_ADMIN_URL for CI, or --from-local-config to explicitly use
the configured local server credentials for provisioning only. Never prints URLs.
The child test process receives only the new restricted role's database URL.
"""
import argparse
import asyncio
import os
from pathlib import Path
import secrets
import subprocess
import sys
import tempfile
import uuid

from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import create_async_engine

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


async def run() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--from-local-config", action="store_true")
    args, pytest_args = parser.parse_known_args()
    if pytest_args[:1] == ["--"]:
        pytest_args = pytest_args[1:]
    raw = os.environ.get("SCHOOLING_TEST_ADMIN_URL")
    if args.from_local_config:
        from app.core.config import settings
        if settings.ENVIRONMENT.lower() not in {"development", "dev", "local"}:
            parser.error("--from-local-config is restricted to development configuration")
        raw = settings.DATABASE_URL
    if not raw:
        parser.error("Set SCHOOLING_TEST_ADMIN_URL or explicitly choose --from-local-config")
    source = make_url(raw)
    if args.from_local_config and source.host not in {"localhost", "127.0.0.1", "::1"}:
        parser.error("--from-local-config only provisions on a loopback PostgreSQL server")
    if source.drivername != "postgresql+asyncpg":
        parser.error("Provisioning requires PostgreSQL with asyncpg")
    name = "schooling_test_" + uuid.uuid4().hex
    password = secrets.token_hex(24)
    maintenance = create_async_engine(source.set(database="postgres"), isolation_level="AUTOCOMMIT")
    role_created = database_created = False
    try:
        async with maintenance.connect() as conn:
            # Identifiers and password are generated internally from hex only.
            await conn.exec_driver_sql(
                f'CREATE ROLE "{name}" LOGIN PASSWORD \'{password}\' NOSUPERUSER NOCREATEDB NOCREATEROLE'
            )
            role_created = True
            await conn.exec_driver_sql(f'CREATE DATABASE "{name}" OWNER "{name}"')
            database_created = True
        print(f"Running tests in isolated database {name}", flush=True)
        env = os.environ.copy()
        env.pop("SCHOOLING_TEST_ADMIN_URL", None)
        env["SCHOOLING_TEST_DATABASE_URL"] = source.set(
            username=name, password=password, database=name, query={}
        ).render_as_string(hide_password=False)
        from app.core.test_database import configure_test_environment
        configure_test_environment(env)
        with tempfile.TemporaryDirectory(prefix="schooling-test-uploads-") as uploads:
            env["STORAGE_LOCAL_DIR"] = uploads
            env["STORAGE_BACKEND"] = "local"
            return subprocess.run(
                [sys.executable, "-m", "pytest", *(pytest_args or ["-q"])],
                env=env, cwd=Path(__file__).resolve().parents[1], check=False,
            ).returncode
    finally:
        try:
            async with maintenance.connect() as conn:
                if database_created:
                    # Only the exact database created by this invocation is removed.
                    await conn.exec_driver_sql(f'DROP DATABASE "{name}" WITH (FORCE)')
                if role_created:
                    await conn.exec_driver_sql(f'DROP ROLE "{name}"')
            if database_created:
                print(f"Removed isolated test database and role {name}", flush=True)
        finally:
            await maintenance.dispose()


if __name__ == "__main__":
    try:
        raise SystemExit(asyncio.run(run()))
    except Exception as exc:
        # Database exceptions can contain SQL/credentials; keep console output safe.
        print(f"Isolated test runner failed ({type(exc).__name__}); check local provisioning permissions.", file=sys.stderr)
        raise SystemExit(1) from None
