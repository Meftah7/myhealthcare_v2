# Shared server pilot

This is an online-first **local pilot**, separate from the existing device-local
database. It has durable SQLite storage, authenticated sessions, current account
and patient authorization, versioned tasks, immutable issued snapshots, encrypted
PDF storage, live minimal verification, in-app delivery and encrypted backups.
It does not automatically convert the entire existing clinic app into a shared app.
The Flutter pilot currently exposes tasks, documents, uploaded PDF originals,
profiles and admin health. Other existing modules still use local repositories.
The old Records layout and staff Profile navigation are preserved.

## Run locally (PowerShell, Node 24.13+ and the pinned Flutter SDK)

Run from the repository root. Put runtime data under `.tmp` for this synthetic
local test only. Production must use a private durable volume outside the web
root/source tree, with encrypted host storage and restrictive OS permissions.

```powershell
$env:MYHEALTH_DATA_DIR = "$PWD/.tmp/shared-data"
$env:MYHEALTH_BACKUP_DIR = "$PWD/.tmp/shared-backups"
$env:MYHEALTH_FILE_KEY = (node -e "process.stdout.write(require('node:crypto').randomBytes(32).toString('hex'))")
$env:MYHEALTH_BACKUP_KEY = (node -e "process.stdout.write(require('node:crypto').randomBytes(32).toString('hex'))")
$env:MYHEALTH_DEMO_PASSWORD = 'Choose-your-own-synthetic-password-2026!'
$env:MYHEALTH_ORIGINS = 'http://localhost:8080'
$env:MYHEALTH_PDF_RENDERER = 'english'
node services/shared_api/cli.mjs init-demo
node services/shared_api/cli.mjs serve
```

Keep the two keys in a password manager or server secret store before restarting.
Do not regenerate the file key for an existing database. The backup key must be
held separately from the running server's data; losing it makes backups unusable.
Environment variables above are process-local: configure them in a service/secret
manager for later runs. Never put them into a Flutter build or Git.

In a second terminal:

```powershell
flutter build web --release --no-web-resources-cdn --dart-define=SHARED_API_ORIGIN=http://localhost:8080
node tools/serve_local.mjs build/web 8080 http://127.0.0.1:8787
```

The local server binds only to loopback and proxies `/api` to the authenticated
API. Keeping browser requests on the page's origin and bundling CanvasKit makes
the strict page security policy work without adding wildcard connections or CDNs.
Use an equivalent HTTPS same-origin reverse proxy when hosting is selected.

Open two independent browser windows on `http://localhost:8080`, sign in to the
shared accounts (`doctor@shared.demo`, `patient@shared.demo`, `admin@shared.demo`,
or `nurse@shared.demo`) with your chosen password. Doctor task updates persist
on the server and refresh across clients. Completed synthetic visits are seeded;
document policy approval is **not** seeded. Admin policy approval must be performed
explicitly in Documents using "Record clinic policy decision" (or `/api/templates`)
with a reason and password confirmation after review. This is not clinic
approval for real use. The local pilot's English renderer rejects unsupported
characters/Arabic; configure an Arabic-capable trusted server renderer before
claiming bilingual PDF support. Unknown document types fail closed.

Without `SHARED_API_ORIGIN`, the existing local app starts normally. Shared startup
returns before local storage/seeding initializes. There is no offline write queue,
automatic local fallback, stored browser token or persistent patient cache.

## API boundary

All protected calls use `Authorization: Bearer <session token>`. Session tokens
are random 256-bit values; only hashes are stored. Sessions expire after 24 minutes
of user inactivity or 12 hours absolute. Background GET polling does not renew
activity; user interactions call `/api/activity`. Sign-out/account deactivation
invalidate server sessions. Sensitive actions need password confirmation within
15 minutes through `/api/reauthenticate`. Exact allowed browser origins are
configured with `MYHEALTH_ORIGINS`; no wildcard CORS or public SQL endpoint exists.

