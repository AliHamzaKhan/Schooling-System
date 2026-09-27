# Student-facing action access contract

F01.9 closes the current nested-object boundaries for homework, student documents
and transport actions. Module permissions remain necessary; these service checks
also bind every supplied object ID to the current school and relationship.

## Homework

- Assignment create, list, detail, update and delete validate the section and
  subject in the same school. Class-bound subjects must match the section class.
- Students see and open assignments only for sections in which they are actively
  enrolled. Submission writes require the same active local enrollment.
- Submission reads, grading and review require school-owned assignments and
  school-owned submission rows; malformed assignment links are rejected or filtered.

## Student documents

- Document create/list/delete validates that the URL student is a local user with
  the student role. Delete also requires the document's own student ID to match
  the URL student, preventing sibling or foreign-row deletion.

## Transport

- Route stops, transport assignments, trips, events, locations and ETA queries carry
  school predicates on both parent and child rows. Route filters reject foreign routes.
- Assignment creation validates local student, route, stop, approved request and
  driver ownership. Capacity counts are restricted to the current school.
- Student requests are self-scoped; guardian requests require an explicitly linked
  child. Driver trip actions remain limited to the owning trip, while student and
  guardian tracking is restricted to manifest students.

## Evidence and limits

The final isolated backend suite passed **329 tests in 483.36 seconds**. The focused
homework/document/transport/lesson suite passed **25 tests**, including **5 new**
cross-school, privacy and no-write regressions. Ruff and whitespace checks pass. No
schema migration, frontend change, UI preview, deployment or provider send was
performed. Remaining registered-router, background-job and export paths continue
under F01.10.
