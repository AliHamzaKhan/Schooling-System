# Session and route rollout — F02.1–F02.4 / F03.1–F03.2

Updated: 2026-09-15. Technical scope only; F02/F03 and Phase 1 remain open.

## Authentication contract

- New access tokens and private-file tickets contain a session ID (`sid`). Every
  authenticated request and ticket redemption checks the existing refresh-session
  row for the matching user, expiry and committed revocation. No schema migration.
- Logout revokes that session. Logout-all, password change/reset and account
  deactivation revoke all of the user's sessions. Re-enabling the account does not
  restore old sessions. Requests already authorized/in flight are not cancelled.
- Refresh and logout serialize on the session row. Reusing an old refresh token
  revokes the entire session, including access minted by a concurrent winning
  refresh. Refresh accepts only refresh-purpose tokens, never access/file tickets.
- Login and password changes serialize on the user row. OTP verification and reset
  token consumption serialize on the reset challenge, preventing concurrent reuse.
- The client clears local credentials before attempting online logout, with a
  bounded two-second request. Offline logout does **not** guarantee server
  revocation. It does not restore credentials or silently claim remote success.
- Login requires a valid profile before reporting success. Profile/refresh outages
  are retryable. Epoch checks and serialized token writes prevent late login,
  refresh or profile responses from restoring a logged-out session. Requests from
  an earlier login are not replayed under a newer account.

## Compatibility and deployment gates

1. Existing access tokens without `sid` are rejected. A valid stored refresh token
   can rotate into a new session-bound access token; otherwise users must sign in.
2. Old private-file tickets without `sid` are rejected; clients request a new ticket.
   Tickets still expire after 60 seconds and remain subject to record authorization.
3. Coordinate backend/client rollout and rehearse legacy-refresh and forced-login
   paths in staging. Do not roll back to stateless checks as a security workaround.
4. Measure the per-request indexed session lookup under representative load. Do not
   add a revocation cache without defining its stale-authorization window.
5. Browser tabs serialize refresh-token rotation with the Web Locks API. A tab
   that receives a stale 401 rereads credentials after waiting and treats an
   already-rotated access token as recovered. Login/logout writes a revision
   marker; another tab clears the previous account's route and controller state
   before it can make a further authenticated request. A browser without Web
   Locks treats the operation as recoverable rather than attempting concurrent
   refreshes.
6. A secure-store failure never authorizes a request. A session write uses a
   persisted invalidation marker until both tokens are saved; logout blocks local
   use first, attempts each delete independently and reports server cleanup as
   unconfirmed while offline. A native secure-storage walkthrough, device-token
   cleanup, MFA and full recovery-flow review remain open.

## Teacher read-only routes

- `/teacher/classes/students?section_id=…&title=…` resolves its section from the URL.
- `/teacher/students/report?student_id=…` has a route-local report binding and
  resolves its student from the URL. Missing ID fails locally without a request.
- Both require the teacher role. Class and performance links now use these routes;
  headmaster-only guards are unchanged. Teacher reports hide management actions
  and their controller refuses meeting/message/complaint actions in read-only mode.
- Backend school/object/permission checks remain authoritative. Sharing a view
  does not grant endpoint permissions.

Widget tests cover direct URLs, role denial, roster-to-report navigation/back and
read-only actions. A real browser reload, login-return preservation, all other
deep links and nested controller lifecycles remain unverified. The roster still
uses the existing quiz-section student endpoint; decoupling that module dependency
belongs to the remaining F01/F03 work.

See [verification results](PHASE_1_VERIFICATION.md) and the
[progress tracker](PRODUCT_ENHANCEMENT_PLAN.md). No existing database rows or files
were migrated, and no production deployment or manual device walkthrough was done.

## F02.3 session controls (2026-09-26)

Admin settings, the school account menu and the driver toolbar open the shared
Active sessions screen. Current-session and global revocation return to login
only after server confirmation; other-session revocation reloads the live list.
The screen exposes lifecycle times only, clears stale rows on failed refresh and
supports retry without claiming a failed request succeeded. Global logout keeps
local credentials on failure. Five widget checks cover failures, confirmation,
duplicate actions and small-screen large text; real browser/device acceptance
remains open. Local times are explicitly labelled; device names are not inferred.

## F02.4 / F03.2 reliability follow-up (2026-09-26)

Every school role route now carries a role guard and registers its module
repository before feature bindings run, so an authorized direct URL does not
depend on visiting its shell first. Cold pages that previously required a
transient object show a safe return-to-list state instead of crashing. A guarded
target is preserved through session restoration and login only when it is a
known in-app route; external, auth and unknown paths are rejected. Guardian
child state clears and fences in-flight loads on account changes. Focused tests
cover storage failures, authorization guards, cold bindings and login-return
validation. Chrome cross-context and physical device walkthroughs remain release
evidence, not simulated success.
