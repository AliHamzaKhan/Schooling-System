# Operations runbook

Status: O02.2 operational preparation. This document does not claim a hosted
backup, restore, rollback, monitoring integration or provider test has happened.
Record those exercises here only after an operator runs them with approved
credentials and synthetic data.

## Signals and alert routing

Monitor three independent conditions:

| Condition | Source | Initial severity | Meaning |
| --- | --- | --- | --- |
| API unavailable | `/health/ready` / Prometheus `up` | Page after 2 min | Requests cannot safely use a required dependency. |
| Elevated API errors | `http_requests_total` | Ticket after 10 min over 5% | A route or dependency is failing at meaningful volume. |
| Outbox worker stale/not seen | authenticated `GET /api/v1/admin/operations` | Page after 2 min | No worker replica has recently written its coalesced heartbeat. |

Use [the supplied Prometheus rules](../backend/deploy/alerts/prometheus-rules.yml)
as a starting point. The monitoring agent must expose only a Boolean
`schooling_outbox_worker_healthy` gauge from the operations result; it must not
export message IDs, recipients, errors, counts by school, access tokens or raw
response bodies. The operations route is deliberately Super-Admin-only. Store a
dedicated monitor account in the approved secret manager, give it no interactive
use, and rotate/revoke it through the normal account/session process.

Production logs must set `LOG_FORMAT=json`. Each app log line carries timestamp,
level, logger, correlation ID and a source-controlled message; exceptions add
only their type. API logs use route templates rather than raw path/query values.
Do not add request/response bodies, authorization headers, credentials, student
names, addresses, stored-file tickets or provider responses to log fields.

## API unavailable

1. Confirm the load balancer target and `/health/ready` result. Record only the
   failing dependency category (`database`, `redis`, or `upload_scanner`).
2. Check container status and recent structured logs by correlation ID/category.
   Do not paste `.env`, complete logs, headers or connection strings into an
   incident ticket.
3. Restore the dependency or roll the affected API container. Do not roll back
   the database merely to make readiness green.
4. Confirm readiness remains healthy for ten minutes and the 5xx alert clears.

## Elevated 5xx rate

1. Group the metric by route template and inspect error IDs in the structured
   logs. Treat unknown exception types as an application incident.
2. Check database/Redis/scanner readiness before changing application versions.
3. If a release is implicated, follow the deploy rollback procedure below;
   preserve the current image SHA and migration revision for investigation.
4. Verify the error rate returns below threshold and capture only aggregate
   counts, route template and correlation IDs in the incident record.

## Outbox worker stale or not seen

1. Retrieve the aggregate operations result. Record worker state, heartbeat age,
   pending/due/processing/expired-lease/needs-review counts and oldest-due age;
   do not retain a response body containing unrelated metadata.
2. Check the worker container and its structured logs. A stale worker with a
   healthy API is a worker incident, not an API readiness failure.
3. Restore database/worker connectivity, then restart only the worker if needed.
   Never reset leases, attempts or `needs_review` rows to force a retry.
4. If an ambiguous provider attempt exists, use the documented manual review
   process. Unknown delivery outcomes must not be resent automatically.
5. Confirm a fresh heartbeat and declining due-work age. Keep the alert open
   until the worker is fresh for ten minutes and unresolved counts are triaged.

## Backup and restore rehearsal

Target recovery objective proposal: RPO at most 24 hours and RTO at most four
hours, pending hosting/product approval. This is a planning target, not a service
promise.

Run at least quarterly and before any irreversible migration:

1. Produce an encrypted PostgreSQL backup and a versioned storage manifest.
   Keep encryption keys separate from the backup and record backup timestamp,
   database schema revision, object count and checksum only.
2. Restore into a newly created, isolated database and isolated object-storage
   prefix. Never restore over the primary database or live upload path.
3. Apply the intended image to the isolated environment and check `alembic
   current`, `/health/ready`, the Super-Admin operations summary, and aggregate
   counts for schools, users, invoices, payments, messages and outbox states.
   Do not export names, addresses, values, credentials or notification content.
4. Prove private uploads require their normal record-authorized download path.
   Use synthetic school accounts only.
5. Record elapsed backup/restore time, revision/image SHA, aggregate comparison,
   operator and exceptions. Delete the rehearsal environment and rotate its
   credentials after sign-off.

## Deploy rollback

1. Stop promotion of the new image and preserve the failed image SHA, current
   migration revision, readiness category and aggregate operations summary.
2. Review migrations before changing images. Prefer a forward-compatible fix;
   never run an Alembic downgrade against unresolved notification outbox work.
   The outbox migration explicitly blocks that unsafe downgrade.
3. If code rollback is safe for the schema, pin `IMAGE_TAG` to the last approved
   SHA and run the documented compose pull/up procedure in
   [the deployment guide](../backend/deploy/README.md#rollback).
4. Check API readiness, worker heartbeat and aggregate queue state after rollback.
   Resolve uncertain notifications by review, never by deleting or replaying rows.
5. Run the next restore rehearsal before declaring the incident closed if a
   migration or persistent data was involved.

## External-provider tests

Use stub providers for ordinary automated tests. Any staging provider exercise
requires approved synthetic recipients, an explicit operator, a pre-agreed
send window and a recorded cleanup/reconciliation result. Do not use students,
guardians, staff, production device tokens or real school contacts as test
recipients.
