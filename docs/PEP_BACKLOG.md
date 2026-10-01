# Meri Taleem — Enhancement Plan: Backlog & Definition of Done

Part of the [Product Enhancement Plan](PRODUCT_ENHANCEMENT_PLAN.md). This is the canonical per-packet **status** source (Foundation, Experience, Module, Reliability and Optional backlogs), the common definition of done, the required acceptance scenarios, and the open decisions that gate implementation. Verified implementation substeps and the execution log are tracked in the [progress log](PEP_PROGRESS.md); packet scope context is in the [reference](PEP_REFERENCE.md).

---

## 9. Canonical work tracker

### Status and ownership rules

Allowed statuses: `Planned`, `In progress`, `Blocked`, `Review`, `Verified`, `Deferred`.

- The source roadmap has 44 original implementation packets and four deferred discovery packets. The lean launch portfolio replaces its 31 standalone planned packets with six integrated release tracks: 16 original records are folded into a release track and 15 are deferred to post-launch. Current status/ownership is shown below; verified implementation substeps are tracked separately in the [progress log](PEP_PROGRESS.md) and do not automatically close their parent packet.
- `Review` means implemented but missing final evidence; only `Verified` counts as completed enhancement work.
- Before starting a packet, add a dated entry in the execution log with a named owner, exact scope, estimate, affected files/APIs and dependencies. Split large packets into stable child IDs such as `M17.1` without deleting the parent.
- Mark `Blocked` with the missing decision/dependency and the next action. Do not silently omit unfinished acceptance criteria.
- Every packet also inherits the common definition of done in section 10 below.

### Foundation backlog

| ID | Priority | Owner discipline | Dependencies | Scope and packet-specific acceptance | Status |
| --- | --- | --- | --- | --- | --- |
| F08 | P0 | Codex / backend QA | None | Make database tests fail closed before schema destruction; reject inherited/non-test DB URLs and DB-component overrides; use disposable credentials/database. Demonstrate rejection without connecting to a real user database. | Review |
| F01 | P0 | Codex / backend security | F08 | Fix broadcast audience scoping; audit every nested ID/action across all registered routers, files, jobs and exports. Two-school/role fixtures prove forbidden operations produce no writes, deliveries or private data. | Review — F01.1–F01.11 verified technically; independent security/product review required |
| F02 | P1 | Shared frontend / backend | F08 | Complete login/profile-loading/refresh/logout/logout-all/revocation and device lifecycle. Profile failure is recoverable, not a false successful landing; offline logout clears local state; server revocation and access-token guarantees are explicit and tested. | In progress — F02.1–F02.3 verified technically; F02.4 cross-tab and storage recovery is implemented with focused tests. Chrome and real-device acceptance remain |
| F03 | P1 | Frontend / QA | F02 | Repair teacher shared-route conflict; add explicit role/capability guards and route-local bindings. Authorized teacher report/roster links work; teacher admin edits remain forbidden; direct URL/refresh/back/login-return tests pass for both portals. | In progress — F03.1 verified; F03.2 full role-route guards, cold-route bindings and safe login return are implemented with focused tests. Physical browser acceptance remains |
| F04 | P0 | Codex / backend security | F08 | Private/public asset classification; authorized private retrieval or short-lived signed access; upload ownership, bounded reads, content/type limits, quotas, quarantine and deletion policy. Anonymous/wrong-school downloads fail; public logos still work. Plan existing-URL migration. | In progress — F04.1–F04.5 technically verified; public-media approval, scanner staging/operations evidence, cumulative quotas/retention, production inventory and approved migration remain |
| F05 | P0 | Codex / shared frontend | None | Explicit development/staging/production builds; unconditional redaction of passwords/tokens/PII; secret/config checks. Release artifacts cannot default to debug logging or a developer API host. | In progress — F05.1–F05.3 technically verified; approved staging release startup and infrastructure log acceptance remain |
| F06 | P0 | Codex / backend finance QA | F08 | Audit all money fields; migrate to agreed fixed precision/currency semantics with backups and reconciliation; add transaction locks/constraints and idempotency. Concurrent/retried payments cannot overpay or diverge from receipts; historical totals reconcile. | In progress |
| F07 | P1 | Backend / integrations | F01, F05, F08 | Distinguish queued/provider-accepted/delivered/failed/simulated states; real email setup and v1 push deployment; queue retries/deduplication and commit-before-side-effect design. Provider outage cannot show a false success or lose recoverable work. | In progress — F07.1/F07.2 verified technically; rollout open |

### Experience foundation backlog

### Lean launch portfolio

The six tracks below are the complete planned launch scope. Original packet rows remain below as traceability records; their `Deferred` status says whether the work is included in a lean track or intentionally postponed. Their original dependencies describe the source plan; the release-track dependencies above govern the lean sequence. This does not remove existing capabilities.

