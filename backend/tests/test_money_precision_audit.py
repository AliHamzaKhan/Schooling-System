from scripts.audit_money_precision import (
    classify_amount, policy_from_args, reconcile_invoice, report,
)


def test_money_precision_policy_requires_explicit_safe_inputs():
    policy = policy_from_args("pkr", 2, "half-up")
    assert policy.currency == "PKR"
    assert classify_amount("10.005", policy, allow_zero=False) == "requires_rounding"
    assert classify_amount("10.00", policy, allow_zero=False) == "already_scaled"
    assert classify_amount("NaN", policy, allow_zero=True) == "non_finite"


def test_money_precision_reconciliation_detects_cached_ledger_mismatch_and_overpayment():
    policy = policy_from_args("USD", 2, "half-even")
    assert reconcile_invoice("100", "60", "50", policy) == "cached_total_mismatch"
    assert reconcile_invoice("100", "110", "110", policy) == "overpaid"
    assert reconcile_invoice("100", "100", "100", policy) == "reconciled"


def test_money_precision_report_never_includes_money_values():
    policy = policy_from_args("PKR", 2, "half-up")
    output = report(policy, [("school", "payment", "123.456", False)], [], details=True)
    assert output["read_only"] is True
    assert output["policy"]["currency"] == "PKR"
    assert "123.456" not in str(output)
    assert output["amount_summary"] == [{"source": "payment", "state": "requires_rounding", "count": 1}]


def test_subscription_money_rows_share_the_same_explicit_policy_audit():
    policy = policy_from_args("PKR", 2, "half-up")
    output = report(
        policy,
        [
            ("platform", "subscription_plan_price", "250.00", True),
            ("school", "subscription_payment", "249.999", True),
        ],
        [],
        details=True,
    )
    assert output["amount_summary"] == [
        {"source": "subscription_payment", "state": "requires_rounding", "count": 1},
        {"source": "subscription_plan_price", "state": "already_scaled", "count": 1},
    ]
    assert output["exceptions"] == [
        {"school_id": "school", "source": "subscription_payment", "state": "requires_rounding"}
    ]
