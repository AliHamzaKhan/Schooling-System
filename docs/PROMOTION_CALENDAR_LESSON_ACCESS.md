# Promotion, calendar and lesson access contract

F01.8 closes the technical nested-object boundaries for promotion, academic
calendar and lesson-planning actions. These rules are enforced in services after
the module permission dependency, so direct API calls cannot widen access.

## Promotion

- Exam-driven preview and merit lists resolve an exam's class and session inside
  the current school and consume only published results for active local students.
- Promotion batches validate every student, target section, target class session,
  destination session and optional exam before changing an enrollment. A foreign
  or invalid item aborts the whole request before any earlier item is moved.
- Active enrollment lookups and upserts include the school and valid section. A
  promotion cannot adopt a matching section/student row owned by another school.
- Promotion history filters malformed section, session, exam and student links;
  optional student and session filters are validated in the requested school.

## Calendar

- Event create/update and session-filtered reads accept only academic sessions
  owned by the current school. Historical events with foreign session references
  are excluded from lists.
- Partial updates revalidate the effective date range, so an update cannot create
  an end date before its start date.
- Exam schedule is derived only from exams with valid local classes and local or
  null sessions. A foreign session filter is rejected before querying.

## Lesson planning

- Lesson create, update, delete, list and progress validate the section and subject
  as current local records. A class-bound subject must match the section's class;
  an unbound subject remains usable across sections in the same school.
- List and progress queries apply the same structural filters as writes, excluding
  malformed historical lesson links instead of returning them.

## Evidence and limits

The final isolated backend suite passed **327 tests in 509.41 seconds**. The focused
promotion/calendar/lesson/scenario suite passed **13 tests**, and the new
cross-school/no-partial-write suite passed **3 tests**. Ruff and whitespace checks
pass. No schema migration, frontend change, UI preview, deployment or provider send
was performed. Remaining homework, document, transport and student-facing action
paths continue under F01.9.
