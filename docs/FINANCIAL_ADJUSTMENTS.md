# Financial adjustment contract

## Purpose

The manual school-billing workflow records proposed refunds, credits, waivers
and payroll corrections. It never uses Stripe, bank APIs, webhooks or automatic
settlement.

## Authority and targets

Decided 2026-10-02 (product owner): finance staff request, the Headmaster
decides; a Headmaster's own adjustment applies at once.

| Who | Can do |
| --- | --- |
| Accountant (fee/payroll edit permission) | Request refunds, credits, waivers (fee edit) and payroll corrections (payroll edit); see the queue and export it. Cannot decide. |
| Headmaster / Super Admin | Make an adjustment that applies immediately (recorded with an automatic approval), and approve or reject requests. |

| Kind | Target | Effect when approved |
| --- | --- | --- |
| Waiver | Invoice | The charge drops by the amount (at most the balance owed). |
| Credit | Invoice | Same as a waiver. |
| Refund | Invoice | Money already paid is returned: a negative `refund` payment is added to the ledger and the charge drops by the same amount, so the balance owed does not change. At most the amount paid. |
| Payroll correction | Unpaid payslip | The amount is the corrected net pay; allowances (increase) or deductions (decrease) absorb the difference. A paid payslip cannot be corrected; correct the next one. |

Each request stores a positive amount, a three-letter code (`XXX`, no
currency, unless supplied), a reason and the requesting user, and has at most
one approval or rejection. An impossible request (e.g. a refund larger than
what was paid) is refused when it is made; one that becomes impossible later
cannot be approved and should be rejected.

## API

All endpoints are under `/schools/{school_id}/fees/adjustments`.

- `POST /` creates a request (finance staff) or an applied adjustment (Headmaster).
- `GET /` and `GET /export` list the newest adjustments (fee edit permission).
- `POST /{adjustment_id}/decision` records the only approval or rejection
  (Headmaster / Super Admin); approval posts the effect above in the same
  transaction.

No endpoint modifies or deletes an adjustment or decision.
