# Course content access contract

F01.10 defines tenant and enrollment boundaries for courses, books, chapters, notes
and reading progress.

## Course ownership

- Course create and update validate supplied section and subject IDs in the URL
  school before any mutation.
- When a subject is bound to a class, that class must match the selected section.
- School-wide legacy courses, with no section, remain readable by active school
  members as before.

## Student content visibility

- A student can list, open and save reading progress for a section-scoped course
  only while they hold an active enrollment in that section.
- The same rule applies to direct course, book, chapter and note URLs, preventing a
  guessed child ID from bypassing the course list.
- Reading-progress lookup and writes first resolve the selected book or note in the
  URL school and apply the course visibility rule. A foreign or inaccessible resource
  produces no progress row.

## Jobs and exports reviewed

- The fee-reminder job requires `X-Cron-Secret`, selects active schools only, and
  invokes the fee service separately for each selected school.
- Attendance/report exports continue to require report export permission and use the
  F01.6 school and academic-structure filters.

## Evidence and limits

The focused course/router suite passed **6 tests**. The final isolated backend suite
passed **331 tests in 488.01 seconds**, with Ruff and whitespace checks clean. No
schema migration, frontend change, UI preview, deployment or provider send was
performed. F01 remains open for final registered-router inventory reconciliation and
independent review.
