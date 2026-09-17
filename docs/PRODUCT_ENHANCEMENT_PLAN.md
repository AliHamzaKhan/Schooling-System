# Meri Taleem — Product Flow, Enhancement Plan & Progress Tracker

Last updated: **2026-09-16** (Asia/Karachi)
Baseline: commit `90a91a0` **plus the current uncommitted working tree**  
Document owner: Product owner / engineering lead — individual to be assigned  
Stage: **Phase 1 implementation in progress**
Next work: **F01.5 attendance/enrollment read, write and nested-session boundaries; F01.4 academic/student-report boundaries are technically verified. Provider reconciliation and coordinated F07.2 rollout remain gated, followed by remaining F02 device lifecycle, F03 deep links and F04/F06 work before Phase 1 acceptance**

## 1. Purpose and boundaries

Make Meri Taleem a dependable, connected school-management and learning product: a complete headmaster web workspace, efficient staff workflows, and a colorful, accessible student/mobile experience.

This is the canonical enhancement tracker. It complements, rather than replaces, the [foundation-first development process](architecture/10-development-process-and-roadmap.md). Future development should reference the work IDs below and update this file before ending each implementation session.

The initial discovery revision was **planning and documentation only**. Phase 1 implementation has now started; its changes and verification are recorded in section 11. No production deployment or existing school-database migration has been performed. New test databases are isolated and disposable.

### Evidence and confidence

- **Code present:** registered API, service, route, or view was inspected. This does not mean the feature works end to end or is production-ready.
- **Surfaced:** a relevant frontend route/view exists; completeness, permissions, browser refresh, and real-provider behavior may remain unverified.
- **Confirmed code gap:** the described behavior is visible in the inspected implementation. Runtime impact is stated separately when not reproduced.
- **Audit required:** a risk or missing verification, not a claim of a proven vulnerability.
- **Proposed:** new work, not an existing product capability or approved release commitment.

Scope covers the **31 baseline backend router groups plus two file-access infrastructure routers**, both Flutter applications, and their shared package. The router count is not a count of independently finished product modules. Six built-in roles exist: super admin, headmaster, teacher, student, guardian, driver. Custom roles exist in the backend, but a generic staff workspace is not registered in the school app.

This was a source-led discovery with targeted service inspection, not an exhaustive penetration test, full API-contract audit, or usability study. Previous local UI/test verification is recorded separately from this planning pass. Production configuration, real provider credentials, device testing, scale, and legal obligations remain unverified.

## 2. Product architecture and existing feature inventory

### Application boundaries

| Surface | Current responsibility | Required direction |
| --- | --- | --- |
| `frontend/admin_portal` | Platform schools, headmasters, plans, subscriptions, billing/revenue, module controls; now also imports headmaster pages from the school app | Preserve platform/school separation while making school administration fully usable on desktop |
| `frontend/school_portal` | Role-specific headmaster, teacher, student, guardian, and driver experiences | Complete each journey; adapt interaction patterns to phone, tablet, and web |
| `frontend/shared` | Auth, API client, persistence, notifications, biometric utilities, themes, reusable UI | One design system, reliable session lifecycle, capability-aware navigation, shared contracts |
| `backend` | FastAPI, async SQLAlchemy/PostgreSQL, migrations, permissions, domain services, jobs and providers | Tenant-safe workflows, transaction integrity, trustworthy delivery, operational visibility |

The current backend is a modular application. Preserve these boundaries; do not introduce microservices merely to appear modern. Extract services only after measured scaling or isolation needs justify the operational cost.

### Module map

Backend source paths below are relative to `backend/app/modules/`. “Limited UI evidence” means no complete dedicated management journey was established during this review, not that every widget is absent.

| Product area / source routers | Features visible in current code | Frontend evidence / limitation | Enhancement IDs |
| --- | --- | --- | --- |
| Identity — `auth` | Login, access/refresh tokens, profile, password recovery, change password, logout and logout-all APIs | F02.1 adds session-bound authorization and local-first server logout; device/recovery completion remains open | F02, F05, M01 |
| Access — `permissions`, `roles` | Effective permissions, module catalogue, custom roles and action grants | Platform module controls; role guards; no registered generic staff shell | F01, F03, M02 |
| Platform oversight — `admin` | Dashboard, revenue, billing, transactions, metrics | Admin views/routes present | M03 |
| School lifecycle — `schools` | School CRUD/status, profile, module toggles, subscription assignment, academic sessions/activation | School onboarding/detail; headmaster settings; session-management journey needs completion | M04, M06 |
| SaaS billing — `subscriptions` | Plans, subscription instances, renewal/cancellation/history and school status | Admin plan/assignment/management views | F06, M05 |
| People — `users` | Headmaster/user provisioning, listing, editing, deactivation and role assignment | Student/teacher registration and directories | M07 |
| Family links — `guardians` | Link/unlink guardians and students; current guardian's children | Headmaster guardian directory; guardian child selection | F01, M08 |
| Academics — `academic` | Classes, sections, subjects, timetable and scoped schedule reads | Headmaster structure/timetable; teacher/student/guardian schedules | M06, M09 |
| Attendance — `attendance` | Student attendance, subject-related views and reports | Teacher marking, student records, headmaster reporting | M10 |
| Curriculum — `courses` | Courses, books, chapters, notes, reading-progress lookup/save | Headmaster content management and student readers | M11 |
| Teaching plans — `lessons` | Lesson CRUD and teaching progress | Limited dedicated UI evidence | M12 |
| Homework — `homework` | Assignments, submissions, grading and review | Teacher authoring/grading, student assignment views | M13 |
| Quizzes — `quiz` | Authoring, questions, assignment, publish/close, attempts, grading and performance | Teacher quiz tools and student attempts | M14 |
| Exams/results — `examination` | Categories, announce, exams/papers, marks, publication, report cards and seating | Headmaster exam setup; teacher gradebook; learner/family results | M15 |
| Session outcomes — `promotion` | Preview/execute/history-oriented promotion routes; retained, graduated and re-exam outcomes | Headmaster promotion view | M16 |
| School fees — `fees` | Structures, single/bulk invoices, payments, receipts, student balances, reports/reminders | Headmaster fee/overdue/payment workflows; guardian fee views | F06, M17 |
| Broadcasts/push — `communication` | Templates, event configs, device tokens, immediate/scheduled broadcasts and delivery records | Announcements/notifications surfaced; provider and operations UI incomplete | F01, F07, M18 |
| Direct conversations — `messages` | Send/list/thread/read-state APIs | Shared inbox/conversation screens used by school roles | F01, M19 |
| Calendar — `calendar` | Events, holidays, CRUD and exam schedule aggregation | Teacher calendar, headmaster upcoming-events screen; standalone entry has argument dependency | F03, M20 |
| Meetings — `meetings` | Create/list/update/delete meetings | Guardian meeting view; headmaster endpoint exists; organizer workflow needs validation | M20 |
| Leave — `leave` | Requests, own/review lists, approval and rejection | Learner/family requests; teacher/headmaster review | M21 |
| Transport — `transport` | Vehicles, routes/stops, assignments, drivers, requests, trips, location, ETA, manifests and stop ordering | Headmaster transport management, driver trip screen, learner/family tracking | M22 |
| Staff/payroll — `hr` | Staff profiles, payslips/payment marking, teacher attendance | Headmaster salary and teacher-attendance views | F06, M23 |
| Inventory — `inventory` | Items, stock movements and transaction history | Limited dedicated UI evidence | M24 |
| Reporting — `reports` | Student/overview, attendance, academic, finance, enrollment and attendance export | Headmaster analytics/student reports; F03.1 adds teacher-owned read-only roster/report routes sharing the view | F03, M25 |
| Student files — `documents` | Add/list/delete document metadata | No complete document-management journey established | F04, M26 |
| File infrastructure — `uploads` | Member upload, size check, school-prefixed storage key and URL | Attachment integrations exist; only local storage is implemented | F04, M26 |
| AI assistance — `ai` | Text generation, reviewable quiz-question drafts and interaction log; real/stub provider modes | Quiz generation integration; broader governance/admin experience needs work | M27 |
| Automation — `jobs` | Fee-reminder endpoint plus queue/worker integration in core services | No complete job-operations UI established | F07, O02 |

