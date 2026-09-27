"""Redis-independent outbox runner: python -m app.delivery_worker [--once]."""
import argparse
import asyncio
import logging

from app.core.database import AsyncSessionLocal, engine
from app.core.errors import configure_logging
from app.modules.communication.outbox import OutboxWorker
from app.worker import record_worker_heartbeat

logger = logging.getLogger("app.delivery_worker")


async def run(once=False, interval=10):
    configure_logging()
    worker = OutboxWorker(AsyncSessionLocal)
    try:
        while True:
            try:
                await record_worker_heartbeat()
                await worker.run_due()
                await record_worker_heartbeat()
            except Exception:
                logger.warning("Outbox poll failed; awaiting database recovery")
                if once:
                    raise
            if once:
                return
            await asyncio.sleep(interval)
    finally:
        await engine.dispose()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--once", action="store_true")
    args = parser.parse_args()
    asyncio.run(run(once=args.once))
