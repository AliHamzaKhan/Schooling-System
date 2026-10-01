"""Backup/restore and migration-rollback drill against an isolated copy.

1. ``pg_dump`` the source database (custom format) and checksum the file.
2. Restore it into a newly created scratch database on the same server.
3. Compare the schema revision and exact row counts of every table.
4. Roll the scratch copy back ``--rollback-steps`` Alembic revisions and
   forward to head again, then compare counts once more.
5. Drop the scratch database (``--keep`` leaves it for inspection).

The source database is only read. Output is JSON with timings, revision,
checksum and per-table counts; no URLs, credentials or row contents::

    python scripts/drill_backup_restore.py --rollback-steps 1

The credentials need CREATEDB on the server. Use a staging copy, never the
primary production server, for the rollback step.
"""
from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND))

from sqlalchemy import text  # noqa: E402
from sqlalchemy.engine import make_url  # noqa: E402
from sqlalchemy.ext.asyncio import create_async_engine  # noqa: E402

from app.core.config import settings  # noqa: E402


def _pg_env(url) -> dict[str, str]:
    env = dict(os.environ)
    env.update({
        "PGHOST": url.host or "localhost", "PGPORT": str(url.port or 5432),
        "PGUSER": url.username or "", "PGPASSWORD": url.password or "", "PGDATABASE": url.database or "",
    })
    return env


async def _snapshot(url) -> dict:
    engine = create_async_engine(url)
    try:
        async with engine.connect() as conn:
            tables = (await conn.execute(text(
                "SELECT table_name FROM information_schema.tables "
                "WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name"
            ))).scalars().all()
            counts = {}
            for table in tables:
                counts[table] = (await conn.execute(text(f'SELECT count(*) FROM "{table}"'))).scalar_one()
            revision = None
            if "alembic_version" in tables:
                revision = (await conn.execute(text("SELECT version_num FROM alembic_version"))).scalar()
        return {"revision": revision, "counts": counts}
    finally:
        await engine.dispose()


async def _admin(url, statement: str) -> None:
    engine = create_async_engine(url.set(database="postgres"), isolation_level="AUTOCOMMIT")
    try:
        async with engine.connect() as conn:
            await conn.exec_driver_sql(statement)
    finally:
        await engine.dispose()


def _run(command: list[str], env: dict[str, str]) -> float:
    started = time.perf_counter()
    result = subprocess.run(command, env=env, cwd=BACKEND, capture_output=True, text=True)
    if result.returncode != 0:
        # stderr of pg tools / alembic does not include passwords.
        raise RuntimeError(f"{command[0]} {command[1] if len(command) > 1 else ''} failed: {result.stderr.strip()[-800:]}")
    return round(time.perf_counter() - started, 2)


def _diff(before: dict, after: dict) -> dict:
    tables = sorted(set(before) | set(after))
    return {t: [before.get(t), after.get(t)] for t in tables if before.get(t) != after.get(t)}


async def drill(source_url: str, rollback_steps: int, keep: bool) -> dict:
    source = make_url(source_url)
    scratch_name = f"restore_drill_{uuid.uuid4().hex[:12]}"
    scratch = source.set(database=scratch_name)
    report: dict = {"scratch_database": scratch_name}
    before = await _snapshot(source)
    report["source_revision"] = before["revision"]
    report["tables"] = len(before["counts"])
    report["rows"] = sum(before["counts"].values())

    with tempfile.TemporaryDirectory() as tmp:
        dump = Path(tmp) / "backup.dump"
        report["backup_seconds"] = _run(["pg_dump", "-Fc", "--no-owner", "-f", str(dump)], _pg_env(source))
        report["backup_bytes"] = dump.stat().st_size
        report["backup_sha256"] = hashlib.sha256(dump.read_bytes()).hexdigest()
        await _admin(source, f'CREATE DATABASE "{scratch_name}"')
        try:
            report["restore_seconds"] = _run(
                ["pg_restore", "--no-owner", "--exit-on-error", "-d", scratch_name, str(dump)], _pg_env(scratch),
            )
            restored = await _snapshot(scratch)
            report["restore_revision_matches"] = restored["revision"] == before["revision"]
            report["restore_count_differences"] = _diff(before["counts"], restored["counts"])

            if rollback_steps:
                env = dict(os.environ, DATABASE_URL=scratch.render_as_string(hide_password=False),
                           DB_HOST="", DB_NAME="", DB_USER="")
                report["downgrade_seconds"] = _run(["alembic", "downgrade", f"-{rollback_steps}"], env)
                down = await _snapshot(scratch)
                report["rolled_back_to"] = down["revision"]
                report["upgrade_seconds"] = _run(["alembic", "upgrade", "head"], env)
                forward = await _snapshot(scratch)
                report["upgrade_revision_matches"] = forward["revision"] == before["revision"]
                # Tables a rolled-back revision created come back empty; anything
                # else differing means the rollback lost data.
                report["rollback_count_differences"] = _diff(restored["counts"], forward["counts"])
        finally:
            if not keep:
                await _admin(source, f'DROP DATABASE IF EXISTS "{scratch_name}" WITH (FORCE)')
                report["scratch_dropped"] = True
    report["ok"] = bool(
        report.get("restore_revision_matches") and not report.get("restore_count_differences")
        and (not rollback_steps or report.get("upgrade_revision_matches"))
    )
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--source-url", default=os.environ.get("DRILL_SOURCE_DATABASE_URL", settings.DATABASE_URL))
    parser.add_argument("--rollback-steps", type=int, default=1, help="0 skips the rollback drill")
    parser.add_argument("--keep", action="store_true", help="keep the scratch database")
    args = parser.parse_args()
    try:
        report = asyncio.run(drill(args.source_url, args.rollback_steps, args.keep))
    except Exception as exc:  # report without echoing connection details
        print(json.dumps({"ok": False, "error": str(exc)[:1000], "error_type": type(exc).__name__}, indent=2))
        return 1
    print(json.dumps(report, indent=2))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
