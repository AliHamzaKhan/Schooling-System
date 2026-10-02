"""Read-only F06.3 reconciliation for a proposed money precision policy.

Use a read-only database credential and state the proposed policy explicitly::

    MONEY_AUDIT_DATABASE_URL=postgresql+asyncpg://... \
      python scripts/audit_money_precision.py --currency PKR --scale 2 --rounding half-up

This command neither writes nor prints money values, names, references or its
database URL. It reports only counts, school IDs and structural exceptions for
an authorized migration review. It covers fee, payroll and platform-subscription
money fields; percentage discounts are deliberately excluded because they are
rates, not currency amounts. It is a rehearsal aid, not a data migration.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import math
import os
from collections import Counter
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation, ROUND_HALF_EVEN, ROUND_HALF_UP
from pathlib import Path
import sys
from typing import Any, Iterable

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine


ROUNDING = {"half-up": ROUND_HALF_UP, "half-even": ROUND_HALF_EVEN}


@dataclass(frozen=True)
class PrecisionPolicy:
    currency: str
    scale: int
    rounding: str

    @property
    def quantum(self) -> Decimal:
        return Decimal(1).scaleb(-self.scale)


def policy_from_args(currency: str, scale: int, rounding: str) -> PrecisionPolicy:
    normalized = currency.strip().upper()
    if len(normalized) != 3 or not normalized.isalpha():
        raise ValueError("currency must be a three-letter ISO-style code")
    if not 0 <= scale <= 6:
        raise ValueError("scale must be between 0 and 6")
    if rounding not in ROUNDING:
        raise ValueError("rounding must be half-up or half-even")
    return PrecisionPolicy(normalized, scale, rounding)


def classify_amount(value: Any, policy: PrecisionPolicy, *, allow_zero: bool) -> str:
    """Return a structural category without exposing the financial value."""
    try:
        if isinstance(value, float) and not math.isfinite(value):
            return "non_finite"
        amount = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        return "invalid"
    if not amount.is_finite():
        return "non_finite"
    if amount < 0 or (not allow_zero and amount == 0):
        return "invalid_sign"
    try:
        rounded = amount.quantize(policy.quantum, rounding=ROUNDING[policy.rounding])
    except InvalidOperation:
        return "invalid"
    return "already_scaled" if amount == rounded else "requires_rounding"


def reconcile_invoice(amount: Any, amount_paid: Any, payment_total: Any, policy: PrecisionPolicy) -> str:
    """Compare cached and ledger totals under the proposed policy, without values."""
    try:
        charge = Decimal(str(amount)).quantize(policy.quantum, rounding=ROUNDING[policy.rounding])
        cached = Decimal(str(amount_paid)).quantize(policy.quantum, rounding=ROUNDING[policy.rounding])
        ledger = Decimal(str(payment_total)).quantize(policy.quantum, rounding=ROUNDING[policy.rounding])
    except (InvalidOperation, TypeError, ValueError):
        return "invalid"
    if not all(item.is_finite() for item in (charge, cached, ledger)):
        return "invalid"
    if cached != ledger:
        return "cached_total_mismatch"
    if ledger > charge:
        return "overpaid"
    return "reconciled"


def report(
    policy: PrecisionPolicy,
    amounts: Iterable[tuple[str, str, Any, bool]],
    invoices: Iterable[tuple[str, str, Any, Any, Any]],
    *,
    details: bool,
) -> dict[str, Any]:
    amount_counts: Counter[tuple[str, str]] = Counter()
    invoice_counts: Counter[tuple[str, str]] = Counter()
    exceptions: list[dict[str, str]] = []
    for school_id, source, value, allow_zero in amounts:
        state = classify_amount(value, policy, allow_zero=allow_zero)
        amount_counts[(source, state)] += 1
        if details and state not in {"already_scaled"}:
            exceptions.append({"school_id": school_id, "source": source, "state": state})
    for school_id, invoice_id, amount, amount_paid, payment_total in invoices:
        state = reconcile_invoice(amount, amount_paid, payment_total, policy)
        invoice_counts[("invoice_ledger", state)] += 1
        if details and state != "reconciled":
            exceptions.append({"school_id": school_id, "source": "invoice_ledger", "record_id": invoice_id, "state": state})
    return {
        "read_only": True,
        "policy": {"currency": policy.currency, "scale": policy.scale, "rounding": policy.rounding},
        "amount_summary": [
            {"source": source, "state": state, "count": count}
            for (source, state), count in sorted(amount_counts.items())
        ],
        "invoice_summary": [
            {"source": source, "state": state, "count": count}
            for (source, state), count in sorted(invoice_counts.items())
        ],
        **({"exceptions": exceptions} if details else {}),
    }


async def run(database_url: str, policy: PrecisionPolicy, details: bool) -> dict[str, Any]:
    engine = create_async_engine(database_url)
    try:
        async with AsyncSession(engine) as db:
            async with db.begin():
                await db.execute(text("SET TRANSACTION READ ONLY"))
                rows = (await db.execute(text("""
                    SELECT school_id::text, 'fee_structure' AS source, amount, false AS allow_zero FROM fee_structures
                    UNION ALL SELECT school_id::text, 'invoice_amount', amount, false FROM invoices
                    UNION ALL SELECT school_id::text, 'invoice_paid', amount_paid, true FROM invoices
                    UNION ALL SELECT school_id::text, 'payment', amount, false FROM payments WHERE method <> 'refund'
                    -- Approved refunds are negative ledger rows; check their size.
                    UNION ALL SELECT school_id::text, 'refund', -amount, false FROM payments WHERE method = 'refund'
                    UNION ALL SELECT school_id::text, 'staff_salary', base_salary, true FROM staff_profiles
                    UNION ALL SELECT school_id::text, 'payslip_gross', gross, true FROM payslips
                    UNION ALL SELECT school_id::text, 'payslip_allowances', allowances, true FROM payslips
                    UNION ALL SELECT school_id::text, 'payslip_deductions', deductions, true FROM payslips
                    UNION ALL SELECT school_id::text, 'payslip_net', net, true FROM payslips
                    UNION ALL SELECT school_id::text, 'payslip_absence_deduction', absence_deduction, true FROM payslips
                    UNION ALL SELECT 'platform', 'subscription_plan_price', price, true FROM subscription_plans
                    UNION ALL SELECT school_id::text, 'subscription_base_price', base_price, true FROM school_subscriptions
                    UNION ALL SELECT school_id::text, 'subscription_discount_fixed', discount_value, true
                        FROM school_subscriptions WHERE discount_type = 'fixed'
                    UNION ALL SELECT school_id::text, 'subscription_net_amount', net_amount, true FROM school_subscriptions
                    UNION ALL SELECT school_id::text, 'subscription_payment', amount, true FROM subscription_payments
                """))).all()
                invoices = (await db.execute(text("""
                    SELECT i.school_id::text, i.id::text, i.amount, i.amount_paid,
                           COALESCE(SUM(p.amount), 0)
                    FROM invoices i LEFT JOIN payments p ON p.invoice_id = i.id
                    GROUP BY i.school_id, i.id, i.amount, i.amount_paid
                """))).all()
        return report(policy, rows, invoices, details=details)
    finally:
        await engine.dispose()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database-url", default=os.environ.get("MONEY_AUDIT_DATABASE_URL"))
    parser.add_argument("--currency", required=True)
    parser.add_argument("--scale", type=int, required=True)
    parser.add_argument("--rounding", required=True, choices=sorted(ROUNDING))
    parser.add_argument("--details", action="store_true", help="include IDs for noncompliant rows, never values")
    args = parser.parse_args()
    if not args.database_url:
        parser.error("set MONEY_AUDIT_DATABASE_URL or pass --database-url")
    try:
        result = asyncio.run(run(args.database_url, policy_from_args(args.currency, args.scale, args.rounding), args.details))
        print(json.dumps(result, indent=2, sort_keys=True))
    except Exception as exc:
        print(json.dumps({"error": "money audit failed", "error_type": type(exc).__name__}))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
