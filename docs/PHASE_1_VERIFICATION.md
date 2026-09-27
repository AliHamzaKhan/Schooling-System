# Phase 1 — safe development and verification

## Backend tests

The database test suite no longer drops existing tables. Direct pytest requires
an explicit `SCHOOLING_TEST_DATABASE_URL`, a `schooling_test_*` database owned by
a restricted `schooling_test_*` role, and an empty database. Normal `DATABASE_URL`
and inherited `DB_*` values are never used as fallback targets.

From `backend`, run:

```sh
.venv/bin/python -m unittest discover -s verification -v
.venv/bin/python scripts/run_isolated_tests.py --from-local-config -- -q
```

The second command explicitly uses the local configured database credentials
only to provision a uniquely named disposable database/role on the same server.
It requires database/role creation privileges and rejects non-development or
non-loopback local configuration. Pytest receives the restricted
credentials, disables external providers and uses temporary upload storage.
Only that invocation's generated database, role and test uploads are removed
afterward. Existing school databases are not reset or migrated. Do not use
`--from-local-config` when local configuration points at production.

CI instead supplies `SCHOOLING_TEST_ADMIN_URL` from its disposable PostgreSQL
service and runs `python scripts/run_isolated_tests.py -- -q`. Never print or
commit either database URL. Database connection/validation errors are redacted.

## Flutter environments

Both entrypoints now resolve `APP_ENV`. Debug builds default to development;
release builds default to production and reject an explicit development setting.
Staging/production require an explicit HTTPS `API_BASE_URL` with a public host,
an API version path, and no credentials/query/fragment. A missing or invalid
configuration fails before shared services are initialized.

Local example, from either frontend app:

```sh
flutter run -d web-server --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://127.0.0.1:8090/api/v1
```

For distribution, supply `--dart-define=APP_ENV=production` (or `staging`) and
`--dart-define=API_BASE_URL=` with the approved endpoint. Do not distribute a
build until startup against that environment has been smoke-tested. Building a
bundle alone does not verify its endpoint or production readiness.

HTTP diagnostics intentionally retain only method, status, byte count and error
category. They omit bodies, headers, URLs, query values and exception messages
in every environment. Production diagnostics are disabled.

Backend communication/AI stub logs also omit message contents, addresses, device
tokens and prompts. Provider errors retain categories/status codes instead of
raw response or exception text. This does not yet change the legacy delivery
status semantics; honest simulated/delivered states remain under F07.

Run `flutter test test/environment_safety_test.dart` from `frontend/shared` for
default development/missing-endpoint checks. Also run it with
`--dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.com/api/v1`
for build-define configuration and quiet-logging checks. The example hostname is
used with mocked HTTP only; it is not a production deployment target.

Tracked scope/status and remaining Phase 1 work live in
[the product tracker](PRODUCT_ENHANCEMENT_PLAN.md).

## Recorded results — 2026-09-14

| Working directory | Command | Result |
| --- | --- | --- |
| `backend` | `.venv/bin/python scripts/run_isolated_tests.py --from-local-config -- -o addopts= -q --tb=short --show-capture=no` | 167 passed in 184.93 seconds; generated database/role removed |
| `backend` | `.venv/bin/python -m unittest discover -s verification -v` | 8 passed; no database access |
| `frontend/shared` | `flutter test` | 10 passed |
| `frontend/shared` | `flutter test test/environment_safety_test.dart --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.com/api/v1` | 5 passed; mock HTTP only |
| `frontend/school_portal` | `flutter test` | 20 passed |
| `frontend/admin_portal` | `flutter test` | 8 passed |
| `frontend/shared` | `flutter analyze lib/src/env/env_config.dart lib/src/services/api_service.dart test/environment_safety_test.dart` | No issues |
| Repository | `git diff --check` | Clean |

Targeted Ruff checks passed for the changed backend configuration, safety helper,
isolated runner, communication/AI providers, communication service, fixtures and
new safety/privacy/broadcast tests. Native distribution is not verified: the
existing `local_auth_android` reference and `printing` Swift Package Manager
warnings are recorded in the tracker. No hosted CI job, production deployment,
private-file migration, financial migration or independent review was performed.

## Second batch — document boundaries, bounded reads and payment locking

Changes are migration-free and backend-only:

- Document add/list validates a student role and school ownership. Delete also
  validates the student ID in the URL, not only the document's school.
- Upload content is read in chunks of at most 64 KiB, stopping after at most
  one byte beyond the configured limit; empty/oversized files never reach the
  storage adapter. The multipart parser/proxy still needs separate request-size
  and disk-use limits. This is not malware scanning or private download control.
- Payment recording takes a PostgreSQL row lock on the scoped invoice until the
  request commits/rolls back. Balance validation sums the existing payment ledger,
  so a stale cached total cannot authorize an overpayment.
