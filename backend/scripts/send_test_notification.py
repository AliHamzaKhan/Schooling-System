"""Send one synthetic notification to verify a provider is configured.

Uses the same adapter as real broadcasts, with the provider settings from the
environment (.env or secrets). Send only to an approved test recipient you
control, never to a student, guardian or staff member::

    python scripts/send_test_notification.py --channel email \
        --to ops-test@your-school.org --approved-test-recipient

Prints the outcome (accepted / failed / simulated / uncertain) without the
address or message text. "accepted" means the provider took the message, not
that it reached the inbox or device; check the recipient yourself.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.modules.communication.providers import Notifier  # noqa: E402

CHANNELS = ("email", "push", "sms", "whatsapp")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--channel", choices=CHANNELS, required=True)
    parser.add_argument("--to", required=True, help="email address, phone number or FCM device token")
    parser.add_argument("--approved-test-recipient", action="store_true",
                        help="confirm the recipient is an approved synthetic test address")
    args = parser.parse_args()
    if not args.approved_test_recipient:
        parser.error("refusing to send: pass --approved-test-recipient for an approved test address")
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    result = asyncio.run(Notifier().dispatch(
        args.channel, args.to, "Meri Taleem delivery test", f"Delivery test sent {stamp}. No action needed.",
    ))
    print(json.dumps({"channel": args.channel, "status": result.status, "provider": result.provider,
                      "simulated": result.stub, "error": result.error}, indent=2))
    return 0 if result.status == "accepted" else 1


if __name__ == "__main__":
    raise SystemExit(main())
