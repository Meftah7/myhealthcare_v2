# Phase 0 Threat Model

Status: initial repository-grounded model, 2026-09-28. This is not a compliance
certification or a substitute for review by qualified security, privacy, legal,
clinical-safety, and clinic-operations owners.

## Scope and trust boundaries

Protected assets include account credentials, patient identity and clinical
records, family/proxy relationships, appointment capacity, clinical drafts and
orders, messages/referrals/tasks, invoices/payment state, exported documents,
AI keys/prompts/outputs, audit history, and notification content.

Current boundaries:

1. Flutter UI and Riverpod controllers.
2. Repository/domain layer.
3. Local Drift database (encrypted on supported native platforms; web storage is
   explicitly unencrypted in the current implementation).
4. Device secure storage for database/AI keys where supported.
5. Optional direct Gemini API calls from the client.
6. Local filesystem/document picker and PDF export.
7. Future authoritative backend and external payment/notification providers,
   which are not selected or implemented.

The current client and its local database are not a production authorization
boundary. A modified client or copied database can bypass local-only checks.

## Primary threat scenarios and required controls

| Threat | Current exposure | Required control/evidence |
|---|---|---|
| Production ships demo credentials/data | Runtime previously seeded unconditionally. | Explicit runtime mode, release default production, seeder service guard, UI gating, regression tests. Implemented locally. |
| Account takeover through recovery | No verified external recovery channel. | Trusted identity service, expiring single-use proof, throttling, revocation, audit, generic responses. |
| Direct-object/cross-patient access | Route IDs and client-supplied IDs can become confused-deputy inputs. | Actor from authenticated context, object authorization at authoritative boundary, negative tests for every read/export/mutation. |
| Privilege escalation in modified client | Roles and enforcement are local. | Server-issued session/claims and server-side least-privilege authorization. |
| Shared-device data leakage | Providers, preferences, drafts, files, caches, and notifications may outlive a session. | User/patient-scoped storage plus verified purge/invalidation on logout, expiry, revocation, and account switch. |
| Database migration loss/corruption | Schema and demo seed lifecycle were coupled; interrupted upgrades are possible. | Transactional versioned migrations, populated fixtures, backups, restore/rollback rehearsal, no production seeding. |
| Booking race/double claim | Check-then-write or weak uniqueness can oversubscribe capacity. | Authoritative atomic reservation, overlap invariant, version/lock, idempotency key, concurrency tests. |
| Duplicate or partial clinical writes | Retry/crash can split encounter, medication, and notification writes. | Durable versioned draft, atomic clinical commit, append-only amendment, outbox for side effects. |
| False payment confirmation | Client currently marks invoice paid locally. | Provider/server verification, transaction ledger, idempotency, reconciliation, refund authorization. |
| False notification-delivery claim | Reminder rows are not delivery receipts. | Provider delivery state, permission/app-closed behavior, retry/suppression lifecycle, honest UI. |
| Sensitive data sent to AI | Direct client calls may transmit clinical context; fallback provenance can be unclear. | Data minimization, consent/legal basis, vendor terms/retention review, server proxy where required, provenance, access logs, human review. |
| Secret extraction | Client-bundled or dart-defined API keys can be recovered from binaries/processes. | Do not ship privileged shared secrets in clients; use backend token exchange/proxy and scoped credentials. |
| Sensitive logs/analytics | Raw notes/messages/identifiers may enter generic telemetry or audit detail. | Event allowlist, pseudonymous identifiers, protected audit store, retention/access policy, content exclusion tests. |
| Export/file disclosure | PDFs/imported files can escape app authorization and remain on shared storage. | Reauthorize export, minimize content, controlled destination, retention/deletion UX, issuer/source labels, platform review. |
| Availability abuse | Login/reset/search/message endpoints can be flooded in a shared service. | Server-side actor/device/network throttling, quotas, monitoring, safe degradation, operational owner. |
| Stale or failed data shown as safe | Empty/error collapse can hide clinical or operational work. | Typed freshness/errors, last-updated state, no all-clear on failure, monitoring and recovery action. |
| Web storage exposure | Current web database lacks native keystore encryption. | Do not treat browser storage as protected clinical persistence; use backend storage and minimize local cache before live web scope. |

## Security verification backlog

- [ ] Select production identity, backend, audit, payment, and notification
      architecture and update this model with data-flow diagrams.
- [ ] Enumerate every repository/API operation and its actor/resource/action
      authorization rule.
- [ ] Add automated negative tests for route, read, mutation, export, and
      cross-role access.
- [ ] Add account-switch, session-expiry, revocation, and local-file cleanup tests.
- [ ] Add concurrency/idempotency tests for booking, encounter finalization,
      payments, claims, referrals, and notification outbox handling.
- [ ] Define data classification, retention, backup, restoration, deletion,
      consent, breach response, and access-review policy.
- [ ] Review mobile, desktop, and web storage separately on supported targets.
- [ ] Perform dependency, secret, runtime, and penetration testing before pilot.

