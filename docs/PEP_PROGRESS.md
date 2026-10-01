# Meri Taleem — Enhancement Plan: Progress Dashboard & Execution Log

Part of the [Product Enhancement Plan](PRODUCT_ENHANCEMENT_PLAN.md). Append-heavy: current progress, Phase 1 / experience substep tables, the dated execution log, and the source index. Per-packet status is in the [backlog](PEP_BACKLOG.md); the session update procedure and next-work pointers are in the [main plan](PRODUCT_ENHANCEMENT_PLAN.md).

---

## 11. Progress dashboard and execution log

### Current progress

| Deliverable | Status | Evidence / limits |
| --- | --- | --- |
| PLAN-01 — source inventory, user flows, risk triage, standards baseline and enhancement tracker | Verified | This file; inspection and official sources listed here. Initial discovery only, not exhaustive runtime validation. |
| Recent student/shared visual refresh | Existing baseline — partial | Student dashboard/course/assignment styling, shared tokens and reduced-motion widget/test exist in the working tree. Not completion of U01/U03/U04. |
| Headmaster entry in admin portal | Existing baseline — partial | Admin imports headmaster pages and has role-based landing. F03/U02 remain open for route regression, refresh-safe flows and desktop completeness. |
| Auth rate-limit response fix | Existing baseline — targeted verification recorded previously | `backend/verification/test_auth_rate_headers.py` and modified auth router. Does not close the broader identity/security backlog. |
| Phase 1 implementation | In progress | F08 is implemented and under review. F01 is in Review after its F01.1–F01.11 technical packets; F05.1–F05.3 and scoped F02/F03/F04/F06/F07 substeps below are technically verified. F04.3 adds a non-mutating inventory command and migration/rollback plan; F04.4 narrows new upload types/folders; F04.5 adds a fail-closed pre-storage scanner contract. F05.3 makes production config and diagnostics fail closed/source-redacted. O01 is in Review: Flutter lint/analyze/test/release-build, redacted secret, migration-rehearsal, OpenAPI contract, critical-journey and backend/Pub dependency-audit gates are locally verified; one hosted GitLab run remains. O02.1/O02.2 add aggregate worker/outbox visibility, enforced structured logs, alert rules and recovery runbooks; hosted alert integration, restore/rollback rehearsal and provider acceptance remain. Local Flutter evidence is shared **65**, school **60** and admin **10** passing tests. Production inventory, staging scanner/configuration acceptance and all data changes remain open. Latest full backend suite: **347 passed in 500.11s**. F01 independent security/product review and F07.2 migration remain open. Phase 1 is not complete. |
| Experience foundation | In progress | U01 is in Review after catalogue, canonical components, headmaster-settings adoption, keyboard/200%-text coverage, measured WCAG AA text-pair contrast and reduced-motion dialog checks. U02.1/U02.2 add grouped search, capability-aware navigation and persistent school/session context; U02.3.1–U02.3.4 add cold-route dependencies, direct-link capability gates, URL-first canonical reads, canonical approval/class lists and automated named-route/back coverage. Latest recorded Flutter suites: shared 63, school 60, admin 10 passed (not rerun for the backend-only F01.5 packet). U02.4.1–U02.4.3 add automated setup/management mutation coverage. The lean launch portfolio now groups the remaining 31 planned records into six tracks (L01–L06); 16 source records are included by those tracks and 15 expansion records are post-launch. Independent U01 acceptance and physical browser acceptance of the complete journeys remain open. |

The earlier development session reported local student login/mobile-layout checks. This Phase 1 batch reruns automated suites; it does not repeat the live browser/device walkthrough or certify a production release.

### Phase 1 implementation substeps — 2026-09-14

Owner and implementation reviewer: **Codex (self-review)**. Independent engineering/product acceptance and production rollout remain outstanding. `Verified` below denotes the stated automated technical scope only; parent completion still requires the full definition of done.

| Child ID | Implemented scope | Evidence | Status / remaining work |
| --- | --- | --- | --- |
| F08.1 | Removed `drop_all`; explicit test URL, connected database/owner/privilege/emptiness checks; isolated runner provisions unique restricted role/database and temporary uploads; dotenv/provider credentials excluded; CI uses isolated runner | `verification/test_database_safety.py`: four test methods including invalid URL, inherited configuration and connected-identity cases. Final isolated backend suite: 167 tests pass; runner cleans up its generated resources. | Verified technically; parent Review pending independent review and hosted CI execution |
| F01.1 | Tenant-owned class/section/student audience references validated before write/enqueue and again at recipient resolution; recipient queries constrain user, enrollment and section school IDs plus active status | `tests/test_broadcast_isolation.py`: 10 tests pass, including immediate/scheduled foreign references, zero side effects, active/enrolled recipients and missing/unknown references | Verified; full router/object/action audit remains under F01 |
| F05.1 | Both Flutter entrypoints resolve APP_ENV; release selection rejects debug; staging/production require explicit HTTPS public endpoint; HTTP diagnostics omit payloads, URLs, headers and exception text | `frontend/shared/test/environment_safety_test.dart`: default and production-define runs; changed-file static analysis clean | Verified for configuration/unit scope; real release artifact startup against approved staging endpoint remains |
| F05.2 | Communication/AI stub diagnostics omit recipient/content/token/prompt; provider exceptions and remote error bodies no longer copied into delivery errors; FCM preserves allowlisted machine codes | `verification/test_provider_privacy.py`: three tests pass for stub, exception and AI prompt privacy | Verified for tested paths; broader backend/infrastructure logging audit remains |
| F05.3 | Production configuration rejects development database/default admin/non-HTTPS CORS; CI requires deploy secrets; notification, cache, attendance and access diagnostics omit payloads, tokens, IDs, query values and exception strings | Focused isolated scanner/privacy/config suite **28 passed in 20.59s**; shared environment/notification diagnostics suite **6 passed**; focused Flutter analysis clean; full isolated backend **347 passed in 500.11s** | Verified technically; approved staging artifact startup and reverse-proxy/infrastructure log acceptance remain |
| F04.1 | Document add/list student-school-role validation and delete student-ID binding; bounded upload reads reject empty/oversized files before storage | Four upload-limit unit tests and three document/HTTP upload regressions pass; included in latest full suite | Verified technically; byte access is handled separately by F04.2 |
| F04.2 / F01.2 | Private uploader-owned keys; no public storage-root mount; resource-bound 60-second tickets with authorization rechecks; student/teacher download UI; assigned-staff homework lists, history and mutations | 13 new backend tests; final full suite 190 passed in 211.72s. Shared 14, school 22, admin 8 Flutter tests pass; changed-file analysis clean | Verified technically; [legacy/public-media rollout gates](PRIVATE_FILE_ROLLOUT.md), scanning/quotas and real device/browser acceptance remain open |
| F06.1 | Scoped invoice row lock; ledger-based balance check; ledger-derived receipt projection; non-finite fee write rejection and safe 422 validation response | Seven payment integration cases pass, including three deliberately overlapping request scenarios; two money-validation unit tests pass; full suite 177/177 | Verified technically; Float storage, historical reconciliation and payroll/subscription money remain open; keyed fee retries addressed by F06.2 |
| F06.2 | Optional UUID payment request identity; transaction key lock and original-response replay; changed payload/actor/invoice conflict; stable headmaster client attempts, duplicate-tap guard and responsive payment action | 12 new backend regressions; full backend 202 passed in 577.68s. Shared 25, school 26, admin 8 tests passed; includes phone/large-text/desktop payment checks and auth-refresh/lost-response replay | Verified technically for keyed fee requests and in-memory client recovery. Keyless callers, durable restart/device recovery and payroll/subscription replay remain open. [Contract and precision migration design](PAYMENT_SAFETY_AND_MIGRATION.md); currency decision requested, no data migration |
| F06.3 | Explicit-policy, read-only fee/payroll precision reconciliation: flags non-finite, sign/scale, cached-ledger and overpayment exceptions without reporting amounts or changing rows | `tests/test_money_precision_audit.py`: 3 policy/reconciliation/privacy cases; focused money/payment/report suite **31 passed in 52.43s** | Verified technically; an approved currency/scale/rounding policy, read-only production run, restored-copy rehearsal and additive migration remain required |
| F02.1 | Session-bound access/file tickets; locked refresh/revoke and one-use reset challenges; deactivate/re-enable revocation; honest profile login, retryable refresh outages, local-first logout and account-switch request guards | Full isolated backend 213 passed; 11 new backend regressions; shared 37 passed including 12 lifecycle cases; standalone 14 passed | Verified technically. [Rollout contract](SESSION_AND_ROUTE_ROLLOUT.md); cross-tab refresh, device cleanup, storage-failure handling and full recovery review remain open |
| F02.2 | Self-service live-session list and single-session revoke; server returns lifecycle metadata only and client clears local credentials after revoking the current device | Backend session/auth suite **19 passed in 14.91s**; shared lifecycle suite **13 passed**; targeted analysis clean | Verified technically; session-management UI, cross-tab behavior and real-device acceptance remain |
| F03.1 | Dedicated guarded teacher roster/report URLs, query IDs, local binding, read-only actions and repaired class/performance links | School 30 passed including four teacher URL/guard/back/action tests; admin 8 passed; changed-route analysis clean | Verified widget/route scope; actual browser refresh/login-return and all-module route/controller audit remain open |
| F02.4 | Browser credential mutation coordination, cross-tab account invalidation, fail-closed secure-storage reads/writes and local logout cleanup reporting | Focused shared auth/storage/navigation suite **20 passed**; static analysis reported no source issues. A Chrome cross-context suite exercises Web Locks, separate contexts and stale-account blocking; final runner evidence remains pending. | Implemented; Chrome and native-device acceptance remain required. |
| F03.2 | Every school role route has a client guard and cold-route binding; known in-app deep links survive session restoration/login; missing transient detail context recovers safely; guardian account changes clear selected-child state | Focused school route-recovery suite **3 passed**; existing school suite **72 passed** before the new targeted suite; static analysis reported no source issues. | Implemented; browser refresh/login-return across all routes remains required. |
| F07.1 | Simulated vs provider-accepted outcomes; missing-device failure records; honest summaries/timestamps; teacher/headmaster confirmations and responsive status cards; current grouped audience radios | Nine new backend outcome tests; final backend 222 passed in 279.74s; standalone 16 including mocked Twilio/FCM acceptance; shared 37 / school 34 / admin 8 passed; changed announcement/auth analysis clean | Verified technically. [Delivery contract](NOTIFICATION_DELIVERY_CONTRACT.md); real email, receipts, transactional outbox, worker retry/deduplication and real-provider/broker rollout remain open |
| F07.2 | Transactional notification outbox; fenced worker leases; per-recipient committed attempt markers; bounded recovery of untouched work; uncertainty instead of blind resend; independent DB poller and ARQ adapter; additive migration and guarded downgrade | Full backend 233 passed in 279.14s; twelve outbox cases plus migration rehearsal; standalone 17; Flutter shared 37 / school 34 / admin 8 passed; static/compose/head checks pass | Verified technically. [Migration/worker rollout](NOTIFICATION_OUTBOX_ROLLOUT.md) remains required and unapplied to existing data. Real provider/broker acceptance, review tooling, request-level idempotency and provider-specific retry rules remain open |
| F07.3 | UUID broadcast request serialization/replay; actor/school/payload conflicts; immutable teacher/headmaster retry drafts; sender/admin-only delivery inspection; masked, paginated read-only headmaster review panel with responsive/error states | 13 new backend cases; full backend 246 passed in 294.86s; standalone 17; Flutter shared 48 / school 41 / admin 8 passed, including refresh/lost-response identity and phone/desktop review | Verified technically. [Replay/review contract](BROADCAST_REPLAY_AND_REVIEW.md). In-memory recovery only; legacy keyless clients, provider receipts/reconciliation, teacher review navigation, real devices and coordinated rollout remain open. No resend or outcome override added |
| F01.2 | Shared SQL feed/detail visibility, current role/enrollment/guardian checks, scheduled-content privacy, sender/admin due-work oversight, aligned worker recipient checks and private no-store response headers | 12 new privacy tests; final isolated backend 258 passed in 601.73s; final focused privacy/review/download suite 38 passed; standalone 17; Flutter shared 48 / school 41 / admin 8 passed | Verified technically. [Audience policy](BROADCAST_AUDIENCE_ACCESS.md); current-membership history, not recipient-snapshot history. Direct conversations, full nested-object audit, real-browser acceptance and production rollout remain open |
| F01.3 | Send/contact parity, current shared-student validation for both participants, tenant-safe contact relationships, private participant history, server-side conversation filter, row-locked read receipts and safer shared UI context/error state | 15 new backend cases; full backend 273 passed in 333.11s; standalone 17; Flutter shared 56 / school 41 / admin 8 passed; eight new messaging tests | Verified technically. [Direct-message contract](DIRECT_MESSAGE_ACCESS.md). No administrative mailbox surveillance; historical participant mailbox retained. Request replay/offline recovery, pagination, moderation/retention and real-device acceptance remain open |
| F01.4 | Current teacher/student/guardian report relationships, section and quiz-picker roster gates, draft-result visibility, nested tenant filters, active teacher assignment validation and denied-refresh data clearing | Full backend 286 passed in 393.33s; final affected-module suite after multi-role adjustment 32 passed in 69.50s; standalone 17; Flutter shared 56 / school 42 / admin 8 passed; 14 new backend cases and one new UI case | Verified technically. [Academic/report contract](ACADEMIC_REPORT_ACCESS.md). Broader aggregate, attendance-write, examination/quiz lifecycle, published-grade snapshots and custom-staff audits remain open |
| F01.5 | Current attendance section/student read relationships; session validation on enrollment; tenant-safe attendance references, roster eligibility and locked existing-row ownership checks; private no-store reads | Full isolated backend **305 passed in 456.99s**, including **18 new cases**; standalone safety/provider **17 passed**; changed backend Ruff and whitespace checks pass | Verified technically. [Attendance/enrollment contract](ATTENDANCE_ENROLLMENT_ACCESS.md). Broader aggregates, exam/quiz lifecycle, concurrent new saves, honest frontend save/error states and physical acceptance remain open |
| F01.6 | School overview, attendance/academic/enrollment/finance aggregate ownership; explicit REPORTS view/export and module-toggle checks; structurally filtered attendance JSON/CSV; ledger-derived finance totals; distinct valid enrollment totals | Final isolated backend **321 passed in 472.89s**, including **34 final focused F01.6/F01.5 cases**; standalone **17 passed**; Ruff and whitespace checks clean | Verified technically. [Aggregate report access contract](AGGREGATE_REPORT_ACCESS.md). Exam/quiz lifecycle, concurrent payment writes, fixed-precision migration, export pagination, independent acceptance and physical browser/device acceptance remain open |
| F01.7 | Exam category/class/session/paper/mark/result ownership; published-result and draft-report privacy; seating/admit-card roster boundaries; quiz nested links, publication, assignment, answer IDs, attempt privacy and staff-only reports | Final isolated backend **324 passed in 469.05s**, including **3 new cross-school/privacy regressions**; focused final exam/quiz/scenario suite **19 passed**; Ruff and whitespace checks clean | Verified technically. [Exam/quiz access contract](EXAM_QUIZ_ACCESS.md). Promotion, concurrent payment writes, fixed-precision migration, export pagination, independent acceptance and physical browser/device acceptance remain open |
| F01.8 | Promotion exam/session/student/section ownership with no-partial-write preflight; calendar session/date and exam-feed filtering; lesson section/subject class pairing and progress scope | Final isolated backend **327 passed in 509.41s**, including **3 new cross-school/no-write regressions**; focused promotion/calendar/lesson/scenario suite **13 passed**; Ruff and whitespace checks clean | Verified technically. [Promotion/calendar/lesson access contract](PROMOTION_CALENDAR_LESSON_ACCESS.md). Remaining student-facing action paths, finance precision/concurrency, export pagination, independent acceptance and physical browser/device acceptance remain open |
| F01.9 | Homework assignment/submission nested links and student visibility; document student ownership; transport route/stop/assignment/trip school filters and student/guardian actions | Final isolated backend **329 passed in 483.36s**, including **5 new cross-school/privacy/no-write regressions**; focused homework/document/transport/lesson suite **25 passed**; Ruff and whitespace checks clean | Verified technically. [Student action access contract](STUDENT_ACTION_ACCESS.md). Remaining registered-router/job/export audit, finance precision/concurrency, independent acceptance and physical browser/device acceptance remain open |
| F01.10 | Course section/subject ownership; active student enrollment for direct course/book/chapter/note reads and reading-progress resources; registered jobs/export audit | Final isolated backend **331 passed in 488.01s**, including **2 new course cross-school/privacy/no-write regressions**; focused course/router suite **6 passed**; Ruff and whitespace checks clean | Verified technically. [Course content access contract](COURSE_CONTENT_ACCESS.md). Final F01 audit reconciliation, finance precision/concurrency, independent acceptance and physical browser/device acceptance remain open |
| F01.11 | Reconciled all registered routers with the F01 contract; hardened malformed guardian placement and leave-link relationships | Focused guardian/leave/final-audit suite **11 passed**; final isolated backend **333 passed in 523.57s**; Ruff and whitespace checks clean | Verified technically. [Registered-router audit](F01_ROUTER_AUDIT.md). Parent F01 moved to Review pending independent security/product review |
| F04.3 | Read-only persisted-reference inventory, visibility classification and migration/rollback runbook; no existing school data or objects changed | `tests/test_private_asset_inventory.py`: 4 cases; focused inventory/download suite **17 passed in 17.73s**; full isolated backend **337 passed in 526.32s**. The command uses an explicit URL and `SET TRANSACTION READ ONLY`, redacts stored references, and produces aggregate or record-ID detail JSON. | Verified technically; public-avatar/course-cover policy, scanning/quotas/retention, production inventory evidence and an explicitly approved migration remain |
| F04.4 | New-upload folder/type policy: only document/submission PDF/raster and public avatar/uniform raster signatures; caller MIME/extension cannot control stored metadata | `tests/test_upload_policy.py`: 3 cases; focused upload/download suite **19 passed in 26.01s**; full isolated backend **340 passed in 518.96s**. [Policy and production gates](PRIVATE_ASSET_POLICY.md). | Verified technically; public-media approval, scanner/quarantine, cumulative quotas/retention, staging evidence and an approved migration remain |
| F04.5 | ClamAV pre-storage scan gate, scanner-aware readiness and production configuration/deploy guard | `tests/test_upload_scanner.py` and `tests/test_upload_scanner_config.py`: 5 scanner/config cases; focused scanner/privacy/config suite **28 passed in 20.59s**; full isolated backend **347 passed in 500.11s**. [Scanner rollout](PRIVATE_ASSET_SCANNING.md). | Verified technically; staging scanner evidence, public-media approval, cumulative quotas/retention, production inventory and an approved migration remain |