- Receipts derive total paid and displayed invoice balance/status from their
  listed payment records. This is a read-only projection; it does not repair
  historical invoice caches or reconcile every report.
- Fee write schemas reject non-finite amounts. Validation errors omit raw input
  and context, retaining field location/type/message for client compatibility;
  an overflowed JSON number returns 422 rather than failing error serialization.

Regression tests are in `tests/test_document_boundaries.py`,
`tests/test_payment_concurrency.py`, `verification/test_upload_limits.py` and
`verification/test_money_validation.py`. Concurrent-payment tests deliberately
hold an invoice lock, wait for both independent requests to contend, then release
the lock. They cover overlapping partial payments, two full-payment attempts,
permitted separate partial payments, cached-total drift and invalid numeric input.

**At the end of batch 2 (superseded by batch 3 below):** `/media` remained publicly mounted. Existing/new upload URLs were
not yet private, and document metadata authorization does not secure the file
bytes. Coordinated private download authorization, browser/mobile attachment
opening, legacy URL classification/migration, type scanning and quotas are the
next F04 work. Financial amounts remain Float; fixed-precision migration,
historical reconciliation and request idempotency remain F06 work. A retried
partial payment can still be duplicated if the remaining balance permits it.

No running school database is migrated, reset or repaired by these changes.
The isolated test runner removes only the disposable resources it creates.

### Second-batch results — 2026-09-14

- Full isolated backend command shown above: **177 passed in 190.99 seconds**.
- `.venv/bin/python -m unittest discover -s verification -v`: **14 passed**.
- Targeted Ruff on the changed error handler, document/upload/fee modules and new
  tests: passed. `git diff --check` and local documentation links: passed.
- The initial targeted run had one stale-cache receipt assertion failure; the
  receipt projection fix is included in the successful full rerun.
- No frontend files changed in this batch; no frontend build, native-device
  walkthrough, hosted CI or production deployment was performed.

## Third batch — record-authorized private attachments

- Removed the public storage-root mount. Public raster avatars/uniform images
  remain compatible; every other namespace fails closed on direct access.
- New private keys bind school/category/uploader. New document/submission
  references cannot claim another uploader's blob or arbitrary legacy paths.
- Added authenticated record-ticket issuance and 60-second resource-bound
  downloads, with account/school/relationship/permission checks at redemption.
  Legacy school-scoped references work through existing records, not anonymously.
- Closed homework staff-boundary gaps in full submission lists, per-student
  histories, grading/review and assignment mutations. Students/linked guardians
  retain their personal record access; unrelated teachers cannot access work.
- Student and teacher attachment controls now use a prepare/download dialog
  with loading, retry and error states. The separate Download gesture avoids
  launching a new browser window after an asynchronous authorization request.
- Download responses and denials are not cached; ticket queries are redacted
  from Uvicorn logs. The disabled proxy template documents query-free logging.

Regression coverage: `backend/tests/test_private_downloads.py`,
`frontend/shared/test/attachment_access_service_test.dart`, and
`frontend/school_portal/test/attachment_download_dialog_test.dart`.

Final full isolated backend: **190 passed in 211.72s**, including 13 new download/
authorization regressions; generated database/role/uploads removed. Standalone
safety **14 passed**. Flutter suites: **shared 14,
school 22, admin 8 passed**. Changed-file Ruff and Flutter analysis passed.
Initial shared tests needed a platform token-store fake; both failures were
corrected and the complete shared suite passed afterward.

The [rollout guide](PRIVATE_FILE_ROLLOUT.md) is a required deployment gate:
external/old-origin/malformed references, historical mislinks, orphan assets,
public-avatar privacy, proxy/CDN exposure, scanning/quotas and native/browser
acceptance remain open. No existing-data migration, release build, hosted CI,
production deployment or manual device/browser download walkthrough was done.

## F04.3 — read-only private-asset inventory (2026-09-23)

`backend/scripts/audit_private_assets.py` inventories persisted document,
submission, avatar, uniform, logo, course-cover and URL-shaped metadata
references. It requires an explicit audit database URL, opens a PostgreSQL
`SET TRANSACTION READ ONLY` transaction, writes only JSON to stdout, and redacts
stored paths/queries in its aggregate and detail results. It makes no database,
blob or client change.

The [inventory and rollout plan](PRIVATE_ASSET_INVENTORY.md) records expected
private/public/policy visibility, the production read-only runbook, copy/checksum
validation, rollback boundary and remaining public-media, scanning, quota and
retention decisions. It does not authorize or execute a migration.

Focused inventory/download suite: **17 passed in 17.73s**. Full isolated backend:
**337 passed in 526.32s**, with the generated database and role removed. Targeted
`python -m ruff check`, compilation and `git diff --check` passed. No production
database connection, UI preview, asset copy, data rewrite/deletion, deployment or
device/browser acceptance was performed.

## F04.4 — new-upload allowlist and policy gates (2026-09-23)

