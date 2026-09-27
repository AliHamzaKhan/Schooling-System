# Aggregate report and export access — F01.6

Implemented 2026-09-23. Owner/reviewer: Codex (self-review). Automated technical
verification is recorded in PEP_PROGRESS.md; independent acceptance remains open.

Aggregate report routes remain school-wide operations gated by REPORTS view. The
attendance CSV route requires REPORTS export; export is not inferred from view.
Super admins retain their existing bypass, while school users are still bounded
by school status, subscription plan, module toggle and role action. A disabled or
out-of-plan reports module blocks both JSON and CSV for school users.

Attendance report filters reject foreign or unknown sections and reversed date
ranges. JSON and CSV use the same structural attendance source boundary as the
register: school-owned section/class, student, subject, optional timetable slot
and marker references, plus known status values. Unknown stored statuses are
excluded from totals and CSV cells, so malformed history cannot become a
spreadsheet formula or inflate a report.

Overview and enrollment aggregates validate nested class, section, subject,
student and academic-session ownership. Active enrollments count once per class
and once in the school-wide total. Academic summaries include only school-owned
classes, sessions/categories and published results for school students. Finance
reports include only school-owned student invoices with valid local session and
fee-structure references; collected totals come from the school-owned payment
ledger rather than cached invoice amounts. Existing cached invoice fields are
not rewritten.

No response shape, schema, migration, frontend code or existing data was changed.
Malformed rows are filtered from projections, not repaired or deleted. Concurrent
payment writes, fixed-precision conversion, export pagination and broader
exam/quiz lifecycle rules remain separate work. Physical browser/device and
production acceptance were not performed.