Verification instructions and environment changes: [Phase 1 verification guide](PHASE_1_VERIFICATION.md).

Remaining Phase 1 work is explicit: private-asset scanner staging/operations evidence, cumulative quotas/retention, public-avatar approval and rollout verification (F04), fixed-precision money and concurrency/idempotency (F06), session/device lifecycle (F02), teacher route/deep-link repair (F03), complete nested-object audit (F01), staging artifact/infrastructure-log acceptance (F05), and honest delivery states/provider/queue recovery (F07). No existing private-file or money data migration has been applied.

Known tooling warnings: `local_auth_android` plugin registration and `printing` Swift Package Manager support warnings remain. They do not fail the Flutter tests or web builds. O01 records current analyzer info/warning debt as non-fatal while analyzer errors remain release-blocking; the baseline must be reduced before native distribution acceptance under O04. No plugin dependency changes were made in this batch.

**Next implementation packet: O03.1 — representative-fixture and pagination performance baseline.**
O01 is in Review pending hosted GitLab evidence. F06.3 remains pending
currency/scale/rounding approval, a read-only production run and restored-copy
rehearsal; no money data is changed until those gates are accepted. Independent F01
security/product review remains open.

Next experience prerequisite: **physical browser acceptance of U02 (user-run)**.
U02.4.3 automated mutation journeys are complete; follow the
[physical browser checklist](U02_HEADMASTER_BROWSER_CHECKLIST.md). Do not open a
preview. The next launch experience track is **L01 — role journeys**, which folds
in U03 and U04 after its active foundation dependencies are ready.

### Experience foundation substeps — 2026-09-16

| Child ID | Implemented scope | Evidence | Status / remaining work |
| --- | --- | --- | --- |
| U01.1 | Replaced the generated shared-package README with a token/component/state/accessibility catalogue; added reusable `AppCard`, `AppTextField`, `AppDataTable` and `AppStateView` APIs and exported them from the package | Full shared suite: **60 passed**, including four focused widget tests for a concise asynchronous-state live region, interactive-card semantics, 320 px layout at 200% text, horizontally resilient tabular data and reduced-motion rendering. Targeted static analysis reports no issues | Verified technically. U01 remains In progress: representative portal adoption, keyboard/focus traversal, contrast measurement, dialog reduced-motion verification and documented exceptions remain open |
| U01.2 | Adopted shared cards, form fields and loading/error states on headmaster school settings; made logo and colour choices explicit semantic controls with 44 px targets; reflowed colour summaries/sliders and expanded shared buttons for narrow 200% text; added keyboard focus traversal | Settings tests pass at **320/1200 px with 200% text** plus keyboard traversal; the initial test exposed a 187 px shared-button overflow and the final focused suite passes after the canonical fix. School full suite: **45 passed**; targeted analysis clean | Verified technically. Real-browser focus-ring/assistive-technology walkthrough and independent product review remain |
| U01.3 | Added measured WCAG AA checks for representative semantic text pairs and made shared dialog route/badge presentation skip decorative animation when reduced motion is enabled | Shared design-system tests: **7 passed**; full shared suite: **63 passed**; targeted analysis clean. Tested seven foreground/background pairs at contrast ratio >= 4.5 and verified dialogs contain no scale/badge tween under reduced motion | Verified technically. No component-level exception recorded; U01 moved to Review pending independent acceptance |

### Experience shell substeps — 2026-09-16

| Child ID | Implemented scope | Evidence | Status / remaining work |
| --- | --- | --- | --- |
| U02.1 | Added grouped module search to the headmaster directory, matching names/descriptions/group names; added accessible shared cards and an actionable no-results state; removed two-line description truncation | Admin layout/search suite: **5 passed**; full admin suite: **9 passed**; school full suite: **45 passed**; targeted analysis clean | Verified technically. Capability filtering, persistent school/session context, route refresh/browser acceptance and complete headmaster-web journey remain open |
| U02.2 | Loaded school identity, active academic session and effective modules through existing profile, reports-overview and `/permissions/me` contracts; failed the shell closed when any context read fails; filtered desktop tabs, dashboard shortcuts and the searchable module directory; kept school/session visible in the desktop sidebar | Workspace/controller/API/sidebar tests plus settings coverage: **6 passed**; full school suite: **48 passed**; full admin suite: **10 passed**; targeted analysis has no errors or warnings in the new shell/controller/model/widget/test files (existing API-service info lints remain) | Verified technically. Backend authorization remains authoritative. Direct-link capability guards, refresh/back browser acceptance and the complete browser-only setup/management journey remain open under U02.3+ |
| U02.3.1 | Prepended a route-local headmaster repository binding to every headmaster page so cold URLs no longer require a prior shell visit; replaced the upcoming-events screen's transient `Get.arguments` list with a canonical overview read and explicit loading, empty, retryable error and stale-data-clearing states | Focused workspace/cold-route suite: **5 passed**; full school suite: **50 passed**; targeted analysis: **no issues**; whitespace check clean | Verified technically for module dependency initialization and `/headmaster/overview/events`. Remaining argument-dependent routes, capability guards, actual browser refresh/back and complete web journey remain under U02.3.2+ |
| U02.3.2 | Added fresh effective-capability gates to all mapped headmaster module routes; the gate wraps the page builder so lazy feature controllers remain unconstructed until access is confirmed, fails closed on denied, failed or unexpected permission checks, and keeps backend authorization authoritative | Focused workspace/route suite: **6 passed** across allowed, disabled, service-failure and thrown-error states; full school suite: **51 passed**; targeted analysis: **no issues**; whitespace check clean | Verified technically for mapped direct-link module access. Remaining argument-only drill-downs, actual browser refresh/back and complete web journey remain under U02.3.3+ |
| U02.3.3 | Replaced transient navigation state with URL-first IDs/query filters for teacher-attendance rosters, exam-category timetables, course content, book chapters, section/student reports, message history and payslip generation; each sensitive detail resolves canonical backend records before rendering or mutation, while typed arguments remain compatibility-only fallbacks | Focused workspace/shared-report route suites: **12 passed**; full school suite: **52 passed**; targeted analysis: **no issues**; whitespace check clean | Verified technically for the listed drill-downs. Approval/class aggregate routes, actual browser refresh/back, physical visual inspection and the complete headmaster-web journey remain under U02.3.4+ |
| U02.3.4 | Removed the last transient-only aggregate route state: approvals now reload through a route-local controller, while class rosters use URL-first class IDs and reload canonical sections/students; both expose explicit loading, empty, retryable failure and stale-clearing behavior. Added router-harness coverage for named-route construction and returning to the origin | Focused workspace/route suite: **8 passed**; full school suite: **53 passed**; targeted analysis: **no issues**; whitespace check clean | Verified technically for approval/class cold loads and automated back history. Physical visual inspection and the complete browser-only setup/management journey remain under U02.4+ |
| U02.4.1 | Hardened student/teacher setup against partial-success retries. Student enrollment and guardian linking retain completed account IDs; teacher salary setup retains the created teacher ID; section-service failures are distinguished from genuinely empty setup | Focused form journeys: **2 passed**; school suite after this slice: **55 passed**; focused changed-file analysis clean (the wider API service retains existing info lints) | Verified technically for explicit partial failures returned to the client. Lost-response create idempotency remains a backend concern. Physical visual acceptance remains user-run; no preview |
| U02.4.2 | Cleared stale class, student, teacher, timetable and school-settings records before every canonical refresh, so a failed read cannot leave previous data presented as current; introduced injectable read loaders for deterministic journey-state coverage | Focused U02.4 suites: **3 passed**; full school suite: **56 passed**; focused analysis: **no issues**; whitespace check clean | Verified technically. Class/section mutations, timetable authoring, settings-save journey and physical browser acceptance remain under U02.4.3+ |
| U02.4.3 | Extracted the class/section create, timetable class-authoring and school-settings save mutations into UI-free, harnessable controller methods (`submitNewClass`/`submitNewSection`/`submitSave` + `validate`) that own validation, duplicate detection, day-range checks, backend-failure surfacing and refresh-on-success; form sheets and the save button now delegate to them. Delivered the user-run [physical browser checklist](U02_HEADMASTER_BROWSER_CHECKLIST.md) | Focused mutation-journey suite: **4 passed**; management-state + settings design-system suites still green; full school suite: **60 passed**; targeted analysis on the three controllers and the new test: **no issues** | Verified technically for the automated create/author/save journeys (validation, duplicate, backend-failure and refresh paths). Physical browser acceptance of the checklist remains a user-run step; no preview opened. Settings validation snackbars now use a single "Could not save" title with the specific message as the body |