New uploads can use only `documents`, `submissions`, `avatars` and `uniform`.
Private documents/submissions accept PDF/PNG/JPEG/WebP signatures; public avatar/
uniform assets accept PNG/JPEG/WebP signatures. The server ignores caller MIME
headers and filename extensions, derives its returned content type from the bytes,
and uses the corresponding suffix in the stored key. Unknown folders and active/
unknown private bytes fail before storage.

The [new-upload policy](PRIVATE_ASSET_POLICY.md) records the compatibility-only
public media posture and the unimplemented scanner/quarantine, cumulative quota,
retention, staging and approval gates. Focused upload/download suite: **19 passed
in 26.01s**. Full isolated backend: **340 passed in 518.96s**, with the generated
database and role removed. Targeted `python -m ruff check`, compilation and
`git diff --check` passed. No production database connection, UI preview,
existing-data migration, deletion or deployment was performed.

## F04.5 — fail-closed upload scanning and readiness (2026-09-23)

New uploads stream to a configurable ClamAV INSTREAM endpoint before any storage
key is constructed. Clean content is stored; detected content is discarded; a
scanner timeout, connection failure or unrecognized reply returns 503 without a
blob or metadata write. Non-development configuration must use ClamAV and name a
private scanner host. Readiness, compose health and CI deployment readiness now
include the scanner.

Focused scanner/upload/readiness suite: **26 passed in 27.42s**; the final combined
scanner/privacy/configuration suite: **28 passed in 20.59s**. Full isolated backend:
**347 passed in 500.11s**, with the generated database and role removed. The
[scanner rollout](PRIVATE_ASSET_SCANNING.md) defines protected configuration variables
and required staging checks. No UI preview, scanner deployment, production database
connection, existing-data migration, deletion or deployment was performed.

## F05.3 — production configuration and diagnostic redaction (2026-09-23)

Production settings now reject the development database URL, default super-admin
identity, wildcard/non-HTTPS CORS values, missing Redis and a disabled/missing
ClamAV scanner. The deploy job requires every critical value before it writes the
remote environment. Notification diagnostics use fixed event labels; cache, attendance
and Uvicorn access diagnostics avoid identifiers, exception text and all query values.

Focused isolated scanner/privacy/configuration suite: **28 passed in 20.59s**;
shared environment/notification diagnostics suite: **6 passed**; focused Flutter
analysis reports no issues. Full isolated backend: **347 passed in 500.11s**, with
the generated database and role removed. The existing `local_auth_android` package
warning remains. No UI preview, staging release, production database access, data
migration, deletion or deployment was performed.

## F06.3 — fixed-precision policy rehearsal (2026-09-23)

Added a policy-required read-only money reconciliation command for fee and payroll
floats. It requires an explicit currency, decimal scale and rounding mode, opens a
read-only transaction, and reports only structural counts/IDs for scale, sign,
non-finite, cached-ledger and overpayment exceptions. It does not print amounts or
change records. Focused money/payment/report suite: **31 passed in 52.43s**; Ruff,
compilation and `git diff --check` pass. The isolated database and role were removed.
No production read, backup, restored-copy rehearsal, data migration or deployment was
performed. Currency policy and migration approval remain required.

## Fourth batch — fee-payment retry safety (2026-09-14–15)

Added optional UUID `Idempotency-Key` support to fee-payment creation, backed by
the existing payment ID. Key-scoped transaction locking precedes invoice locking;
identical retries return the original payment and changed details return 409.
Authorization still applies to every attempt. No schema/data migration is needed.

The shared headmaster client retains immutable in-memory payment intents through
uncertain errors and token refresh; overlapping taps share one request. The UI
disables the payment action while recording and distinguishes unknown outcomes
from success. A new phone-width test found status/button overflow; labels now
wrap and the responsive payment action replaces the no-op pending button.

- Targeted backend payment tests: **19 passed in 23.39s**.
- Full isolated backend: **202 passed in 577.68s**; generated resources removed.
- Standalone safety checks: **14 passed**. Targeted Ruff and `git diff --check`
  pass. Shared Flutter suite: **25 passed**, including 11 retry-guard tests.
- Headmaster mocked-transport test verifies stable body/key across a 401 refresh,
  lost response and later retry. Full school suite: **26 passed**; admin suite:
  **8 passed**. Payment UI passes at 320px, 320px with 1.4× text and 1280px.
  The first phone test exposed status/button overflow; final checks pass after
  the responsive layout fix.
- Shared retry-service analysis has no issues. The broader pre-existing
  headmaster API service reports 26 style-only infos outside the changed payment
  method; these are not new payment failures and were not bulk-rewritten.

See [payment contract and migration design](PAYMENT_SAFETY_AND_MIGRATION.md).
Keyless callers, durable restart/device recovery, payroll/subscription replay
protection, currency decisions, exact-money conversion and historical
reconciliation remain open. No hosted CI, release deployment or real-device
payment walkthrough was performed.

