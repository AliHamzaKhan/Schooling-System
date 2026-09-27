# Meri Taleem — Product Flow, Enhancement Plan & Progress Tracker

Last updated: **2026-09-23** (Asia/Karachi)
Baseline: commit `590b60d` (U02.4.3) plus the current uncommitted F01.11/F04.3–F04.5/F05.3 working tree
Document owner: Product owner / engineering lead — individual to be assigned
Stage: **Phase 1 implementation in progress**

This is the **navigator** for the canonical enhancement tracker. It is intentionally small so a work session can start cheaply. Detailed content lives in the sibling files below; read only the one you need. It complements, rather than replaces, the [foundation-first development process](architecture/10-development-process-and-roadmap.md). Future development references the work IDs in the [backlog](PEP_BACKLOG.md) and updates the [progress log](PEP_PROGRESS.md) before ending each implementation session.

## Document map

| File | Contents | When to read | Changes each session? |
| --- | --- | --- | --- |
| **PRODUCT_ENHANCEMENT_PLAN.md** (this file) | Next-work pointers, evidence legend, update procedure, file map | Every session start | Next-work + date only |
| [PEP_BACKLOG.md](PEP_BACKLOG.md) | Canonical work tracker: per-packet **status** (Foundation / Experience / Module / Reliability / Optional), status rules, definition of done, acceptance scenarios, open decisions | When picking or updating a packet | Occasionally (status edits) |
| [PEP_PROGRESS.md](PEP_PROGRESS.md) | Progress dashboard, Phase 1 / experience substep tables, dated execution log, source index | When recording verified work or checking history | Yes — append every session |
| [PEP_REFERENCE.md](PEP_REFERENCE.md) | Purpose/boundaries, architecture inventory, user flows, integration contracts, baseline findings, standards, UI/UX direction, phased delivery | For deep product context on an area | Rarely |

Scope covers the 31 baseline backend router groups plus two file-access infrastructure routers, both Flutter applications, and their shared package. No production deployment or existing school-database migration has been performed; new test databases are isolated and disposable.

### Evidence and confidence

- **Code present:** registered API, service, route, or view was inspected. This does not mean the feature works end to end or is production-ready.
- **Surfaced:** a relevant frontend route/view exists; completeness, permissions, browser refresh, and real-provider behavior may remain unverified.
- **Confirmed code gap:** the described behavior is visible in the inspected implementation. Runtime impact is stated separately when not reproduced.
- **Audit required:** a risk or missing verification, not a claim of a proven vulnerability.
- **Proposed:** new work, not an existing product capability or approved release commitment.

`Review` means implemented but missing final evidence; only `Verified` counts as completed enhancement work. `Verified` in the substep tables denotes the stated automated technical scope only; parent completion still requires the full definition of done.

## Next work

**Current implementation: O03.1 — representative-fixture and pagination performance baseline.**
The next local work is to define a backward-safe bounded-list contract, add
tenant-fair representative fixtures and publish an isolated before/after baseline.
The active release foundations also still need independent F01 review, O01 hosted
pipeline evidence, and O02 alert-routing, restore/rollback and approved
synthetic-provider evidence.

**Next experience step: physical browser acceptance of U02 (user-run).**
U02.4.3 landed the automated class/section, timetable and settings mutation
harnesses and the [physical browser checklist](U02_HEADMASTER_BROWSER_CHECKLIST.md).
The remaining U02 step is the user running that checklist in a real browser; do
not open a preview. The next launch experience track is **L01 — role journeys**;
it incorporates the U03 student work and U04 role-journey work. It begins only
when its active foundation dependencies are ready.

## Update procedure for every future development session

1. Read this navigator and inspect current working-tree changes; do not overwrite unrelated work. Open [PEP_BACKLOG.md](PEP_BACKLOG.md) for statuses and [PEP_PROGRESS.md](PEP_PROGRESS.md) for history only when you need them.
2. Select the next unblocked packet in phase/dependency order. Record `In progress`, named owner, scope and estimate in the [execution log](PEP_PROGRESS.md).
3. Before implementation, document the packet's concrete sequence: data/API → permission rules → UI → integration → tests.
4. Keep acceptance checks and child IDs current as work proceeds; record new findings against their affected module and severity.
5. Move to `Review` when implementation is done, then `Verified` only with evidence and acceptance. Record blockers and remaining work explicitly.
6. Update the date and **Next work** in this file, and the progress dashboard, substep table and execution log in [PEP_PROGRESS.md](PEP_PROGRESS.md). Append history; do not erase earlier status changes. Update the packet's `Status` in [PEP_BACKLOG.md](PEP_BACKLOG.md) when it changes.
7. Attach commit/PR references when available. Do not invent a commit reference for uncommitted work.

Reusable log entry:

```text
Date / packet ID:
Named owner / reviewer:
Status before → after:
Scope and implementation sequence:
Dependencies / estimate:
Files, API contracts and migrations changed:
Tests and exact results:
UI/accessibility/performance evidence:
Remaining acceptance criteria / blockers:
Rollback or recovery notes:
Next action:
Commit / PR (when available):
```