### Execution log

| Date | IDs | Status change / work performed | Verification | Blocker / next action |
| --- | --- | --- | --- | --- |
| 2026-09-26 | L05.6 | Made invoice and student-fee class filters fail closed: a foreign class ID is rejected instead of producing an ambiguous empty financial list. | Isolated invoice-pagination regression: **1 passed in 1.47s**; Ruff/compile/whitespace pass. No UI preview opened. | Continue L05 reporting definitions, drill-down and safe-export coverage; payment-gateway integration remains deferred. |
| 2026-09-26 | L05.5 | Made bulk fee issuance retry-safe: if any targeted student already has the same structure, resolved session, title and due-date invoice, the entire repeat request is rejected before it creates another charge. | Isolated fee-scope suite: **4 passed in 6.71s**; Ruff/compile/whitespace pass. No UI preview opened. | Continue L05 reporting definitions, drill-down and safe-export coverage; payment-gateway integration remains deferred. |
| 2026-09-26 | L05.4 | Prevented duplicate invoice issuance for the same student, fee structure, resolved session, title and due date, while retaining legitimate invoices for a later due date. | Isolated fee-scope suite: **3 passed in 4.13s**; Ruff/compile/whitespace pass. No UI preview opened. | Continue L05 reporting definitions, drill-down and safe-export coverage; payment-gateway integration remains deferred. |
| 2026-09-26 | L05.2–L05.3 | Continued L05. L05.2 rejects future payment dates and preserves the unpaid invoice. It also validates class/session-scoped fee structures before issuance. L05.3 applies shared valid-enrollment eligibility to student-report assignments, excluding foreign-session enrollment rows. | Future-payment regression: **4 passed in 5.51s**. Fee-scope suite: **2 passed in 2.96s**; combined fee suite: **6 passed in 7.49s**. Reporting Ruff/compile/whitespace pass; its isolated runner was blocked by local provisioning permissions and an approval-service rejection, so no passed count is claimed. No UI preview opened. | Continue L05 reporting definitions, drill-down and safe-export coverage; payment-gateway integration remains deferred. |
| 2026-09-25 | L05.1 | Began the finance and reporting launch track. Invoice lists now use the shared bounded pagination contract and a stable due-date/id order after school scope. | Isolated invoice-pagination regression: **1 passed in 1.55s**; Ruff/compile/whitespace pass. No UI preview opened. | Continue fee-operation and reporting integrity slices; payment-gateway integration remains deferred. |
| 2026-09-25 | O03.9, L01.9–L04.9 | Completed the ninth parallel batch. O03.9 paginates student-document history after tenant and child access checks. L01.9 clears stale student notifications and timetable context before live reads. L03.8 clears stale teacher leave-review queues and provides retryable recovery. L04.9 prevents exam-date updates from excluding existing dated papers. | O03.9 isolated document suites: **7 passed in 8.56s**; Ruff/compile/whitespace pass. L03.8 Flutter recovery suite: **1 passed**; focused analysis clean. L04.9 isolated exam-result suite: **4 passed in 4.73s**; Ruff/compile/whitespace pass. L01.9 focused Flutter analysis clean. No UI preview opened. | Continue O03 with representative data/budgets and continue end-to-end role journeys; do not treat per-slice tests as launch certification. |
| 2026-09-25 | O03.8, L01.8–L04.8 | Completed the eighth five-scope batch. O03.8 applies bounded, stable pagination only after own, reviewer or school leave visibility. L01.8 clears stale guardian notifications and exposes a recoverable error. L02.8 prevents restricting a subject to a class when an existing timetable slot uses it elsewhere. L03.7 clears guardian transport requests, trips and tracking data before live reload. L04.8 requires a class-specific exam paper subject to match the exam class while retaining school-wide subjects. | O03.8 isolated leave suite: **6 passed in 10.59s**; Ruff/compile/whitespace pass. L02.8 isolated timetable suite: **2 passed in 1.90s**; Ruff/compile/whitespace pass. L04.8 isolated exam-result suite: **3 passed in 3.69s**; Ruff/compile/whitespace pass. L01.8/L03.7 focused Flutter analysis clean. No UI preview opened. | Continue O03 with representative data/budgets and continue end-to-end role journeys; do not treat per-slice tests as launch certification. |
| 2026-09-25 | O03.7, L01.7–L04.7 | Completed the seventh five-scope batch. O03.7 bounds ordered transport-assignment lists. L01.7 clears stale teacher classes before a failed live reload. L02.7 rejects duplicate subject-code changes before mutation. L03.6 clears the selected section and cached rosters when teacher-performance context reload fails. L04.7 requires each scheduled exam paper to fall inside its exam window. | O03.7/L02.7/L04.7 isolated transport, academic and examination regressions: **13 passed in 20.50s**; Ruff/compile/whitespace pass. L01.7/L03.6 focused Flutter recovery suite: **2 passed**; focused analysis clean. No UI preview opened. | Continue O03 with representative data/budgets and continue end-to-end role journeys; do not treat per-slice tests as launch certification. |
| 2026-09-25 | O03.6, L01.6–L04.6 | Completed the sixth five-scope batch. O03.6 bounds the valid, school-scoped exam list with stable ordering. L01.6 rejects malformed teacher-attendance routes instead of inventing a class. L02.6 rejects duplicate class renames before mutation. L03.5 clears stale announcement sections, exposes retry and blocks section sends until recovery. L04.6 rejects invalid exam date ranges on create and partial update. | O03.6/L02.6/L04.6 isolated examination and academic regressions: **4 passed in 4.02s**; Ruff/compile/whitespace pass. L01.6/L03.5 focused Flutter suites: **7 passed**; focused analysis clean. No UI preview opened. | Continue O03 with representative data/budgets and continue end-to-end role journeys; do not treat per-slice tests as launch certification. |
| 2026-09-25 | O03.5, L01.5–L04.5 | Completed the fifth five-scope batch. O03.5 paginates active transport trips only after actor visibility is established. L01.5 presents a family-access recovery state after selected-child refresh failure. L02.5 rejects duplicate section renames before mutation. L03.4 clears stale teacher conversations and presents retryable recovery. L04.5 requires a class-compatible subject for timetable creates and updates. | O03.5 isolated transport suite: **5 passed in 10.67s**; Ruff/compile/whitespace pass. Guardian family-access suite: **2 passed**; focused analysis clean. L02.5 isolated section-update regression: **1 passed**; Ruff/compile/whitespace pass. L03.4 communication failure test: **1 passed**; focused analysis clean. L04.5 isolated timetable/attendance suite: **4 passed in 4.86s**; Ruff/compile/whitespace pass. No UI preview opened. | Continue O03 with representative data/budgets and continue end-to-end role journeys; do not treat per-slice tests as launch certification. |
| 2026-09-25 | O03.4, L01.4–L04.4 | Completed the fourth five-scope batch. O03.4 applies homework pagination only after school, valid academic-link, section and enrollment visibility filters. L01.4/L03.3 clear a selected child's cached identity and scoped data if linked-child refresh fails. L02.4 recursively merges nested school-settings updates without deleting sibling settings. L04.4 blocks exam-result publication until every active student has an explicit score or recorded absence for every paper. | O03.4 isolated homework suite: **13 passed in 20.04s**; Ruff/compile/whitespace pass. Guardian session suite: **2 passed**; focused analysis clean. L02.4 school suite: **12 passed**; Ruff/compile/whitespace pass. L04.4 result-integrity suite: **8 passed in 11.56s**; Ruff/whitespace pass. No UI preview opened. | Continue pagination coverage and connected role workflow slices; representative fixtures and measured budgets remain required for O03. |
| 2026-09-25 | O03.3, L01.3–L04.3 | Completed the third five-scope batch. O03.3 paginates student attendance history only after tenant/access/date filters. L01.3/L03.3 make guardian child-scoped reads and driver trip loading clear stale state and expose retryable errors. L02.3 rejects partial calendar edits whose merged end time precedes the stored/proposed start time without changing the event. L04.3 returns an immutable saved quiz attempt for a retry rather than overwriting answers. | O03.3 isolated attendance regression: **1 passed in 3.22s**; Ruff/compile/whitespace pass. Guardian failure-state test: **1 passed**; focused analysis has no errors (one pre-existing driver `onReorder` deprecation info). L02.3 calendar suite: **5 passed in 4.86s**; Ruff/compile/whitespace pass. L04.3 quiz/access suite: **10 passed in 15.99s**; Ruff/whitespace pass. No UI preview opened. | Continue bounded pagination coverage and complete role journeys; use a representative fixture and agreed budgets before claiming performance readiness. |
| 2026-09-25 | O03.2, L01.2–L04.2 | Completed the second five-scope batch. O03.2 paginates broadcast history after tenant/audience filtering. L01.2/L03.2 make teacher attendance reads fail closed and prevent a failed attendance save from showing success or navigating away. L02.2 makes section admissions session-consistent and retry-safe. L04.2 clears a staff-read receipt after a changed homework resubmission while preserving it for an identical retry. | O03.2 isolated broadcast regression: **1 passed in 8.41s**; Ruff/whitespace pass. Teacher attendance submission test: **1 passed**; focused analysis clean. L02.2 isolated admission/enrollment suite: **3 passed in 3.48s**; disposable DB/role removed. L04.2 isolated targeted homework regression, Ruff and compile checks pass; a broader runner gave no final summary and is not claimed. No UI preview opened. | Continue O03.3 and next L01–L04 slices; repeat broader homework coverage only with a conclusive final summary. |
| 2026-09-25 | O03.1, L01–L04 | Began five concurrent launch workstreams. O03.1 adds reusable bounded direct-message pagination and a representative 105-row history regression. L01.1/L04.1 clear stale student attendance, assignment and exam data on a failed live read, expose a retryable error, and retain no false empty state. L02.1 adds academic-session date/rename integrity, session-filtered class listing, fail-closed setup targets and a no-session-move-after-enrollment rule. L03.1 adds durable guardian relinking and immediate post-unlink attendance revocation. | O03.1 focused direct-message suite: 6 tests, including the new 105-row regression, plus Ruff/compile/whitespace pass. L01.1/L04.1 focused Flutter failure-state suite: 3 passed; focused analysis clean. L02.1 focused academic-setup suite: 3 passed in 3.33s; Ruff/compile/whitespace pass. Its wider 24-case regression emitted no final summary, so it is not claimed as evidence. L03.1 focused guardian/final-audit suite: 8 passed; Ruff/whitespace pass. No UI preview opened. | Repeat L02.1's broader academic/enrollment regression to a conclusive result, then continue each track by its release-track dependency order. |
| 2026-09-24 | PLAN-02 | Replaced 31 standalone planned packets with six dependency-ordered lean launch tracks (L01–L06). Retained every original ID as a deferred traceability record: 16 are folded into a track and 15 are deferred until after the L06 pilot. | Backlog, progress and reference phase mapping updated; this is a scope-planning change only and makes no release-readiness claim. | Continue O03.1. Execute L01 only after its active foundation dependencies are ready; L06 still requires the open O01/O02/O03 evidence. |
| 2026-09-24 | O03.1 | Planned → In progress. Mapped current high-growth list/report paths and existing bounded-list conventions; isolating a backward-safe shared pagination contract and representative fixture before changing public responses. | Source inspection only; no performance numbers are claimed. | Implement bounded high-growth lists with tenant-fairness regressions, then publish an isolated baseline. |
| 2026-09-24 | O02.3 | In progress → technically verified. Added fail-closed partial-provider configuration validation, configuration-mode-only provider visibility, and a line-safe protected base64 FCM service-account input for CI-generated environments. Both documented worker modes now write the same heartbeat. | Combined isolated provider/worker/logging/readiness/migration suite **33 passed in 15.21s**; Ruff, compilation, CI YAML, alert-rule YAML and whitespace checks pass. No provider was contacted. | Hosted alert routing, restore/rollback rehearsal and an approved synthetic-recipient provider exercise remain before O02 can be Reviewed. Continue O03 local performance preparation. |
| 2026-09-24 | O02.2 | In progress → technically verified. Enforced production JSON logging, fixed route-template request logging, added versioned Prometheus alert rules and an explicit redacted alert/restore/rollback/provider-test runbook. CI now rehearses the additive worker-heartbeat migration alongside the guarded outbox migration. | Combined isolated operations suite **27 passed in 15.24s**; Ruff, compilation, CI YAML, alert-rule YAML and whitespace checks pass. | Configure hosted alert routing, run a restore and deploy-rollback rehearsal, and record an approved synthetic-recipient provider exercise before O02 can be Reviewed. |
| 2026-09-24 | O02.1 | Planned → In progress → technically verified. Added a migration-backed, coalesced outbox-worker heartbeat and a Super-Admin aggregate operations view. It exposes only queue counts/timing and worker freshness, never messages, recipients, identifiers, hostnames or provider errors. | Isolated worker/outbox/readiness/API/migration suite **20 passed in 15.36s**; real heartbeat upsert, fresh/stale/not-seen states, Super-Admin gate and reversible migration covered. Ruff, compilation and whitespace checks pass. | Continue O02.2: alert response, backup/restore and deploy/provider rollback runbooks. Hosted O01 pipeline evidence remains separately required. |
| 2026-09-24 | O01.5 | Added a fail-closed OSV Pub advisory scanner for the three Flutter lockfiles and a dedicated CI job. O01 moved In progress → Review. | Pub audit **375 hosted package locks checked**, no findings; scanner unit tests **2 passed in 0.02s**. CI YAML and whitespace checks pass. | Run one hosted GitLab pipeline and attach the result before O01 is Verified. Continue O02 operational readiness locally. |
| 2026-09-24 | O01.4 | Added a pinned blocking `pip-audit` CI job, upgraded FastAPI/Starlette, pytest/pytest-asyncio, multipart and PDF dependencies, and replaced vulnerable Python-JOSE/ECDSA with PyJWT for application and FCM service-account JWTs. | Audit reduced **63 → 12 → 4 → 0** known vulnerabilities. Auth **9 passed in 3.39s**, session lifecycle/revocation **10 passed in 14.61s**, provider privacy **6 passed in 0.15s**, quiz/PDF **9 passed in 13.02s**, upload/multipart **9 passed in 3.59s**. `pip check`, tracked-secret scan, CI YAML and whitespace checks pass. | Obtain hosted GitLab pipeline evidence and add Flutter ecosystem advisory coverage. No UI preview, production access, deployment, migration or provider call. |
| 2026-09-24 | O01.3 | Added `test_api_contract.py` and a named backend critical-journey gate covering authentication/session lifecycle, payment concurrency/idempotency, private-download authorization and broadcast tenant isolation. | Isolated contract/auth/session **12 passed in 3.81s**; payments **19 passed in 22.66s**; private downloads **14 passed in 18.04s**; broadcast isolation **10 passed in 12.37s**. Each runner removed its generated database/role. | Add dependency-vulnerability scanning, then obtain hosted GitLab pipeline evidence. No UI preview, production access, migration, deployment or provider call. |
| 2026-09-23 | O01.2 | Added a tracked-file secret gate that reports only path/line/category, recognizes dynamic/template values and documented public Firebase client config, and rejects likely committed keys/tokens. Added a standalone disposable outbox migration upgrade/downgrade rehearsal job. | Repository secret scan passes. Focused isolated scanner/migration suite **4 passed in 0.11s**; generated role/database removed. GitLab CI YAML parses and whitespace check passes. | Add API-contract/critical-journey selection and dependency vulnerability scan, then obtain hosted GitLab pipeline evidence. |
| 2026-09-23 | O01.1 | Planned → In progress. Added pinned Flutter 3.44.1 GitLab jobs for shared, school and admin dependency resolution, analyzer gate and tests, plus explicit production-mode web builds for both portals. Frontend changes and CI-file changes trigger all gates; build artifacts are retained for one day. Corrected the existing Docker service YAML quoting so the configuration parses. | GitLab CI YAML parses. Local non-interactive analyzer gates report only the recorded informational/warning baseline; shared **65**, school **60** and admin **10** tests pass. Both release web artifacts compiled with `APP_ENV=production` and explicit HTTPS `API_BASE_URL`; no UI preview opened. | Add API-contract/critical-journey selection, dependency/secret scanning and a disposable migration rehearsal; then obtain hosted GitLab pipeline evidence. Analyzer baseline and native plugin warnings remain tracked for O04. |
| 2026-09-22 | F01.5 | In progress → Review → Verified technically (Codex self-review). Enforced current attendance read relationships, same-school enrollment sessions and nested write references; prevented upserts adopting another school/section record; filtered corrupt history and added no-store headers. | Full isolated backend **305 passed in 456.99s**, including **18 new regressions**; standalone **17 passed**; Ruff and whitespace checks clean. Initial focused run: 40 passed/1 fixture failure, corrected before the full run. | Next F01.6 aggregate/report export audit. Parent F01 remains In progress. Teacher false-success save and student/teacher stale-refresh UI gaps recorded under M10/U03/U04. No UI preview, frontend change, migration, deployment or provider send. |
| 2026-09-21 | U02.4.3 | Made the headmaster create/author/save mutation journeys harnessable: extracted UI-free `submitNewClass`/`submitNewSection` (classes), `submitNewClass` (timetable) and `validate`/`submitSave` (settings) that own validation, duplicate/day-range checks, backend-failure surfacing and refresh-on-success; sheets/save button delegate to them. Wrote the user-run physical browser checklist. | Focused mutation-journey **4 passed**; full school suite **60 passed**; targeted analysis on the three controllers + new test clean. Existing `printing` distribution warning remains. | Physical browser acceptance of `U02_HEADMASTER_BROWSER_CHECKLIST.md` is user-run; no preview. Next unblocked experience work is U03 (student design beyond home). No backend, migration, dependency or deployment change. |
| 2026-09-17 | U02.4.2 | Made core management refreshes fail closed by clearing prior class, student, teacher, timetable and settings state before each canonical read. Added deterministic loader seams and a combined success-to-failure regression. | Focused U02.4 **3 passed**; full school suite **56 passed**; targeted analysis and `git diff --check` clean. Existing `printing` distribution warning remains. | Next U02.4.3 cover class/section, timetable and settings mutations, then issue the user-run physical browser checklist. No preview. |
| 2026-09-17 | U02.4.1 | Found duplicate-account risk after partial student enrollment or teacher salary-profile failure; added resumable IDs and honest section-load failure state. Committed the preceding complete working tree and pushed `839dcb6` directly to `origin/main` at user request. | Focused form journeys **2 passed**; full school suite at slice completion **55 passed**; focused changed-file analysis clean. | Continue U02.4.2 management refresh correctness. No preview; lost-response create idempotency remains backend work. |
| 2026-09-16 | U02.3.4 | Replaced dashboard-memory approval lists with a canonical route-local reload; made class rosters URL-first and fail closed when section/student reads fail; added named-route and back-history coverage for both aggregate routes. | Focused workspace/route **8 passed**; full school suite **53 passed**; targeted analysis and `git diff --check` clean. Existing `printing` distribution warning remains. | Next U02.4 automate complete setup/core-management journeys and prepare the user-run physical browser checklist. No preview, backend change, migration, dependency, deployment or external action. |
| 2026-09-16 | U02.3.3 | Made attendance, exam, course/book, section/student message-history and payslip drill-downs reconstructible from URL parameters. Detail controllers re-fetch canonical records, reject missing/not-found IDs, clear stale data and expose retryable failures before enabling actions. | Focused route suites **12 passed**; full school suite **52 passed**; targeted analysis and `git diff --check` clean. Existing `printing` distribution warning remains. | Next U02.3.4 finish approval/class transient lists and automated router back coverage. No preview, backend change, migration, dependency, deployment or external action. |
| 2026-09-16 | U02.3.2 | Added fresh route-level effective-module checks for students/people, fees, attendance, timetable, messaging, reports, HR/payroll, transport, leave and exams. Disabled or unverifiable modules never construct the protected feature page; unexpected errors are redacted and recoverable. | Focused workspace/route **6 passed**; full school suite **51 passed**; targeted analysis and `git diff --check` clean. Existing `printing` distribution warning remains. | Next U02.3.3 replace remaining transient drill-down arguments with URL identifiers and canonical reads. No preview, backend change, migration, dependency, deployment or external action. |
| 2026-09-16 | U02.3.1 | Began refresh-safe routing: every headmaster route now initializes the module repository before feature bindings, and the upcoming-events route reloads canonical data instead of silently treating missing navigation arguments as an empty result. | Focused cold-route/workspace **5 passed**; full school suite **50 passed**; targeted analysis and `git diff --check` clean. Existing `printing` distribution warning remains. | Continue U02.3.2 with URL identifiers/canonical reads for remaining argument-dependent drill-downs and direct-link capability guards. No preview, backend change, migration, dependency, deployment or external action. |
| 2026-09-16 | U02.2 | Added a fail-closed headmaster workspace context from effective permissions, school profile and active session; capability-filtered shell tabs, dashboard actions and module search; persisted school/session identity in the desktop sidebar. | Focused workspace/settings **6 passed**; full Flutter suites **shared 63 / school 48 / admin 10 passed**. New shell/controller/model/widget/test analysis has no errors or warnings; the wider API service retains existing info lints. | Next U02.3 refresh-safe route-local bindings and capability guards. No preview, backend authorization change, migration, dependency, deployment or external action. Physical browser inspection remains for visual acceptance. |
| 2026-09-16 | U02.1 | Began U02 with grouped, searchable headmaster modules and a recoverable no-results state; module cards now use the shared accessible surface and retain full descriptions at large text. | Full Flutter suites **shared 63 / school 45 / admin 9 passed**; targeted component/test analysis clean. | Next U02.2 capability-aware desktop navigation and persistent school/session context. No backend authorization change, migration or deployment. |
| 2026-09-16 | U01.2, U01.3 | Adopted the U01 catalogue on headmaster settings, added keyboard and 200%-text evidence, corrected the discovered shared-button overflow, measured representative WCAG AA text contrast and disabled decorative dialog motion under reduced-motion preference. U01 moved In progress → Review. | Settings adoption **3 passed**; design system **7 passed**; full Flutter suites **shared 63 / school 45 / admin 9 passed**; targeted analysis clean. Existing `local_auth_android` and `printing` distribution warnings remain. | Independent U01 product/accessibility review remains. Continue U02; no data, dependency, backend, deployment or external-service changes. |
| 2026-09-16 | U01.1 | Started the Experience foundation in parallel with remaining Phase 1 gates. Published the shared UI catalogue and added canonical accessible card, form-field, table and empty/error/loading components without replacing existing feature screens. | Full shared suite **60 passed**; focused design-system tests **4 passed**; targeted Flutter analysis **no issues**. Verified semantics, 320 px at 200% text and reduced-motion behavior. The existing `local_auth_android` plugin-reference warning remains. | Next U01.2 representative headmaster-flow adoption plus keyboard/focus and measured contrast evidence. U01 remains open; no deployment, backend, data or dependency changes. |
| 2026-09-16 | F01.4 | Completed academic/student-report relationship gates, teacher-scoped section and quiz-picker rosters, draft-result gate, nested tenant filtering and stale/denied report clearing. Preserved guardian child access when an additional staff permission is revoked. | Full backend **286 passed in 393.33s**; final affected-module suite after the multi-role adjustment **32 passed in 69.50s**. Both saved JUnit reports show zero failures/errors/skips and runners cleaned their generated databases/roles. Standalone **17**; Flutter **shared 56 / school 42 / admin 8 passed**; Ruff, changed Dart analysis and whitespace clean. | Next F01.5 attendance/enrollment boundaries. No existing school data changes, migration, deployment or real sends. Custom staff policy, publication snapshots, broader aggregates and real-device acceptance remain open. |
| 2026-09-16 | F01.4 | Implemented current academic relationships, validated student targets and nested tenants, publication gating and teacher-scoped rosters including the quiz-picker endpoint used by report navigation. Shared report UI clears denied/stale data. | First focused backend 25 passed in 55.21s; standalone 17; full backend and school-app runs pending. | No migration or real sends. Save final evidence before marking technically verified; broader module access audit remains open. |
| 2026-09-15 | F01.3 | Completed send/contact relationship enforcement, both-party student context, tenant-safe participant history and thread filtering, row-locked recipient read receipts, private response headers, and shared reply-context/read-error/stale-list fixes. | Backend **273 passed in 333.11s** with saved report and test DB/role cleanup; standalone **17**; Flutter **shared 56 / school 41 / admin 8 passed**. Changed backend Ruff and controller/data/model analysis clean. Extended inbox analysis retains nine preexisting import infos, no errors/warnings. | Next F01.4 academic/student-report access. No migration, real sends or deployment. Direct history remains private to original participants, not administratively browsable; real devices, retention and send idempotency remain open. |
| 2026-09-15 | F01.3 | Started direct-message send/contact parity, valid shared student context, participant-only history/read operations, server-filtered conversations and honest read-receipt UI. | Send currently accepts any same-school member and unchecked student IDs; contact relationships lack complete tenant validation. | Preserve legitimate teacher/guardian and administrator reply flows; no administrative mailbox surveillance or new migration. |
| 2026-09-15 | F01.2 | Completed broadcast feed/detail audience checks, scheduled-content privacy, current relationship revocation, due-work sender/admin filtering, aligned recipient queries and private no-store response headers. Saved policy and rollout limits. | Final backend **258 passed in 601.73s** with saved JUnit report; focused **38 passed in 55.72s**; standalone **17**; Flutter **shared 48 / school 41 / admin 8 passed**. First fixture name collision corrected; an unavailable intermediate full-run result was not counted, and exact resource cleanup was verified before final rerun. Ruff and whitespace checks pass. | Next F01.3 direct-conversation boundaries. No new migration, production deployment or real sends. Current-membership policy does not recall downloaded content; real-browser and independent review remain open. |
| 2026-09-15 | F01.2 | Started broadcast feed/detail audience authorization and due-work oversight filtering. Current role/enrollment/guardian relationships will govern recipient reads; future scheduled content remains sender/admin-only until its scheduled instant. | Inspection confirms school-only feed/detail queries and unrestricted creator-level due listings. | Verify role/relationship changes, stale delivery records, malformed historical targeting and cross-school references. No database migration or provider sends. |
| 2026-09-15 | F07.3 | Completed keyed broadcast replay and original-draft recovery, sender/admin review authorization, paginated masked delivery review in headmaster school/admin workspaces, and explicit loading/error/uncertainty UI. | Backend **246 passed in 294.86s**; standalone **17**; Flutter **shared 48 / school 41 / admin 8 passed**. Initial focused run exposed test-school queued-work leakage into a later worker test; fixture-scoped cleanup fixed it, and the full rerun passed. No school data touched. | Next F01.2 communication feed/detail audience audit. Real sends, receipts/reconciliation, restart-durable drafts and production/browser acceptance remain open. F07.2 migration still unapplied; no new migration or deployment. |
| 2026-09-15 | F07.3 | Started UUID broadcast request replay protection and a staff/sender-scoped read-only delivery review with paginated recipient outcomes and masked addresses. | Existing message identity can back idempotency without a new migration; details/summary currently allow ordinary messaging viewers. | No manual outcome override or resend action without verified reconciliation. Keep F07.2 migration unapplied to existing data. |
| 2026-09-15 | F07.2 | Completed atomic notification intent, database polling, fenced leases, unique recipient planning and durable pre-I/O attempt markers. Interrupted/ambiguous attempts require review; untouched work resumes with bounded backoff. Prepared migration, independent worker command, ARQ poller and compose migration gate. | Backend **233 passed in 279.14s**; safety/provider **17**; Flutter **shared 37 / school 34 / admin 8 passed**. School first hit a temporary compiler disk-space failure; stopped that test session and reran serially successfully, without deleting files. Ruff, analyzer, migration rehearsal, single-head and compose YAML checks pass. Test DB resources removed. | No existing-data migration, real sends or deployment. Pinned ARQ 0.26.3 installed locally for adapter verification. Next F07.3 review/reconciliation and request-level idempotency; rollout requires matching schema/API/worker versions. |
| 2026-09-15 | F07.2 | Started transactional database outbox, fenced worker leases, durable per-recipient attempt markers and bounded safe worker recovery. API writes will no longer invoke providers or depend on Redis availability. | Inspection confirms enqueue-before-commit and whole-broadcast retry can duplicate external side effects. | Prepare additive migration only; do not apply to existing school data. Uncertain provider outcomes must require review, not automatic resend. |
| 2026-09-15 | F07.1 | Completed the next requested task: truthful simulated/accepted/failed/partial delivery outcomes, missing push-device records, neutral recovery acknowledgment and outcome-aware teacher/headmaster UI. Replaced deprecated audience radio properties; responsive cards show explanatory status text. | Full isolated backend **222 passed in 279.74s**; standalone **16 passed**; Flutter **shared 37 / school 34 / admin 8 passed**. Changed backend Ruff and auth/announcement/route analysis clean; local documentation links and diff whitespace checks pass. Generated test resources removed. | No real sends, historical data migration or deployment. Next F07.2 outbox/worker retry/deduplication; real email/receipt integration requires approved configuration and staging acceptance. Parent phases remain open. |
| 2026-09-15 | F07.1 | Started the next requested task: explicit simulated/provider-accepted delivery states, missing push-recipient outcomes, truthful broadcast UI. | Inspection confirms stubs return SENT and both composers claim sent for any HTTP success. Existing status columns are strings; no schema migration needed. | Real email, provider receipts, outbox/queue deduplication and deployment remain separate gates. |
| 2026-09-15 | F02.1, F03.1 | Completed session-bound authorization, rotation/reset locking, deactivation revocation, local-first logout, profile error handling, stale-response/account-switch guards and teacher-owned read-only routes. | Backend 213 passed in 261.93s; standalone 14; Flutter shared 37 / school 30 / admin 8. Changed auth/routes analysis clean. Disposable test resources removed. | No deployment/migration. Saved session rollout contract. Continue F07.1; device cleanup, cross-tab coordination and broader real-browser route acceptance remain open. |
| 2026-09-15 | F02.1, F03.1 | Codex begins session/route batch: bind access and file tickets to existing server sessions; serialize refresh/revoke; make local logout reliable and login profile failures honest; repair teacher report routes without widening headmaster guards. Estimate: one batch, no schema migration. | Inspection confirms stateless access survives logout, frontend logout does not call server, refresh lacks a row lock, and two teacher links target headmaster-only routes. | Verify legacy-token rollout and concurrent/offline cases; full device management and complete deep-link audit remain broader scope. |
| 2026-09-15 | F06.2 | Completed UUID fee-payment replay protection, transaction key serialization, client attempt retention, tap guard and uncertainty messaging. Phone-width test exposed existing status/action overflow; fixed wrapping/action layout and removed the no-op pending button. Saved money-field inventory and gated precision migration design. | Backend **202 passed in 577.68s**, standalone safety **14 passed**, Flutter **shared 25 / school 26 / admin 8 passed**. Changed backend Ruff and new shared retry analysis pass. Existing headmaster API file has 26 unrelated style infos; no payment compile errors. Initial layout regression failed before the fix; expanded final suite passes. Test resources removed. | No existing data/schema migration or deployment. Await currency policy for exact-money conversion; durable restart/device recovery remains open. Next F02 session/revocation audit and F03 route repairs while F04/F06 acceptance gates remain explicit. |
| 2026-09-14 | F06.2 | Codex starts payment-retry batch: UUID request key backed by existing payment identity → transaction-scoped key lock and immutable-payload replay checks → stable frontend attempts and duplicate-tap guard → isolated concurrent/retry tests. Estimate: one batch, no schema migration. | Inspection confirms invoice locking alone does not deduplicate partial payments; the existing UI also has no in-flight guard. | Preserve legacy keyless compatibility explicitly; fixed-precision migration and restart/device reconciliation remain separate acceptance work. |
| 2026-09-14 | F04.2, F01.2 | Third Phase 1 batch: record-authorized downloads, uploader ownership, public-static removal, student/teacher secure-download integration, assigned-staff homework boundaries and explicit legacy compatibility gates. | Final isolated backend **190 passed in 211.72s**; standalone safety **14 passed**; Flutter **shared 14, school 22, admin 8 passed**. Changed-file Ruff/Flutter analysis, documentation links and `git diff --check` clean. Initial shared failures were unmocked platform token storage, corrected with a token-store fake. Generated test resources removed. | No existing files/database rows moved or deleted. No deployment or manual device/browser walkthrough. Next F06 idempotency/fixed-precision design; F04 rollout inventory, public-avatar privacy, scanning/quotas remain open. |
| 2026-09-14 | F04.1, F06.1 | Completed document ownership/URL-identity checks, bounded upload reads, invoice locking, ledger-based receipts and finite-money validation. A stale-cache test exposed receipt totals still using the cache; changed receipt projection to sum its listed payments without modifying historical records. | Final isolated backend run: **177 passed in 190.99s**; standalone safety/privacy/limits/money tests: **14 passed**. Targeted Ruff, local document links and `git diff --check` pass. No frontend changes or frontend test rerun in this batch. Generated test database/role/uploads removed; no existing school data migrated or repaired. | Next F04 scope: authorized private downloads plus browser/mobile attachment integration and legacy-URL migration plan. F06 still needs idempotency, fixed-precision migration and historical report reconciliation. |
| 2026-09-14 | F04.1, F06.1 | Codex owns second Phase 1 batch. Sequence: validate document student/school/role and delete URL identity → bounded upload reads → invoice row locking and finite amount validation → isolated cross-school/concurrent-request tests. Estimate: one implementation batch, no schema migration. | Inspection confirms document add lacks student ownership validation; delete omits student ID; payment check/update lacks invoice lock. | Public media authorization, existing URL migration, scanning/quotas, fixed-precision migration and request idempotency remain open; these substeps do not close F04/F06. |
| 2026-09-14 | F08.1, F05.1, F05.2, F01.1 | Implemented safe test provisioning, environment/log privacy and broadcast isolation. A first full backend run had six failures in the new second-school fixture (roles were not provisioned); corrected the fixture, with all 10 broadcast tests passing afterward. | Final full backend rerun: **167 passed in 184.93s**. Standalone safety/privacy/auth regression tests: **8 passed**. Flutter: **shared 10, school 20, admin 8 passed**; production-define environment tests: **5 passed**. Targeted Ruff and Flutter analysis clean; `git diff --check` clean. No production data changed; generated test databases/roles/uploads removed. | F08 awaits independent/CI review. Continue F04/F06 P0 work, full F01 audit, then F02/F03/F07; finish F05 release/config and remaining logging verification. Phase 1 stays In progress. |
| 2026-09-14 | F08, F05; F01.1 next | Codex owns first Phase 1 batch. Sequence: remove destructive test reset → explicit isolated configuration and guard tests → safe build environment/logging and frontend tests → broadcast ownership/recipient regression tests. Estimate: one implementation batch; full Phase 1 remains broader. | Changes target test bootstrap/CI, shared environment/API client and both entrypoints; no production migration or deployment intended. | Fresh test database and existing Flutter runtime required; F01.1 follows the safe test gate. |
| 2026-09-14 | PLAN-01 | Initial source-led inventory, role flow map, confirmed-gap triage, official-standard review and phased tracker created | Inspected router registration, role routes, selected services/configuration/CI and existing tests; all local document links resolve; 48 unique packet IDs; `git diff --check` clean. No application tests run in this planning pass. | Start F08 and F05; then F01/F04/F06; resolve F02/F03 and F07 before broad feature expansion |

