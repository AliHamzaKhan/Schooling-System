# Release blockers that need a person, not code

Last updated: **2026-10-01**. Companion to the [backlog](PEP_BACKLOG.md) and the
[progress log](PEP_PROGRESS.md).

Everything on this page has finished its engineering work, or cannot safely
continue, until a named person makes a decision, grants access, or performs an
action outside the repository. Each item states the exact ask and what follows
once it is answered.

## Decisions (product owner / school leadership)

| Packet | Decision needed | Why code cannot decide it | What happens next |
| --- | --- | --- | --- |
| F06 / L05 | ~~Money policy~~ **Decided 2026-10-01:** amounts are plain numbers with no currency symbol or code (stored as ISO `XXX`). Still open: who may approve refunds, credits, waivers and payroll corrections, and the rounding rule if decimals are introduced | Adjustment approval is a school-governance choice | Posting adjustments to balances after the approver rule is agreed |
| F04 | Public media: may school logos, avatars and uniform images stay publicly reachable? **Decided 2026-10-01:** storage limits and file clean-up follow each school's subscription plan | Privacy and retention are legal/school-policy choices | Apply the approved classification, add quota/retention jobs with the agreed limits, run the private-asset inventory in production read-only mode |
| O03 | Target school size and concurrency for latency budgets (e.g. students per school, peak concurrent users) | Statement budgets are enforced; time budgets need an agreed load profile | Run the representative fixture at the agreed size on staging and record p95 targets |
| L06 | Supported devices/browsers list, pilot school, training owner, rollback decision owner | Release audience is a business decision | Execute the device matrix and pilot checklist |
| Locale | Urdu/RTL scope and timezone/currency defaults (U05, deferred) | Language scope is a product decision | Deferred until after the pilot |

## Access or credentials (operations)

| Packet | Needed | Notes |
| --- | --- | --- |
| O01 | One hosted GitLab pipeline run on `main` | All gates run locally. A new `frontend:shared:browser-test` job installs Chromium in CI; confirm the runner image allows `apt-get` |
| O02 | Alert routing destination, a staging environment for restore and rollback rehearsal | Runbooks are in [OPERATIONS_RUNBOOK.md](OPERATIONS_RUNBOOK.md) |
| F07 | Email/FCM provider credentials for an **approved synthetic recipient** | No provider was contacted; delivery states are verified with simulated providers |
| F05 | An approved staging release start and access to its infrastructure logs | Production configuration guards are verified locally |
| F04 | ClamAV scanner in staging | The pre-storage scan gate and readiness are verified locally |

## Reviews and sign-off (named people)

| Packet | Review needed |
| --- | --- |
| F01 | Independent security/product review of the tenant-isolation audit ([F01 router audit](F01_ROUTER_AUDIT.md)) |
| F02, F03, U02 | Named reviewer sign-off. Chrome acceptance is automated and recorded; physical phones/tablets and Safari/Firefox are not yet covered |
| U01 | Design review of the design-system catalogue |
| L06 | Accessibility/security/privacy checklist owner and final release sign-off |

## Known engineering limitations (not blocking a pilot)

- **Browser Forward on the web portals** does not restore the next screen. The
  apps use Navigator 1; Flutter's single-entry browser history keeps Back working
  but drops the forward entry. Fixing it means migrating to the Router API.
- **Flutter web keyboard focus** is verified with widget tests and visually; DOM
  focus reporting in automated browsers does not track Flutter's focus tree.
