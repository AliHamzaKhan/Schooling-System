# Private attachment rollout — F04.2

Status: implemented locally; F04.3 supplies a read-only existing-data inventory
and migration/rollback plan, F04.4 adds an allowlisted new-upload policy, and
F04.5 adds a fail-closed ClamAV pre-storage scan/readiness contract. Staging
scanner evidence, production inventory and any approved data migration remain
outstanding.
No existing files or school records have been moved, rewritten or deleted.

## Access contract

- Uploads outside `avatars` and `uniform` now use
  `private/<folder>/<school-id>/<uploader-id>/<unique-filename>`.
- Stored `/media/...` values are references, not private download links. The
  storage root is no longer mounted publicly. Never expose it through a proxy
  alias, public bucket or CDN.
- Authenticated clients POST `/api/v1/schools/{school}/files/{kind}/{record}/ticket`
  (`kind`: `documents` or `submissions`). The response contains a relative `path`
  and `expires_in: 60`. Use the configured API origin, not a metadata URL host.
  Account access/refresh tokens never enter file URLs.
- Redemption repeats account, school, record and relationship/permission checks.
  Tickets bind to the reference fingerprint; replacing/deleting the record
  invalidates its old link. Bytes use attachment disposition, `no-store`,
  `nosniff` and `no-referrer`. Denials are not cached either.
- Documents follow the existing student-record policy: self, linked guardian,
  staff with student-management view, or super admin. Authorized document staff
  have school-wide access, not a class-only restriction.
- Homework permits self/linked guardian or assigned staff (author, section
  teacher, subject timetable teacher, headmaster, super admin). Staff need
  effective homework edit permission. Assignment lists, grading/review and
  assignment mutations use this boundary; staff student-history responses filter
  out unassigned work. The broader nested-object audit remains F01.
- Student and teacher attachment opening now prepares a ticket in a loading/
  error/retry dialog, then uses a separate Download click for a fresh browser
  gesture. Stale prepared links are refreshed before another download attempt.
  The shared document resolver/API exists; a full document hub remains M26.

## Compatibility and migration gates

| Existing asset | Behavior | Required action |
| --- | --- | --- |
| Existing record with `/media/documents/<school>/<filename>` or `/media/submissions/<school>/<filename>` | Direct link denied; record-authorized download works without moving bytes | Audit ownership/duplicate references; update older raw-URL clients |
| Absolute equivalent on the configured `PUBLIC_BASE_URL` origin | Same record-based access | Keep the configured origin correct |
| External URL, unrecognized old origin, malformed/foreign-school path, mismatched private uploader | No ticket, proxy fetch or unsafe fallback | Operator inventories and validates source, then reuploads and reviews metadata change |
| Unreferenced private file | Not downloadable | Inventory; retention/deletion requires an approved policy |
| Historical avatar/uniform raster namespace | Still public; only PNG/JPEG/WebP signatures served | Public-avatar privacy is unresolved; plan authenticated-image migration before claiming all personal media private |
| Other formerly public namespace or SVG/GIF | No public route | Inventory and add a reviewed integration; never restore a broad static mount |

New local references must match the current uploader, school and category;
callers cannot claim another uploader's blob or newly attach a legacy path.
An unchanged historical attachment can remain on a resubmission. External
HTTP(S) metadata links remain accepted where previously supported, but the
managed-download flow refuses to proxy/open them. Old mislinked records require
audit: code cannot reconstruct historical blob ownership. Deleting an uploader
whose private document still exists also requires reviewed ownership handling.

Deploy backend and updated clients together after inventory. Older mobile builds
opening raw links fail securely until updated. Do not roll back by restoring
the public storage mount. Back up metadata and storage before any separately
approved migration; retain required records. No migration is executed here.

## Remaining security and acceptance work

- Links are shareable/replayable bearer capabilities for up to 60 seconds while
  the issuer remains authorized. They are not single-use/device-bound. As of
  F02.1, committed session revocation is checked on redemption; account disablement and
  relationship/permission changes are rechecked. School checks retain existing
  lifecycle cache TTL/invalidation behavior.
  See [session rollout and offline limitations](SESSION_AND_ROUTE_ROLLOUT.md).
- Uvicorn download access logs redact ticket queries. The disabled Nginx template
  now shows query-free logging. Configure and verify real proxies, load balancers,
  APM and analytics before release; never log ticket response bodies/queries.
  Browser/download history may retain expired links. Require HTTPS in production.
- Raster checks inspect signatures, not full decoding or malware safety. Private
  files still need type allowlists, scanning/quarantine, quotas, multipart disk
  limits, streaming/download limits and retention controls.
- Verify downloads on supported browsers/native devices against staging, plus
  proxy routing/cache behavior, guardian revocation, school disablement and
  external-link migration messaging. Automated tests are not release acceptance.

See [verification](PHASE_1_VERIFICATION.md) and
[progress tracker](PRODUCT_ENHANCEMENT_PLAN.md). See the
[F04.3 inventory and rollout plan](PRIVATE_ASSET_INVENTORY.md) before any
existing-data work and the [F04.4 new-upload policy](PRIVATE_ASSET_POLICY.md)
and [F04.5 scanner rollout](PRIVATE_ASSET_SCANNING.md) before production rollout.
F04 stays In progress.