## 12. Source index and maintenance notes

Repository evidence:

- [Registered API groups and health/storage mounting](../backend/app/main.py), [module/action/role enums](../backend/app/core/enums.py), [access dependencies](../backend/app/core/deps.py).
- [Backend feature folders](../backend/app/modules/), [models](../backend/app/models/), [database migrations](../backend/alembic/versions/), [backend tests](../backend/tests/).
- [School route aggregation](../frontend/school_portal/lib/school/config/app_pages.dart), [headmaster pages](../frontend/school_portal/lib/school/config/headmaster_pages.dart), [teacher pages](../frontend/school_portal/lib/school/config/teacher_pages.dart), [student pages](../frontend/school_portal/lib/school/config/student_pages.dart), [guardian pages](../frontend/school_portal/lib/school/config/guardian_pages.dart), [driver pages](../frontend/school_portal/lib/school/config/driver_pages.dart).
- [Admin routes](../frontend/admin_portal/lib/src/app/admin_routes.dart), [admin entrypoint](../frontend/admin_portal/lib/main.dart), [shared package](../frontend/shared/lib/), [student redesign tests](../frontend/school_portal/test/student_redesign_test.dart).
- [CI pipeline](../.gitlab-ci.yml), [operations architecture](architecture/12-scaling-and-operations.md), [existing development methodology](architecture/10-development-process-and-roadmap.md).

