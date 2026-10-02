# New-upload policy and migration readiness — F04.4

Status: technically verified locally. This policy controls **new** uploads. It
does not change existing records or objects, and it does not approve a production
asset migration.

## Enforced new-upload policy

The upload endpoint accepts only these exact folders. It derives type from file
signatures, never from a browser/client MIME header or filename extension, and
rewrites the stored filename suffix to the detected type before creating a key.

| Folder | Visibility | Allowed signatures | Storage contract |
| --- | --- | --- | --- |
| `documents` | Private | PDF, PNG, JPEG, WebP | `private/documents/<school>/<uploader>/<uuid>.<type>`; ticket-only retrieval |
| `submissions` | Private | PDF, PNG, JPEG, WebP | `private/submissions/<school>/<uploader>/<uuid>.<type>`; ticket-only retrieval |
| `avatars` | Public compatibility | PNG, JPEG, WebP | `avatars/<school>/<uuid>.<type>`; limited raster API route |
| `uniform` | Public compatibility | PNG, JPEG, WebP | `uniform/<school>/<uuid>.<type>`; limited raster API route |

Unknown, path-like, or undeclared folders fail before storage. Empty and over-limit
uploads remain blocked by the existing bounded reader; `MAX_UPLOAD_MB` is a
per-request 10 MB default. Public/private blob bytes are never served from a
storage-root mount. Private document/submission downloads remain record-authorized
and ticket-bound under the F04.2 contract.

The code does not reclassify old metadata. The [F04.3 inventory](PRIVATE_ASSET_INVENTORY.md)
is the source for identifying legacy, foreign, malformed and externally hosted
references.

## Visibility decisions and remaining approvals

Decided 2026-10-02 (product owner): photos and logos are not public. They are
for the school's own people (students, guardians, teachers, accountant,
drivers) and the platform admin panel.

`GET /media/{avatars|uniform}/{school_id}/{file}` now requires a signed-in
user who belongs to that school, or the Super Admin; no token gives 401 and
another school's user gets 404. The apps load these images with the user's
token (`schoolImage` in the shared package); other hosts never receive it.

| Asset | Current behavior | Remaining approval |
| --- | --- | --- |
| Student/staff avatars | School members and Super Admin only | Consent and removal process for minors' photos |
| Uniform images | School members and Super Admin only | None |
| School logos | School members and Super Admin only (avatar namespace) | None |
| Course covers | Existing URL metadata; no managed cover upload path | Product owner decides public, school-restricted or approved external-host policy before adding uploads/migration |
| Documents/submissions | Private ticket-only retrieval | Records owner approves retention, legal hold and deletion schedule |

## Controls that remain release gates

Signature allowlists stop obvious active/unknown content and caller-controlled
content-type confusion. F04.5 adds a ClamAV pre-storage scanner contract; see
[upload scanning and production readiness](PRIVATE_ASSET_SCANNING.md). No
cumulative school/user storage quota or automatic blob-retention/deletion job
exists. Do not run a broad existing-data copy until all remaining items below
have named owners and evidence.

1. Complete the staging scanner/readiness checks and configure production
   operational alerts. Detected bytes are rejected before storage; no application
   quarantine object is retained or released.
2. Set per-school and per-user byte/object quotas, metric/alert thresholds, and
   reverse-proxy multipart limits no larger than the application limit.
3. Approve retention, legal hold, deletion request, orphan cleanup and backup
   restoration rules. A record delete must not silently delete required academic
   or financial history.
4. Capture staging evidence that the proxy, CDN, bucket and observability stack
   cannot expose `/media/private/...` or ticket queries. Verify public raster
   paths, authorized tickets, wrong-school denial and revoked-guardian denial.
5. Run the F04.3 inventory with a read-only credential, freeze the backup and
   checksum manifest, then obtain explicit approval for a canary migration.

## Controlled-migration readiness

F04.4 permits planning and validation only. A future migration must use the
[F04.3 copy and rollback sequence](PRIVATE_ASSET_INVENTORY.md#controlled-migration-proposal):
copy and checksum first, update one matching record only after a successful copy,
retain old objects through the approved window, and never restore a public storage
mount as rollback. The migration operator records source/target checksums, owner,
batch, timestamp and rollback result in a restricted ledger.