**Not active modules:** library lending, hostel, and online classes were explicitly removed in migration `f1a2b3c4d5e6`. Old migrations/documents must not be used as evidence of available features. Course books are learning content, not a library circulation system. Restoring deprecated modules requires a new product decision and migration plan.

## 3. Current user flows and their intended completion

These sequences describe the intended connections between existing features. An arrow does not assert that every transition is automatic or already verified.

### Super admin

1. Sign in → platform dashboard.
2. Create school → configure plan/subscription, school status and allowed modules → provision headmaster.
3. Monitor school metrics/revenue/transactions → renew, cancel or suspend as authorized.
4. Target completion: guided onboarding checklist, explicit activation readiness, auditable billing changes and safe support tooling. School fees and SaaS subscriptions remain separate financial domains.

### Headmaster — browser and mobile

1. Sign in → resolve headmaster role → school dashboard/module directory in either portal.
2. Configure school → academic session → classes/sections/subjects → staff assignments → student enrollment/guardian links.
3. Prepare timetable/content/fees → manage attendance, leave, announcements, exams, transport and payroll.
4. Review results/finance/reports → promote students into the next session.
5. Target completion: every authorized routine setup/edit/approval/export can be completed from a browser without first opening the mobile app. Refreshing a detail URL must restore context safely.

### Teacher

1. Sign in → assigned classes/schedule.
2. Open class → roster → mark attendance or inspect authorized student performance.
3. Create homework/quiz/exam work → receive submissions/attempts → grade/review → publish authorized feedback.
4. Communicate with permitted recipients → review assigned leave requests → inspect progress.
5. Known break: teacher links to shared headmaster student-report/section-student pages now conflict with the blanket headmaster-only guard. Fix route ownership without granting teachers administrative access.

### Student

1. Sign in → learning dashboard with attendance, work and shortcuts.
2. Open course → book/chapter/note → reading progress.
3. Open assignment → prepare/submit work → inspect feedback; open quiz → start → answer → submit → results when permitted.
4. Review timetable/exams/report cards → messages/notifications → leave or transport where available.
5. Target completion: a trustworthy “Today” view, correct due/overdue/completed states, protected drafts, clear feedback, encouraging visuals and optional, non-disruptive motion.

### Guardian

1. Sign in → choose linked child → child-scoped dashboard.
2. Inspect attendance, exams/results, timetable and fees → receipt/payment workflow where authorized.
3. Message authorized staff → meetings → leave request → transport status.
4. Target completion: selected child is always visible; changing/unlinking a child clears prior child state and permissions. No sibling or unrelated-child data leakage.

### Driver

1. Sign in → assigned route/students → start pickup/drop-off trip.
2. Record location and passenger status → follow stops → end trip.
3. Target completion: reliable reconnect/resume, clear stale-location indicators, safe large controls and incident escalation. Do not require interaction while driving or expose unrelated children's locations.

### Custom staff — missing complete journey

Backend roles/actions can represent roles such as accountant or office staff. Proposed flow: sign in → capability-derived workspace → only authorized tasks. Do not map unknown roles to headmaster or require a fake built-in role to use custom permissions.

## 4. Cross-module integration contracts

Implement these as explicit service/API contracts and regression scenarios. Reuse existing notifications/jobs where correct; do not duplicate business rules in each dashboard.

| Trigger / source of truth | Required downstream behavior | Invariant / completion evidence |
| --- | --- | --- |
| School status, subscription or permission changes | API access, navigation, active-session capability refresh | Disabled capability cannot be used by old URL or stale client state; authorized renewal/status information remains reachable |
| Enrollment or guardian-link change | Rosters, fees, learning assignments, reporting, communication audiences and transport eligibility | All references belong to the same school/session; historical records are retained; revoked links invalidate cached child data |
| Timetable/calendar change | Teacher/student/family schedules, lesson planning, exam conflicts | One timezone/session-aware schedule; conflict checks and explicit exceptions |
| Attendance or approved leave | Daily/subject registers, headmaster reports, optional guardian notice | Approved leave does not silently overwrite an independently corrected record; correction history is visible |
| Assignment/quiz/exam publication | Learner visibility, notifications, gradebook/reporting | Drafts and answer keys remain private; publish is authorized and retry-safe |
| Fee payment or financial adjustment | Balance, receipt, reminders and reports | One durable financial event; retries cannot double-charge; reports reconcile with recorded payments |
| Promotion/session activation | Enrollment, future timetable/fees, cohort assignments and historical reports | Preview and approval precede batch execution; rerun cannot duplicate enrollments or rewrite historical results |
| Transport assignment/trip update | Driver manifest, guardian/student tracking, alerts | Driver/child membership checked on every read/write; location freshness and retention are explicit |
| User deactivation/logout/revocation | Tokens, device registrations, role caches and private downloads | Access follows documented revocation policy; no notifications to the wrong user's reused device |
| Background message/export job | Job status, retries, delivery/download view and audit trail | Committed data precedes side effects; deduplication and recovery do not claim exactly-once external delivery |

## 5. Findings that determine priority

These findings describe the initial audit baseline. Remediation and current
verification status are recorded in section 11; a baseline finding is not
automatically still unfixed after its associated substep is verified.

P0 = release-blocking safety/correctness work. P1 = required workflow/release foundation. P2 = meaningful enhancement after foundations. P3 = discovery only. Priority indicates sequencing, not a CVSS score.