Documentation descriptions and stale comments are not authoritative proof of runtime capability. Reconcile old foundation-only README text, outdated permission-document paths and removed-module claims as their associated packets are completed. Keep source links and standards review dates current.

### 2026-09-22 — F01.5 started

Owner/reviewer: Codex (self-review). Status: In progress. Estimate: one scoped implementation and verification session. Sequence: validate enrollment sessions and attendance nested IDs/upsert ownership → current relationship gates for reads while preserving daily/subject write authority → retain existing UI/API shapes → isolated HTTP negative/positive regressions and backend checks. Dependencies: F08 isolated runner and F01.4 access helpers. Physical browser acceptance remains user-run; no preview.

F01.5 inspection follow-up: **P1 M10/U04** — teacher attendance submit ignores the repository result and always shows Submitted; **P1 U03/U04** — student attendance and teacher roster refresh retain prior data on failed reads. Confirmed by controller inspection; no browser reproduction. These frontend changes are outside this backend packet and remain open.

### 2026-09-22 — F01.5 verification and handoff

- Owner/reviewer: **Codex (self-review)**. In progress → Review → **Verified technically**;
  independent engineering/product acceptance remains outstanding, and F01 remains In progress.
- Implemented API/permission scope and recovery limits:
  [attendance/enrollment access contract](ATTENDANCE_ENROLLMENT_ACCESS.md).
  No response-shape, frontend, dependency or schema change; no existing school data changed.