## Fifth batch — session revocation and teacher-owned routes (2026-09-15)

Access tokens and file tickets now require a live matching server session. Logout,
logout-all, password change/reset and account disablement take effect on the next
authorization check. Refresh/revoke and one-use reset challenges are row-locked;
replayed refresh credentials revoke the entire session, including a concurrent
winner's access token. Reactivating a user does not resurrect old sessions.

The shared client attempts server logout after local cleanup, handles profile and
refresh outages without claiming successful login, and prevents late requests from
restoring or crossing sessions. Teacher class/performance links use guarded,
read-only teacher URLs with query IDs and a route-local report controller. Existing
headmaster boundaries remain unchanged.

- Full isolated backend: **213 passed in 261.93s**, including nine session tests
  and two deliberately concurrent OTP/reset tests. Generated resources removed.
- Standalone safety: **14 passed** at this batch's completion.
- Flutter: **shared 37 / school 30 / admin 8 passed**, including twelve shared
  lifecycle tests and four teacher role/direct-URL/back/read-only tests.
- Changed auth and route analysis plus backend Ruff passed. One new Dart lint was
  corrected before final analysis. No actual browser reload/device walkthrough.

See [session and route rollout](SESSION_AND_ROUTE_ROLLOUT.md). Legacy access
credentials require refresh or sign-in. Offline logout cannot guarantee remote
revocation; cross-tab refresh, device cleanup and full route/recovery review remain
open. No schema migration or deployment was performed.

## Sixth batch — honest notification outcomes (2026-09-15)

Unconfigured providers and email placeholder results are now `simulated`; real
adapter success is `accepted`, never a manufactured delivery receipt. Missing push
devices create failed recipient records. Aggregation distinguishes accepted,
simulated, partial and failed outcomes, and only acceptance sets `sent_at`.

Headmaster/teacher confirmations use the returned status rather than HTTP success.
Headmaster announcement cards retain labels and explanations at narrow widths.
Password recovery retains account-neutral wording without promising a stub send.
Teacher audience radios use the current grouped control API.

- Targeted isolated backend: **28 passed in 31.68s** (delivery outcomes, queue
  handoff, audience isolation and password reset); generated resources removed.
- Standalone safety/provider suite: **16 passed**, including mocked Twilio/FCM
  acceptance checks and content-free simulation diagnostics. No real provider calls.
- Phone/desktop outcome cards pass at **320px and 1200px, with 1.4× text**.
- Final complete isolated backend: **222 passed in 279.74s**; generated database,
  role and upload resources removed. Flutter: **shared 37 / school 34 / admin 8
  passed**. School includes four notification presentation/data/radio tests.
- Changed backend Ruff, shared auth/outcome analysis and teacher/announcement
  analysis are clean. Two pre-existing radio deprecation infos were removed by
  migrating the changed composer to `RadioGroup`; its interaction test passes.
  Documentation links and `git diff --check` pass. Existing native plugin warnings
  remain rollout gates; this is not a native release-build acceptance.

See [notification contract and remaining gates](NOTIFICATION_DELIVERY_CONTRACT.md).
Real email, signed delivery receipts, durable outbox/worker deduplication and
actual broker/provider outage recovery remain open. No historical notification
records were rewritten; older `sent` records are not evidence of delivery.

## Seventh batch — transactional notification outbox (2026-09-15)

Messages and outbox intent now commit atomically with their originating business
transaction. API requests do not call providers or enqueue Redis jobs. An
independent database worker snapshots recipients, claims work with fenced leases,
and commits a per-recipient sending marker before I/O. Duplicate/stale jobs cannot
repeat attempted recipients. Interrupted/ambiguous attempts require review; safe
untouched work resumes with bounded backoff. Scheduled work remains pending until
due. Legacy messages are not automatically adopted or requeued.

- Full isolated backend: **233 passed in 279.14s**; generated database/role/uploads
  removed. Twelve outbox tests cover transaction visibility/rollback, broker
  independence, concurrent/repeated jobs, cancellation and result-write failure,
  stale ownership, retry exhaustion, scheduling, recipient changes, ambiguous
  provider failure and missing/legacy jobs.
- New migration rehearsal uses a temporary predecessor-shaped schema, rolls it
  back afterward, preserves legacy rows and verifies the unresolved-work downgrade
  guard. It does not migrate the normal school database or rehearse the full chain.
- Standalone safety/provider suite: **17 passed**. Targeted school outcome suite:
  **4 passed**, including uncertain wording at 320px/1200px and 1.4× text.
- Shared **37** and admin **8** tests passed. The first full school run hit a
  temporary `No space left on device` compiler-copy error and was stopped via its
  own test session. No files were deleted; final `flutter test --concurrency=1`
  passed **all 34 school tests**.
