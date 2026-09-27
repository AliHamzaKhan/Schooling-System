# Private-asset inventory and rollout plan — F04.3

Status: technically verified locally. This packet provides a read-only inventory
tool and rollout decision record; it does not change a school row, attachment
reference or stored object.

## What is inventoried

`backend/scripts/audit_private_assets.py` reads the persisted locations below in
one PostgreSQL `SET TRANSACTION READ ONLY` transaction. It writes its JSON report
only to stdout and deliberately redacts reference values: details contain source
record IDs and a short, hashed shape, never file paths, queries or ticket values.

| Source | Stored reference | Target visibility | Expected state |
| --- | --- | --- | --- |
| `student_documents.file_url` | Student document blob | Private | `managed_private` or a verified `legacy_record_path` |
| `submissions.attachment_url` | Homework attachment | Private | `managed_private` or a verified `legacy_record_path` |
| `users.profile_metadata.avatar_url` | Person avatar | Public compatibility, pending policy | `public_compatibility_path` |
| `school_info.uniform_image_url` | Uniform image | Public compatibility | `public_compatibility_path` |
| `schools.settings.logo_url` | School logo | Public compatibility | `public_compatibility_path` |
| `courses.cover_url` | Course-cover visual | Policy decision | classify and approve before moving |
| Other URL-shaped profile/settings values | Extensible metadata | Policy decision | classify and assign an owner before moving |

The existing public route only serves raster files from `avatars/<school>/...`
and `uniform/<school>/...`; it does not make the storage root public. The
inventory therefore treats a public or unrecognized local path in a private
field as an exception, never as a compatible private attachment.

## Runbook

Run from `backend` against a **read-only database credential**, preferably on a
production replica after the backup window. The script rejects no data itself,
but read-only credentials are the independent operational safeguard.

```sh
PRIVATE_ASSET_AUDIT_DATABASE_URL='postgresql+asyncpg://readonly:…@db/schooling' \
PRIVATE_ASSET_AUDIT_PUBLIC_ORIGIN='https://api.example.edu' \
.venv/bin/python scripts/audit_private_assets.py --details > /secure/audit/private-assets.json
```

`--details` adds record IDs and redacted reference shapes for remediation. The
default report contains aggregate counts only. The database URL is never printed.
Keep the report in approved restricted storage because record IDs and counts are
still operationally sensitive. Do not use `DATABASE_URL` implicitly or run this
against a production primary with a writable application credential.

Review the report in this order:

1. `managed_private`: sample record authorization and blob existence through the
   ticket endpoint; do not test by direct `/media` access.
2. `legacy_record_path`: establish the owning record, object checksum/size and
   duplicate-reference set. These work through record authorization today and
   need no emergency move.
3. `misowned_or_unrecognized_local`, `invalid_reference` and
   `external_reference`: quarantine the finding in a remediation list. Do not
   proxy, fetch, relink or delete it automatically.
4. `public_compatibility_path`: obtain the public-media/privacy decision below
   before any migration.
5. `policy_decision` and other review states: name the content owner and target
   visibility before a migration batch is designed.

## Controlled migration proposal

This is the sequence for a separate, explicitly approved data-change packet.

1. Freeze an inventory report, PostgreSQL backup/restore point and object-store
   version/checksum manifest. Re-run the report immediately before each batch;
   only rows still matching the reviewed fingerprint can enter that batch.
2. Confirm public-avatar consent, school-logo/public-course-cover policy,
   retention and deletion ownership. Define a documented allowlist of content
   types, scanning/quarantine result, byte quota and the retention owner before
   copying private files.
3. In a disposable restored dataset, copy a small legacy batch to
   `private/<kind>/<school>/<owner>/<unique-name>`, checksum both objects, update
   only the corresponding record after its copy succeeds, and verify access as
   owner, linked guardian, authorized staff and wrong-school user.
4. Retain old objects and the pre-change metadata manifest for the agreed
   retention window. Roll out by school/batch with metrics for copy failures,
   missing blobs, ticket failures and authorization denials. Do not delete old
   keys or restore a public storage mount during this window.
5. Delete a legacy object only after the approved retention, backup/restore
   rehearsal and a final reference scan confirm it is unreferenced. Record the
   actor, source/target checksum, date and reason in the migration ledger.

## Rollback boundary

For a failed batch, stop subsequent batches, restore only the affected metadata
from the frozen manifest, retain both object versions, and re-run the inventory
plus authorized ticket checks. The safe rollback preserves the private download
boundary: it must never re-enable a broad `/media` static mount, public bucket or
CDN origin. Reconcile record counts and checksums before retrying.

## Decisions still required

- Whether personal avatars may remain public, and what consent, removal and
  retention rules apply to minors and staff.
- Whether school logos and course covers are public branding/media, restricted
  school content, or externally hosted by an approved provider.
- Allowed private file types/sizes, malware scanning/quarantine, upload quotas,
  download streaming limits and retention/deletion obligations.
- The production proxy/CDN/object-store posture, backup owner, audit report
  custodian, canary size and rollback authority.

See the current access contract and client compatibility notes in
[PRIVATE_FILE_ROLLOUT.md](PRIVATE_FILE_ROLLOUT.md). No migration command is
provided here intentionally.