| Finding | Evidence and confidence | Planned treatment |
| --- | --- | --- |
| Class/section broadcast audience lacks tenant filter | **Confirmed code gap:** `_resolve_audience` joins enrollments but does not filter school/active user in the CLASS/SECTION branches; `create_broadcast` stores `audience_ref` without a school-ownership lookup. Foreign references may select another school's recipients. No real sends or exploit test performed. [Service](../backend/app/modules/communication/service.py) | **P0 / F01:** validate referenced class/section and scope every recipient query; isolated two-school test must prove rejection and zero deliveries |
| Private uploads served as public static files | **F04.2 implemented locally:** storage-root static mount removed; document/submission bytes require record-authorized short-lived tickets. Public raster avatars/uniform images remain a compatibility exception. Production/external asset exposure needs audit. [Routes](../backend/app/main.py), [storage](../backend/app/core/storage.py), [rollout gates](PRIVATE_FILE_ROLLOUT.md) | **P0 / F04 remains open:** existing-asset inventory, public-avatar policy, coordinated deployment, type validation, scanning/quarantine and retention |
| Test bootstrap can drop a wrongly configured database | **Confirmed unsafe precondition:** test import calls `drop_all`; URL uses `setdefault`, and configured DB components can override it. Not executed during this audit. [Fixtures](../backend/tests/conftest.py), [configuration](../backend/app/core/config.py) | **P0 / F08:** fail closed on an explicitly isolated disposable database before any destructive setup; align CI environment precedence |
| Frontend is forced into debug environment | **Confirmed code gap:** both entrypoints bootstrap `Environment.debug`; API client logs request bodies in that environment, including auth payloads. [School entry](../frontend/school_portal/lib/main.dart), [admin entry](../frontend/admin_portal/lib/main.dart), [API client](../frontend/shared/lib/src/services/api_service.dart) | **P0 / F05:** explicit build environments; redact secrets/PII in every environment; release smoke test checks effective configuration |
| Logout and access revocation gap | **F02.1 verified locally:** access and file tickets check server sessions; client clears locally before bounded server logout; password/reset/deactivation and replay cases tested. [Contract](SESSION_AND_ROUTE_ROLLOUT.md) | **P1 / F02 remains open:** device cleanup, cross-tab refresh and real-device/storage-failure acceptance; offline logout cannot guarantee server revocation |
| Teacher navigation conflicts with headmaster guard | **F03.1 verified locally:** class/performance links now use guarded teacher-owned read-only URLs and query IDs. Headmaster-only guards unchanged. Four role/direct-URL/back/action tests pass. [Routes](../frontend/school_portal/lib/school/config/teacher_pages.dart) | **P1 / F03 remains open:** actual browser reload/login-return and all-module route/controller audit; existing quiz-roster dependency remains |
| Desktop navigation is not consistently refresh-safe | **Confirmed architecture gap:** headmaster repository is registered in its shell; several pages rely on prior controller state/`Get.arguments`. Events opened without arguments display an empty list rather than fetching. [Shell](../frontend/school_portal/lib/school/modules/headmaster/headmaster_shell.dart), [events](../frontend/school_portal/lib/school/modules/headmaster/features/overview/view/upcoming_events_view.dart) | **P1 / F03, U02:** route-local bindings, URL IDs/query state, canonical fetch and not-found/forbidden/error states |
| Financial precision/concurrent writes need hardening | **Confirmed code choices; concurrency impact untested:** fees use Float and payment recording performs read/check/sum/write without visible row locking or request idempotency. [Models](../backend/app/models/fees.py), [service](../backend/app/modules/fees/service.py) | **P0 / F06:** fixed precision, migration/reconciliation plan, concurrency control and duplicate-request tests; inspect payroll/subscription money too |
| Delivery success can mean a stub | **F07.1 implemented locally:** unconfigured providers return simulated, adapter success is accepted rather than delivered, missing push devices record failure, and composer/feed wording follows outcomes. [Contract](NOTIFICATION_DELIVERY_CONTRACT.md) | **P1 / F07 remains open:** real email, receipt verification, transactional outbox and worker retry/deduplication; historical sent records remain unconfirmed |
| Deployment and frontend quality gates are incomplete | **Confirmed configuration gap:** GitLab intentionally omits Flutter jobs; deployment health gate uses liveness, and generated environment passes legacy FCM key rather than the implemented v1 credential fields. [CI](../.gitlab-ci.yml), [config](../backend/app/core/config.py) | **P1 / O01, O02:** frontend pipelines, readiness/worker gates, validated secret configuration and rollback rehearsal |
| Endpoint/UI/module-policy coverage needs reconciliation | **Audit required:** some areas use school-member/admin dependencies rather than the toggleable Module vocabulary; inventory/documents/lessons/custom staff have incomplete UI evidence | **P1 / M02:** explicit mapping for every endpoint/action/UI entry; no assumption that every API is governed identically |

Other required audits: object/property-level authorization, teacher assignment boundaries, guardian unlinking, export and answer-key visibility, attachment ownership, retry safety, cache invalidation, enrollment/session consistency, inactive accounts, scheduled-job authorization, and production logs. An existing tenant guard is valuable but is not proof that nested object IDs are safe.

## 6. Standards baseline and measurable quality targets

Sources checked **2026-09-14**. Use stable published guidance; do not treat drafts or changing store policies as permanent requirements. These are engineering targets, **not a claim of certification or legal compliance**.