- Changed backend Ruff, shared outcome analysis, compose YAML/migration dependency
  checks and Alembic single-head check passed. ARQ **0.26.3**, already pinned in
  requirements, was missing locally and installed (with hiredis) for adapter import
  verification. No requirements version change or real Redis/provider test.

See [outbox migration and recovery gates](NOTIFICATION_OUTBOX_ROLLOUT.md).
Prepared migration `e1f2a3b4c5d6` was **not applied to existing school data**. A worker
is required even when the legacy queue flag is false. Review tooling, request-level
broadcast idempotency, real email/receipts and staged rollout remain open; this is
not exactly-once external delivery or Phase 1 completion.

## Eighth batch — broadcast replay and delivery review (2026-09-15)

Implemented F07.3: optional UUID `Idempotency-Key` serialized before broadcast
creation; same-intent replays return the existing message's current status and
never create another outbox. Actor, school and content mismatch are conflicts.
Scheduled inputs now require timezone-aware timestamps. Teacher/headmaster clients
retain an immutable, actor/school-scoped attempt through unknown responses, block
changed payloads, restore drafts and preserve keys through auth refresh.

New read-only review API is sender/headmaster/super-admin scoped, paginated and
privacy-minimized. Existing delivery/summary endpoints also require sender/admin
access, and legacy push address values are suppressed. Headmaster announcement
cards open a responsive review dialog in both portals, with masked recipients,
worker state, outcome totals, refresh/pagination and error recovery. It cannot
resend, reset attempts or declare an unknown delivery successful.

Verification:

- Full isolated backend: **246 passed in 294.86s**. The 13 new tests cover changed
  fields, current-state replay, one persisted message/outbox, deliberately overlapping
  request locks, actor/tenant binding, UUID/timezone validation, legacy keyless
  compatibility, sender/admin roles and denial, pagination bounds, redaction and
  read-only behavior. The runner removed its generated database and restricted role.
- The first focused run had **43 passed / 1 failed**: this file's pending fixture
  messages were consumed by a later global worker test. Added teardown restricted
  to each newly created test school; the full rerun above passed. No existing school
  data or normal database was used/deleted.
- Standalone safety/provider suite: **17 passed**; communication backend Ruff and
  tracked diff whitespace checks passed.
- Full Flutter suites, serial within each package: **shared 48 / school 41 / admin 8
  passed**. Includes 11 retry guard tests and seven school integration/widget tests
  for both API paths, auth-refresh/lost-response replay, restored draft/section,
  320px/1200px review at 1.4× text, pagination and failed-load recovery.
- New shared retry analysis clean. Broader modified-file analysis initially found
  only the headmaster API's **26 preexisting style infos**, no errors/warnings;
  unrelated style cleanup was left alone. New review/test brace infos from formatting
  were fixed; final announcement/teacher/new-test analysis reported **no issues**,
  and the final seven-test review suite passed again after formatting.

See [broadcast replay and review contract](BROADCAST_REPLAY_AND_REVIEW.md). No new
migration, existing-data migration, real provider delivery or deployment. Recovery
is in-memory, not browser-refresh/restart durable; broader feed privacy, provider
receipts/reconciliation and real browser/native acceptance remain open. Next scoped
implementation is F01.2 communication feed/detail audience visibility. Phase 1 is
still in progress.

## Ninth batch — broadcast audience privacy (2026-09-15)

Implemented F01.2: the feed and direct broadcast URL now apply one SQL visibility
predicate before serialization. Current roles, active enrollments and valid guardian
relationships govern recipient reads; sender/admin oversight remains. Scheduled
content is hidden from recipients until its scheduled instant. Hidden direct URLs
return the same 404 as unknown message IDs. The due-work listing now returns only
the sender's own work or administrator oversight. Worker recipient queries reject
mismatched roles and corrupt cross-school relationships. Communication responses,
including denied reads, carry `Cache-Control: private, no-store`.

Verification:

- Final full isolated backend run: **258 passed in 601.73s**, with saved report
  `/private/tmp/schooling-f012-check.ZZZVey/backend.xml`. The runner confirmed removal
  of its generated database and restricted role.
- Final focused visibility/review/private-download suite: **38 passed in 55.72s**,
  including final cache-header assertions on permitted and denied content reads.
- Twelve new privacy tests cover role matrices, class/section/child audiences,
  worker/read alignment, withdrawal despite a historical delivery, link removal,
  child deactivation, role changes, wrong-school links, sender/admin oversight,
  schedules, due listings, malformed historical rows and cross-school parent data.
- First focused run: **46 passed / 1 failed**. The deliberate corrupt-parent fixture
  collided with an existing section name before reaching its assertions. Gave that
  test section a distinct name; the final focused rerun passed. No product defect
  was hidden or disabled to make this setup pass.
- An intermediate full-run output handle became unavailable. Its result is **not
  counted**. Read-only metadata checks confirmed its exact disposable database and
  role were removed; the final rerun above saves a report to preserve evidence.
