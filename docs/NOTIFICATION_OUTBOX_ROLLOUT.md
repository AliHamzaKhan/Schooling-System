# Transactional notification outbox — F07.2

Updated: 2026-09-15. Implemented locally and tested with disposable PostgreSQL
databases. **Migration prepared, not applied to existing school data.** No real
provider messages or deployment were performed.

## Contract and guarantees

The message and its `notification_outbox` row commit together with the business
transaction. Broadcast creation always returns pending/scheduled; there is no
inline provider send and no Redis enqueue in the request. Rolling back an
attendance/broadcast transaction rolls back its notification intent too.

A database worker claims due work with a row lock, a random ownership token and
a five-minute lease. It snapshots recipients once into pending delivery rows,
with a unique `(message_id, recipient_key)` constraint. It rechecks current school,
active audience and address/device ownership before starting each attempt. A
changed address is not silently substituted. New audience members are not added
to an already-prepared snapshot.

Recipient identity includes user, channel and address. Two different users sharing
one phone/email remain separate recipients; this is not global address deduplication.

Each `sending` marker commits **before** provider I/O. Accepted/failed/simulated
results commit separately. Completed attempts are never repeated by duplicate
jobs. A stale worker cannot claim another recipient after its lease is replaced.
The lease is renewed when starting each attempt; no DB transaction stays open
during provider I/O.

| Situation | Recovery behavior |
| --- | --- |
| Broker unavailable or no Redis configured | Pending intent stays in PostgreSQL; the standalone worker needs no broker |
| Worker stops before starting an attempt | After lease expiry, another worker can continue untouched recipients |
| Worker stops after committing `sending`, or result persistence fails | That attempt becomes `uncertain`; it is not automatically resent |
| Timeout, provider exception or HTTP 5xx | Conservatively uncertain, even if the provider may actually have accepted it |
| Preparation/DB transaction error | Persisted bounded backoff: 10, 20, 40, 80, 160 seconds; five claims maximum before review |
| Completed or historical message receives a duplicate/stale job | No automatic replay; historical messages without outbox rows are not adopted |

Recovery only repeats safe, **unattempted** work. This is not exactly-once external
delivery: a crash immediately before the network call can leave an unsent attempt
marked uncertain. We prefer review over potentially sending twice. Creating a
second broadcast via a repeated HTTP POST still creates a separate intent; this
batch does not add request-level broadcast idempotency.

The UI shows “Delivery needs review” with a warning not to resend. Unknown outcomes
take precedence over an aggregate partial/accepted label; per-recipient records
retain confirmed acceptance separately. No automatic retry endpoint for uncertain
or failed recipients has been added.

## Worker operation

After a reviewed migration, run one of:

```bash
.venv/bin/python -m app.delivery_worker
# Or one bounded poll of at most 50 messages:
.venv/bin/python -m app.delivery_worker --once
# Existing Redis/ARQ deployments:
.venv/bin/arq app.worker.WorkerSettings
```

The standalone process polls every 10 seconds. ARQ also polls every 10 seconds and
at startup; explicit legacy `deliver_message` jobs pass through the same claim
checks. Its schedule uses the documented [ARQ cron API](https://arq-docs.helpmanual.io/#arq.cron.cron),
verified against the project's pinned **0.26.3** runtime. That already-required
dependency was installed in the local virtual environment for import verification;
requirements were not upgraded. Real Redis outage/restart acceptance remains open.

`TASK_QUEUE_ENABLED` remains a compatibility setting, **not an inline-delivery
switch**. A worker is required in development too. `POST /communication/process-due`
now lists due committed scheduled work; it does not send inside its request.
F01.2 restricts that listing to the sender's own work or headmaster/super-admin
school oversight. See [broadcast audience access](BROADCAST_AUDIENCE_ACCESS.md).
Worker throughput and database polling must be load-tested for large audiences.

## Migration and release gates

1. Back up and inventory pending/scheduled notifications and existing delivery
   history. Pause legacy workers and notification-writing traffic before rollout.
2. Review/apply Alembic `e1f2a3b4c5d6` after `c9d0e1f2a3b4` in staging first.
   It adds the outbox and a nullable recipient key/unique constraint. Existing
   delivery rows retain NULL keys and unchanged statuses. It does **not** backfill
   old messages into jobs. Resolve old pending/scheduled work explicitly.
3. Deploy matching API and worker versions together. The production compose
   template now waits for API health (after migration) before starting its worker.
   Do not run legacy workers, which still have unsafe resend behavior, alongside
   the new implementation. Update clients for the uncertain-outcome label.
4. Monitor `pending` age, expired `processing` leases and `needs_review` counts.
   A healthy API does not prove notification delivery is operating. The standalone
   worker logs a content-free poll failure; it does not substitute inline sends.
5. Rehearse approved test recipients, real broker/database restart, provider timeout,
   rolling deploy and operational reconciliation. Automated tests use mocked
   providers and real isolated DB transactions, not real external delivery.
6. The migration downgrade refuses unresolved jobs. Resolve/archive work under a
   reviewed procedure before rollback; do not delete jobs or reset attempt states
   to force retries. The test rehearsal covers this migration in a temporary
   predecessor-shaped schema, not an end-to-end production migration rehearsal.

## Remaining work

Provider message IDs and verified delivery receipts; audited per-recipient review
and safe retry tooling; request-level broadcast idempotency; real email adapter;
device logout/unregister; full module/permission-change policy for queued events;
worker health/metrics and production load/rollback acceptance remain open. Provider
4xx failures are terminal here, including rate limiting; provider-specific safe
retry rules require verified contracts before enabling retries.

See the [overall delivery contract](NOTIFICATION_DELIVERY_CONTRACT.md),
[verification](PHASE_1_VERIFICATION.md) and [progress tracker](PRODUCT_ENHANCEMENT_PLAN.md).
