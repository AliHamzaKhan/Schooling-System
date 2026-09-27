# Upload scanning and production readiness — F04.5

Status: technically verified locally. The service now performs a fail-closed
pre-storage scan for every new upload. This does not run a production scanner,
move existing assets, or approve an existing-data migration.

## Runtime contract

- Development and isolated tests use `UPLOAD_SCANNER_BACKEND=disabled`.
- Any non-development environment refuses to start unless
  `UPLOAD_SCANNER_BACKEND=clamav` and `UPLOAD_SCANNER_HOST` are configured.
- The API streams the size-bounded bytes to ClamAV's private INSTREAM service
  before constructing a storage key or calling storage. A clean result is the
  only result that permits storage.
- A detected result returns a normal upload rejection. The bytes are discarded;
  no malicious object is retained in an application-accessible quarantine.
- A timeout, network failure, malformed scanner reply or unknown result returns
  a retryable 503. It creates no blob and no metadata record.
- `/health/ready` includes `upload_scanner`. Production compose and CI deploy
  checks use readiness, so a reachable process without a healthy scanner is not
  treated as ready.

The scanner receives bytes only. Application code does not send an account,
school ID, stored object key, original filename or ticket to the scanner.

## Production configuration

Set protected CI variables before deploying:

```text
UPLOAD_SCANNER_BACKEND=clamav
UPLOAD_SCANNER_HOST=<private-network-dns-or-ip>
UPLOAD_SCANNER_PORT=3310
UPLOAD_SCANNER_TIMEOUT_SECONDS=15
```

Operate ClamAV on a private network and keep its signatures current. Restrict
the service so only the API's network identity can connect. Do not publish the
scanner port, use a public scanning endpoint, or log uploaded bytes/scanner
responses. The supplied deployment pipeline refuses to create a production
environment file when the backend/host variables are missing.

## Staging acceptance before release

1. Configure a staging ClamAV service with current signatures and run
   `/health/ready`; database, Redis and `upload_scanner` must all report `ok`.
2. Upload a permitted synthetic PDF/image and verify it scans clean, receives a
   normalized type, and follows the existing record-authorized private download
   path when attached.
3. Use an approved harmless scanner test fixture in an isolated staging account
   to confirm detected content is rejected with no stored object or metadata.
   Do not upload test signatures to production school records.
4. Stop or firewall the scanner and verify upload returns 503 with no new blob;
   verify readiness becomes 503. Restore it and verify readiness recovery.
5. Confirm NPM/CDN/bucket logs omit ticket queries and cannot serve
   `/media/private/...`; direct private links, wrong-school tickets and revoked
   guardian tickets must fail.
6. Run the F04.3 read-only inventory, preserve its checksum/backup manifest,
   and record product/privacy approval before a canary migration.

## Quarantine, quota and retention boundary

The pre-storage gate deliberately rejects detected bytes instead of creating a
retrievable quarantine object. This keeps untrusted content out of storage and
avoids a release/review path that could accidentally expose it. Scanner service
logs and operational alerts are the quarantine evidence; retain them under the
infrastructure policy without file content or user-identifying metadata.

Per-file size is still bounded by `MAX_UPLOAD_MB`. Per-school/user byte and
object quotas, retention/legal-hold/deletion rules, orphan cleanup and migration
approval remain F04.6 work. Public-avatar, uniform, logo and course-cover policy
remains subject to the approvals in [PRIVATE_ASSET_POLICY.md](PRIVATE_ASSET_POLICY.md).