- Standalone safety/provider checks: **17 passed**. Flutter suites: **shared 48 /
  school 41 / admin 8 passed**. Only frontend API comments changed; existing consumers
  retain their response shape, search behavior and headmaster oversight UI.
- Changed backend Ruff and tracked diff whitespace checks passed. No new dependency,
  schema migration, production deployment or real notification send.

See [broadcast audience policy](BROADCAST_AUDIENCE_ACCESS.md) for current-membership
history semantics and rollout limits. This does not recall previously downloaded
content or remotely purge an open screen. Parent F01 and Phase 1 remain open; next
packet is F01.3 direct-conversation recipient/student-reference and read boundaries.

## Tenth batch — direct-conversation boundaries (2026-09-15)

Implemented F01.3: send-time recipient eligibility matches contact discovery;
teachers can contact current students and their linked guardians. Both parties
must be entitled to discuss an optional, active same-school student reference.
Class/enrollment/timetable/subject/guardian queries validate tenant IDs and roles.
Students may reply to an administrator who already contacted them without adding
administrators to the student contact picker. Participant-only history rejects
corrupt tenant/student references, supports an optional server-side counterpart
filter, and never grants administrative surveillance. Read marking is recipient-only
and row-locked. Direct-message endpoints now also carry private no-store headers.

Shared conversation UI uses the server-side pair filter, rejects foreign pairs,
preserves explicit reply context without reviving older child IDs after a general
message, reports failed read receipts and only updates successful receipt state.
Failed refreshes clear stale history/contact lists; denied sends do not append a
message or clear the typed draft.

Verification:

- Full isolated backend: **273 passed in 333.11s**; saved report
  `/private/tmp/schooling-f013-check.Pds7LS/backend.xml` confirms zero errors,
  failures and skipped tests. The runner removed its generated database and role.
- Initial focused direct-message suite: **15 passed in 39.78s** (three existing
  cases and twelve new cases), with its disposable database/role removed.
  Three additional corrupt enrollment/timetable/role cases were subsequently added
  to the full run. The basic legacy send test was updated to create a legitimate
  teacher/student/guardian relationship; formerly arbitrary school-wide sends are
  intentionally denied and covered by zero-write regressions.
- Fifteen new backend cases cover contact/send parity, both-party student context,
  inactive/foreign users, relationship/role changes, history isolation, forged
  counterpart filtering, concurrent read timestamps, administrator replies,
  malformed historical data, school hierarchy corruption and blank-body rejection.
- Eight new shared messaging tests passed. Full Flutter suites: **shared 56 /
  school 41 / admin 8 passed**. Includes reply-context behavior, receipt failure,
  filtered conversation requests, foreign-pair rejection and stale-list clearing.
- Standalone safety/provider suite: **17 passed**. Changed backend Ruff and tracked
  whitespace checks passed. Shared messaging analysis initially reported six
  redundant test imports; they were removed and final changed controller/data/model
  and test analysis reported **no issues**. Extended analysis including the inbox
  view reported nine preexisting redundant-import infos, no errors/warnings; those
  unrelated imports were left alone. Shared's full 56-test suite passed again after
  inbox opens were changed to derive context from the fresh thread response.

See [direct-message access contract](DIRECT_MESSAGE_ACCESS.md) for role rules,
mailbox-history semantics and limits. No new migration, existing-data changes,
deployment, new dependency or real provider sends. Parent F01 and Phase 1 remain
open. Next: F01.4 academic/student-report nested-object access audit.

## Eleventh batch — academic/student-report boundaries (2026-09-16)

Implemented F01.4: current teacher/guardian/student relationships gate individual
reports and student schedules/performance. Headmasters retain school-wide oversight;
teachers need current class-teacher or timetable relationships. Attendance and quiz
picker rosters (including the teacher report drill-down) use the same section gate.
Students/guardians cannot retrieve peer rankings or unpublished exam papers.
Unknown, foreign and nonstudent targets are rejected. Nested school/class/section,
enrollment, exam/paper/subject, assignment/submission, quiz and guardian references
are validated or filtered. Teacher assignments require active same-school teachers.
Covered responses use private no-store headers.

The shared headmaster/teacher report controller clears previous data when loading,
discards superseded responses and disables guardian actions without a loaded report.
An additional staff role without student-management view no longer blocks a
guardian's own child self-service access.

Verification:

- Full isolated backend: **286 passed in 393.33s**. Saved JUnit report:
  `/private/tmp/schooling-f014-check.tvmDCM/backend.xml`, zero errors/failures/skips.
  This full run collected the first thirteen new cases before the final multi-role
  adjustment and fourteenth test were added.
- Final affected-module run on the adjusted code: **32 passed in 69.50s** across
  academic-report access, academic/attendance, enrollment reports, subject attendance
  and quiz tests. Saved JUnit report:
  `/private/tmp/schooling-f014-check.tvmDCM/final-focused.xml`, zero errors/failures/skips.
  Both runners confirmed removal of their generated databases and roles.
