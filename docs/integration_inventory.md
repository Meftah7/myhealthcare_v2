# Integration and Simulation Inventory

Captured: 2026-09-28. This inventory prevents local or fallback behavior from
being presented as a live clinic integration.

| Capability | Current implementation | Classification | Release action |
|---|---|---|---|
| Accounts, sessions, roles | Local Drift users, local password verification and Riverpod session. | Demo/local only | Replace with trusted identity/session service before live use. |
| Patient/clinical data | Local Drift database; native encryption, web storage unencrypted. | Demo/local only | Select shared authoritative backend and sync/conflict model. |
| Demo dataset | Deterministic local seeder. Explicit runtime mode now gates startup/UI/service. | Simulation | Keep only in demo builds; production regression tests must stay green. |
| Booking and schedules | Local repository and database validation. | Functional local prototype | Move reservation/invariants to authoritative service; add concurrency/idempotency. |
| Payments and wallet | Payment ledger with a `PaymentGateway` boundary; the only provider is `SimulatedPaymentGateway` (labelled demo). Invoices paid only by settled transactions; reconciliation, refunds, desk payments (Phase 5). | Simulation behind a real boundary | Integrate a provider (tokens, webhooks) behind `PaymentGateway`; finance owner for refund policy. |
| Appointment reminders | Writes local reminder rows. Scheduler explicitly does not deliver them. | Planned/simulated delivery | Integrate supported channels and record actual delivery outcomes. |
| Notification center/broadcast | Local database rows and in-app stream. | Functional local prototype | Add authoritative recipient/permission checks and delivery service if promised. |
| Patient-staff messaging | Local database threads. No clinic queue, transport, SLA, or off-duty coverage. | Functional local prototype | Add service ownership, backend transport, coverage, retention, monitoring. |
| Home visits/referrals/tasks | Local workflow rows and UI. | Functional local prototype | Define owners/transitions/escalations and move to shared service. |
| Payment cards | Stores masked descriptors/metadata; no tokenized payment-provider vault. | Simulation | Never store PAN/CVC; use provider tokens if enabled. |
| PDF import | Local extraction; original stored in the database with SHA-256, issuer, patient, review status; authorized, audited reads (Phase 5). | Local prototype | Malware/content scanning and retention policy before any real documents. |
| PDF/report export | Authorized + audited exports; provenance block; selectable text; English/Arabic RTL (Phase 5). | Functional local prototype | Fluent Arabic review; shared-device download handling. |
| AI summaries | Optional direct Gemini call; deterministic fallback is demo-only. Production reports unavailable without a working live provider. | Hybrid; live provider optional, fallback simulated in demo only | Define consent, minimization, retention, evaluation. |
| Clinical scribe | Optional direct Gemini call; offline draft fallback is demo-only. Human save action required. | Hybrid; live provider optional | Keep review-only; add durable drafts, provenance, governance, outage tests. |
| Care Navigator | Direct network path when configured; deterministic responder is demo-only. Production reports live service unavailable. | Hybrid | Prohibit diagnosis claims; define privacy boundary. |
| Capacity forecast | Local calculation with optional AI-related paths. Inputs are not authoritative staffed capacity. | Prototype/decision support only | Define metrics and sources; remove overclaims; add stale/failure behavior. |
| No-show prediction | Bundled local model and feature extraction. | Local predictive prototype | Validate data, calibration, drift, fairness, intended use, and human action policy. |
| Sound cues | Local audio assets. | Functional device feature | Test device/user scoping and accessibility alternatives. |
| SMS/email/push settings | In-app delivery via outbox; browser alerts while the app is open (permission-aware); SMS/email disabled and labelled unavailable (Phase 5). | Honest partial capability | SMS/email provider and a push server for app-closed delivery. |
| Calendar export | Local ICS generation where exposed. | Functional local feature | Verify timezone, authorization, sensitive content, and target-platform behavior. |

## Release rule

Every enabled capability must be one of:

1. **Integrated:** authoritative service, ownership, monitoring, recovery, and
   acceptance evidence exist.
2. **Local-only:** UI states this clearly and no cross-device/live claim is made.
3. **Simulated:** available only in explicit demo mode and labeled as simulation.
4. **Disabled:** hidden behind a feature flag until its release requirements pass.

Unknown or silent fallback is not an acceptable fifth state.
