# Public document verification

Standalone Node server using built-in modules. This implements reference plus exact PDF fingerprint checks, not certificate-based digital signatures. The browser hashes the PDF locally; the server receives only its SHA-256 digest. Public output is validity, document type, issue date, registry update time and file match. Patient names, diagnoses and issuer details are excluded.

## Configure and publish

1. On a trusted clinic host, generate a private 32-byte hex key with `node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))"`. Store it in the host's secret manager as `VERIFICATION_SIGNING_KEY`. Never put this key in Flutter, a manifest, a browser bundle or source control.
2. Set `VERIFICATION_REGISTRY_PATH` to durable private storage. Restrict filesystem permissions to the publishing operator and service account; back up the registry and key securely.
3. Build Flutter with `--dart-define=DOCUMENT_VERIFICATION_ORIGIN=https://verify.your-clinic.example`. New issued PDFs freeze this origin and a random 256-bit token into their QR. Without a configured origin, the PDF retains the in-app verification reference. Existing immutable PDFs are never rewritten.
4. In Admin > Document policies > Document access, export the minimal registry using a recently authenticated administrator with an explicit template-management grant. Transfer the manifest through a private trusted channel, review it against the authoritative clinic database, then run `node services/document_verification/server.mjs import path/to/manifest.json --approve` within five minutes of export. Local app exports are **not independently authenticated clinic records**: trusted operator review is required before publication. Protect manifest tokens and delete transient exports after import.
5. Run `node services/document_verification/server.mjs serve`. It binds to `127.0.0.1:8787` by default. Put it behind HTTPS, disable request/access logs containing reference paths or fingerprint queries, and apply per-client rate limits at the proxy. The service ignores forwarded IP headers and limits by socket peer; all requests through one proxy share its limit. Set `HOST`/`PORT` only as needed for your host.

The signed server registry uses HMAC to detect storage tampering, stores token hashes, and rejects changes to issued file fingerprints or reactivation of revoked/superseded versions. No public write/import endpoint exists. Losing or rotating the HMAC key requires a reviewed registry recovery/re-signing operation; preserve the trusted invalidation history.

## Freshness and revocation

The current Flutter database is device-local. Publication is explicit and does not claim cross-device or instant revocation. Republish after issue, replacement or revocation. Valid entries become **stale after five minutes** without refresh, and stale entries never report valid or a successful file match. Revoked/superseded states remain invalid. Omitted records are retained and expire rather than disappearing. The public page shows the last registry update.

For sustained production operation, connect a trusted publisher to the shared backend in Task 7, refresh more frequently than five minutes, and monitor stale entries and publication failures. This server and its tests are implemented; public hosting, clinic credentials, policy approval and automated authoritative publication still require configuration. Do not present a manual snapshot as live clinic validity.

## Checks

`node --test services/document_verification/server.test.mjs`

Unknown references return a uniform response. Requests are read-only, rate limited and uncached. A missing/tampered registry fails closed. The public page requires HTTPS (or localhost) for local PDF hashing and limits selected files to 20 MB.
