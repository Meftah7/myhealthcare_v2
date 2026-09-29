# Whole-App Review Traceability

Source: `MyHealth_Care_Whole_App_Review.md`  
Status date: 2026-09-28

Status meanings:

- **Mitigated:** repository evidence and focused tests cover the reviewed issue;
  later live-service architecture may still supersede the local implementation.
- **In progress:** relevant safeguards exist, but the finding's complete outcome
  or acceptance scenario is not yet satisfied.
- **Open:** no evidence yet establishes the required outcome.
- **Decision required:** implementation depends on clinical, operational,
  deployment, or vendor policy outside the repository.

| Finding | Status | Current evidence | Planned acceptance evidence | Workstream |
|---|---|---|---|---|
| F01 Password recovery ownership | Open / decision required | Local admin-queued reset avoids direct requester reset; no verified external ownership channel. | Expiring single-use verified recovery, abuse controls, screen-reader test. | Phase 1 identity/backend |
| F02 Patient record authorization | In progress | `security.md` records scoped record-detail fixes and negative tests. Local client remains the trust boundary. | Server/repository negative cross-account route, export, and mutation tests. | Phase 1 authorization |
| F03 Seed-version data wipe | Mitigated locally | Seeder now preserves existing nonzero-version data; production mode refuses all seeding/reset. | Populated upgrade fixture plus backup/restore rehearsal. | Phase 0 migrations |
| F04 Local-only clinic data | Open / decision required | Drift is device-local; no shared authoritative backend selected. | Two-session/device consistency, freshness, conflict, and reconnect tests. | Phase 2 shared data |
| F05 Urgent shortcut routing | Open / decision required | No approved clinical routing policy recorded. | Clinically approved urgent route with escalation and no future-slot substitution. | Phase 3 appointments |
| F06 Booking/reschedule invariants | In progress | Interval, ownership, schedule-grid, cancellation/reminder tests exist; current suite has appointment/schedule failures. | Atomic final-capacity race, overlap, closing boundary, idempotency, reschedule-loss tests all pass. | Phase 3 appointments |
| F07 Family booking identity | In progress | Family-link permissions and negative tests exist. | Acting account and dependent patient persist across booking, encounter, invoice, and export. | Phases 1 and 3 |
| F08 Durable encounter completion | Open | Draft provider and local completion exist; durability/atomicity not established. | Crash resume and partial-write retry produce one encounter and no duplicates. | Phase 4 clinical |
| F09 Trusted payment status | Open / decision required | Payment paths update local invoice state; no provider confirmation/reconciliation. | Provider webhook/server reconciliation and interruption/no-double-charge tests. | Phase 5 billing |
| F10 Real reminder delivery | Open / decision required | Reminder rows are scheduled locally; scheduler explicitly says delivery is separate. | App-closed delivery, permission denial, retry, reschedule, and cancellation evidence. | Phases 3 and 5 |
| F11 Staff/admin mark-read | In progress | Repository scopes updates by recipient ID; role UI behavior needs explicit regression coverage. | Each role marks only its own notification; zero-row/failure is visible; counts update. | First milestone |
| F12 Missing data looks reassuring | Open | Shared error components exist, but whole-app read-state coverage is not established. | Failed risk/queue/result reads retain safe context and never show empty/all-clear. | Phases 2 and 6 |
| F13 Clinical labels/provenance | Open / decision required | Some local range classification exists. | Clinical owner approves rules; unknown bounds/source/units/reviewer remain explicit. | Phase 4 clinical |
| F14 Referral responsibility | Open / decision required | Referral request states exist; accepted ownership/handover model is incomplete. | Send/clarify/accept/arrange/close plus shift handover and escalation tests. | Phase 4 referrals |
| F15 Large-text navigation | Open | Automated accessibility tests exist, but ordinary viewport/200% coverage is incomplete. | Navigation and key flows pass 200% text scale at supported viewports. | Phase 7 accessibility |
| F16 Rotating/past appointments | Open | Existing home carousel tests do not establish stable priority behavior. | Home presents one stable next appointment and excludes past visits. | Phase 3 patient home |
| F17 Cross-account state | In progress | Some preferences are user-keyed and security audit contains scoped fixes. | Logout/switch tests cover drafts, nutrition, chat, AI caches, files, and providers. | Phases 1 and 2 |
| F18 Nutrition claim mismatch | Open / decision required | Current feature calculates targets; diary scope is undecided. | Relabel calculator or ship dated patient-scoped diary with edit/history. | Phase 8 nutrition |
| F19 Forecast overclaim | Open | Local forecast/AI paths exist; definitions and real staffing inputs are not authoritative. | Metric definitions, sources, freshness, demand/capacity separation, failure states. | Phase 8 analytics |
| F20 AI/risk boundaries | In progress / decision required | Mock/live model IDs and fallbacks exist; governance and clinical validation do not. | Honest provenance, review-only drafts, evaluation, outage, privacy, and owner approval. | Phase 8 AI |
| F21 Message ownership | Open / decision required | Local patient-clinician threads exist; no service queue/SLA/coverage ownership. | Off-duty message enters owned queue with coverage and honest response expectation. | Phase 4 inbox |
| F22 Upload journey | In progress | Local PDF selection/extraction and provenance flags exist. | Authorized import review, source retention, recovery, bilingual export, round trip. | Phase 5 documents |
| F23 Timeout/mutation feedback | In progress | Timeout and result types exist; timeout baseline test fails and feedback is inconsistent. | Timeout warning/lock/restore plus failure-preserving mutation states pass. | Phases 1 and 6 |

## Ownership placeholders

Repository contributors can own implementation and automated evidence. The
following acceptance authorities must be named before a live pilot:

| Authority | Findings requiring approval |
|---|---|
| Product/release owner | Scope, platforms, F18, enabled integrations |
| Clinical-safety owner | F05, F13, F14, F20, urgent/results/prescribing policy |
| Security/privacy owner | F01, F02, F04, F09, F10, F17, F20, F22 |
| Clinic operations owner | F04, F06, F10, F14, F19, F21, support coverage |
| Accessibility/localization reviewers | F15 and full Arabic/assistive-technology gate |