- Initial focused run before the quiz-picker gate: **25 passed in 55.21s**, saved in
  `/private/tmp/schooling-f014-check.tvmDCM/focused.xml`; its test resources were removed.
- Fourteen new backend cases exercise authorized and unrelated roles, same-token
  relationship revocation, class/timetable authority, enrollment revocation, rosters,
  foreign/missing/nonstudent targets, invalid UUIDs, draft/publish/unpublish visibility,
  malformed cross-school relationships, teacher assignment eligibility, corrupted
  enrollment tenants and multi-role permission revocation.
- Flutter suites: **shared 56 / school 42 / admin 8 passed**. The new report-refresh
  widget test verifies that denied refresh and missing student context clear private
  data. Existing teacher deep links, section-to-report navigation and read-only
  actions continue passing. This is automated coverage, not real-device acceptance.
- Standalone safety/provider checks: **17 passed**. Changed backend Ruff, changed
  report-controller/test Flutter analysis and `git diff --check` passed. Shared tests
  retain the previously documented `local_auth_android` dependency warning.

See [academic/report contract](ACADEMIC_REPORT_ACCESS.md) for exact scope and limits.
No existing school-data migration, provider send, deployment or dependency change.
F01 and Phase 1 remain open. Next packet: **F01.5 attendance/enrollment access**, then
remaining aggregate, exam/quiz and other nested-object audits.

## Twelfth batch — attendance/enrollment boundaries (2026-09-22)

F01.5 validates current attendance read relationships, enrollment session ownership,
all supplied attendance references and existing-row school/section ownership before
mutation. Registers, summaries and individual history filter malformed tenant
references. Daily/subject teacher write authority and valid historical reads remain.

- Full isolated backend: **305 passed in 456.99s**; **18 new regressions**.
  JUnit: `/private/tmp/schooling-f015-backend.xml`, zero failures/errors/skips.
  Generated database and restricted role were removed by the runner.
- Initial focused run: 40 passed / 1 fixture setup failure (duplicate section name
  in deliberately corrupt parent data). Corrected before the successful full run.
- Standalone safety/provider checks: **17 passed**; changed backend Ruff and
  `git diff --check` pass. No frontend changes or new Flutter run.

See [attendance/enrollment contract](ATTENDANCE_ENROLLMENT_ACCESS.md) for exact
rules, remaining UI defects and recovery limits. No existing-data migration,
real provider delivery, UI preview or deployment. Parent F01 remains open;
next packet is F01.6 aggregate reports and export access.

## Thirteenth batch — aggregate report and export boundaries (2026-09-23)

F01.6 validates school-wide report ownership and action boundaries. Overview and
enrollment aggregates reject malformed nested classes, sections, subjects,
students and sessions. Academic reports exclude foreign classes, categories,
sessions, students, draft results and invalid result tenants. Finance projections
use valid local invoice references and sum school-owned payment ledger rows rather
than cached invoice amounts. Attendance JSON and CSV share the register's
structural filters, reject foreign sections/reversed dates and exclude unknown
statuses. REPORTS view/export and subscription/module-toggle behavior are tested.

- Full isolated backend: **321 passed in 472.89s**; final focused F01.6/F01.5 suite
  **34 passed in 92.12s**. JUnit: `/private/tmp/schooling-f016-final-backend.xml`,
  zero failures/errors/skips.
  Generated database and restricted role were removed by the runner.
- Standalone safety/provider checks: **17 passed**; changed backend Ruff and
  `git diff --check` pass. No frontend changes or Flutter run.

See [aggregate report access contract](AGGREGATE_REPORT_ACCESS.md). No existing-data
migration, real provider delivery, UI preview or deployment. Parent F01 remains
open; next packet is F01.8 remaining nested-object and action audit.

## Fourteenth batch — exam and quiz lifecycle boundaries (2026-09-23)

F01.7 validates exam class/session/category and paper/subject ownership, school-scoped
marks/results/seats and current student rosters. Published results remain visible only
through authorized result paths; draft report cards require result-approval authority.
Quiz reads and attempts are limited by publication, assignment and active enrollment;
answer IDs must belong to the submitted quiz, students cannot inspect other attempts,
and performance/report views are staff-only.

- Full isolated backend: **324 passed in 469.05s**; focused final exam/quiz/scenario suite
  **19 passed**. JUnit: `/private/tmp/schooling-f017-final-backend.xml`, zero
  failures/errors/skips; the three new F01.7 cross-school/privacy cases are included.
  Generated database and restricted role were removed by the runner.
- Changed backend Ruff and `git diff --check` pass. No frontend changes, migration,
  UI preview, physical browser/device acceptance, deployment or provider send.

See [exam/quiz access contract](EXAM_QUIZ_ACCESS.md). Parent F01 remains open;
next packet is F01.9 remaining student-facing action audit.