| ID | Priority | Owner discipline | Dependencies | Integrated launch outcome | Status |
| --- | --- | --- | --- | --- | --- |
| L01 | P1 | Mobile frontend / design | U01, F02, F03 | Complete the student, teacher, guardian and headmaster critical journeys with honest loading/error/stale states, small-screen recovery and role-appropriate layouts. Includes U03 and U04. | In progress — L01.1–L01.9 role live-read, guardian selected-child, family-access, teacher-class, notification and timetable recovery states verified technically |
| L02 | P0 | Backend / web | U02, F01, F04 | Deliver one safe school setup and academic-people foundation: school readiness, sessions/classes/sections/subjects, admissions/enrollment and staff profiles. Includes M04, M06 and M07. | In progress — L02.1–L02.8 academic setup, enrollment, calendar, nested-settings and timetable-safe setup updates verified technically |
| L03 | P0 | Backend / mobile | L02, F01, F07 | Deliver accountable family attendance and communication: guardian linking/revocation, multi-child context, honest attendance saves and recoverable communication. Includes M08, M10 and M18. | In progress — L03.1–L03.8 guardian-link, selected-child, attendance, performance, transport and leave-review recovery verified technically |
| L04 | P1 | Backend / frontend | L02, F04 | Deliver the teaching and assessment lifecycle: timetable, controlled learning content, homework, quizzes, exams and authorized results. Includes M09, M11 and M13–M15. | In progress — L04.1–L04.9 read-state, homework/quiz retry, results, timetable and exam-window integrity verified technically |
| L05 | P0 | Finance / backend / web | F06, L02 | Deliver fee operations and reconcilable school reporting: recurring fees, adjustments, aging, metric definitions, drill-down and safe exports. Includes M17 and M25; payment-gateway integration remains deferred. | In progress — L05.1–L05.6 invoice pagination, fee-scope, retry-safe issuance, list-filter and reporting eligibility integrity verified technically |
| L06 | P0 | QA / product / operations | O01–O03, L01–L05 | Certify the release through accessibility/security/privacy checks, supported device/browser evidence, a pilot, training, rollback decision and named sign-off. Includes O04. | Planned |

| ID | Priority | Owner discipline | Dependencies | Scope and packet-specific acceptance | Status |
| --- | --- | --- | --- | --- | --- |
| U01 | P1 | Design / shared frontend | F05 | Design-system catalogue for tokens, forms, cards, tables, dialogs, states and motion. Color/contrast, semantics, 200% text and reduced-motion checks pass on representative components; document exceptions. | Review — U01.1–U01.3 verified technically |
| U02 | P1 | Web frontend | F03, U01 | Headmaster desktop shell with grouped capability-aware navigation, persistent school/session context, searchable modules, list/detail/form patterns and refresh-safe routes. A headmaster completes setup and core management entirely in admin web. | In progress — U02.1–U02.4.3 verified technically; physical browser acceptance pending user run |
| U03 | P1 | Mobile frontend / design | U01 | Apply student design beyond home to assignments, quizzes, exams/results, content, messages and profile/settings. Every state has legible hierarchy and real data; include the confirmed student-attendance stale-refresh gap from F01.5; draft recovery and keyboard-safe actions work on small screens. | Deferred — folded into L01 |
| U04 | P1 | Mobile frontend / design | U01, F03 | Bring teacher, guardian, headmaster and driver journeys onto role-appropriate shared patterns. Child/class/trip identity stays visible; each role's critical journey passes phone/tablet/web layout checks. | Deferred — folded into L01 |
| U05 | P2 | Shared frontend / QA | U01, F02 | Localization/timezone/currency and accessible preferences; offline read-cache and explicit draft/sync patterns where safe. Cache keys include account/school/child/session; logout clears sensitive state; no silent last-write-wins for money/results/trips. | Deferred — post-launch; revisit after L06 pilot |

### Module enhancement and addition backlog

“Add” here means a proposed extension to the existing module, not evidence that the current implementation lacks every underlying primitive.

