# Academic and student-report access — F01.4

Updated: 2026-09-16. Implementation verification is recorded in
[Phase 1 verification](PHASE_1_VERIFICATION.md). This is a bounded access-control
packet, not completion of the whole academic, examination or reporting audit.

## Covered reads

All paths below are under `/schools/{school_id}`:

- `academic/students`: school student directory, with teacher-scoped rows.
- `academic/students/{student_id}/performance` and `/timetable`.
- `reports/students/{student_id}`: cross-module student summary.
- `academic/sections/{section_id}/performance`: peer rankings and draft marks.
- `sections/{section_id}/students`: attendance enrollment roster.
- `quizzes/sections/{section_id}/students`: quiz picker and teacher report drill-down.

School context, active authenticated sessions and existing endpoint module gates
remain enforced. These object checks are additional, not a replacement for RBAC.

| Caller | Individual student | Section roster / ranking |
| --- | --- | --- |
| Platform super admin | Valid student in the requested school | Valid section in that school |
| School headmaster | School-wide, including unenrolled/inactive student records | School-wide |
| Teacher with student-management view | Student actively enrolled in a currently taught section | Currently taught sections only |
| Student | Own record only; no draft marks | Denied |
| Guardian | Currently linked child only; no draft marks | Denied |
| Other/custom staff | No implicit school-wide academic authority | Denied pending explicit custom-staff policy (M02) |

Teaching means class-teacher assignment or a same-school timetable/subject link
to a section whose class belongs to that school. Section enrollment must be
active, in the same school, and point to a same-school user with the student role.
Inactive student accounts do not lose their historical academic records; inactive
callers cannot authenticate. Role/guardian/enrollment/teaching changes take effect
on subsequent API requests with the same token; previously downloaded information
cannot be recalled. Multiple roles are additive: a guardian who is also an entitled
teacher can preview staff information for students they teach.

Unknown, foreign-school and nonstudent targets return 404; unrelated valid students
return 403, invalid UUIDs 422. Section existence and its parent class are validated
before returning rankings. School-wide directory reads retain unenrolled students
for leadership but never use a malformed foreign enrollment to decorate them with
another school's class/section names.

## Data visibility and integrity

- Student/guardian performance includes papers only when a same-school published
  `ExamResult` exists for that student and exam. Unpublishing removes those papers
  from subsequent performance responses. Authorized teaching staff retain draft
  preview; the 360-degree report continues to use published result aggregates only.
- Mark queries check mark, paper, exam, exam class and subject tenant ownership.
  Attendance summaries check school/section ownership; subject attendance in the
  student summary also checks subject ownership.
- Student timetable joins use valid current enrollments/sections and same-school
  subjects. A foreign, inactive or nonteacher user is not resolved as the teacher's
  name. New teacher assignments require an active teacher in the school.
- Student summary exam/quiz titles, guardian names and assignment counts reject
  inconsistent related tenant references. Guardian contacts require an active
  same-school guardian role. Assignment totals and submitted counts now use the
  same current-section scope; old-section submissions are not mixed into that total.
- Covered academic/report/roster responses, including denials, carry
  `Cache-Control: private, no-store`. Shared teacher/headmaster report UI clears
  old data when loading and rejects superseded responses; a denied refresh cannot
  leave the previous report available to guardian actions.

No schema migration, existing-school data repair, provider send or deployment is
part of this packet. Invalid legacy relationships are filtered/denied, not deleted.

## Explicit remaining work

- Other consumers of the generic `verify_student_access` dependency remain to be
  audited; this packet deliberately does not silently change every module's policy.
- Next packet F01.5 covers attendance register/summary/student reads, enrollment
  session references and attendance upsert tenant boundaries. School/section and
  daily-versus-subject authority must agree before any write or notification.
- School-level aggregate reports, general timetable/list endpoints and teacher
  dashboard joins are not certified by this packet. Attendance write authority,
  enrollment/session mutations, exam gradebooks and quiz attempt/answer lifecycles
  need their own module audit.
- Published paper details still read live marks, not an immutable publication
  snapshot. Grade amendments after publication need explicit versioning/republication
  policy in the examination work; the new gate does not create a snapshot.
- Attendance metrics retain their existing definitions (daily performance versus
  cross-module attendance summary); harmonized reporting/analytics is separate.
- Custom staff access policy, scale/pagination, native/browser acceptance, stale
  screen eviction after remote revocation, avatar privacy and production rollout
  remain open. No claim of whole-product production readiness is made.