## Fifteenth batch — promotion, calendar and lesson boundaries (2026-09-23)

F01.8 validates promotion exam/session/student/section ownership before mutating
enrollments. Mixed or foreign target batches fail during preflight, so an earlier
valid item cannot partially move a student. Promotion previews and merit lists use
published local results and current student roles. Calendar events validate local
sessions and update date ranges; exam feeds exclude malformed class/session links.
Lessons require a local section and subject whose class relationship is valid, and
progress uses that same structural scope.

- Full isolated backend: **327 passed in 509.41s**; focused promotion/calendar/
  lesson/scenario suite **13 passed**; new F01.8 cross-school/no-write suite
  **3 passed**. JUnit: `/private/tmp/schooling-f018-final-backend.xml`, zero
  failures/errors/skips. Generated database and restricted role were removed by
  the runner.
- Changed backend Ruff and `git diff --check` pass. No frontend changes, migration,
  UI preview, physical browser/device acceptance, deployment or provider send.

See [promotion/calendar/lesson access contract](PROMOTION_CALENDAR_LESSON_ACCESS.md).
Parent F01 remains open; next packet is F01.10 remaining registered-router and job audit.

## Sixteenth batch — student-facing action boundaries (2026-09-23)

F01.9 validates homework assignment section/subject structure and limits student
assignment reads and submissions to active enrollment. Submission reads and grading
use school-owned assignment links. Student documents remain tied to a local student
and the student ID in the URL. Transport route stops, assignments, trips, events,
locations and student/guardian requests keep school and relationship predicates on
each read or write.

- Full isolated backend: **329 passed in 483.36s**; focused homework/document/
  transport/lesson suite **25 passed**; new F01.9 cross-school/privacy/no-write
  suite **5 passed**. JUnit: `/private/tmp/schooling-f019-final-backend.xml`, zero
  failures/errors/skips. Generated database and restricted role were removed by
  the runner.
- Changed backend Ruff and `git diff --check` pass. No frontend changes, migration,
  UI preview, physical browser/device acceptance, deployment or provider send.

See [student action access contract](STUDENT_ACTION_ACCESS.md). Parent F01 remains
open; next packet is F01.10 remaining registered-router and job audit.

## Seventeenth batch — course-content and remaining router audit (2026-09-23)

F01.10 validates every academic link supplied while creating or updating course
content. A course can only reference its own school's section and subject, and a
class-bound subject must match the selected section's class. Students can directly
read or save progress only for school-wide content or courses assigned to one of
their active sections; the same check now covers course, book, chapter and note
URLs. Progress lookup and writes validate the local book or note before querying or
storing a position.

- The scheduled fee-reminder job authenticates with its dedicated secret, selects
  only active schools, and passes the selected school ID into the already scoped
  fee service. The registered export paths retain the report permission and
  school/structure validation added in F01.6. Meetings, leave, inventory and HR
  paths were reviewed; their route payloads do not introduce an unscoped nested
  reference in this packet.
- Focused course/router verification: **6 passed**. Full isolated backend:
  **331 passed in 488.01s**. JUnit:
  `/private/tmp/schooling-f0110-final-backend.xml`, zero failures/errors/skips.
  Generated database and restricted role were removed by the runner.
- Changed backend Ruff and `git diff --check` pass. No frontend changes, schema
  migration, UI preview, physical browser/device acceptance, deployment or provider
  send.

See [course content access contract](COURSE_CONTENT_ACCESS.md). Parent F01 remains
open; next packet is F01.11 final audit reconciliation and independent-review scope.

## Eighteenth batch — registered-router reconciliation (2026-09-23)

F01.11 reconciles all registered routers against the F01 contract and records the
platform-only exceptions separately from tenant routes. The final audit found two
malformed-data paths outside normal API writes: guardian placement enrichment could
display a foreign enrollment's class metadata, and a corrupted guardian link could
carry a foreign student into a local leave request. Both now fail closed.

- Guardian placement enrichment requires the enrollment, section and class to be
  owned by the requested school. Guardian leave child resolution requires an
  association, user and student role in that same school.
- `tests/test_final_f01_audit.py` directly seeds malformed rows, proves the
  placement metadata is withheld, and proves a rejected foreign-child leave makes
  no local leave write. Focused guardian/leave/final-audit suite: **11 passed**.
- Full isolated backend: **333 passed in 523.57s**. JUnit:
  `/private/tmp/schooling-f0111-final-backend.xml`, zero failures/errors/skips.
  Generated database and restricted role were removed by the runner.
- Changed backend Ruff and `git diff --check` pass. No frontend change, schema
  migration, UI preview, physical browser/device acceptance, deployment or provider
  send.

See the [registered-router audit](F01_ROUTER_AUDIT.md). F01 moves to **Review**;
independent security/product review remains required. Next implementation packet:
F04.3 private-asset rollout inventory.
