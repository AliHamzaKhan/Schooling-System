# Direct-conversation access — F01.3

Implemented 2026-09-15. Technical scope only, not production acceptance.
[Progress](PRODUCT_ENHANCEMENT_PLAN.md) · [Verification](PHASE_1_VERIFICATION.md)

## Sending and contacts

Direct messages remain self-service routes under the existing authentication,
school membership and tenant/subscription lifecycle gates. This change does not
add messaging-create permission requirements that would disable student/guardian
self-service. It enforces the same relationship policy in the API as in the picker:

| Acting role | Can initiate with |
| --- | --- |
| Headmaster / super-admin | Active members of the selected school, excluding self |
| Teacher | Currently taught students, their linked guardians, and school headmasters |
| Guardian | Current children's teachers and school headmasters |
| Student | Their current teachers |
| Other staff | School headmasters |

Multiple roles combine their permitted contacts. Class teachers and timetable
teachers are supported. Enrollment, section, parent class, timetable, subject and
guardian-link school IDs are checked; active student/teacher/guardian roles are
required where applicable. Removed roles, withdrawal, unlinking and deactivation
are checked on subsequent sends. A historical conversation does not preserve a
revoked teaching/family relationship for new messages.

Students may reply to a school headmaster who has already directly contacted them,
without adding administrators to their discovery picker. School users may similarly
reply to a platform super-admin who has contacted them in that school. The recipient
must still be an active, valid administrator, and there must be a valid incoming
message from that administrator to the acting user. This is not a general bypass
for arbitrary peers or former teachers.

Same-school membership alone is no longer sufficient to send. Missing/foreign or
inactive recipients return 404; ineligible school contacts return 403. No message
row is inserted on a rejected request. Empty/whitespace-only bodies return 422.
Message and complaint kinds use the same authorization rules.

## Student context

An optional `student_id` must identify an active student in the selected school.
Both sender and recipient must be entitled to discuss that specific student:

- The student themselves.
- A currently linked guardian.
- A teacher currently teaching the student's active section.
- The school's headmaster or platform super-admin.

An administrator's broad access does not permit attaching an unrelated child to
a message sent to any guardian. A teacher and guardian sharing one child does not
authorize a different child. General messages without student context remain
available to eligible contacts; the service does not infer student identity from
free text or inspect the meaning of the message body.

## History, threads and read receipts

Inbox, sent and all-message lists remain strictly participant-scoped. Administrators
do **not** gain access to private conversations in which they are not participants.
`GET /schools/{school_id}/messages?box=all&counterpart_id={uuid}` additionally filters
the pair on the server; caller identity cannot be replaced by the query parameter.
Unknown/foreign/nonparticipant counterpart filters return an empty list. Invalid
UUIDs or box values are rejected by request validation.

Direct history is a participant mailbox, **not** the current-membership broadcast
feed from F01.2. Historical messages remain available to their original participants
after a teaching/family relationship ends or the other account is deactivated.
The caller must still pass authentication and tenant gates. No remote purge or
recall of previously read/downloaded content is claimed.

Historical rows with foreign-school participants, non-student/foreign student
references or otherwise invalid tenant relationships are hidden, not silently
rewritten. A platform account is a valid cross-school participant only when it has
the system super-admin role and no school. Deactivated students with an intact
student role retain valid historical references. Deleted student references already
set to NULL by the schema cannot be distinguished from originally general messages;
no historical data repair or retention policy is introduced here.

Only the recipient can mark a valid message read. Sender attempts return 403;
nonparticipants, hidden records and missing IDs return 404. Read marking locks the
message row so overlapping retries preserve the first timestamp. Name lookups are
also tenant-scoped. Direct-message responses, including denials, carry
`Cache-Control: private, no-store` through the existing security middleware.

## Shared UI behavior

- Conversations request their counterpart on the server and defensively discard
  nonparticipant message pairs before grouping/displaying them.
- An explicitly selected student context is preserved in replies. Otherwise the
  latest message's context is used, including NULL for a general message; older
  child-specific context is not silently resurrected. Opening from the inbox derives
  that context from the fresh thread response, not the cached inbox preview.
- Failed sends do not append a message or clear the typed draft. Failed read receipts
  remain unread and surface a retry/refresh explanation. Successful receipts update
  local state only from the server response.
- Failed history/contact refreshes clear the stale visible list and show the error.

## Limits and rollout

No migration, existing-data edit, provider notification, deployment or new dependency
is required by this packet. Deploy the API authorization change with the matching
shared UI behavior. The updated basic send test now creates a legitimate teacher /
student / guardian relationship; the old unlinked teacher-to-any-guardian behavior
is intentionally rejected, with explicit denial and zero-write regression coverage.

Authorization is checked during each request, not a guarantee that already in-flight
operations are cancelled when membership changes concurrently. Request-level send
idempotency, durable offline recovery, pagination/load tests, moderation/retention,
and real browser/device acceptance remain separate work. School lifecycle gates
retain their existing cache/invalidation behavior. Parent F01 and Phase 1 remain
open. Next packet: F01.4 academic/student-report nested-object access audit.
