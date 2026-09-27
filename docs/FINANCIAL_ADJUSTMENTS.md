# Financial adjustment contract

## Purpose

The manual school-billing workflow records proposed refunds, credits, waivers
and payroll corrections. It never uses Stripe, bank APIs, webhooks or automatic
settlement.

## Authority and targets

Only a Headmaster or Super Admin can create, view or decide an adjustment.

| Kind | Required target | Decision authority |
| --- | --- | --- |
| Refund | School invoice | Headmaster / Super Admin |
| Credit | School invoice | Headmaster / Super Admin |
| Waiver | School invoice | Headmaster / Super Admin |
| Payroll correction | School payslip | Headmaster / Super Admin |

Each proposal stores a positive submitted decimal string, a three-letter
currency code, a reason and the requesting user. A proposal has at most one
immutable approval or rejection. The database validates kind/target pairings,
currency-code format and decision values.

## Non-posting boundary

Recording or approving a proposal does not alter an invoice, payment, cached
invoice total, receipt, payslip or payroll payment. This prevents an apparently
exact monetary change while the product's currency scope, decimal scale and
rounding policy are still undecided.

Before decisions may post an accounting effect, approve and implement:

1. The currency scope for every school and payroll record.
2. Decimal scale, range and rounding rule.
3. Exact posting semantics for each adjustment kind, including whether a
   refund is a new manual disbursement record or an invoice credit.
4. Reconciliation invariants for invoices, receipts, aging and payslips.

## API

All endpoints are under `/schools/{school_id}/fees/adjustments` and require
school-admin authority.

- `POST /` creates a proposal.
- `GET /` lists the newest proposals.
- `POST /{adjustment_id}/decision` records the only approval or rejection.

These routes have no endpoint that modifies or deletes a proposal, decision or
target financial record.