| Area | Baseline and source | Required evidence |
| --- | --- | --- |
| Web accessibility | Target **WCAG 2.2 AA**; include keyboard access, focus visibility/not obscured, error recovery and accessible authentication. [W3C recommendation](https://www.w3.org/TR/WCAG22/) | Criterion-level checklist on complete journeys, not only dashboard screenshots; manual screen-reader and keyboard tests plus automated checks |
| Flutter accessibility | Screen-reader semantics, large text, legible contrast, non-color status cues and large touch targets. [Flutter accessibility](https://docs.flutter.dev/ui/accessibility) | TalkBack/VoiceOver on native builds; 200% text where applicable; grayscale review; proposed product minimum 48 logical-pixel touch controls (not a statement of WCAG's minimum) |
| Adaptive interaction | Layout based on available space; preserve state and support touch, keyboard/mouse and meaningful deep links. [Flutter adaptive guidance](https://docs.flutter.dev/ui/adaptive-responsive/best-practices) | Portrait/landscape and widths 320, 390, 768, 1024, 1440; browser refresh/back/forward; no clipped actions or phone-width desktop forms |
| Application/API security | **OWASP ASVS 5.0.0**, latest stable identified in official releases; propose applicable Level 2 controls as verification scope. API Security Top 10 2023 informs abuse tests. [ASVS releases](https://github.com/OWASP/ASVS/releases), [API Top 10](https://api-security.owasp.org/editions/2023/en/0x00-header/) | Control-to-test matrix and reviewed exceptions; cross-tenant, role/action and nested-object tests; no unresolved P0 findings |
| Native app security | Storage, auth, network, platform and privacy controls from [OWASP MASVS](https://mas.owasp.org/MASVS/) | Native storage/session review; permission-denial tests; no credentials in bundles/logs; sensitive state removed on logout as designed |
| Push delivery | HTTP v1 server authorization with appropriate credentials. [Firebase v1 documentation](https://firebase.google.com/docs/cloud-messaging/send/v1-api) | Real test-device receipt; provider failures visible; token lifecycle, retries and credential setup tested without exposing secrets |
| Web performance | Where applicable/observable: p75 LCP ≤2.5s, INP ≤200ms, CLS ≤0.1. [Web Vitals](https://web.dev/articles/vitals?hl=en) | Measure actual builds on representative networks; Flutter canvas rendering needs complementary first-usable-screen and interaction tracing, not just a passing Lighthouse score |

### Proposed product budgets — validate against a baseline first

- API p95 ≤500ms for normal reads and ≤1s for normal writes under an agreed school-size/concurrency fixture; bulk exports and broadcasts run as jobs. Track database query counts and worst tenants.
- Native UI: profile core scrolling/navigation on a representative mid-range Android device; target a 60fps experience and report frame timings. Do not judge performance from debug web builds.
- Cold authenticated dashboard usable within 3 seconds on the agreed reference device/network after required network availability; record current baseline before committing to this target.
- Initial operational proposal: 99.9% monthly availability, backup RPO ≤24h and recovery RTO ≤4h, subject to hosting budget and product approval. These are not current service promises.
- Zero open P0 issues; all critical role journeys pass; money reconciles exactly at the chosen currency precision; private downloads reject unauthorized access.
- No forced animation, false progress, surprise context switches, or sensitive student/guardian data in analytics.
- Recheck target/minimum OS versions, Flutter/plugin compatibility and app-store release/privacy requirements before each release. Upgrade in tested increments, not blindly to every newest dependency.

### Privacy and safeguarding decisions

Confirm deployment countries, student age ranges, school/guardian responsibilities, retention periods and contractual requirements with the product owner and qualified advisers. Do not assume one jurisdiction's rules apply universally. Plan data minimization, guardian-link verification, private defaults, permission-limited exports, deletion/anonymization workflows, breach handling and subprocessor records. Precise transport location needs short, configurable retention and explicit access rules.

## 7. UI/UX direction for the complete product

Keep the recent indigo/violet foundation, teal/rose accents, soft backgrounds and subject colors as the starting direction. The student dashboard redesign is a **partial foundation**, not completion of every screen.

| Experience | Visual and interaction direction |
| --- | --- |
| Student | Friendly learning-focused dashboard, subject-colored cards, readable progress, clear next action and optional achievement feedback; age-appropriate illustrations without clutter |
| Guardian | Calm child-focused summaries, persistent child identity, urgent notices, outstanding balances and direct access to staff; less decorative motion |
| Teacher | Class-first workbench, fast roster marking, grading queue, reusable lesson/homework tools and visible save/sync state |
| Headmaster web | Grouped sidebar, school/session context, searchable directories, sortable/filterable tables, batch actions, detail panels and multi-column setup forms |
| Platform admin | Distinct platform identity, school health/subscription overview, clear financial provenance and explicit high-impact confirmations |
| Driver | Large high-contrast trip controls, passenger/stop status, connectivity/location freshness and simple recovery; no decorative animation during trip tasks |

Shared requirements:

- Tokenize color, typography, spacing, radius, elevation and motion; use semantic status colors separately from subject colors. School branding must not bypass contrast checks.
- Define reusable list/table, detail, form, filter, approval, empty, error, offline, denied, expired-subscription and loading patterns.
- Use brief, interruptible transitions (proposed 150–250ms), subtle feedback on meaningful completion, and reduced-motion alternatives. No looping decoration during reading, quizzes or driving.
- Desktop is a genuine productivity layout, not a stretched phone. Mobile supports keyboard-safe forms, safe areas, thumb-friendly actions and interrupted-task recovery.
- Use one consistent module vocabulary across UI, URLs, permissions, APIs and help text. Distinguish “Courses” from “Subjects,” “Fees” from “Subscription billing,” and “Results” from draft marks.
- Centralize date/time, timezone, currency and pluralization. English/Urdu with RTL is a proposed localization direction to confirm, not a verified existing feature.
- Add optional positive learning milestones only after progress data is trustworthy. Avoid public rankings, shame-based streaks or engagement pressure on children.

## 8. Phased delivery and dependencies

Phases are dependency gates, not promised calendar dates. Work estimates are deliberately deferred until each packet has a reviewed screen/API scope, fixtures and owner. Widening access, payment integrations and sensitive new modules require explicit product decisions.

| Phase | Outcome | Work packets | Exit gate |
| --- | --- | --- | --- |
| 0 — Discovery | Inventory, role flows, risks and maintained plan | PLAN-01 | This document saved; initial evidence linked; product decisions recorded as open |
| 1 — Safety & correctness | Secure boundaries and functioning existing journeys | F01–F08 | P0 fixes verified in isolated tests; teacher route regression and cold/deep-link auth flows verified; no misleading delivery status |
| 2 — Shared experience & headmaster web | Reusable UI and complete administration foundation | U01–U05; M01–M09; O01 starts early | Role-aware workspace, setup/session/people journeys and accessible component patterns verified on web/mobile |
| 3 — Academic lifecycle | Connected teaching, learning and assessment | M10–M16; M25, M26 | Enrollment → schedule → attendance/content → work → grading/results → promotion fixture passes across roles |
| 4 — School operations | Reliable finance, communication and operations | M17–M24; O02 | Payment reconciliation, recipient scoping, leave/meeting and transport/payroll/stock workflows pass |
| 5 — Intelligence & release hardening | Governed AI, observability and pilot release | M27; O03–O04; finish O01/O02 and remaining UI coverage | Standards checklist, native/browser tests, restore/rollback drills and school pilot accepted |
| 6 — Optional expansion | Validated new product opportunities | D01–D04 | Product discovery and privacy/cost review approved before implementation |

Critical dependency order: **safe test environment → tenant/session/config/storage/financial foundation → capability and shared UI contracts → school/session/people setup → academic and operational workflows → trustworthy reports/AI → release gates**.

Do not delay CI until the end: O01 starts during Phase 1/2. Design work can proceed alongside safe foundations, but new sensitive workflows must not ship around failing gates.

## 9. Canonical work tracker

### Status and ownership rules

Allowed statuses: `Planned`, `In progress`, `Blocked`, `Review`, `Verified`, `Deferred`.

- The roadmap has 44 top-level implementation packets and four deferred discovery packets. Current status/ownership is shown below; verified implementation substeps are tracked separately in section 11 and do not automatically close their parent packet.
- `Review` means implemented but missing final evidence; only `Verified` counts as completed enhancement work.
- Before starting a packet, add a dated entry in the execution log with a named owner, exact scope, estimate, affected files/APIs and dependencies. Split large packets into stable child IDs such as `M17.1` without deleting the parent.
- Mark `Blocked` with the missing decision/dependency and the next action. Do not silently omit unfinished acceptance criteria.
- Every packet also inherits the common definition of done in section 10.

### Foundation backlog

| ID | Priority | Owner discipline | Dependencies | Scope and packet-specific acceptance | Status |
| --- | --- | --- | --- | --- | --- |
| F08 | P0 | Codex / backend QA | None | Make database tests fail closed before schema destruction; reject inherited/non-test DB URLs and DB-component overrides; use disposable credentials/database. Demonstrate rejection without connecting to a real user database. | Review |
| F01 | P0 | Codex / backend security | F08 | Fix broadcast audience scoping; audit every nested ID/action across all registered routers, files, jobs and exports. Two-school/role fixtures prove forbidden operations produce no writes, deliveries or private data. | In progress |
| F02 | P1 | Shared frontend / backend | F08 | Complete login/profile-loading/refresh/logout/logout-all/revocation and device lifecycle. Profile failure is recoverable, not a false successful landing; offline logout clears local state; server revocation and access-token guarantees are explicit and tested. | In progress — F02.1 verified |
| F03 | P1 | Frontend / QA | F02 | Repair teacher shared-route conflict; add explicit role/capability guards and route-local bindings. Authorized teacher report/roster links work; teacher admin edits remain forbidden; direct URL/refresh/back/login-return tests pass for both portals. | In progress — F03.1 verified |
| F04 | P0 | Codex / backend security | F08 | Private/public asset classification; authorized private retrieval or short-lived signed access; upload ownership, bounded reads, content/type limits, quotas, quarantine and deletion policy. Anonymous/wrong-school downloads fail; public logos still work. Plan existing-URL migration. | In progress |
| F05 | P0 | Codex / shared frontend | None | Explicit development/staging/production builds; unconditional redaction of passwords/tokens/PII; secret/config checks. Release artifacts cannot default to debug logging or a developer API host. | In progress |
| F06 | P0 | Codex / backend finance QA | F08 | Audit all money fields; migrate to agreed fixed precision/currency semantics with backups and reconciliation; add transaction locks/constraints and idempotency. Concurrent/retried payments cannot overpay or diverge from receipts; historical totals reconcile. | In progress |
| F07 | P1 | Backend / integrations | F01, F05, F08 | Distinguish queued/provider-accepted/delivered/failed/simulated states; real email setup and v1 push deployment; queue retries/deduplication and commit-before-side-effect design. Provider outage cannot show a false success or lose recoverable work. | In progress — F07.1/F07.2 verified technically; rollout open |

### Experience foundation backlog

| ID | Priority | Owner discipline | Dependencies | Scope and packet-specific acceptance | Status |
| --- | --- | --- | --- | --- | --- |
| U01 | P1 | Design / shared frontend | F05 | Design-system catalogue for tokens, forms, cards, tables, dialogs, states and motion. Color/contrast, semantics, 200% text and reduced-motion checks pass on representative components; document exceptions. | Review — U01.1–U01.3 verified technically |
| U02 | P1 | Web frontend | F03, U01 | Headmaster desktop shell with grouped capability-aware navigation, persistent school/session context, searchable modules, list/detail/form patterns and refresh-safe routes. A headmaster completes setup and core management entirely in admin web. | In progress — U02.1–U02.3.4 verified technically |
| U03 | P1 | Mobile frontend / design | U01 | Apply student design beyond home to assignments, quizzes, exams/results, content, messages and profile/settings. Every state has legible hierarchy and real data; draft recovery and keyboard-safe actions work on small screens. | Planned |
| U04 | P1 | Mobile frontend / design | U01, F03 | Bring teacher, guardian, headmaster and driver journeys onto role-appropriate shared patterns. Child/class/trip identity stays visible; each role's critical journey passes phone/tablet/web layout checks. | Planned |
| U05 | P2 | Shared frontend / QA | U01, F02 | Localization/timezone/currency and accessible preferences; offline read-cache and explicit draft/sync patterns where safe. Cache keys include account/school/child/session; logout clears sensitive state; no silent last-write-wins for money/results/trips. | Planned |

### Module enhancement and addition backlog

“Add” here means a proposed extension to the existing module, not evidence that the current implementation lacks every underlying primitive.

| ID | Priority | Owner discipline | Dependencies | Enhancement/addition and acceptance | Status |
| --- | --- | --- | --- | --- | --- |
| M01 | P1 | Identity / frontend | F02, F05, U01 | Unified recovery and account settings on both apps; accessible password-manager flow, session management and privileged-user MFA/recovery design. Verified recovery cannot leak account existence or bypass school access; privileged MFA has tested recovery before rollout. | Planned |
| M02 | P1 | Backend / web | F01, F03 | Endpoint→module→action→role map; permission-aware UI and generic custom-staff workspace; role templates and permission-change audit. Accountant/office-role fixture works without headmaster grants; removed permission takes effect predictably. | Planned |
| M03 | P1 | Platform web / backend | M02, F06, U01 | Platform school-health dashboard, auditable lifecycle actions, consistent transaction provenance and search/filter/pagination. Platform totals reconcile with subscription records; no casual access to student records via support tooling. | Planned |
| M04 | P1 | Headmaster web / backend | M02, U02 | Guided school setup: identity/branding, contact/timezone/calendar defaults, readiness checklist and status transitions. Partial setup resumes safely; activation explains missing prerequisites; school boundaries remain explicit. | Planned |
| M05 | P1 | Billing / platform web | F06, M03 | Plan/version/entitlement consistency, renewals/cancellation/history, invoices/receipts and clear expiry/grace behavior. Plan changes preserve financial history; expired schools see authorized renewal information without regaining gated operations. | Planned |
| M06 | P1 | Academics / web | M04 | Academic sessions/terms, classes, sections, subjects, enrollment constraints and archival rules. Only intended active session drives new work; historical reports remain stable after rollover; duplicates/cross-school references rejected. | Planned |
| M07 | P1 | People / web | M02, M06, F04 | Complete admission/enrollment and teacher/staff profiles; validated bulk import preview, duplicate detection, document checklist, archive/transfer history. Import failures identify rows and cannot partially duplicate students; role/session assignments are validated. | Planned |
| M08 | P1 | Family / mobile | F01, M07, U04 | Verified guardian linkage, multi-child context, authorized contact changes and revocation. Linking/unlinking is auditable; stale child screens/downloads fail after unlink; family summaries agree with student records. | Planned |
| M09 | P1 | Academics / frontend | M06, M07 | Timetable editor with teacher/room/section conflict checks, substitutions and calendar integration. Double-bookings are rejected or explicitly overridden with reason; all role views show the same effective schedule. | Planned |
| M10 | P1 | Attendance / QA | M08, M09, F07 | Daily/subject attendance completeness, bulk marking, explicit save state, correction reasons, leave/holiday rules and scoped alerts. Repeated save is safe; late/offline corrections reconcile; guardian/student/report totals match. | Planned |
| M11 | P1 | Learning / frontend | M06, F04, U03 | Curriculum/content organization, controlled publishing, reader search/bookmarks and reliable reading progress. Membership/private-file checks apply to every resource; progress survives reconnect without granting access to unpublished material. | Planned |
| M12 | P2 | Teaching / frontend | M09, M11 | Surface lesson-planning backend in teacher/headmaster UI: objectives, scheduled coverage, resources and actual completion. Schedule/lesson changes stay consistent; coverage report uses persisted teaching data rather than inferred dashboard numbers. | Planned |
| M13 | P1 | Learning / frontend | M09, M11, F04 | Homework authoring/submission/feedback lifecycle: due/late rules, attachment validation, drafts, revision/rubric support and review. Due-soon excludes overdue/completed work; retries cannot duplicate submissions; teachers see only assigned work. | Planned |
| M14 | P1 | Assessment / frontend | M11, F01, U03 | Robust quiz draft/publish/assignment/attempt lifecycle, question-bank reuse, accommodations and reconnect strategy. Server enforces timing/attempt rules; no answer-key leakage before allowed review; duplicate submit yields one result. | Planned |
| M15 | P1 | Assessment / web | M09, M14, F07 | Exam scheduling/seating, marks validation/moderation, grading schemes, authorized publication and versioned report cards. Draft results stay private; mark edits are auditable; published reports match the approved marks and grading version. | Planned |
| M16 | P1 | Academics / backend | M06, M15 | Promotion preview/approval, retained/re-exam/graduated cases, batch safety and session rollover summary. Rerun is idempotent; mid-batch failure is recoverable; old enrollment/marks/fees are not overwritten. | Planned |
| M17 | P1 | Finance / web | F06, M07, F07 | Full fee workflow: recurring billing rules, concessions/scholarships, installments, credit/refund adjustments, aging and reconciliation. Authorized adjustments retain immutable provenance; balances/receipts/reports agree; gateway integration remains separately approved. | Planned |
| M18 | P1 | Communication / web | F01, F07, M08 | Communication center: audience preview, templates, scheduling, preferences/quiet hours, delivery details and bounded retries. Correct school/role recipients only; provider acceptance is not called confirmed delivery; failed messages have actionable recovery. | Planned |
| M19 | P1 | Messaging / frontend | F01, M08, U04 | Authorized conversation directory, read/unread consistency, pagination, attachments and safeguarding/reporting controls. No arbitrary contact discovery; marking read is scoped; child-related communication follows school policy. | Planned |
| M20 | P1 | Calendar / web | M09, F03, F07 | Unified events and meeting organizer: CRUD, audience, reminders, booking/reschedule/cancel and conflict checks. Events fetch correctly from a cold link; meetings cannot silently double-book staff; all roles see authorized updates. | Planned |
| M21 | P1 | Operations / frontend | M08, M10 | Leave rules, approval hierarchy, evidence, cancellation and notification trail. Only the assigned approver can act; duplicate/conflicting decisions are safe; attendance reconciliation is explicit and auditable. | Planned |
| M22 | P1 | Transport / mobile | F01, F07, M08, U04 | Harden route/driver/student assignment, live-trip reconnect, location freshness, passenger transitions, incident flow and capacity checks. Driver sees assigned trips only; linked families see their child's trip only; stale GPS is never presented as live. | Planned |
| M23 | P1 | HR / web | F06, M02, M10 | Staff lifecycle, salary rules, attendance/leave inputs, payroll approval, payslip history and payment reconciliation. Same staff/period cannot be paid twice; private salary data and edits require dedicated permissions. Confirm local payroll rules before calculation automation. | Planned |
| M24 | P2 | Operations / web | M02, U02 | Surface inventory UI with stock-in/out, adjustments, suppliers/reorder alerts and asset assignment where needed. Concurrent movements cannot create invalid stock; every adjustment has reason/actor; inventory staff need no broad school-admin access. | Planned |
| M25 | P1 | Reporting / backend | F03, M10, M15, F06 | Define shared metric formulas and filters; drill-down, safe exports, snapshot/as-of labels and dashboard consistency. Attendance/academic/finance totals reconcile to sources; spreadsheet export injection and cross-tenant leaks are tested. | Planned |
| M26 | P1 | Records / frontend | F04, M07 | Student document hub, typed documents, verification/versioning, access history, expiry and retention controls; reusable attachment picker/viewer. Metadata and blob permissions agree; archival/deletion handles both without deleting required financial/academic history. | Planned |
| M27 | P2 | AI / teaching / security | M11, M14, F01, F05 | Governed teacher-assistance workflow: review/edit before publishing, provider availability, budget/rate controls, provenance and minimized logs. Stub mode is explicit; generated questions are validated; AI cannot publish marks, discipline students or expose private records autonomously. | Planned |

### Reliability and release backlog

| ID | Priority | Owner discipline | Dependencies | Scope and acceptance | Status |
| --- | --- | --- | --- | --- | --- |
| O01 | P1 | QA / operations | F08, F05 | CI for backend, shared, school and admin apps; lint/analyze/test/build, API-contract and critical-journey tests, dependency/secret scans and migration rehearsal. Failed gates block release; Flutter changes cannot skip validation. | Planned |
| O02 | P1 | Operations / backend | F07, O01 | Readiness and worker/job visibility, structured redacted logs, alerting, backup/restore, provider configuration and rollback runbooks. Restore and deploy rollback are rehearsed; failed workers/jobs are visible; external notification tests use approved test recipients only. | Planned |
| O03 | P1 | Performance / backend | O01, M25 | Profile realistic school fixtures; bounded server pagination, indexes/query budgets, cache policy, bulk job quotas and native/web traces. Publish before/after measurements against agreed budgets and test tenant fairness. | Planned |
| O04 | P1 | QA / product / operations | O01–O03, release-scoped M/U packets | Accessibility/security checklist, supported-device/browser matrix, privacy/store declarations, pilot, training and rollback decision. All release acceptance evidence attached; no P0 issues; named product/engineering sign-off. | Planned |

### Optional additions — discovery only

| ID | Priority | Opportunity | Dependencies / decision gate | Acceptance for discovery | Status |
| --- | --- | --- | --- | --- | --- |
| D01 | P3 | Online admissions enquiry → application → document review → offer → enrollment; applicant tracking | M07, M26; confirm school demand and identity/consent policy | Approved workflow, integration boundaries, permissions, cost and measurable benefit before building | Deferred |
| D02 | P3 | Hosted online fee payments and accounting integration | F06, M17; choose jurisdiction/provider, settlement/refund/dispute ownership | Approved provider sandbox and webhook/idempotency/reconciliation design; never store raw card data in the product | Deferred |
| D03 | P3 | Multi-campus consolidation, SSO and external roster/LMS interoperability | M02, M06, M25; validate buyer requirements | Confirm tenant-vs-campus model and integration contracts; no cross-school access merely to simplify reports | Deferred |
| D04 | P3 | Student support/wellbeing referrals, learning goals and optional achievements; library/hostel/live-class restoration only if requested | Reliable core workflows; safeguarding/privacy review; deprecated-module decision | Interview users, define access/retention, estimate operational burden and approve a separate scoped plan | Deferred |

## 10. Common definition of done

A packet becomes `Verified` only when applicable checks below are met; record reasoned non-applicability rather than skipping silently.

- [ ] Scope/design and API/data contract agreed; all dependencies satisfied.
- [ ] Backend enforces school, nested-object, role/action, session and publication boundaries independently of UI.
- [ ] Schema changes include migration/reconciliation and recovery procedure tested on disposable data.
- [ ] Mobile and web role journeys completed with real API responses; no placeholder button or simulated success presented as real.
- [ ] Loading, empty, validation, denied, missing-record, timeout, expired-session, conflict and retry states covered.
- [ ] Responsive, keyboard, screen-reader, large-text, contrast and reduced-motion checks completed as applicable.
- [ ] Critical negative, duplicate/concurrent and cross-module tests pass; regression coverage added.
- [ ] Performance/security/privacy implications checked; sensitive logging removed.
- [ ] Relevant build/analyzer/lint checks pass; pre-existing unrelated failures identified separately.
- [ ] Evidence linked: change/commit, test commands/results, screenshots or recordings with synthetic/redacted data, migration/rollback notes.
- [ ] Named reviewer and product acceptance recorded; tracker and help/architecture docs updated.

### Required end-to-end acceptance scenarios

| Scenario | Essential assertions |
| --- | --- |
| Two schools and all six built-in roles plus custom staff | Manipulated object IDs, direct URLs and disabled modules never broaden access; platform actions remain separated |
| Headmaster browser-only setup | Configure school/session/people/timetable, issue fees and inspect reports without mobile; refresh works mid-journey |
| Teacher daily workflow | Open roster/report → mark attendance → assign work → grade; authorized shared views work after route-guard repair |
| Student learning lifecycle | Content → homework/quiz → feedback/results; large text and reduced motion; no premature answer/result visibility |
| Guardian multiple children | Switch child → fees/results/messages/transport; unlink revokes access and clears prior child state |
| Finance under failure | Parallel payments, double taps, client timeout/retry, adjustment and report export reconcile exactly |
| Academic year rollover | Promotion preview, mixed outcomes, rerun/recovery, new enrollments and unchanged historical reports |
| Real notifications | Correct audience; configured test provider; simulated, provider-accepted, failed and delivered states distinguishable |
| Driver trip interruption | Start/update/reconnect/end with authorized manifest, stale GPS and permission denial; no unrelated location disclosure |
| Production recovery | Bad migration/provider/worker/dependency failure detected; restore/rollback documented and rehearsed |

## 11. Progress dashboard and execution log

### Current progress

| Deliverable | Status | Evidence / limits |
| --- | --- | --- |
| PLAN-01 — source inventory, user flows, risk triage, standards baseline and enhancement tracker | Verified | This file; inspection and official sources listed here. Initial discovery only, not exhaustive runtime validation. |
| Recent student/shared visual refresh | Existing baseline — partial | Student dashboard/course/assignment styling, shared tokens and reduced-motion widget/test exist in the working tree. Not completion of U01/U03/U04. |
| Headmaster entry in admin portal | Existing baseline — partial | Admin imports headmaster pages and has role-based landing. F03/U02 remain open for route regression, refresh-safe flows and desktop completeness. |
| Auth rate-limit response fix | Existing baseline — targeted verification recorded previously | `backend/verification/test_auth_rate_headers.py` and modified auth router. Does not close the broader identity/security backlog. |
| Phase 1 implementation | In progress | F08 is implemented and under review. F01/F05 and scoped F02/F03/F04/F06/F07 substeps below are technically verified. Full backend suite: 286 passed; final affected-module suite after multi-role adjustment: 32 passed; standalone safety/provider tests: 17 passed. Latest Flutter suites: shared 56, school 42, admin 8 passed. F01.4 academic/student-report boundaries verified technically; F07.2 migration still not applied to existing school data. Phase 1 is not complete. |
| Experience foundation | In progress | U01 is in Review after catalogue, canonical components, headmaster-settings adoption, keyboard/200%-text coverage, measured WCAG AA text-pair contrast and reduced-motion dialog checks. U02.1/U02.2 add grouped search, capability-aware navigation and persistent school/session context; U02.3.1–U02.3.4 add cold-route dependencies, direct-link capability gates, URL-first canonical reads, canonical approval/class lists and automated named-route/back coverage. Latest Flutter suites: shared 63, school 53, admin 10 passed. Independent U01 acceptance plus physical browser acceptance and complete setup/management journeys remain open. |

The earlier development session reported local student login/mobile-layout checks. This Phase 1 batch reruns automated suites; it does not repeat the live browser/device walkthrough or certify a production release.

### Phase 1 implementation substeps — 2026-09-14

Owner and implementation reviewer: **Codex (self-review)**. Independent engineering/product acceptance and production rollout remain outstanding. `Verified` below denotes the stated automated technical scope only; parent completion still requires the full definition of done.

| Child ID | Implemented scope | Evidence | Status / remaining work |
| --- | --- | --- | --- |
| F08.1 | Removed `drop_all`; explicit test URL, connected database/owner/privilege/emptiness checks; isolated runner provisions unique restricted role/database and temporary uploads; dotenv/provider credentials excluded; CI uses isolated runner | `verification/test_database_safety.py`: four test methods including invalid URL, inherited configuration and connected-identity cases. Final isolated backend suite: 167 tests pass; runner cleans up its generated resources. | Verified technically; parent Review pending independent review and hosted CI execution |
| F01.1 | Tenant-owned class/section/student audience references validated before write/enqueue and again at recipient resolution; recipient queries constrain user, enrollment and section school IDs plus active status | `tests/test_broadcast_isolation.py`: 10 tests pass, including immediate/scheduled foreign references, zero side effects, active/enrolled recipients and missing/unknown references | Verified; full router/object/action audit remains under F01 |
| F05.1 | Both Flutter entrypoints resolve APP_ENV; release selection rejects debug; staging/production require explicit HTTPS public endpoint; HTTP diagnostics omit payloads, URLs, headers and exception text | `frontend/shared/test/environment_safety_test.dart`: default and production-define runs; changed-file static analysis clean | Verified for configuration/unit scope; real release artifact startup against approved staging endpoint remains |
| F05.2 | Communication/AI stub diagnostics omit recipient/content/token/prompt; provider exceptions and remote error bodies no longer copied into delivery errors; FCM preserves allowlisted machine codes | `verification/test_provider_privacy.py`: three tests pass for stub, exception and AI prompt privacy | Verified for tested paths; broader backend/infrastructure logging audit remains |
| F04.1 | Document add/list student-school-role validation and delete student-ID binding; bounded upload reads reject empty/oversized files before storage | Four upload-limit unit tests and three document/HTTP upload regressions pass; included in latest full suite | Verified technically; byte access is handled separately by F04.2 |
| F04.2 / F01.2 | Private uploader-owned keys; no public storage-root mount; resource-bound 60-second tickets with authorization rechecks; student/teacher download UI; assigned-staff homework lists, history and mutations | 13 new backend tests; final full suite 190 passed in 211.72s. Shared 14, school 22, admin 8 Flutter tests pass; changed-file analysis clean | Verified technically; [legacy/public-media rollout gates](PRIVATE_FILE_ROLLOUT.md), scanning/quotas and real device/browser acceptance remain open |
| F06.1 | Scoped invoice row lock; ledger-based balance check; ledger-derived receipt projection; non-finite fee write rejection and safe 422 validation response | Seven payment integration cases pass, including three deliberately overlapping request scenarios; two money-validation unit tests pass; full suite 177/177 | Verified technically; Float storage, historical reconciliation and payroll/subscription money remain open; keyed fee retries addressed by F06.2 |
| F06.2 | Optional UUID payment request identity; transaction key lock and original-response replay; changed payload/actor/invoice conflict; stable headmaster client attempts, duplicate-tap guard and responsive payment action | 12 new backend regressions; full backend 202 passed in 577.68s. Shared 25, school 26, admin 8 tests passed; includes phone/large-text/desktop payment checks and auth-refresh/lost-response replay | Verified technically for keyed fee requests and in-memory client recovery. Keyless callers, durable restart/device recovery and payroll/subscription replay remain open. [Contract and precision migration design](PAYMENT_SAFETY_AND_MIGRATION.md); currency decision requested, no data migration |
| F02.1 | Session-bound access/file tickets; locked refresh/revoke and one-use reset challenges; deactivate/re-enable revocation; honest profile login, retryable refresh outages, local-first logout and account-switch request guards | Full isolated backend 213 passed; 11 new backend regressions; shared 37 passed including 12 lifecycle cases; standalone 14 passed | Verified technically. [Rollout contract](SESSION_AND_ROUTE_ROLLOUT.md); cross-tab refresh, device cleanup, storage-failure handling and full recovery review remain open |
| F03.1 | Dedicated guarded teacher roster/report URLs, query IDs, local binding, read-only actions and repaired class/performance links | School 30 passed including four teacher URL/guard/back/action tests; admin 8 passed; changed-route analysis clean | Verified widget/route scope; actual browser refresh/login-return and all-module route/controller audit remain open |
| F07.1 | Simulated vs provider-accepted outcomes; missing-device failure records; honest summaries/timestamps; teacher/headmaster confirmations and responsive status cards; current grouped audience radios | Nine new backend outcome tests; final backend 222 passed in 279.74s; standalone 16 including mocked Twilio/FCM acceptance; shared 37 / school 34 / admin 8 passed; changed announcement/auth analysis clean | Verified technically. [Delivery contract](NOTIFICATION_DELIVERY_CONTRACT.md); real email, receipts, transactional outbox, worker retry/deduplication and real-provider/broker rollout remain open |
| F07.2 | Transactional notification outbox; fenced worker leases; per-recipient committed attempt markers; bounded recovery of untouched work; uncertainty instead of blind resend; independent DB poller and ARQ adapter; additive migration and guarded downgrade | Full backend 233 passed in 279.14s; twelve outbox cases plus migration rehearsal; standalone 17; Flutter shared 37 / school 34 / admin 8 passed; static/compose/head checks pass | Verified technically. [Migration/worker rollout](NOTIFICATION_OUTBOX_ROLLOUT.md) remains required and unapplied to existing data. Real provider/broker acceptance, review tooling, request-level idempotency and provider-specific retry rules remain open |
| F07.3 | UUID broadcast request serialization/replay; actor/school/payload conflicts; immutable teacher/headmaster retry drafts; sender/admin-only delivery inspection; masked, paginated read-only headmaster review panel with responsive/error states | 13 new backend cases; full backend 246 passed in 294.86s; standalone 17; Flutter shared 48 / school 41 / admin 8 passed, including refresh/lost-response identity and phone/desktop review | Verified technically. [Replay/review contract](BROADCAST_REPLAY_AND_REVIEW.md). In-memory recovery only; legacy keyless clients, provider receipts/reconciliation, teacher review navigation, real devices and coordinated rollout remain open. No resend or outcome override added |
| F01.2 | Shared SQL feed/detail visibility, current role/enrollment/guardian checks, scheduled-content privacy, sender/admin due-work oversight, aligned worker recipient checks and private no-store response headers | 12 new privacy tests; final isolated backend 258 passed in 601.73s; final focused privacy/review/download suite 38 passed; standalone 17; Flutter shared 48 / school 41 / admin 8 passed | Verified technically. [Audience policy](BROADCAST_AUDIENCE_ACCESS.md); current-membership history, not recipient-snapshot history. Direct conversations, full nested-object audit, real-browser acceptance and production rollout remain open |
| F01.3 | Send/contact parity, current shared-student validation for both participants, tenant-safe contact relationships, private participant history, server-side conversation filter, row-locked read receipts and safer shared UI context/error state | 15 new backend cases; full backend 273 passed in 333.11s; standalone 17; Flutter shared 56 / school 41 / admin 8 passed; eight new messaging tests | Verified technically. [Direct-message contract](DIRECT_MESSAGE_ACCESS.md). No administrative mailbox surveillance; historical participant mailbox retained. Request replay/offline recovery, pagination, moderation/retention and real-device acceptance remain open |
| F01.4 | Current teacher/student/guardian report relationships, section and quiz-picker roster gates, draft-result visibility, nested tenant filters, active teacher assignment validation and denied-refresh data clearing | Full backend 286 passed in 393.33s; final affected-module suite after multi-role adjustment 32 passed in 69.50s; standalone 17; Flutter shared 56 / school 42 / admin 8 passed; 14 new backend cases and one new UI case | Verified technically. [Academic/report contract](ACADEMIC_REPORT_ACCESS.md). Broader aggregate, attendance-write, examination/quiz lifecycle, published-grade snapshots and custom-staff audits remain open |

Verification instructions and environment changes: [Phase 1 verification guide](PHASE_1_VERIFICATION.md).

Remaining Phase 1 work is explicit: private-asset inventory/migration, public-avatar policy, scanning/quotas and rollout verification (F04), fixed-precision money and concurrency/idempotency (F06), session/device lifecycle (F02), teacher route/deep-link repair (F03), complete nested-object audit (F01), production environment/logging verification (F05), and honest delivery states/provider/queue recovery (F07). No existing private-file or money data migration has been applied.

Known tooling warnings: shared-package tests report a missing `local_auth_android` plugin reference; app tests report `printing` Swift Package Manager support warnings. They do not fail these tests but must be resolved/verified for native distribution under O01/O04. No plugin dependency changes were made in this batch.

Next implementation packet: **F01.5 — attendance/enrollment access boundaries**.
Audit section register/summary and individual attendance reads, enrollment session
references, and attendance upsert tenant ownership. Preserve class-teacher versus
subject-teacher write authority; denied or malformed requests must not change data
or schedule notifications. Broader aggregate reports and exam/quiz lifecycles remain
separate audit work; F01.4 does not certify all student-record endpoints.
F07 provider-receipt reconciliation and real-provider rollout remain separate gates.

Next experience packet: **U02.4 — complete setup and core-management journey
coverage**. Exercise the headmaster's web setup and primary management paths
through automated route/form harnesses, close any honest loading/error/state
gaps found, and prepare a concise physical browser checklist for the user.
Actual visual browser refresh remains a physical acceptance step by user
request; do not open a preview. U02.3.1–U02.3.4 do not certify the complete
browser-only setup and management journey.

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

### Execution log

| Date | IDs | Status change / work performed | Verification | Blocker / next action |
| --- | --- | --- | --- | --- |
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

### Update procedure for every future development session

1. Read this file and inspect current working-tree changes; do not overwrite unrelated work.
2. Select the next unblocked packet in phase/dependency order. Record `In progress`, named owner, scope and estimate in the log.
3. Before implementation, document the packet's concrete sequence: data/API → permission rules → UI → integration → tests.
4. Keep acceptance checks and child IDs current as work proceeds; record new findings against their affected module and severity.
5. Move to `Review` when implementation is done, then `Verified` only with evidence and acceptance. Record blockers and remaining work explicitly.
6. Update the date, progress dashboard and “Next work” field. Append history; do not erase earlier status changes.
7. Attach commit/PR references when available. This baseline includes uncommitted work; do not invent a commit reference for it.

Reusable log entry:

```text
Date / packet ID:
Named owner / reviewer:
Status before → after:
Scope and implementation sequence:
Dependencies / estimate:
Files, API contracts and migrations changed:
Tests and exact results:
UI/accessibility/performance evidence:
Remaining acceptance criteria / blockers:
Rollback or recovery notes:
Next action:
Commit / PR (when available):
```

### Decisions to resolve before affected implementation

| Decision | Default planning assumption | Needed before |
| --- | --- | --- |
| Release audience and supported devices | Existing Flutter apps and browser portals remain; validate real school devices/network quality | U01–U05, O03/O04 |
| Headmaster browser scope | Full parity for routine management, setup, approval and exports; native capture/location may stay device-specific | U02 acceptance |
| Locale and calendar/currency rules | Configurable school timezone/currency; English first, Urdu/RTL proposal to confirm | U05, F06, M05/M17/M23 |
| Child privacy, retention and consent responsibilities | Minimize collection; private defaults; school-specific policy requires review | F04, M08, M19, M22, M26/M27 |
| Financial adjustments, refunds and subscription grace | No implied accounting/legal policy; owner must define approval rules | F06, M05, M17/M23, D02 |
| Provider and hosting budget | Use existing integration abstractions; no purchase, new provider commitment or production credential change without approval | F07, O02, M27, D02 |
| Team capacity and release dates | Sequence by gates; do not promise dates without named owners and estimates | Phase scheduling |
| Deferred/deprecated modules | Remain outside committed enhancement scope until demand is validated | D01–D04 |

## 12. Source index and maintenance notes

Repository evidence:

- [Registered API groups and health/storage mounting](../backend/app/main.py), [module/action/role enums](../backend/app/core/enums.py), [access dependencies](../backend/app/core/deps.py).
- [Backend feature folders](../backend/app/modules/), [models](../backend/app/models/), [database migrations](../backend/alembic/versions/), [backend tests](../backend/tests/).
- [School route aggregation](../frontend/school_portal/lib/school/config/app_pages.dart), [headmaster pages](../frontend/school_portal/lib/school/config/headmaster_pages.dart), [teacher pages](../frontend/school_portal/lib/school/config/teacher_pages.dart), [student pages](../frontend/school_portal/lib/school/config/student_pages.dart), [guardian pages](../frontend/school_portal/lib/school/config/guardian_pages.dart), [driver pages](../frontend/school_portal/lib/school/config/driver_pages.dart).
- [Admin routes](../frontend/admin_portal/lib/src/app/admin_routes.dart), [admin entrypoint](../frontend/admin_portal/lib/main.dart), [shared package](../frontend/shared/lib/), [student redesign tests](../frontend/school_portal/test/student_redesign_test.dart).
- [CI pipeline](../.gitlab-ci.yml), [operations architecture](architecture/12-scaling-and-operations.md), [existing development methodology](architecture/10-development-process-and-roadmap.md).

Documentation descriptions and stale comments are not authoritative proof of runtime capability. Reconcile old foundation-only README text, outdated permission-document paths and removed-module claims as their associated packets are completed. Keep source links and standards review dates current.