- Full command from `backend`:
  `.venv/bin/python scripts/run_isolated_tests.py --from-local-config -- -o addopts= -q --tb=short --show-capture=no --junitxml=/private/tmp/schooling-f015-backend.xml`.
  **305 passed in 456.99s**, zero failures/errors/skips. Saved JUnit:
  `/private/tmp/schooling-f015-backend.xml`. Runner confirmed its generated database/role removed.
- **18 new HTTP regression cases** cover role matrices, current relationship revocation,
  foreign/missing/nonstudent targets, invalid UUID/date inputs, session create/reactivation,
  malformed enrollment/student/class ownership, invalid subjects/slots, duplicate/mixed batches,
  cross-school and cross-section upsert rejection, filtered malformed history, teacher authority,
  withdrawal history and inactive-student unenrollment. Negative writes assert unchanged
  attendance/message/outbox counts; collisions also assert unchanged existing rows.
- Initial focused suite: **40 passed / 1 failed in 112.26s**. The corrupt-parent fixture
  hit a section-name uniqueness constraint before exercising the API. Renamed that fixture;
  the final full suite above covers the corrected case and three additional cases.
- Standalone `.venv/bin/python -m unittest discover -s verification -v`: **17 passed**.
  Changed backend Ruff and `git diff --check`: clean. Flutter suites not rerun because
  frontend code and API shapes are unchanged; physical UI/device acceptance remains open.
- Initial sandboxed provisioning was denied by the filesystem/network sandbox; the approved
  isolated runner completed outside that restriction. No user database was reset or migrated.
- UI follow-ups above remain open. Next backend work: **F01.6 aggregate report/export
  access**. No preview, real provider send, deployment, commit or push performed.

### 2026-09-22 — F01.6 started

Owner/reviewer: Codex (self-review). Status: In progress. Estimate: one scoped
implementation/verification session. Dependencies: F08 isolated runner, F01.4
relationship helpers and F01.5 attendance structural filters. Sequence: inspect
aggregate source queries and finance projections → preserve explicit school-wide
REPORTS permissions and verify view/export/toggle boundaries → retain API shapes
and existing UI → two-school corruption/permission/CSV reconciliation tests and
full isolated backend regression. No UI preview; no production data migration.

### 2026-09-23 — F01.6 verification and handoff

- Owner/reviewer: **Codex (self-review)**. In progress → Review → **Verified technically**;
  independent engineering/product acceptance remains outstanding and F01 remains In progress.
- Hardened aggregate projections and report filters: overview/enrollment nested tenant
  checks, distinct valid enrollment totals, school/session/category-bounded academic
  summaries, ledger-derived finance totals, attendance structural filters, known-status
  CSV output, reversed-date/foreign-section validation, and explicit REPORTS view/export
  and module-toggle coverage. No API response shape, schema, migration or frontend change.
- Full command from `backend`:
  `.venv/bin/python scripts/run_isolated_tests.py --from-local-config -- -o addopts= -q --tb=short --show-capture=no --junitxml=/private/tmp/schooling-f016-backend.xml`.
  **321 passed in 472.89s**, zero failures/errors/skips. Saved JUnit:
  `/private/tmp/schooling-f016-final-backend.xml`; generated database and role removed.
- Final focused F01.6/F01.5 suite: **34 passed in 92.12s**. Standalone safety/provider suite:
  **17 passed**. Changed backend Ruff and `git diff --check` pass. No Flutter suite,
  UI preview, physical browser/device acceptance, deployment or provider send.
- New contract: [aggregate report access](AGGREGATE_REPORT_ACCESS.md). Remaining work:
  F01.7 exam/quiz lifecycle access, fixed-precision/concurrent finance work, export
  pagination, independent review and production acceptance.

### 2026-09-23 — F01.7 verification and handoff

- Owner/reviewer: **Codex (self-review)**. In progress → Review → **Verified technically**;
  independent engineering/product acceptance remains outstanding and F01 remains In progress.
- Hardened exam and quiz lifecycle ownership: class/session/category and subject links,
  roster/student roles, school-scoped marks/results/seats, published-result visibility,
  draft report-card privacy, quiz publication and assignment checks, answer-question
  binding, attempt privacy and staff-only performance/report reads. No API response
  shape, schema, migration or frontend change.
- Added `tests/test_exam_quiz_access.py` with cross-school nested-ID, draft-quiz,
  attempt-privacy and cross-quiz-answer regressions.
- Full command from `backend`:
  `.venv/bin/python scripts/run_isolated_tests.py --from-local-config -- -o addopts= -q --tb=short --show-capture=no --junitxml=/private/tmp/schooling-f017-backend.xml`.
  **324 passed in 469.05s**, zero failures/errors/skips. JUnit:
  `/private/tmp/schooling-f017-final-backend.xml`; generated database and role removed.
- Focused final exam/quiz/scenario suite: **19 passed** (including the three new
  F01.7 cases).
  Ruff and `git diff --check` pass. No Flutter suite, UI preview, physical
  browser/device acceptance, deployment or provider send.
- New contract: [exam/quiz access](EXAM_QUIZ_ACCESS.md). Remaining work:
  F01.8 registered-router audit, promotion/remaining action paths, fixed-precision
  and concurrent finance work, export pagination, independent review and production acceptance.

### 2026-09-23 — F01.8 verification and handoff

- Owner/reviewer: **Codex (self-review)**. In progress → Review → **Verified technically**;
  independent engineering/product acceptance remains outstanding and F01 remains In progress.
- Hardened promotion, calendar and lesson lifecycle boundaries: local exam/session/
  student/section validation, published result filtering, no-partial-write promotion
  preflight, calendar session/date validation, nested exam-feed filtering, valid
  section/subject class pairing, and structurally filtered lesson progress. No API
  response shape, schema, migration or frontend change.
- Added `tests/test_remaining_access.py` with foreign nested-ID and promotion
  no-write regressions.
- Full command from `backend`:
  `.venv/bin/python scripts/run_isolated_tests.py --from-local-config -- -o addopts= -q --tb=short --show-capture=no --junitxml=/private/tmp/schooling-f018-final-backend.xml`.
  **327 passed in 509.41s**, zero failures/errors/skips. JUnit:
  `/private/tmp/schooling-f018-final-backend.xml`; generated database and role removed.
- Focused promotion/calendar/lesson/scenario suite: **13 passed**; new F01.8 suite:
  **3 passed**. Ruff and `git diff --check` pass. No Flutter suite, UI preview,
  physical browser/device acceptance, deployment or provider send.
- New contract: [promotion/calendar/lesson access](PROMOTION_CALENDAR_LESSON_ACCESS.md).
  Remaining work: F01.9 student-facing action paths, fixed-precision and concurrent
  finance work, export pagination, independent review and production acceptance.

### 2026-09-23 — F01.9 verification and handoff

- Owner/reviewer: **Codex (self-review)**. In progress → Review → **Verified technically**;
  independent engineering/product acceptance remains outstanding and F01 remains In progress.
- Hardened homework, document and transport actions: class/section/subject links,
  enrolled-student visibility, school-scoped submissions, student document ownership,
  route/stop/assignment nesting, school-scoped trip events/locations, and student /
  guardian transport request boundaries. No API response shape, schema, migration or
  frontend change.
- Added five cross-school/privacy/no-write cases to `tests/test_remaining_access.py`.
- Full command from `backend`:
  `.venv/bin/python scripts/run_isolated_tests.py --from-local-config -- -o addopts= -q --tb=short --show-capture=no --junitxml=/private/tmp/schooling-f019-final-backend.xml`.
  **329 passed in 483.36s**, zero failures/errors/skips. JUnit:
  `/private/tmp/schooling-f019-final-backend.xml`; generated database and role removed.
- Focused homework/document/transport/lesson suite: **25 passed**; new F01.9 suite:
  **5 passed**. Ruff and `git diff --check` pass. No Flutter suite, UI preview,
  physical browser/device acceptance, deployment or provider send.
- New contract: [student action access](STUDENT_ACTION_ACCESS.md). Remaining work:
  F01.10 registered-router/job/export audit, finance precision/concurrency,
  independent review and production acceptance.

### 2026-09-23 — F01.11 verification and handoff

- Owner/reviewer: **Codex (self-review)**. In progress → Review → **Verified
  technically**; the parent F01 moves to Review pending independent security and
  product acceptance.
- Reconciled the registered-router inventory and hardened malformed guardian
  placement and leave-link relations. Added `tests/test_final_f01_audit.py` with
  two cross-school/privacy/no-write regressions.
- Focused guardian/leave/final-audit suite: **11 passed**. Full command from
  `backend`: `.venv/bin/python scripts/run_isolated_tests.py --from-local-config
  -- -o addopts= -q --tb=short --show-capture=no
  --junitxml=/private/tmp/schooling-f0111-final-backend.xml`.
  **333 passed in 523.57s**, zero failures/errors/skips; generated database and role
  removed. Ruff and `git diff --check` pass.
- New audit: [registered routers](F01_ROUTER_AUDIT.md). No frontend change, schema
  migration, UI preview, physical browser/device acceptance, deployment or provider
  send. Next implementation packet: F04.3 private-asset rollout inventory.

### 2026-09-23 — F04.3 verification and handoff

- Owner/reviewer: **Codex (self-review)**. In progress → **Verified technically**;
  F04 remains In progress because production evidence and policy decisions cannot
  be inferred from a local codebase.
- Added `backend/scripts/audit_private_assets.py`: an explicit-URL, read-only
  PostgreSQL inventory of document, submission, avatar, uniform, logo, course-cover
  and URL-shaped metadata references. It emits aggregate JSON by default and only
  record IDs plus redacted/hashes reference shapes with `--details`; it neither
  changes database metadata nor loads, copies or deletes objects.
- Added [private-asset inventory and rollout plan](PRIVATE_ASSET_INVENTORY.md),
  including classification targets, production runbook, staged copy validation,
  object/metadata rollback boundary and unresolved policy decisions. Updated the
  existing [private-file rollout](PRIVATE_FILE_ROLLOUT.md) to point to it.
- Focused inventory/download suite: **17 passed in 17.73s**. Full command from
  `backend`: `.venv/bin/python scripts/run_isolated_tests.py --from-local-config
  -- -o addopts= -q --tb=short --show-capture=no
  --junitxml=/private/tmp/schooling-f043-final-backend.xml`.
  **337 passed in 526.32s**, zero failures/errors/skips; the generated test database
  and role were removed. `python -m ruff check` for the new script/tests,
  compilation and `git diff --check` pass.
- No schema migration, UI preview, production database connection, deployment,
  asset copy, data rewrite or deletion was performed. Next implementation packet:
  F04.4 asset policy and controlled-migration readiness.

### 2026-09-23 — F04.4 verification and handoff

- Owner/reviewer: **Codex (self-review)**. In progress → **Verified technically**;
  F04 remains In progress pending product/privacy and operations approvals.
- New-upload enforcement now accepts only `documents`, `submissions`, `avatars`
  and `uniform`; private uploads allow signature-detected PDF/PNG/JPEG/WebP and
  public uploads allow signature-detected PNG/JPEG/WebP. A caller-provided MIME
  type or extension cannot determine the stored suffix or returned type. Unknown
  folders and unrecognized bytes fail before storage.
- Added [new-upload policy and migration readiness](PRIVATE_ASSET_POLICY.md),
  including the compatibility status of avatars/uniform/logos, course-cover
  decision, scanner/quarantine, quota/retention and staging evidence gates.
- Focused upload/download suite: **19 passed in 26.01s**; generated database and
  role removed. Full command from `backend`: `.venv/bin/python
  scripts/run_isolated_tests.py --from-local-config -- -o addopts= -q --tb=short
  --show-capture=no --junitxml=/private/tmp/schooling-f044-final-backend.xml`.
  **340 passed in 518.96s**, zero failures/errors/skips; generated database and
  role removed. Ruff and `git diff --check` pass. No schema migration, UI preview,
  production database connection, asset copy, data rewrite, deletion or deployment
  was performed. Next packet: F04.5 scanning, quarantine and production readiness.

### 2026-09-23 — F04.5 verification and handoff

- Owner/reviewer: **Codex (self-review)**. In progress → **Verified technically**;
  F04 remains In progress pending staging and production acceptance.
- Added a ClamAV INSTREAM scanner gate before storage. A clean result is required
  before a key/blob can exist; detected content is discarded, and scanner errors
  fail closed with a retryable 503 and no blob/metadata write. Non-development
  configuration requires `UPLOAD_SCANNER_BACKEND=clamav` plus a private host.
- `/health/ready`, production compose health and the CI deploy readiness check
  now include the scanner. CI refuses a production deploy without protected
  scanner configuration. New [scanner rollout](PRIVATE_ASSET_SCANNING.md) records
  the private-network configuration and staging acceptance sequence.
