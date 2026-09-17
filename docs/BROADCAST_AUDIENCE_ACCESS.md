# Broadcast audience access — F01.2

Implemented 2026-09-15. Technical scope only; production/browser acceptance remains
open. [Progress](PRODUCT_ENHANCEMENT_PLAN.md) · [Verification](PHASE_1_VERIFICATION.md)

## Access contract

Every request still requires an active authenticated account, school/module access
and the existing messaging action permission. Super-admin oversight is explicitly
school-scoped by the requested school; ordinary accounts cannot select another
tenant. This change does not broaden who may create broadcasts.

Feed `GET /schools/{school_id}/communication/broadcasts` and direct detail
`GET .../broadcasts/{message_id}` use the same SQL visibility predicate before
serialization. Sender and headmaster/super-admin may inspect school broadcasts
they own/administer, including scheduled, failed and historical records.

For everyone else, current audience membership is required:

| Audience | Recipient visibility |
| --- | --- |
| Entire school | Active same-school account with messaging-view |
| Teachers / students / guardians | Matching current role in the same school |
| Class / section | Current student role plus active enrollment; enrollment, section and parent class must all belong to the school |
| Student's guardians | Current guardian role and same-school guardian link to that active same-school student, who must still have the student role |
| Unknown, missing or invalid target | Hidden from recipients; sender/admin oversight remains |

Role audiences and entire-school messages must have no audience reference.
Class/section audiences do **not** implicitly include staff or parents; this matches
the existing delivery model. A teacher who authored such a message retains sender
oversight. A non-authoring teacher needs the corresponding teachers/whole-school
audience rather than access through a student's enrollment.

Scheduled content becomes readable by its audience at `scheduled_at`, not before.
A malformed historical `scheduled` row without a scheduled timestamp fails closed
for recipients. Immediate pending, simulated or failed messages remain valid in-app
announcements for their intended audience: provider success is not a content-access
requirement, and content visibility is not a claim of external delivery.

Current membership is evaluated on every request. Removing an enrollment/guardian
link or changing a role removes audience-derived access on subsequent reads;
historical delivery records do not grant it back. Conversely, newly eligible members
can see older messages for their current audience. This is a **current-membership
feed**, not a historical recipient-snapshot inbox. Saved/screenshot/downloaded content
cannot be recalled, and an already-open screen is not remotely purged.

## Secondary paths and recipient alignment

- The due-work listing `POST .../communication/process-due` remains read-only and
  requires messaging-create, but only returns the caller's own due messages or
  all due school work for headmaster/super-admin. Being an intended recipient is
  not sufficient to inspect another sender's worker listing.
- Delivery details, summaries and masked review retain F07.3 sender/admin gates.
  The original recipient-review 403 contract is unchanged; hidden direct broadcast
  URLs return the same 404 response as nonexistent/foreign message IDs.
- Student, guardian and teacher feeds consume the server-filtered list. Teacher
  client-side search cannot restore rows the server did not return. Guardian direct
  messages remain a separate inbox contract, not broadcast audience data.
- The teacher dashboard's separate announcement activity query is already restricted
  to the authenticated teacher's own creations; it does not read other senders' titles.
- Worker audience resolution now also requires student/guardian roles and complete
  tenant checks for enrollment/class/guardian links. Corrupt legacy links cannot
  silently deliver to a non-recipient, even when the feed rejects that recipient.
- Communication responses, including errors, carry `Cache-Control: private, no-store`
  through the existing security middleware. This prevents compliant HTTP caches from
  retaining personalized responses; it is not remote deletion of previously read data.

## Rollout and remaining work

No new schema/data migration or real provider action is required for these read
restrictions. Deploy the tightened API first. F07.2's outbox migration/API/worker
coordination is still required for the broader notification implementation, and
has not been applied to existing school data in this work.

Malformed historical messages/links were not rewritten or deleted. Operators may
see fewer intended recipients until corrupt data is reviewed and corrected. Existing
active enrollment records are authoritative; auditing stale academic-session data
and choosing a different historical-access policy are separate product/data work.

The full nested-object/action audit is not complete. Next packet: **F01.3 direct
conversation boundaries** — verify recipient eligibility and student references on
send, and membership on thread/read operations. Provider receipts/reconciliation,
real browsers/native devices and independent security review remain separate gates.
