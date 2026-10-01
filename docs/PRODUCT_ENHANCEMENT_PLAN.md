# Meri Taleem — Product Flow, Enhancement Plan & Progress Tracker

Last updated: **2026-10-01** (Asia/Karachi)
Baseline: commit `f4aac5f` (invoice page index) plus O03.11 query budgets
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

**Current state (2026-10-01).** O03 local evidence is complete and in Review
(statement budgets, cache policy, bulk quotas). U02, F02 and F03 passed scripted
Chrome acceptance ([harness](../frontend/e2e/chrome/README.md)); six defects found
there were fixed, including a P0 web sign-in failure.

**Next work:**
1. L01–L05 remaining journey slices (student, guardian multi-child, finance under
   failure, academic rollover) using the Chrome harness for each journey.
2. Physical-device runs (Android/iOS) and other browsers for L06 evidence.
3. Decision-, access- and sign-off-gated items are consolidated in
   [RELEASE_BLOCKERS.md](RELEASE_BLOCKERS.md): F06 money policy, F04 media and
   retention policy, hosted CI/alerting (O01/O02), provider credentials (F07),
   pilot and named sign-off (L06).

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