- Focused scanner/upload/readiness suite: **26 passed in 27.42s**; final combined
  scanner/privacy/configuration suite: **28 passed in 20.59s**; full isolated backend:
  **347 passed in 500.11s**. Generated database and role removed. No UI preview,
  scanner deployment, production database access, asset migration, rewrite or deletion
  was performed. F04 remains open for quotas, retention, approvals and staging evidence.

### 2026-09-23 — F05.3 verification and next-phase handoff

- Owner/reviewer: **Codex (self-review)**. In progress → **Verified technically**;
  F05 remains In progress pending staging artifact and infrastructure-log acceptance.
- Production settings now reject the development database, default super-admin email,
  unsafe CORS and disabled upload scanner. CI requires all critical values before it
  writes the deploy environment. Client notification logs, cache/attendance logs and
  Uvicorn access logs retain only content-free event/category/path data.
- Focused isolated scanner/privacy/configuration suite: **28 passed in 20.59s**;
  shared configuration/notification diagnostics suite: **6 passed**; focused Flutter
  analysis reports no issues; final isolated backend: **347 passed in 500.11s**.
  Generated backend database and role removed. The pre-existing `local_auth_android`
  package warning remains. No UI preview, staging release, production access, data
  migration, deletion or deployment was performed. Next phase: F06.3 fixed-precision
  finance policy and migration rehearsal after currency/scale/rounding approval.

### 2026-09-23 — F06.3 precision-rehearsal handoff

- Owner/reviewer: **Codex (self-review)**. In progress → **Verified technically**;
  F06 remains In progress pending financial-policy and rollout acceptance.
- Added `scripts/audit_money_precision.py`, a policy-required `SET TRANSACTION READ
  ONLY` reconciliation command. It classifies fee/payroll scale/sign/non-finite issues
  and invoice cached-versus-ledger mismatches without printing money values, names,
  references or database URLs. It cannot migrate, repair or delete a record.
- `tests/test_money_precision_audit.py`: **3 cases**; focused money/payment/report
  suite: **31 passed in 52.43s**. Ruff, compilation and whitespace validation pass.
  The isolated database and role were removed. No UI preview, production read, backup,
  restored-copy rehearsal, data migration, deletion or deployment was performed.
  Next: approve currency scope, decimal scale and rounding; then run the command with a
  read-only production credential and rehearse an additive migration on an approved copy.

### 2026-09-23 — O01.1 Flutter CI-gate handoff

- Owner/reviewer: **Codex (self-review)**. Planned → **Review**. All local O01
  gates are implemented; one hosted GitLab pipeline result is the remaining
  evidence before O01 can be Verified.
- `.gitlab-ci.yml` now uses the pinned Flutter 3.44.1 image, an SDK-lockfile cache
  and frontend-change rules. It runs dependency resolution, analyzer checks and
  tests for shared, school and admin packages, then compiles both portals with
  `APP_ENV=production` and an explicit public HTTPS API base URL. Shared is a
  library and deliberately has no web-artifact job. CI artifact retention is one day.
- The CI YAML parses. Local non-interactive verification reports shared **65**,
  school **60** and admin **10** tests passing; both production web artifacts
  compiled. Existing analyzer information/warnings are reported but not fatal;
  analyzer errors fail the gate. No UI preview, deployment, production access,
  migration, deletion or external service action was performed.

### 2026-09-23 — O01.2 secret and migration CI-gate handoff

- Added `backend/scripts/scan_tracked_secrets.py` and a dedicated `secret:scan`
  lint job. It scans Git-tracked text only, emits a file/line/category without a
  matched value and avoids documented templates, dynamic values and Firebase
  client configuration that is intentionally public.
- Added `backend:migration-rehearsal`, which uses the existing isolated runner to
  exercise the notification-outbox upgrade and guarded downgrade in a disposable
  schema. The scanner passes; its focused test plus the migration rehearsal are
  **4 passed in 0.11s**. No UI preview, production credentials/data, migration,
  deletion, deployment or external service action was performed.

### 2026-09-24 — O01.3 contract and critical-journey CI-gate handoff

- Added a small stable OpenAPI contract test for login/refresh/logout/session
  operations and the privacy-limited session-list schema. `backend:critical-journeys`
  now makes those checks and the existing identity, payment, private-download and
  broadcast-isolation journeys a named release gate.
- Local isolated evidence: contract/auth/session **12 passed in 3.81s**; payment
  concurrency/idempotency **19 passed in 22.66s**; private downloads **14 passed in
  18.04s**; broadcast isolation **10 passed in 12.37s**. No UI preview, production
  access, data change, deployment or provider call was performed.

### 2026-09-24 — O01.4 backend dependency-audit handoff

- Added a pinned blocking `backend:dependency-audit` job. `pip-audit` receives
  `requirements-dev.txt`, which includes production dependencies, and fails on a
  finding or an incomplete dependency collection.
- Remediated every backend advisory reported on Python 3.12: FastAPI 0.141.1 /
  Starlette 1.7.0, pytest 9.0.3 / pytest-asyncio 1.4.0, python-multipart 0.0.31
  and pypdf 6.16.1. Replaced unfixable Python-JOSE/ECDSA with PyJWT 2.15.0 while
  preserving the app's `JWTError` boundary and FCM RS256 assertion flow. The audit
  now reports **no known vulnerabilities**. No UI preview, production access,
  deployment, migration, deletion or provider call was performed.

### 2026-09-24 — O01.5 Pub dependency-audit handoff

- Added `audit_pub_dependencies.py`, a fail-closed OSV batch-query scanner for
  hosted packages in all three Flutter lockfiles, and `frontend:dependency-audit`
  to CI. It reports only public package/version/advisory coordinates.
- The scanner's two isolated unit tests pass and the OSV audit found no advisories
  across **375** hosted package locks. O01 is now in Review pending hosted GitLab
  evidence. No UI preview, production access, data change, deployment or external
  provider action was performed.

### 2026-09-26 — F02.3 session-management UI start

- Owner: **Codex**. Scope: shared active-session screen, revoke confirmation,
  logout-all API/client flow, recoverable failures and entry points in both portals
  (including driver). Estimate: one implementation/verification session.
- Affected: shared auth service/new session view and tests, admin settings,
  school account menu/driver shell. Depends on technically verified F02.1/F02.2;
  existing session API contract is unchanged. No schema or deployment changes.

### 2026-09-26 — F02.3 session-management UI verification

- Owner/reviewer: **Codex (self-review)**. **Verified technically**; parent F02
  remains In progress. Shared active-session screen is reachable from admin
  settings, school account menus and driver toolbar. It identifies the current
  session, shows local lifecycle times, confirms revocation and supports global
  sign-out. Failure never claims confirmed revocation; refresh clears stale rows;
  pending actions disable duplicate taps. Logout-all retains credentials on server
  failure and clears local state after confirmation, with an account-epoch guard.
- Shared regression suite: **71 passed**, including five new widget scenarios and
  one logout-all service regression. Coverage includes retry, failed revocation,
  cancellation, current/global revocation, duplicate actions and 320px / 200% text.
  Shared changed-file and admin entry-point analysis pass. School analysis has
  only the existing driver `onReorder` deprecation. Real device/browser walkthrough,
  cross-tab coordination, storage-failure recovery and independent acceptance remain.
- No backend contract/schema change, deployment, provider action or production
  access. Existing working changes retained; no subagents used.
- Final portal regression results: **admin 10 passed; school 72 passed**. Shared
  changed-file analyzer reports no issues; repository whitespace check passes.

### 2026-09-26 — F02.4 / F03.2 reliability implementation start

- Owner: **Codex**, no subagents. Scope: recoverable credential-store failures,
  cross-tab refresh serialization and account-change invalidation, guarded cold
  links/login return, all school-role route guards and missing-context recovery.
  Estimate: one implementation/verification session. Affected: shared storage,
  auth/API/bootstrap/routing, school route bindings, portal entry points and tests.
- Dependencies: F02.1–F02.3/F03.1 technical contracts; server-side revocation and
  authorization remain authoritative. No production data/schema/provider changes.

### 2026-09-26 — F02.4 / F03.2 implementation evidence

- Owner/reviewer: **Codex (self-review)**. F02 and F03 remain **In progress**.
  Credential reads fail closed; incomplete token writes remain invalidated across
  restart; logout attempts independent cleanup and explains unconfirmed remote
  revocation. Browser refreshes are serialized through Web Locks and revision
  changes discard the previous account's state before another authenticated call.
- All school role pages now inherit a role guard and route-local repository binding.
  Safe in-app deep links survive session restore/login; unsupported or external
  return targets are discarded. Missing transient detail state shows a recovery
  screen, and guardian selected-child data is cleared/fenced on an account change.
- Focused shared auth/storage/navigation suite: **20 passed**. Focused school
  route-recovery suite: **3 passed**; the prior full school suite was **72
  passed**. Static analysis reported no source issues. Chrome cross-context and
  physical browser/device walkthroughs remain open release evidence. No database,
  production credential, deployment, provider or user data change was made.

### 2026-09-26 — F06 / L05 full-track implementation start

- Owner: **Codex**, no subagents. Scope: complete the money-field and mutation
  inventory across fees, payroll and subscriptions; harden remaining fee/payment
  paths; prepare an additive fixed-precision migration, reconciliation and
  rollback rehearsal package. Affected: backend money models/services/schemas,
  Alembic migrations, finance tests and payment-safety documentation.
- Dependencies: F08 and the existing F06.1–F06.3 contracts. The currency scope,
  decimal scale, rounding rule and adjustment/refund approval policy remain an
  explicit product gate; no production data, conversion or provider integration
  will be changed before that decision.

### 2026-09-26 — F06 / L05 mutation-safety and migration-package evidence

- Owner/reviewer: **Codex (self-review)**. F06 remains **In progress** pending
  financial-policy and rollout acceptance. Subscription assignment and renewal
  now accept durable UUID request identities, use transaction advisory locks and
  lock their school/subscription state before a ledger write. Identical retries
  return the existing resource; incompatible key reuse is a 409. Payslip
  generation locks the staff profile before its unique-period check, and payment
  marking locks the payslip row.
- The precision audit now inventories fee, payroll and platform-subscription
  money fields under one explicit proposed policy, while excluding percentage
  discounts because they are rates rather than currency. The payment safety
  document now includes the exact additive/shadow-column field map, immutable
  ledger invariants, restored-copy rehearsal sequence and rollback boundary.
- Focused isolated backend finance suite completed successfully; changed-file
  Ruff, compilation and `git diff --check` pass. No production database read,
  backup, restored-copy migration, data conversion, deletion, provider call or
  deployment was performed. Required decision before the executable migration:
  currency scope, decimal scale, rounding mode and refund/credit/waiver/payroll-
  adjustment approval policy.

### 2026-09-26 — F06 manual billing workflow implementation

- Owner/reviewer: **Codex (self-review)**. F06 remains **In progress** for the
  exact-money migration and adjustment ledger. The agreed operating model is
  manual school billing: no Stripe, payment provider, webhook, hosted checkout
  or automatic settlement. A Headmaster records a cash, bank-transfer or cheque
  payment only after verification; an optional private PDF/image proof is
  evidence, never automatic confirmation.
- Added private `payment_proofs` storage references to fee payments, preserving
  idempotent request comparison. Proof access is restricted to the recorder,
  Headmaster or Super Admin. Added Headmaster-only, linked-guardian billing
  contacts for each student, including primary payer, billing email/phone and
  payer reference snapshots. New Alembic head: `fa1b2c3d4e5f`.
- The Headmaster record-payment screen now supports partial manual payments,
  method, reference, note and an optional screenshot/PDF attachment. From the
  same student view, the Headmaster can select a linked guardian, save billing
  details and designate the primary payer. It remains responsive at 320px and
  140% text scaling, and keeps the retry identity when an outcome is uncertain.
- Focused isolated backend suite: **22 passed**; migration graph, Ruff,
  compilation and whitespace checks pass. Focused Flutter payment suite:
  **4 passed**; changed-file analysis reports no issues. No production database,
  provider, banking credential, data migration, refund, waiver, payroll
  correction or deployment was performed.

### 2026-09-27 — L05 fee-aging reconciliation view

- Added a Headmaster/Super Admin-only, read-only fee-aging endpoint and the
  Headmaster Fee Management dashboard display. Outstanding invoice balances are
  calculated from the payment ledger and grouped into Current, 1–30, 31–60,
  61–90 and 91+ days, with an explicit as-of date available for reconciliation.
- A guardian-access regression showed that the general fee-view permission is
  insufficient for school-wide aging totals; the endpoint therefore uses the
  established school-admin guard. Focused isolated backend fee/report/invoice
  suite: **7 passed**. Migration head and whitespace checks pass. Changed
  frontend analysis has no errors; the pre-existing API-service informational
  lint notices remain.
- No finance balances, payments, invoice caches, payroll, production data or
  provider configuration were changed. The immutable refund/credit/waiver and
  payroll-correction ledger still requires the agreed money policy.

### 2026-09-27 — L05 ledger/cache reconciliation status

- Added a Headmaster/Super Admin-only reconciliation endpoint and dashboard
  status. It checks every eligible invoice against its payment ledger, reports
  bounded cached-total/status discrepancies and identifies ledger overpayments
  for review. It is deliberately read-only: no invoice cache or payment is
  repaired as a side effect.
