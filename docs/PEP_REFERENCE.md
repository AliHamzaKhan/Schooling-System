# Meri Taleem — Enhancement Plan: Reference (product context)

Part of the [Product Enhancement Plan](PRODUCT_ENHANCEMENT_PLAN.md). Stable reference: purpose, architecture inventory, user flows, integration contracts, baseline findings, standards and UI/UX direction. Read on demand — not needed to start a routine work session. Current per-packet status lives in the [backlog](PEP_BACKLOG.md); progress and execution history in the [progress log](PEP_PROGRESS.md).

> Note: baseline finding remediation and current verification status are recorded in the [progress log](PEP_PROGRESS.md); a baseline finding is not automatically still unfixed after its associated substep is verified.

---

## 1. Purpose and boundaries

Make Meri Taleem a dependable, connected school-management and learning product: a complete headmaster web workspace, efficient staff workflows, and a colorful, accessible student/mobile experience.

This is the canonical enhancement tracker. It complements, rather than replaces, the [foundation-first development process](architecture/10-development-process-and-roadmap.md). Future development should reference the work IDs below and update this file before ending each implementation session.

The initial discovery revision was **planning and documentation only**. Phase 1 implementation has now started; its changes and verification are recorded in the [progress log](PEP_PROGRESS.md). No production deployment or existing school-database migration has been performed. New test databases are isolated and disposable.

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
verification status are recorded in the [progress log](PEP_PROGRESS.md); a baseline finding is not
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