| ID | Priority | Owner discipline | Dependencies | Enhancement/addition and acceptance | Status |
| --- | --- | --- | --- | --- | --- |
| M01 | P1 | Identity / frontend | F02, F05, U01 | Unified recovery and account settings on both apps; accessible password-manager flow, session management and privileged-user MFA/recovery design. Verified recovery cannot leak account existence or bypass school access; privileged MFA has tested recovery before rollout. | Deferred — post-launch; revisit after L06 pilot |
| M02 | P1 | Backend / web | F01, F03 | Endpoint→module→action→role map; permission-aware UI and generic custom-staff workspace; role templates and permission-change audit. Accountant/office-role fixture works without headmaster grants; removed permission takes effect predictably. | Deferred — post-launch; revisit after L06 pilot |
| M03 | P1 | Platform web / backend | M02, F06, U01 | Platform school-health dashboard, auditable lifecycle actions, consistent transaction provenance and search/filter/pagination. Platform totals reconcile with subscription records; no casual access to student records via support tooling. | Deferred — post-launch; revisit after L06 pilot |
| M04 | P1 | Headmaster web / backend | M02, U02 | Guided school setup: identity/branding, contact/timezone/calendar defaults, readiness checklist and status transitions. Partial setup resumes safely; activation explains missing prerequisites; school boundaries remain explicit. | Deferred — folded into L02 |
| M05 | P1 | Billing / platform web | F06, M03 | Plan/version/entitlement consistency, renewals/cancellation/history, invoices/receipts and clear expiry/grace behavior. Plan changes preserve financial history; expired schools see authorized renewal information without regaining gated operations. | Deferred — post-launch; revisit after L06 pilot |
| M06 | P1 | Academics / web | M04 | Academic sessions/terms, classes, sections, subjects, enrollment constraints and archival rules. Only intended active session drives new work; historical reports remain stable after rollover; duplicates/cross-school references rejected. | Deferred — folded into L02 |
| M07 | P1 | People / web | M02, M06, F04 | Complete admission/enrollment and teacher/staff profiles; validated bulk import preview, duplicate detection, document checklist, archive/transfer history. Import failures identify rows and cannot partially duplicate students; role/session assignments are validated. | Deferred — folded into L02 |
| M08 | P1 | Family / mobile | F01, M07, U04 | Verified guardian linkage, multi-child context, authorized contact changes and revocation. Linking/unlinking is auditable; stale child screens/downloads fail after unlink; family summaries agree with student records. | Deferred — folded into L03 |
| M09 | P1 | Academics / frontend | M06, M07 | Timetable editor with teacher/room/section conflict checks, substitutions and calendar integration. Double-bookings are rejected or explicitly overridden with reason; all role views show the same effective schedule. | Deferred — folded into L04 |
| M10 | P1 | Attendance / QA | M08, M09, F07 | Daily/subject attendance completeness, bulk marking, explicit save state, correction reasons, leave/holiday rules and scoped alerts. Repeated save is safe; late/offline corrections reconcile; guardian/student/report totals match. F01.5 found the teacher submit controller ignores failed save results; fix and test honest failure feedback. | Deferred — folded into L03 |
| M11 | P1 | Learning / frontend | M06, F04, U03 | Curriculum/content organization, controlled publishing, reader search/bookmarks and reliable reading progress. Membership/private-file checks apply to every resource; progress survives reconnect without granting access to unpublished material. | Deferred — folded into L04 |
| M12 | P2 | Teaching / frontend | M09, M11 | Surface lesson-planning backend in teacher/headmaster UI: objectives, scheduled coverage, resources and actual completion. Schedule/lesson changes stay consistent; coverage report uses persisted teaching data rather than inferred dashboard numbers. | Deferred — post-launch; revisit after L06 pilot |
| M13 | P1 | Learning / frontend | M09, M11, F04 | Homework authoring/submission/feedback lifecycle: due/late rules, attachment validation, drafts, revision/rubric support and review. Due-soon excludes overdue/completed work; retries cannot duplicate submissions; teachers see only assigned work. | Deferred — folded into L04 |
| M14 | P1 | Assessment / frontend | M11, F01, U03 | Robust quiz draft/publish/assignment/attempt lifecycle, question-bank reuse, accommodations and reconnect strategy. Server enforces timing/attempt rules; no answer-key leakage before allowed review; duplicate submit yields one result. | Deferred — folded into L04 |
| M15 | P1 | Assessment / web | M09, M14, F07 | Exam scheduling/seating, marks validation/moderation, grading schemes, authorized publication and versioned report cards. Draft results stay private; mark edits are auditable; published reports match the approved marks and grading version. | Deferred — folded into L04 |
| M16 | P1 | Academics / backend | M06, M15 | Promotion preview/approval, retained/re-exam/graduated cases, batch safety and session rollover summary. Rerun is idempotent; mid-batch failure is recoverable; old enrollment/marks/fees are not overwritten. | Deferred — post-launch; revisit after L06 pilot |
| M17 | P1 | Finance / web | F06, M07, F07 | Full fee workflow: recurring billing rules, concessions/scholarships, installments, credit/refund adjustments, aging and reconciliation. Authorized adjustments retain immutable provenance; balances/receipts/reports agree; gateway integration remains separately approved. | Deferred — folded into L05 |
| M18 | P1 | Communication / web | F01, F07, M08 | Communication center: audience preview, templates, scheduling, preferences/quiet hours, delivery details and bounded retries. Correct school/role recipients only; provider acceptance is not called confirmed delivery; failed messages have actionable recovery. | Deferred — folded into L03 |
| M19 | P1 | Messaging / frontend | F01, M08, U04 | Authorized conversation directory, read/unread consistency, pagination, attachments and safeguarding/reporting controls. No arbitrary contact discovery; marking read is scoped; child-related communication follows school policy. | Deferred — post-launch; revisit after L06 pilot |
| M20 | P1 | Calendar / web | M09, F03, F07 | Unified events and meeting organizer: CRUD, audience, reminders, booking/reschedule/cancel and conflict checks. Events fetch correctly from a cold link; meetings cannot silently double-book staff; all roles see authorized updates. | Deferred — post-launch; revisit after L06 pilot |
| M21 | P1 | Operations / frontend | M08, M10 | Leave rules, approval hierarchy, evidence, cancellation and notification trail. Only the assigned approver can act; duplicate/conflicting decisions are safe; attendance reconciliation is explicit and auditable. | Deferred — post-launch; revisit after L06 pilot |
| M22 | P1 | Transport / mobile | F01, F07, M08, U04 | Harden route/driver/student assignment, live-trip reconnect, location freshness, passenger transitions, incident flow and capacity checks. Driver sees assigned trips only; linked families see their child's trip only; stale GPS is never presented as live. | Deferred — post-launch; revisit after L06 pilot |
| M23 | P1 | HR / web | F06, M02, M10 | Staff lifecycle, salary rules, attendance/leave inputs, payroll approval, payslip history and payment reconciliation. Same staff/period cannot be paid twice; private salary data and edits require dedicated permissions. Confirm local payroll rules before calculation automation. | Deferred — post-launch; revisit after L06 pilot |
| M24 | P2 | Operations / web | M02, U02 | Surface inventory UI with stock-in/out, adjustments, suppliers/reorder alerts and asset assignment where needed. Concurrent movements cannot create invalid stock; every adjustment has reason/actor; inventory staff need no broad school-admin access. | Deferred — post-launch; revisit after L06 pilot |
| M25 | P1 | Reporting / backend | F03, M10, M15, F06 | Define shared metric formulas and filters; drill-down, safe exports, snapshot/as-of labels and dashboard consistency. Attendance/academic/finance totals reconcile to sources; spreadsheet export injection and cross-tenant leaks are tested. | Deferred — folded into L05 |
| M26 | P1 | Records / frontend | F04, M07 | Student document hub, typed documents, verification/versioning, access history, expiry and retention controls; reusable attachment picker/viewer. Metadata and blob permissions agree; archival/deletion handles both without deleting required financial/academic history. | Deferred — post-launch; revisit after L06 pilot |
| M27 | P2 | AI / teaching / security | M11, M14, F01, F05 | Governed teacher-assistance workflow: review/edit before publishing, provider availability, budget/rate controls, provenance and minimized logs. Stub mode is explicit; generated questions are validated; AI cannot publish marks, discipline students or expose private records autonomously. | Deferred — post-launch; revisit after L06 pilot |

