# Payment safety and precision migration — F06

Updated: 2026-09-26. F06.1–F06.3 are implemented locally; F06 remains In progress.
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
payroll protections remain open. Deploy the backend first: old
servers can ignore unknown headers. Do not claim an older server is retry-safe.

## Platform subscription mutation safety

`POST /api/v1/subscriptions` and
`POST /api/v1/subscriptions/{subscription}/renew` accept the same optional
`Idempotency-Key: <UUID>` header. For assignment, the key is the durable
subscription identity; for renewal, it is the durable payment-ledger identity.
The service takes a transaction-scoped advisory lock for the key, then locks the
affected school or subscription row before changing state. This prevents an
overlapping retry from recording another initial or renewal payment.

- Repeating the same assignment key and immutable request details returns the
  existing subscription and does not create another initial payment.
- Repeating the same renewal key for that subscription returns the subscription
  and does not add another renewal payment. Reusing either key for incompatible
  details or a different subscription returns 409.
- The key must be reused after an unknown timeout or 5xx. A new key is a new
  subscription/payment intent. Existing keyless callers remain supported but
  have no retry deduplication guarantee.
- Payslip creation locks its staff profile before the period duplicate check;
  marking a payslip paid locks the payslip row. The existing period unique
  constraint remains the database invariant.

This provides mutation safety. It does not establish a refund, credit-note,
waiver or payroll-adjustment policy, and it does not convert Float fee/payroll
storage to exact decimal storage.

## Manual school billing policy

School fees are a **manual accounting workflow**. The application does not
initiate, capture, settle or reconcile Stripe, card-processor, bank, wallet or
other provider transactions. A bank transfer, cash payment or cheque becomes a
fee payment only when a school user records it against the correct invoice.

- The Headmaster manages the selected guardian billing contacts for each
  student. Those contacts contain billing-specific email, phone and payer
  reference snapshots; they never replace the guardian's account profile.
- A manual payment may include a private PDF/image proof, such as a bank
  transfer screenshot. The proof must be a managed upload owned by its recorder
  and can be downloaded only by that recorder, the Headmaster or Super Admin.
- The Headmaster is the school approver for refunds, credits, waivers and
  payroll corrections. Those future operations must be appended to an immutable
  adjustment ledger with request, reason, reviewer and decision timestamps;
  they must never rewrite an existing payment or published payslip.
- The initial adjustment ledger records a positive proposed decimal as text
  alongside an explicit three-letter currency code, then permits exactly one
  Headmaster approval or rejection. It validates that a fee adjustment targets
  a school invoice and a payroll correction targets a school payslip. It is
  intentionally non-posting until the currency, scale and rounding policy is
  approved; a recorded decision never changes an invoice, payment or payslip.
- No provider secret, webhook, hosted checkout, bank credential or automatic
  payment-status assumption belongs in the product. A submitted screenshot is
  evidence for a Headmaster's manual decision, not provider confirmation.
- The Headmaster-only aging report is read-only and derives each outstanding
  balance from the payment ledger, grouped as Current, 1–30, 31–60, 61–90 and
  91+ days as of a requested report date. It does not repair invoice caches or
  create an accounting adjustment.
- The Headmaster-only reconciliation report compares each eligible invoice's
  cached paid total and status against its payment ledger. It reports bounded
  discrepancies (including historical overpayments) for review and never
  repairs, deletes or changes an invoice.

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

## F06.3 read-only rehearsal tool

`backend/scripts/audit_money_precision.py` makes the currency, scale and rounding
choice explicit for a reconciliation rehearsal. It opens `SET TRANSACTION READ ONLY`,
examines fee, payroll and existing subscription money fields, and reports only counts, school/record IDs and
structural states (`requires_rounding`, cached-ledger mismatch or overpayment). It
never changes rows or emits amount values, names, references or the database URL.

```bash
MONEY_AUDIT_DATABASE_URL='postgresql+asyncpg://<read-only-user>:<password>@<host>/<db>' \
  python scripts/audit_money_precision.py --currency <approved-code> --scale <approved-scale> \
  --rounding <half-up|half-even> --details
```

The command is deliberately not a migration and does not establish a policy. Do not
run it against production until the currency/scale/rounding decision and read-only
credential are approved. A clean report is evidence for an additive migration rehearsal,
not approval to convert or delete existing floats.

## Additive migration package (prepared, not executable until policy approval)

The migration must add policy-named exact columns alongside every Float fee and
payroll amount; it must not alter or rewrite the current columns in place. The
approved migration will include at least the following mappings and a separate
currency snapshot decision for each historical record type:

| Current field | Shadow field purpose | Reconciliation invariant |
| --- | --- | --- |
| `fee_structures.amount` | configured exact fee amount | source converts once under the approved rule |
| `invoices.amount`, `invoices.amount_paid` | exact charge and cache | exact `amount_paid` equals sum of exact payments |
| `payments.amount` | exact immutable ledger amount | payment UUID/count preserved and sum matches invoices |
| `staff_profiles.base_salary` | exact salary basis | published payslip remains a snapshot of its inputs |
| payslip monetary totals | exact published total snapshots | gross − deductions equals net under approved rounding |

Preparation, rehearsal and rollback are deliberately staged:

1. Take an authorized backup and prove its restoration into an isolated copy.
2. Run the read-only audit for the approved policy, resolve every exception, and
   capture source-row counts plus exact-ledger reconciliation totals.
3. Apply the additive migration only to the restored copy. Backfill in bounded,
   restartable batches without changing existing Float fields or payment IDs.
4. Validate every invariant above, report/receipt totals and API compatibility;
   then rehearse rollback by disabling exact-column reads while preserving every
   write made during the rehearsal.
5. Schedule a production write-control window only after independent financial
   acceptance. Keep the old columns until the approved observation period ends.

Verification and progress: [Phase 1 verification](PHASE_1_VERIFICATION.md),
[product tracker](PRODUCT_ENHANCEMENT_PLAN.md).
