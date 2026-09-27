# Attendance and enrollment access — F01.5

Implemented 2026-09-22. Owner/reviewer: Codex (self-review). Automated technical
verification is recorded in PEP_PROGRESS.md; independent acceptance remains open.

## Read contract

Attendance module view permission is still required. Headmasters and super admins
retain oversight. Teachers may read registers and summaries only for sections
where they are currently the class teacher or have a same-school timetable/subject
relationship. Students and guardians cannot read a whole section's register.
Individual history requires a current teacher/enrollment relationship, the student
themselves, or a current same-school guardian link. Custom staff receive no new
implicit school-wide academic read permission. AcademicAccess accepts an explicit
module for attendance; existing academic/report consumers retain their original
student-management permission requirement.

Unknown, foreign and nonstudent targets return 404. Unrelated readers receive
403. Authorization is checked for each request, including with an existing token.
Attendance responses and denials have `Cache-Control: private, no-store`.

Register rows, summary counts and individual history use the same structural
filter: attendance, student, section/class, subject, optional timetable slot and
marker must have valid tenant relationships. A slot must match the row's section
and subject. Super-admin markers are supported. Withdrawal does not erase valid
historical attendance; a teacher without a current enrollment relationship loses
individual access, while the student, linked guardian and leadership retain it.
Reversed date ranges return 400. A foreign or missing subject filter returns 404.

## Write contract

Existing attendance-create and student-management create/edit permissions remain.
Daily marking remains class-teacher-only for teachers; subject marking permits
the timetabled subject teacher or the section's class teacher covering a colleague.
Leadership and existing permission-authorized nonteacher writers retain their
prior authority. This packet does not define a new custom-staff policy.

Before any attendance mutation or notification intent:

- Validate the section and its parent class against the school.
- Validate subjects for every writer, including leadership.
- If a timetable slot is supplied, require subject attendance and a matching
  school, section and subject. A slot does not substitute for teacher authority.
- Require every entry to identify an active same-school student with an active,
  same-school enrollment and a same-school (or absent) academic-session reference.
- Reject duplicate student entries and mixed batches containing invalid students.
- Lock existing rows matching the database's student/date/subject uniqueness key
  and reject any school or section mismatch with 400 before changing any row.
  A save cannot silently move an existing record to another register.

Enrollment create/reactivation validates the supplied session before mutation;
reactivation also validates the retained session when none is supplied. Foreign
ownership collisions are rejected. Enrollment lists omit foreign-session rows.
Deletion validates tenant relationships, but an inactive student can still be
unenrolled. Enrollment sessions may be omitted or refer to an inactive same-school
session; active-year/rollover policy is separate work.

## Compatibility, recovery and limits

No response shape, frontend code, schema, dependency or existing school data was
changed. Malformed historical rows are filtered or rejected, not repaired or
deleted. Investigate them with authorized maintenance tooling and backups; this
packet does not introduce a correction endpoint. Code rollback restores previous
behavior and therefore previous access gaps; no data rollback is required.

New concurrent inserts, attendance correction provenance, enrollment roll-number
races, request replay, rollover rules and broader aggregates/exam/quiz lifecycles
remain separate work. Existing-row locking is not a claim of complete concurrent
save or notification deduplication safety. Provider delivery and worker rollout
remain separate gates. Physical browser/device acceptance has not been performed.

## Follow-up UI findings (not fixed by this backend packet)

Inspection found that `AttendanceMarkController.submit()` ignores the repository
save result before navigating back and showing “Submitted”; its roster refresh
and `StudentAttendanceController.load()` also retain prior data on failed reads.
Track honest save feedback under M10/U04 and stale-state clearing under U03/U04.
These are confirmed code gaps, not a new runtime/browser acceptance claim. The
server still rejects unauthorized writes; cached client data is not remotely
recalled by this change.
