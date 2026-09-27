# F01 registered-router audit

F01.11 reconciles the registered FastAPI routers in `backend/app/main.py` with
the tenant and nested-object access checks delivered in F01.1–F01.10. This is a
code-level reconciliation and its automated regressions; independent security and
product review remain required before F01 can be marked verified.

## Common boundary

Every feature router below `/schools/{school_id}` receives
`enforce_school_context`: a non-platform caller must be active, belong to that
school, and have a serviceable subscription. Route-specific permissions and
service ownership predicates add the narrower action and object checks.

| Router | Boundary reviewed | F01 evidence |
| --- | --- | --- |
| `auth` | Self-scoped session, credential and profile operations | F02.1 session/access-ticket checks |
| `permissions` | Current-user matrix; public module catalogue only | Router review |
| `admin` | Platform-only dashboard and metrics | Super-admin dependency |
| `schools` | Platform lifecycle routes; headmaster profile is self-school scoped | Router review; platform exception |
| `subscriptions` | Platform plan/subscription mutations; member status read is path-school scoped | Router review; platform exception |
| `jobs` | Dedicated cron secret, active-school selection, per-school fee service call | F01.10 |
| `downloads` | Session-bound, resource-bound ticket is re-authorized at download | F04.2 / F02.1 |
| `users` | Local user and role lookup plus school permissions | Router/service review |
| `roles` | Local role lookup and bounded grants | Router/service review |
| `academic` | Class, section, subject, timetable and student links | F01.4 / F01.5 |
| `attendance` | Section/enrollment/record ownership and malformed-row filters | F01.5 |
| `examination` | Exam, paper, marks, results, seating and reports | F01.7 |
| `fees` | Local invoices/payments and receipt scope | F01.6 |
| `homework` | Assignment, submission, enrolled-student reads and grading | F01.9 |
| `courses` | Academic links, direct content reads and progress resources | F01.10 |
| `schoolinfo` | School-keyed profile only | Router/service review |
| `communication` | Audience references, visibility and delivery review | F01.1 / F01.2 |
| `reports` | Permission-gated, school/structure-filtered aggregates and export | F01.6 |
| `transport` | Route/stop/assignment/trip/manifest relationships | F01.9 |
| `hr` | Local staff profile, payslip and teacher-attendance records | F01.10 review |
| `inventory` | Local item and stock-transaction parent lookup | F01.10 review |
| `ai` | School-owned interaction log; generation has no supplied record ID | F01.11 review |
| `leave` | Guardian child, review and local leave ownership | F01.11 regression |
| `meetings` | Local meeting and participant validation | F01.10 review |
| `messages` | Eligible contacts, current shared-student context and participant-only history | F01.3 |
| `guardians` | Local guardian/student role links and placement metadata | F01.11 regression |
| `quiz` | Quiz/question/assignment/attempt and report ownership | F01.7 |
| `promotion` | Exam/session/student/section preflight and no-partial-write batch | F01.8 |
| `calendar` | Event session/date and exam-feed filtering | F01.8 |
| `documents` | Local student/document ownership and private download records | F04.1 / F04.2 / F01.9 |
| `lessons` | Local section/subject relationship and progress scope | F01.8 |
| `uploads` | School/user-namespaced private keys and constrained public-image folders | F04.1 / F04.2 |

## F01.11 fixes and regression evidence

- Guardian child-placement enrichment now requires the enrollment, section and
  class to each belong to the requested school. A malformed foreign enrollment
  cannot disclose foreign class or section metadata.
- Guardian leave requests now require an association row, linked user and student
  role that all belong to the requested school. A corrupted link cannot create a
  local leave record for a foreign user.
- `tests/test_final_f01_audit.py` exercises both cases with manually malformed
  database rows, verifies hidden placement metadata, and verifies the rejected
  leave write leaves the local leave count unchanged.
- Focused guardian/leave/final-audit verification passed **11 tests**. The final
  isolated backend suite passed **333 tests in 523.57 seconds**; its JUnit report
  is `/private/tmp/schooling-f0111-final-backend.xml`. The runner removed its
  generated database and restricted role.

## Platform exceptions and limits

The `admin`, plan/subscription, and school lifecycle routes deliberately allow the
platform Super Admin to operate across schools; tenant users cannot reach them.
Academic-session update/activation also remains platform-admin-only. This audit
does not treat those platform controls as tenant bypasses.

F01 is ready for independent review, not production certification. It does not
close file migration/scanning, finance precision, provider rollout, browser/device
acceptance, or the other foundation packets.
