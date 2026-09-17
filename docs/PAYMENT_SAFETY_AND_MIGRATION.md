# Payment safety and precision migration — F06

Updated: 2026-09-15. F06.2 is implemented locally; F06 remains In progress.
No existing school data, payment IDs, money values or schema were migrated.

## Implemented fee-payment retry contract

Endpoint: `POST /api/v1/schools/{school}/fees/invoices/{invoice}/payments`.

- Clients may send `Idempotency-Key: <UUID>`. This UUID becomes the payment's
  durable primary key. Generate one random UUID per deliberate payment intent,
  not per HTTP attempt. It is not a credential or a payment reference number.
- Same key, school, invoice, recording user, amount, method, date, reference and
  note returns the original payment response (201), even when the invoice is
  now fully paid. Numeric JSON forms validated to the same amount are equivalent.
- Reuse with different validated details, invoice, school or recording actor is
  rejected with 409 and no new payment. Authorization and tenant checks still
  run before replay; the key cannot grant another user's access.
- Transaction-scoped PostgreSQL advisory locks serialize a key, followed by the
  existing invoice row lock. Concurrent identical attempts return one payment;
  different keys remain separate intents, subject to ledger balance checks.
  Lock collisions only serialize unrelated work; full UUID identity remains the
  authority. Rollback releases locks and does not consume the payment key.
- No separate cache or migration is needed: the existing payment UUID and
  immutable recorded fields hold the identity and comparison data. Existing
  keyless callers remain compatible but do NOT gain retry deduplication.
- Retry protection lasts while the payment record exists. Deletion/cascading
  deletion can remove that protection; retention/tombstones must be addressed
  before introducing payment deletion or promising permanent replay history.

Do not replace a key after an unknown timeout/5xx response. Retry the same body,
key and invoice, or reconcile the receipt first. Changing keys is a new payment
intent, even if amount/reference are identical. A definite 400/422 rejection
does not commit a payment; corrected data may use a fresh intent.

## Headmaster client integration

The school and admin apps share the headmaster data layer. It generates a UUID,
freezes amount/method/payment date and retains an uncertain attempt within that
service instance, scoped by recording user/school/invoice. Concurrent calls share
one in-flight future. Retrying resumes the original payload even if a later
invoice refresh or midnight changes the proposed values. An authenticated token
refresh also reuses the header/body. Confirmed success or 400/422 validation
rejection ends the attempt; ambiguous failures, 409 and auth failures retain it.

The Record Payment page disables the invoice action while recording, reports
uncertain outcomes honestly and refreshes balances after success. At narrow
widths, status/amount labels wrap and the payment action uses available width;
the previous no-op “Keep pending” button was removed. Tests cover 320-pixel,
large-text and desktop layouts.

**Limits:** this is not an offline queue or durable cross-device journal. Pending
attempts are lost when the data-layer instance/app is destroyed. After restart,
reconcile the receipt before manually starting another payment. Persisted secure
intent recovery, conflict resolution UX, keyless-client retirement and equivalent
payroll/subscription protections remain open. Deploy the backend first: old
servers can ignore unknown headers. Do not claim an older server is retry-safe.

## Precision inventory and decisions (design only)

| Area | Inspected storage | Required next work |
| --- | --- | --- |
| Fee structures | Float `amount` | Fixed-scale input/storage and per-currency definition |
| Invoices | Float `amount`, `amount_paid` | Authoritative ledger reconciliation and snapshot currency |
| Fee payments | Float `amount` | Exact money representation with existing IDs preserved |
| Staff/payroll | Float base salary, gross, deductions, net, allowances, absence deduction | Payroll calculation/rounding audit and immutable published payslip totals |
| Platform subscriptions | Existing `Numeric(10,2)` prices, discount values, net amounts and payments | Preserve Decimal semantics; check API conversions, payment locking/idempotency and percentage-vs-money meaning |
| Flutter fee displays | Several hardcoded dollar symbols and whole-unit formatting; salary formatting has different conventions | Agreed currency/locale and consistent minor-unit display, without silently relabeling history |

Currency policy is not established by the inspected data model. The user has
been asked which currency fees/payroll use and whether it varies by school.
Do not infer currency from location or a hardcoded UI symbol.

Before a migration is executable, agree:

1. School currency, platform billing currency, multi-currency requirements and
   where historical invoice/payment/payslip currency is snapshotted.
2. Allowed decimal scale, maximum values and rounding rules for payroll,
   discounts and existing fractional data. Reject excess precision on new writes
   unless an explicit rounding rule is approved.
3. Representation: use Decimal and a reviewed PostgreSQL Numeric precision/scale
   (for example `Numeric(18,2)` only if two minor digits and its range are agreed),
   or integer minor units with currency-specific scales. Do not retain binary
   Float arithmetic behind exact-looking displays.
4. Backward-compatible API representation and frontend parsing/formatting,
   including avoiding precision loss when large decimal amounts pass through
   JavaScript/Dart doubles. Existing subscription columns are not blindly recast.

## Controlled migration sequence (not run)

1. Inventory all money fields, writes, reports/exports, provider integrations and
   current schema revisions. Take and restore-test an authorized backup.
2. Run a read-only reconciliation report per school/invoice: original amounts,
   proposed conversion, ledger sum, cached totals and rounding delta. Flag
   non-finite values, excess scale, overpayments, negatives, missing owners and
   report/payslip inconsistencies. Never silently “repair” historical data.
3. Review exceptions and approve the currency/rounding policy. Implement and
   rehearse an additive/shadow-column migration on an isolated restored copy;
   preserve payment identifiers and verify before/after counts and totals.
4. Introduce validated decimal write/read contracts and database constraints,
   cut over under a documented write-control plan, then reconcile every report,
   receipt and published payslip. Coordinate old/new clients and rollback.
5. Monitor exceptions and prove restore/rollback without discarding payments
   created during rollout. Only retire old storage after independent acceptance.

Verification and progress: [Phase 1 verification](PHASE_1_VERIFICATION.md),
[product tracker](PRODUCT_ENHANCEMENT_PLAN.md).