- Focused isolated fee-aging/reconciliation/payment/invoice suite: **14
  passed**. Guardian access is explicitly denied for both school-wide aging and
  reconciliation. Changed frontend analysis has no errors; the pre-existing
  API-service informational lint notices remain.

### 2026-09-27 — F06 Headmaster adjustment ledger foundation

- Added immutable proposed financial adjustments for refunds, credits, waivers
  and payroll corrections, plus a single immutable Headmaster/Super Admin
  decision. Fee requests validate their invoice target and payroll corrections
  validate their payslip target. The proposal stores the submitted positive
  decimal as text with an explicit currency code, avoiding new Float arithmetic
  before the financial policy is approved.
- The adjustment routes are Headmaster/Super Admin-only. Focused isolated
  adjustment/manual-billing suite: **5 passed**; migration head is
  `fb2c3d4e5f6a`; Ruff, compilation and whitespace checks pass.
- This is non-posting by design: approval does not alter invoice, payment or
  payslip totals. The next implementation step after the currency/scale/
  rounding decision is a reviewed posting policy and reconciliation rules.

### 2026-10-01 — O03.9 / F07 recovery hardening

- Added a deterministic, disposable 105-invoice O03 fixture with a competing
  tenant and an executable three-page assertion. It proves school scope is
  applied before invoice offsets, so foreign rows with overlapping due dates
  cannot shift a school’s result pages. Broadcast delivery history now uses the
  shared bounded page contract after reviewer, message and tenant scope, with
  stable newest-first ordering.
- Provider adapter diagnostics are bounded to the durable delivery-column
  limit before the completion transaction. A long failed-provider result is
  therefore recorded as a known failure rather than turning into an ambiguous
  worker outcome through a database-length error.
- Focused isolated fixture, broadcast and outbox suite: **16 passed**; changed
  communication code passes Ruff and whitespace checks. These checks are a
  deterministic pagination/recovery baseline, not a production performance
  measurement. O03 remains in progress for query/API budgets, cache policy,
  bulk quotas and representative device/browser traces.

### 2026-10-01 — O03.10 invoice-page query index

- Added the reversible `ix_invoices_school_due_id` composite index used by the
  stable school-scoped invoice history query (`school_id`, `due_date`, `id`).
  It supplements the existing single-column indexes and does not change the
  list response or finance values.
- The additive migration upgrade/downgrade is exercised in a disposable schema
  alongside the representative-invoice and standard invoice-page regressions:
  **3 passed**. Ruff, migration-head and whitespace checks pass. Query timing
  and capacity budgets still require an agreed staging-size fixture; no
  production schema change or measurement has been performed.

### 2026-10-01 — O03.11 query budgets and per-request School load

- Added an isolated-test SQL statement recorder (`tests/query_budget.py`) and
  `tests/test_o03_query_budgets.py`. Invoice, broadcast and direct-message
  history are measured on the 105-row representative data at limit 5, limit 50
  and the partial tail. The statement count must be identical across those
  windows (no per-row N+1 work) and within the budget: invoices **10**,
  broadcasts **10**, direct messages **11** per request, including
  authentication, tenant status and permissions, uncached (no Redis).
- Measurement found a duplicate School/plan/module load on every school-scoped
  request: the session identity map holds weak references, so the School loaded
  by the tenant-status gate was collected and re-queried by the permission gate.
  `get_request_school` now pins it for the session. The invoice list also no
  longer runs a full `count(*)` whose result the router discarded. Invoices went
  from 14 to 10 statements and broadcasts from 13 to 10; responses are unchanged.
- Local latency (single client, disposable database, not a budget): p50 about
  20–26 ms and p95 under 35 ms for every window. Set `O03_MEASUREMENT_REPORT`
  to collect the JSON evidence.
- The new budget tests fail on the previous code and pass with the fix. The full
  isolated backend suite: **434 passed, 0 failed** (exit 0).
  Staging-size latency/concurrency budgets, cache policy, bulk-job quotas and
  device/browser traces remain for O03.


### 2026-10-01 — O03.12 academic budgets, HTTP cache policy and bulk quotas

- Extended the statement budgets to homework (14), leave (11), exams (10),
  student attendance history (11) and student documents (12) on 105-row data;
  every endpoint is page-size independent.
- HTTP cache policy: every credentialed API response and every `/auth/`
  response (token issue/refresh) now defaults to `Cache-Control: private,
  no-store`. Previously fee, homework and exam reads and token responses had no
  directive. Server-side caching remains limited to the 30-second Redis
  tenant-status entry with explicit invalidation on school/subscription changes.
- Bulk-job quotas (`app/core/quotas.py`): 500 entries per attendance register
  or exam-marks request, 500 per staff attendance save, and 1,000 students per
  class-wide invoice issuance. Oversized requests are rejected before any write.
- `tests/test_o03_cache_and_quotas.py`: 3 cases that fail on the previous code.
  Full isolated backend suite: all tests passed (exit 0).

### 2026-10-01 — F02 web sign-in failure found in Chrome (P0, fixed)

- First Chrome run of the admin portal (Playwright, Chromium 1194, profile web
  build, `APP_ENV=development`) found that **no user could sign in on any web
  portal**: the session coordinator called `Random.secure().nextInt(1 << 32)`;
  on the web `1 << 32` is a 32-bit JS shift that evaluates to 0, so `nextInt`
  threw and login reported "Secure storage could not save your session".
  Native apps were unaffected. Fixed with a literal bound.
- The Web Lock wrapper now rethrows the action's own Dart error rather than an
  opaque boxed JS error, so failures inside the credential lock keep their type.
- The existing browser test `session_coordination_browser_test.dart` was never
  run in CI and one case failed because its mock backend called `expect`
  outside the test zone; fixed. Added a JS-integer regression case (fails before
  the fix). `flutter test --platform chrome`: **4 passed**. Added a
  `frontend:shared:browser-test` CI job.

### 2026-10-01 — Chrome acceptance: U02, F02, F03 and role journeys

Run in Chromium 1194 via Playwright against profile web builds of both portals
(`APP_ENV=development`, disposable `schooling_chrome` database, synthetic school,
headmaster, teacher, student, guardian and driver). The harness is committed in
[`frontend/e2e/chrome`](../frontend/e2e/chrome/README.md).

| Area | Checks | Result |
| --- | --- | --- |
| U02 setup/mutations | cold deep link, empty/duplicate/valid class, empty/valid section, settings validation (empty name, fee day 40, salary day 0), save and server persistence | Pass |
| U02 refresh/navigation | F5 keeps screen and data; browser Back returns with data | Pass |
| U02 browser Forward | Forward after Back | **Known limitation**: Navigator 1 single-entry browser history drops the forward entry; needs a Router API migration |
| U02 failure states | backend 503 on create keeps the sheet open with the error and writes nothing; failed read shows a retryable error | Pass (retry state fixed in this batch) |
| U02 accessibility | Enter submits; 200% zoom (half CSS viewport) has no page-level horizontal scroll; reduced-motion run | Pass; focus ring and colour-control names fixed in this batch |
| U02/F03 access | teacher on admin portal → access denied; teacher → headmaster URL denied | Pass |
| F02 session | refresh keeps session; logout → sign-in; Back after logout shows no data; direct URL after logout → sign-in with `returnTo`; no token left in browser storage; logout in one tab signs out a second tab | Pass |
| F03 routes | signed-out deep link returns after login; teacher route refresh | Pass |
| Role landing (390×844) | teacher, student, guardian, driver, headmaster land with no API errors | Pass after fixes below |

Defects found and fixed in this session (each with a regression test):

1. **P0 — no web sign-in** (`nextInt(1 << 32)` under JS integers). See F02 entry above.
2. **Over-limit list requests (422)**: headmaster dashboard overdue list, guardian
   fees and guardian homework asked for `limit=200` from endpoints bounded at 100.
3. **No retry on failed reads**: ten headmaster/teacher screens showed bare error text.
4. **Invisible keyboard focus** on shared primary/ghost buttons; unnamed colour swatches.
5. **False all-clear guardian dashboard**: fees always "Paid", homework "All clear",
   attendance "0 %" because the backend never supplied these figures. `/me/children`
   now returns live `fees_due`, `pending_homework` and this month's
   `attendance_percent` (null when no register); unknown values display "—".
6. **Homeroom teacher saw 0 sections**: the teacher dashboard counted only timetable
   sections; class-teacher sections are now included.

Not yet covered: physical phones/tablets, Safari/Firefox, screen-reader runs, and
a named product reviewer's sign-off.

### 2026-10-01 — L03/L04 Chrome journeys: attendance and homework lifecycle

Driven end to end in Chromium on the profile build with synthetic data. Every
step was verified against the server.

| Journey | Result |
| --- | --- |
| Teacher → Attendance → own homeroom section → Mark All Present → Submit | Record saved; guardian dashboard shows 100 % for the month |
| Student → Due Soon → assignment → notes → Turn In | Submission saved; item leaves Due Soon; guardian pending homework updates |
| Teacher → Tasks → assignment → Grade → Save | Submission graded; "1 submitted · 1 graded" |
| Route crawl: every guardian, student, teacher, headmaster and driver route | No API errors; only intended "missing context" recovery states |

Defects found and fixed (regression tests added):

1. **Timetables crashed on any free weekday** (guardian and student): a const
   empty list was sorted.
2. **Headmaster overview read the Super-Admin-only school endpoint** (403), leaving
   the school identity blank; it now reads `/profile`.
3. **Teacher daily register offered the wrong sections**: it listed timetable
   sections (where the backend rejects a non-class-teacher register) and omitted
   the teacher's homeroom section. New `GET /academic/me/sections` returns
   homeroom and taught sections; the register lists homeroom sections with an
   explanatory empty state.
4. **Register screen**: showed a hard-coded "Oct 24, 2023" date, offered Submit
   with no class loaded, sent an empty register to the server, exposed raw
   database ids, and "Mark All Present" was a gesture with no button semantics.
5. **Teacher assignments showed fabricated data**: hard-coded "Algebra 101 /
   Calculus II" filters, "1/0 turned in", "0 to grade" with work waiting and
   invented "+0 today / +0% wk" trends. The list API now returns class/section,
   roster size and graded count (homework budget 14 → 17 statements, still
   page-size independent); filters come from real classes; no deltas are invented.
6. **Submission upload label** advertised DOCX/Pages although only PDF is accepted.

7. **39 custom tap targets were invisible to keyboards and screen readers** (bare
   `GestureDetector`, including "Forgot Password?" on login, filter chips,
   section-header actions and pagination). A shared `AccessibleTap` (button
   semantics, Tab focus, Enter/Space activation, focus ring) replaces them, and
   `Pressable` gains the same behaviour. Widget test included.

Full isolated backend suite after commit `3ce256d`: **all tests passed, exit 0**
(441 tests). Frontend: shared 79, school portal 87, admin portal 10 passed;
browser coordination suite 4 passed in Chromium.

### 2026-10-01 — L05 finance under failure (Chrome)

Headmaster → Record Payment, verified against the server each time:

| Scenario | Result |
| --- | --- |
| Triple click on "Mark as paid", then confirm | One confirmation dialog, **one** payment |
| Double click on "Record payment" in the dialog | **One** payment (3,000 recorded, not 6,000) |
| Server records the payment but the response is lost | Screen re-reads balances and shows the invoice **paid**; one POST |
| Request never reaches the server | Invoice keeps a visible "did not confirm" warning and a **Check payment** action; the retry reuses the idempotency key and records once |
| Guardian view afterwards | Dashboard "Paid / Up to date"; fee screen totals match the server |

Fixed: the uncertain outcome used to be only a transient snackbar while the
invoice kept a plain "Mark as paid" button and stale balance. It is now durable on
the invoice and balances are refreshed immediately. Amounts still display a
hard-coded `$`; the currency is part of the open F06 money-policy decision.

### 2026-10-01 — F01 family fee leak (P0, fixed) and L03 multi-child journey

- **Any guardian could read every family's fee invoices.** Guardians hold
  `FEE_MANAGEMENT` view so they can see their children's fees, but the invoice
  list, invoice detail, receipt and the school-wide fee roster applied only the
  module permission. Found in Chrome while testing unlink revocation: after the
  headmaster unlinked a child, the guardian still listed that child's invoices,
  and also an unrelated family's. Fee reads are now scoped per caller: a user
  whose only roles are guardian/student sees their own and currently linked
  children's records; the fee roster is staff-only; staff keep school-wide
  access. `tests/test_fee_family_scope.py` fails on the previous code.
- New `frontend/e2e/chrome/leakscan.py` probes all 121 school-scoped GET
  endpoints as guardian and student with an unrelated student's id. Before the
  fix it reported exactly the two fee endpoints; after the fix it reports none.
  Endpoints keyed by other ids (invoice, message) are covered by targeted tests.
- Multi-child guardian journey in Chrome: switching child scopes dashboard, fees
  and timetable to that child; after unlink the child disappears on reload and its
  records are refused. Siblings sharing a first name now get distinguishable
  switcher labels ("Muhammad A." / "Muhammad H."), with full names announced to
  screen readers. "Paid this year" is relabelled "Total paid" (it sums all years).

