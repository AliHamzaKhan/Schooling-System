# Exam and quiz access contract

F01.7 closes the technical access boundary for the current examination and quiz
lifecycle. The API remains school-scoped even when a caller supplies an otherwise
valid UUID from another school or a malformed historical row exists.

## Examination

- Exams validate their class, category and academic session links in the same school.
- Papers validate the parent exam and subject ownership before create, read, mark entry,
  gradebook, result publication or deletion.
- Marks, results, seats and paper lists include the school owner in their predicates.
  Class rosters contain active users with the student role and valid section/session links.
- Published result lists contain only published rows for valid local students. Student
  result history validates the target student and nested exam structure before returning it.
- Report cards require current enrollment in the exam class. Unpublished cards are hidden
  from students and guardians; result-approval staff may inspect them for moderation.
- Seating generation and admit cards use the same current roster and school-scoped seat
  and paper queries. A foreign or unenrolled student cannot receive an admit card.

## Quizzes

- Quiz creation validates the section and subject as current records in the same school.
  Student assignments must be active local enrollments; corrupt assignment rows are ignored.
- Students see only published quizzes assigned to them or published section-wide quizzes
  for their active enrollment. Draft and closed quizzes are unavailable to students.
- A student can submit only for an active local enrollment/assignment. Every submitted
  answer question ID must belong to that quiz; unknown question IDs are rejected.
- Attempt reads are limited to the owning student unless the caller has homework edit
  authority. Attempt lists, performance and reports are staff-only. Answer keys remain
  hidden from student detail responses.

## Evidence and limits

The isolated backend suite passed **324 tests in 469.05 seconds**. The focused exam,
quiz and scenario suite passed **19 tests**, including the three new cross-school/privacy
cases. Ruff and whitespace checks pass. No schema migration, frontend
change, UI preview, deployment or provider send was performed. Promotion, remaining
registered-router action paths, export pagination, finance precision/concurrency and
independent product acceptance remain open under F01.8 and later packets.
