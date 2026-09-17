# Session and teacher-route rollout — F02.1 / F03.1

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
5. Test actual browser tabs and native secure storage. Refresh coalescing is within
   one API client instance; cross-tab coordination and response-loss reconciliation
   are not implemented. Strict refresh replay detection can require a new login.
6. Device-token cleanup, session-list/logout-all UI, account-specific controller
   cache disposal, storage failure recovery, MFA and full recovery-flow review
   remain open. The unused legacy register/deactivate client contracts are not
   evidence of implemented backend features.

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