### Reliability and release backlog

| ID | Priority | Owner discipline | Dependencies | Scope and acceptance | Status |
| --- | --- | --- | --- | --- | --- |
| O01 | P1 | QA / operations | F08, F05 | CI for backend, shared, school and admin apps; lint/analyze/test/build, API-contract and critical-journey tests, dependency/secret scans and migration rehearsal. Failed gates block release; Flutter changes cannot skip validation. | Review — Flutter gates, redacted secret scan, migration rehearsal, OpenAPI contract, critical journeys and backend/Pub dependency audits are configured and locally verified; one hosted GitLab pipeline result remains |
| O02 | P1 | Operations / backend | F07, O01 | Readiness and worker/job visibility, structured redacted logs, alerting, backup/restore, provider configuration and rollback runbooks. Restore and deploy rollback are rehearsed; failed workers/jobs are visible; external notification tests use approved test recipients only. | In progress — O02.1–O02.3 verified technically; hosted alert integration, restore/rollback rehearsal and approved synthetic-provider evidence remain |
| O03 | P1 | Performance / backend | O01, M25 | Profile realistic school fixtures; bounded server pagination, indexes/query budgets, cache policy, bulk job quotas and native/web traces. Publish before/after measurements against agreed budgets and test tenant fairness. | In progress — O03.1–O03.10 direct-message, broadcast, attendance, homework, transport, exam, leave and delivery-history pagination verified technically. A disposable 105-row, two-tenant invoice fixture proves stable page boundaries, and the school/due-date/id invoice page index is migration-tested; measured query/API budgets, cache policy, bulk-job quotas and device/web traces remain |
| O04 | P1 | QA / product / operations | O01–O03, release-scoped M/U packets | Accessibility/security checklist, supported-device/browser matrix, privacy/store declarations, pilot, training and rollback decision. All release acceptance evidence attached; no P0 issues; named product/engineering sign-off. | Deferred — folded into L06 |

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