| Endpoint | Boundary |
| --- | --- |
| POST `/api/login`; GET `/api/session`; POST `/api/logout`, `/api/activity`, `/api/reauthenticate` | Current server account/session |
| GET `/api/people`; POST `/api/people/:id/active` | Role-scoped directory; admin, fresh password, last-admin/unfinished-work guards |
| GET/POST `/api/tasks`; PATCH `/api/tasks/:id`; GET `/api/tasks/:id/history` | Current staff owner AND current patient care relationship; expected version/outcome |
| GET `/api/visits?patientId=...` | Patient self or currently assigned staff |
| GET/POST `/api/templates` | Staff metadata/admin policy changes with reason and fresh password |
| POST `/api/requests`; POST `/api/requests/:id/submit`, `/approve`, `/issue` | Matched patient/completed visit/clinician; approved policy, current doctor qualification |
| GET `/api/documents?patientId=...`; POST `/api/documents/:id/render`, `/revoke`; GET `/download` | Scoped subject/issuer; admin metadata does not grant clinical download/signing |
| GET/POST `/api/originals`; GET `/api/originals/:id` | Current patient self/care access; immutable encrypted original bytes |
| GET `/api/verify/:reference?sha256=...` | Public rate-limited minimal validity/type/date/file match; no patient data |
| GET `/api/notifications` | Own notifications only |
| POST `/api/ai` | Current clinician/patient relationship; server provider seam; draft output only |
| GET `/api/health` | Admin only; schema, integrity, backup/restore/delivery jobs and configuration |

Retries require a stable `idempotencyKey`. Reusing it with different inputs fails
with HTTP 409. Issuance commits document, request, audit and delivery together;
rendering failure leaves an explicit pending document, never a ready PDF. Server
copies freeze identity/template/content/qualifications. Retry/render/delivery
cannot duplicate an issue. Verification reads this authoritative registry live;
no operator manifest refresh or client-authenticated publication is required.
Revocation cannot reactivate a document. All writes use bounded SQLite transactions
and WAL with a five-second busy timeout. Task generation preserves existing status,
owner and deadline for a canonical source. General audit contains identifiers and
actions; clinical outcome text stays in scoped immutable task history.

`MYHEALTH_PDF_RENDERER=english` enables the narrow English renderer. Other rendering
and AI providers are trusted server-side functions injected into `createApi`;
provider secrets belong in the server environment. The client has no provider-key
entry field. Payments and external email/SMS delivery are reported **not configured**.
The delivery worker creates one minimal in-app notice after a PDF is ready; it does
not claim an email, SMS or clinical acknowledgement.

## Backups and restore

The server takes an initial backup and schedules one hourly; target RPO is one hour.
Proposed recovery target is four hours, subject to a drill on the eventual host.
Retention is 30 days. The online SQLite backup API captures a consistent database;
referenced immutable encrypted files and the file key are included in an AES-256-GCM
archive under a separate backup key. This first format is bounded to 256 MB and
needs streaming/offsite backup expansion before exceeding that limit. The health
endpoint records failures; copy encrypted archives off-host using the eventual host's
backup service. An archive on the same disk is not disaster recovery.

Stop the service and restore to a **new** directory with an offline operator:

```powershell
$env:MYHEALTH_RESTORE_KEY = '<backup key from the operator secret store>'
node services/shared_api/cli.mjs restore '<archive.mhcb>' '<new-directory>'
```

There is no public restore endpoint. The running web service does not receive the
restore key. Wrong keys/overwriting existing storage are refused. Restore checks
schema, SQLite integrity and every file fingerprint, invalidates all sessions,
and quarantines partial restores. `restored-file-key.txt` is an operator-only
recovery artifact: move it into the secret store, delete that file, configure
`MYHEALTH_FILE_KEY`, then start against the restored directory. Test a login,
original download, issuance state and verification before switching traffic.

## Checks

```powershell
node --test services/shared_api/server.test.mjs services/shared_api/load.mjs
flutter test test/services/shared_client_test.dart test/features/shared_workspace_test.dart
```

Tests exercise independent clients, cross-panel denial, live revocation during
rendering, stale writes, exact original/issued files, qualification/policy checks,
minimal registry disclosure, retry conflicts, immutable history, failed delivery
retry and encrypted restore with session invalidation. The synthetic load check
sends 100 duplicate creates and 100 competing updates; exactly one task and one
outcome commit. Local timing is not a production capacity claim.

## Remaining Task 7 integration

Remote adapters for the rest of the existing app (appointments/consultations,
care/inbox, billing, proxy grants, all document types and the existing full Records
experience) remain to be connected. The pilot has a separate server schema v1;
the local Flutter database remains schema 31. Do not silently upload or reuse an
existing local clinic database. A reviewed migration/import path and complete
production provisioning, recovery, provider integration, Arabic rendering, TLS,
offsite backup and host restore drill are still required before shared clinic use.
Public deployment is intentionally deferred until the user chooses hosting.

Implementation references: [Node SQLite/online backup](https://nodejs.org/api/sqlite.html)
and [Node cryptography](https://nodejs.org/api/crypto.html).
