"""Report or remove uploaded files that no record references.

Dry run (default) only reports counts::

    python scripts/cleanup_unreferenced_uploads.py --min-age-days 7

Add ``--apply`` to delete the files and their ledger rows. Files stored before
the upload ledger existed are never considered. Run on a schedule (e.g. daily)
so abandoned uploads do not count against a school's storage allowance.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.database import AsyncSessionLocal, engine  # noqa: E402
from app.core.storage import get_storage  # noqa: E402
from app.modules.uploads.cleanup import cleanup_unreferenced  # noqa: E402


async def run(min_age_days: int, apply: bool) -> dict:
    try:
        async with AsyncSessionLocal() as db, db.begin():
            result = await cleanup_unreferenced(db, get_storage(), min_age_days=min_age_days, apply=apply)
        return {"orphan_count": result.orphan_count, "orphan_bytes": result.orphan_bytes, "deleted": result.deleted}
    finally:
        await engine.dispose()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--min-age-days", type=int, default=7)
    parser.add_argument("--apply", action="store_true", help="delete the orphaned files")
    args = parser.parse_args()
    if args.min_age_days < 1:
        parser.error("--min-age-days must be at least 1")
    print(json.dumps(asyncio.run(run(args.min_age_days, args.apply)), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
