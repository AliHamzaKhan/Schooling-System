# Notification outcomes and remaining rollout gates — F07.1 / F07.2

Updated: 2026-09-15. This batch makes recorded outcomes honest; it does not make
the delivery pipeline production-ready. No provider credentials were changed and
no real notifications were sent during verification.

## Status meanings

| Status | Meaning |
| --- | --- |
| `scheduled` | Saved for future processing; not yet sent |
| `pending` | Saved and awaiting processing; does not prove a durable broker job exists |
| `uncertain` | Delivery requires review; never automatically resend |
| `simulated` | No provider delivery attempted; includes the email placeholder and unconfigured Twilio/FCM |
| `accepted` | A provider request succeeded; not proof of recipient delivery |
| `partial` | Some attempts accepted, others failed or were simulated |
| `failed` | No attempt accepted and at least one failed, or there were no recipients |
| `delivered` / `read` | Reserved recipient receipt states; current adapters do not manufacture these |
| `sent` | Legacy data only; not confirmed delivery and may include historical stubs |

Per-recipient records and summary counts preserve simulation/failure separately.
Push recipients without a registered device now receive an explicit failed attempt
instead of disappearing from counts. Unknown adapter outcomes fail closed. Legacy
adapter `sent` results become `accepted`; a stub flag/provider always wins and
becomes `simulated`, even if a custom adapter claims success.

The existing `sent_at` column is set only when at least one attempt was accepted;
it means provider-acceptance time, not confirmed recipient delivery time. All
statuses fit existing string columns. F07.1 required no schema or historical-data
migration. F07.2 separately prepares an additive outbox migration;
see [worker and migration gates](NOTIFICATION_OUTBOX_ROLLOUT.md).
Existing records remain unchanged and require a reviewed audit before
any reclassification. Never infer historic delivery from a `sent` label alone.

## User-facing behavior

Teacher and headmaster broadcast confirmation text follows the returned status,
not merely HTTP success. The headmaster announcements hub retains the status from
the API and shows a text label plus explanation, including failures and simulation.
Cards wrap at narrow widths and large text sizes. Teacher audience selection uses
the current grouped-radio API rather than deprecated per-tile state.

HTTP 201 means the broadcast was saved. F07.2 returns pending/scheduled and leaves
provider work to an independent worker; read later status for the outcome. Do not
blindly create another broadcast to retry: partial outcomes may already include
real provider side effects. Password recovery keeps the same neutral response for
known/unknown emails without falsely asserting that the placeholder sent a code.

## Remaining F07 acceptance work

- Implement and verify real email with approved provider settings and test
  recipients. The current email adapter is always simulated. Production recovery
  must not be advertised as functional until verified.
- Persist provider message IDs and verify signed callback/receipt handling before
  promoting accepted to delivered/read; map permanent vs retryable failures.
- F07.2 implements transactional intent, fenced leases, durable per-recipient
  attempt markers and bounded safe recovery. Migration and deployment acceptance
  remain open. Unknown outcomes require reconciliation, not automatic resending.
- Add audited reconciliation, request-level idempotency and provider-specific
  safe retry rules. The outbox does not provide exactly-once external delivery or
  a retry endpoint; repeated POSTs can still create separate broadcasts.
- Rehearse actual Redis/broker outage, worker restart, scheduled processing and
  provider timeout/ambiguous response behavior in staging. New worker tests use
  real isolated DB transactions and mocked providers; they are not real-broker
  recovery acceptance.
- Add provider readiness and delivery-detail/retry operations UI, public-facing
  notification-feed policy, recipient preferences, device logout/unregister and
  token reassignment/privacy review. Full tenant/action mapping remains F01/M02.
- Coordinate backend and frontend release: old clients may still display generic
  success wording or not recognize new statuses. Validate native builds separately.

See [progress tracker](PRODUCT_ENHANCEMENT_PLAN.md) and
[verification results](PHASE_1_VERIFICATION.md). Parent F07 remains In progress.
