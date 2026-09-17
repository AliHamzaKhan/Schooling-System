# Broadcast request replay and read-only review

Implemented scope: F07.3, 2026-09-15. Technical verification is recorded in
[Phase 1 verification](PHASE_1_VERIFICATION.md). Not production acceptance.

## Save identity

`POST /schools/{school_id}/communication/broadcasts` accepts an optional UUID
`Idempotency-Key`. The key is the persisted message ID. A PostgreSQL transaction
advisory lock serializes the key before lookup/write; message and outbox still
commit together. Matching actor, school, channel, audience type/reference, title,
body and scheduled instant return the same message with its **current** status
(HTTP 201). Replays do not plan recipients or create another outbox job.

A reused key with different details, actor or school returns a generic 409.
Normal authentication, school membership, subscription and messaging-create gates
still apply on every replay. Scheduled timestamps require an explicit timezone;
equivalent timezone offsets represent the same instant. Null and absent optional
fields compare as equivalent after schema validation. Different content is not
silently normalized into the old request.

Legacy keyless callers remain supported but repeated requests create new messages.
Keys are not content-based deduplication and do not prove delivery. They remain
effective while the message exists; a future deletion/retention policy must account
for replay identities. This change adds no migration beyond the required
[F07.2 outbox migration](NOTIFICATION_OUTBOX_ROLLOUT.md), which has **not** been
applied to existing school data.

## Composer recovery

Teacher and headmaster API services retain one immutable in-memory attempt per
actor/school, including across reopening their composers while the service remains
alive. Concurrent identical submissions share one future. Unknown/network/server,
auth and conflict outcomes retain the UUID and original payload. Editing an
unresolved attempt is rejected locally; reopening restores the original draft.
Success or definitive 400/422 validation rejection releases the next composition.
Teacher restoration preserves the original section even when timetable loading
finishes afterward or the section is no longer listed.

The key is an ordinary API header and is preserved by the shared transport's
existing authenticated replay path. This is **not durable restart, browser-refresh,
cross-tab, cross-device or offline recovery**. Do not blindly compose the same
message again after losing local state: inspect the saved feed and delivery review.
An unresolved conflict cannot be abandoned through this UI; investigate the
existing message instead of silently generating a new key.

## Review access and fields

`GET /schools/{school_id}/communication/broadcasts/{message_id}/review`
requires messaging-view plus original sender or school headmaster/super-admin.
Existing `/deliveries` and `/summary` endpoints now use the same owner/admin
restriction. School scoping remains enforced. Review is GET-only: no resetting
attempt markers, changing outcomes, sending, acknowledging delivery or reconciling
without evidence.

Review returns message status, outbox state, worker-claim count, next eligible time,
expired-lease indicator, outcome counts and one page of delivery records. `limit`
defaults to 25 (1–100), `offset` defaults to zero (nonnegative); records have stable
ID ordering. Counts cover all matching delivery rows, not unique recipients.
The live worker may change records between page loads; Refresh returns to page one.

Recipient names are retained for authorized operational review. Push tokens, raw
email/phone addresses, arbitrary historical error/provider text, lease tokens and
recipient hashes are excluded from the new review response. Phone labels show only
the last two characters; email/device labels are generic. Deleted/missing users
have a neutral label. The compatibility `/deliveries` response additionally removes
push address values but still includes its other legacy fields for authorized staff;
it is not the privacy-minimized UI contract.

Headmaster **Announcements → Review delivery** opens the responsive panel in both
school and admin headmaster workspaces. It supports loading/error/retry, refresh,
previous/next pages and explicit uncertainty guidance. Teacher senders are authorized
by the API; a dedicated teacher review navigation entry remains future work.

## Remaining gates

- Unknown provider outcomes still require external evidence. There is no manual
  override/resend API, provider receipt ingestion or automatic reconciliation.
- Real email/provider setup, native devices, actual browser/network acceptance and
  coordinated API/schema/worker deployment remain unverified here.
- F01.2 now separately restricts the broader broadcast feed/detail to current
  audiences plus sender/admin oversight. See [audience access](BROADCAST_AUDIENCE_ACCESS.md)
  for scheduling, historical-membership and cache limitations; this is not a
  completed audit of every communication module.
- Parent F07 and Phase 1 remain in progress.
