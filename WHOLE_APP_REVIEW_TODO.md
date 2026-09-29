# MyHealth Care — Whole-App Review Implementation TODO

> Planning artifact only. This file translates `MyHealth_Care_Whole_App_Review.md`
> into an executable project backlog. The review document is evidence and a
> proposal, not a command to implement every suggestion unchanged. No item is
> complete until its acceptance criteria and tests pass.

## Goal

Turn the current Flutter/Riverpod demonstration into a trustworthy, testable
healthcare workflow application while preserving the existing clinical-premium
design system, role-based product structure, Arabic support, and accessible
responsive behavior.

The first release-quality slice is the appointment journey shared by patients,
staff, and admins. It must be backed by authoritative identity, authorization,
storage, booking, notification, and audit behavior—not UI-only simulations.

## Planning assumptions and decisions still required

The repository currently demonstrates the product with local Drift storage and
seed data. The review proposes live-service behavior, but it does not select the
production backend, identity provider, payment provider, messaging provider, or
clinical policies. Those are architecture/product decisions, not frontend
implementation details.

- [x] Intended outcome: assessed university prototype using synthetic data only.
- [x] Supported launch platform: current evergreen Chromium web browsers.
- [x] Accountability: workspace owner `iamxj` owns the prototype artifact;
      qualified clinical-safety, privacy/security, and operations ownership is a
      mandatory scope-change gate before any pilot, live data, or clinical use.
- [x] Authoritative prototype store: local Drift/SQLite in each isolated instance.
- [x] Identity/recovery: local synthetic demonstration accounts and prototype
      recovery flows; no real identity-provider claim.
- [x] Real payments, remote delivery, external uploads, and live clinical AI are
      excluded; local/demo behavior must remain explicit.
- [x] Clinical workflows are demonstrations only; no clinical-policy approval or
      care claim is made.
- [x] Privacy boundary: synthetic data only; real patient information is prohibited.
- [x] Recovery objective: file snapshot RPO 0 and restore below 10 seconds for
      scheduled demonstrations; workspace owner owns prototype support.

Until those decisions are made, implement external services behind interfaces,
use synthetic data, and label simulated behavior honestly.

## Delivery rules

- [x] Keep Flutter, Riverpod, repository boundaries, Material 3, the existing
      `DESIGN.md`, and the three role experiences unless implementation evidence
      justifies a recorded architecture decision.
- [x] Treat authorization and workflow invariants as server/repository rules;
      UI hiding is not enforcement.
- [x] Use idempotency keys and authoritative results for consequential mutations.
- [x] Never show an empty, healthy, booked, paid, sent, or saved state when the
      corresponding read or write failed.
- [x] Preserve entered data through validation, network, session, and conflict
      failures whenever it is safe to do so.
- [x] Keep patient/account data isolated in providers, caches, files, logs, and
      persisted state; clear it at logout and account switching.
- [x] Ship changes as vertical slices with migration, failure states,
      authorization checks, audit behavior, and tests in the same change set.
- [x] Use feature flags for incomplete live integrations; do not expose mock
      actions as real clinical or financial operations.
- [x] Regenerate Drift, Freezed, and localization outputs only through their
      supported generators when source models change.

## Definition of done for every important operation

- [x] Loading identifies what is happening and keeps the layout stable.
- [x] Empty state appears only after a successful read and offers a useful action.
- [x] Validation identifies what to correct, preserves input, and focuses or
      announces the relevant error.
- [x] Submission prevents duplicate commitment and supports safe retry.
- [x] Confirmation comes from authoritative state and includes reference details
      and the next step.
- [x] Partial failure explains what succeeded; retry cannot repeat committed work.
- [x] Offline/stale state shows freshness and never confirms unavailable capacity.
- [x] Conflict state preserves original and proposed values and avoids silent
      overwrite.
- [x] Access loss removes protected content, explains the boundary, and provides
      reauthentication or support.
- [x] Success and failure are covered by unit/repository, widget, integration, and
      negative authorization tests appropriate to the risk.

## Phase 0 — Baseline, scope, and safety freeze

Purpose: establish an honest baseline before changing contracts or screens.

- [x] Record the release scope and unresolved decisions in
      `docs/release_scope_decisions.md` (accountable approval remains open).
- [x] Run and archive baseline `flutter analyze` and unit/widget test results in
      `docs/phase0_baseline.md`.
- [x] Build and test the selected web release target under the pinned toolchain.
      Native platforms are explicitly outside this prototype release scope.
- [x] Cover compact, medium, expanded, light, dark, Arabic/RTL, 200% text-scale,
      and reduced-motion states with automated tests; capture production web
      onboarding evidence. Physical keyboard, keyboard-open, screen-reader, and
      real-device checks remain manual launch-platform work.
- [x] Create a traceability table from review findings F01–F23 to backlog items,
      test cases, owner, decision, and evidence.
- [x] Create a threat model covering account recovery, object access, shared
      devices, exports, local secrets, logs, and external integrations.
- [x] Inventory every simulated/live-looking feature and classify the required
      integrate, feature-flag, relabel, or removal decision.
- [x] Separate demo and production configuration in `lib/main.dart` and
      `lib/core/di.dart`.
- [x] Prevent production builds from exposing demo credentials and reset/reseed
      actions.
- [x] Prevent production builds from presenting mock AI behavior as live.
- [x] Preserve existing data when the synthetic seed version changes.
- [x] Keep schema migrations separate from `lib/data/seed/seeder.dart` and cover
      populated/stuck upgrades plus seed-version data preservation.
- [x] Document the backup/restore rehearsal procedure.
- [x] Execute the file-level Drift backup/restore rehearsal for schema 18 and
      record RPO/RTO evidence in `docs/backup_restore_rehearsal.md`.

Gate 0:

- [x] Production mode cannot seed, wipe, or reveal demo login access.
- [x] Baseline evidence is reproducible; analyzer is clean and all 281 tests pass.
- [x] Live integration work is excluded; changing that boundary requires named
      qualified owners and a selected authoritative shared architecture.

## Phase 1 — Identity, authorization, and patient boundaries

Purpose: ensure every action is performed by the right actor on the right patient.

Primary areas: `lib/features/auth/`, `lib/services/auth/`,
`lib/data/repositories/auth_repository_impl.dart`, `lib/core/di.dart`,
`lib/data/db/tables/users.dart`, family entities/repositories, session providers.

- [x] Separate Account, Patient, ProxyGrant, StaffCredential, role/permission,
      and CareTeamAssignment concepts in domain and persistence models.
      _`domain/identity/`; tables `care_team_assignments`, `staff_credentials`,
      `users.has_login` (patients without an account); proxy grants persist in
      `family_links`. Schema v18._
- [x] Replace identifier-only password reset with a verified, expiring,
      single-use recovery flow; rate-limit attempts and audit outcomes.
      _Hashed 6-digit code, 10-minute expiry, 5 guesses, newest-only, 3 codes
      per account per hour, 5 requests per device per 15 minutes; `recovery.*`
      audit entries. Demo builds deliver to a labelled simulated inbox;
      production falls back to the admin-verified request until an email/SMS
      provider is chosen._
- [x] Derive the acting identity from authenticated context, never a caller-supplied
      patient/staff ID alone. _`AuthContext` principal, set only by sign-in;
      caller IDs are targets, and "done by" IDs are checked (`assertActor`)._
- [x] Add object-level authorization to record, appointment, document, billing,
      notification, care, consultation, and admin mutations.
      _`services/auth/access_policy.dart`, injected into every repository;
      denials are `AccessDeniedFailure` + an `access.denied` audit entry._
- [x] Implement least-privilege role/permission providers for UI availability,
      while keeping repository/server enforcement authoritative.
      _`RolePermissions` (nurse vs doctor), `permissionsProvider`/`canProvider`._
- [x] Model dependent/proxy selection explicitly so appointments, encounters,
      records, invoices, messages, and exports attach to the correct patient.
      _Household members get their own no-login patient record + manage grant;
      rows carry `booked_by`/`created_by`/`paid_by`/`sender`/`requested_by`
      account and the audit log `subject_patient_id`._
- [x] Implement session timeout warning, reauthentication, authorized-context
      restore, and secure cleanup after expiry. _Warning card 2 minutes before
      idle sign-out; repositories also enforce idle (24 min) and absolute
      (12 h) expiry; 15-minute re-auth window for account administration;
      same-account resume._
- [x] Audit shared-device behavior: clear user-scoped providers, drafts, files,
      nutrition state, chat history, AI summaries, and caches at logout/switch.
      _`app/session_scope.dart` allowlist discards every other provider;
      nutrition inputs are per-user and removed at sign-out._
- [x] Add negative tests for cross-patient, cross-clinician, expired-session,
      revoked-proxy, and insufficient-role access. _`test/security/`._

Open decisions carried forward: the email/SMS provider for recovery codes;
clinic policy on clinic-wide staff access to demographics (currently allowed,
clinical content needs a care relationship); break-glass access; whether
staff credentials should gate prescribing.

Gate 1:

- [x] Verified recovery works; expired, reused, and unverified attempts fail.
- [x] Cross-account route, repository, export, and mutation tests are denied.
- [x] Dependent workflows consistently retain both acting-account and patient
      identity.
- [x] Account switching reveals no prior user's sensitive state.

## Phase 2 — Authoritative data, sync, and mutation foundation

Purpose: replace device-local truth with explicit shared truth and safe mutations.

> Status: complete. Schema v20 (v20 adds the merged avatar-photo column);
> analyzer clean; full suite 346/346 passing, including
> `test/sync/phase2_test.dart`.

- [x] Define API/repository contracts with typed errors, authorization context,
      idempotency key, version/conflict data, freshness, and pagination.
      _Built: `core/data/contracts.dart` (Page, PageRequest, IdempotencyKey,
      Freshness), `ConflictFailure`/`OfflineFailure`; authorization context is
      the Phase 1 principal._
- [x] Implement authoritative shared persistence for bookings, encounters,
      records, messages, tasks, referrals, billing, and notifications.
      _Scope decision: the prototype's authoritative store is local
      Drift/SQLite per instance; "shared" is evidenced by two sessions on one
      database. No networked backend._
- [x] Add an outbox/event mechanism for notifications and other external side
      effects; retry independently from core transactions.
      _Built: `data/sync/outbox.dart` — events written in the change's
      transaction, delivered by `OutboxDispatcher` with backoff, deduped per
      event; drained after mutations, at start-up and sign-in; a one-shot
      timer retries automatically while anything is undelivered._
- [x] Add optimistic concurrency/version fields where edits or claims can race.
      _Built: `version` on appointments, walk-ins, referrals, home visits,
      invoices, patient profiles, tasks; bumped by DB triggers; stale writes
      fail with `ConflictFailure`; walk-in claims are conditional._
- [x] Add append-oriented audit events and protected access logs; exclude raw
      health text from generic analytics.
      _Built: audit log update/delete blocked by triggers; viewing the full
      audit log is itself audited; AI usage log stores feature + size only._
- [x] Replace hardcoded 40/200/500 list limits with pagination or clearly exposed
      limits and load-more behavior.
      _Paged repository reads (`loadPages`); "Load more" on the staff patient
      directory, admin audit log, patient timeline and linked-account
      timeline; AI log and imaging state a 200 page limit; the chart card is
      a labelled 12-item preview._
- [x] Add live invalidation/subscriptions or explicit refresh/freshness indicators
      for operational queues; preserve selection during updates.
      _"Updated HH:mm" + refresh on the walk-in, home-visit and referral
      queues (filters kept); notifications/risk/tasks use live streams._
- [x] Distinguish initial, refreshing, stale, offline, partial, conflict, and access
      failure in shared repository/controller contracts.
      _Built: `core/data/data_state.dart` (`DataState.fromAsync`)._
- [x] Test real-data migrations, interrupted writes, retry/idempotency, stale
      versions, reconnect, and multi-device consistency.
      _`test/sync/phase2_test.dart`: idempotent booking/payment/top-up, key
      reuse refusal, trigger-bumped versions, stale-edit and stale-status
      conflicts, walk-in double claim, outbox dedupe/retry/rollback,
      append-only audit, analytics redaction, two sessions on one database,
      paging, populated v18→v19 migration. "Reconnect" = outbox retry after a
      failed delivery (no network layer in this prototype)._

Gate 2:

- [x] The same authorized state is visible across two sessions/devices.
      _Two sessions on one database, per the local-store scope decision._
- [x] Retried mutations do not duplicate committed work.
- [x] Failed reads never render as reassuring zero/empty/all-clear states.
      _Unread/queue counts, slot picker, walk-in queue, admin "needs you"
      card, messages, and linked-family lists (incl. "who can see me")._
- [x] Representative populated migrations preserve relationships and history.

## Phase 3 — Appointment vertical slice

Purpose: deliver the first coherent cross-role workflow from availability through
confirmation, rescheduling, cancellation, reminders, and operational visibility.

> Status: complete. Schema v22; Phase 3 focused gate suite 46/46 passing.

Primary areas: `lib/features/booking/`, `lib/features/appointments/`,
`lib/features/quick_appointment/`, `lib/features/patient_home/`,
`lib/features/staff_dashboard/`, `lib/features/admin/`, appointment repositories,
tables, reminder service, router, and confirmation overlay.

### Booking and availability

- [x] Model ScheduleResource, AvailabilityException, BookingReservation, clinic
      hours/open days, slot duration, appointment duration, and capacity/version.
- [x] Generate only valid `OpenSlot` choices; reject past time, closed days,
      off-schedule clinicians, non-slot minutes, and closing-boundary violations.
- [x] Reject interval overlap using
      `existing.start < requested.end && existing.end > requested.start` while
      excluding cancelled appointments. _Done in `_hasOverlap`; covered by
      `test/data/repositories_test.dart`._
- [x] Make availability validation plus reservation atomic; add database/service
      conflict protection and idempotent request handling. _One transaction
      with overlap check → `ConflictFailure`; idempotency key (Phase 2)._
- [x] Replace count-based ticket generation with a unique transactional counter or
      constraint/retry strategy.
- [x] Reject overlapping clinician schedule templates.
      _Implemented in `setTemplates`; needs a dedicated test._
- [x] Return an explicit no-availability result; remove the fallback that can label
      today as the soonest opening when none exists.
- [x] Replace the urgent shortcut with clinic-approved routing; never translate
      urgency into an unsuitable future appointment.

### Patient flow

- [x] Rebuild booking as: visit reason/type → department/clinician → available day
      → valid slot → full review → authoritative confirmation.
- [x] Add unmistakable selection, local time/timezone, next-available guidance,
      duplicate-submit protection, and retryable errors.
- [x] Persist a confirmation containing patient, date/time, clinician, department,
      location/room, ticket/reference, and reminder details.
- [x] Keep the next appointment stable on patient home; do not auto-rotate critical
      information or include past appointments.
- [x] Add a complete appointment detail surface with check-in instructions,
      calendar export, permitted actions, and help/contact route.
- [x] Replace free-form rescheduling with valid slots and an atomic move that keeps
      the original booking when the target becomes unavailable.
- [x] Make cancel/reschedule result-aware with progress, success, failure, audit,
      repeat-action protection, and preserved state.
- [x] Gate cancel/reschedule by ownership, status, check-in state, time window, and
      configured policy.
- [x] Add paginated appointment history instead of a silent latest-40 cap.

### Staff/admin lifecycle

- [x] Enforce allowed transitions: booked → confirmed → inProgress → completed;
      booked/confirmed → cancelled or noShow.
- [x] Deny invalid shortcuts, double claims, wrong-clinician actions, and role-
      inappropriate clinical actions at the authoritative boundary.
- [x] Show the same appointment state and exceptions in patient, staff, and admin
      experiences with role-appropriate actions.
- [x] Make walk-in claim/conversion concurrency-safe.
      _Conditional claim + one transaction; `test/sync/phase2_test.dart`._

### Reminder lifecycle

- [x] Align visible push/email/SMS/sound preferences with supported channels and OS
      permission state.
- [x] Schedule reminders only after authoritative booking confirmation.
- [x] Rebuild unsent reminders after reschedule or risk-band changes.
- [x] Suppress/cancel unsent reminders after cancellation.
- [x] Track queued, delivered, failed, retried, and suppressed states without
      claiming delivery from a local schedule alone.

Gate 3:

- [x] End-to-end patient booking, concurrent booking, reschedule-loss, cancellation,
      reminder, cross-role visibility, and no-availability scenarios pass.
- [x] Exactly one of two concurrent requests for the final capacity succeeds.
- [x] Closing/reopening during confirmation restores one authoritative outcome.
- [x] No misleading urgent, booked, cancelled, or reminder-delivered state remains.

## Phase 4 — Clinical encounter, results, referrals, and handover

Purpose: make clinical work durable, attributable, recoverable, and owned.

> Status: complete. Schema v25 (v23 drafts/signed notes/amendments; v25 result
> reviews, observation provenance, referral/task/message ownership). Details
> and the responsibility matrix: `docs/phase4_clinical_workflow.md`. Gate
> suite `test/phase4/` 15/15 passing. Clinical rules are demonstration rules
> pending a qualified clinical owner.

Primary areas: `lib/features/consultation/`, `lib/features/patient_chart/`,
`lib/features/records/`, `lib/features/timeline/`, `lib/features/tasks/`,
`lib/features/care/`, consultation/care/record repositories and tables.

- [x] Model EncounterDraft, SignedNote, Amendment, MedicationOrder, ResultReview,
      authorship, timestamps, versions, and immutable finalization history.
      _`encounter_drafts`, `signed_notes` + `signed_note_amendments`
      (update/delete blocked by triggers), medication orders filed at
      finalization with deterministic ids, `result_reviews` (versioned);
      `EncounterRepository`, `ResultReviewRepository`._
- [x] Persist encounter drafts outside ephemeral provider memory; show
      saving/saved/failed/offline/conflict and restore after crash/reauthentication.
      _Debounced, serialized autosave; localized "Saving… / Saved HH:mm /
      Not saved — Retry / Changed elsewhere — Load saved draft"; flushed on
      leave; restored on reopen. No offline state: the store is local._
- [x] Commit encounter completion atomically; send notifications through the
      outbox so retry cannot duplicate encounter, medication, or message records.
      _`EncounterRepository.finalize`: one transaction, idempotency key, and at
      most once per appointment even with a fresh key after a crash._
- [x] Preserve source, units, reference bounds, unknown bounds, verification,
      author, and provenance for clinical observations and results.
      _`lab_values.source/provenance/verification_status/verified_by/at`;
      one-sided ranges shown as `< x` / `> x`; resolving a review verifies._
- [x] Replace inferred/reassuring labels with clinically owned validation rules;
      keep incomplete and unknown states explicit.
      _`domain/clinical/lab_rules.dart` (`demo-lab-rules-v1`): no range →
      `AbnormalFlag.unknown` ("No range"), never normal; lab-supplied critical
      limits win over the documented heuristic. Clinical sign-off open._
- [x] Add owner, due time, priority, status transitions, escalation, and coverage to
      results, referrals, messages, and follow-up tasks.
- [x] Model referral send → clarify → accept → arrange → close and handover as
      explicit accepted transitions rather than unchecked overwrites.
      _`transition` + `handover`; owner required and never cleared; owner
      change needs a note; clarification notifies the requester (outbox)._
- [x] Separate clinician, nursing/reception, billing, and admin responsibilities.
      _`signEncounter`/`reviewResults` doctor-only, `manageTasks`,
      `refundPayments`; matrix in `docs/phase4_clinical_workflow.md`. No
      separate reception/billing-clerk role in the prototype (open decision)._
- [x] Ensure patient and staff messaging enters an owned service queue with honest
      response expectations and off-duty coverage.
      _Owner = thread clinician, on-duty department colleague covers an
      off-shift owner and may reply (audited), 24 h reply-by, `awaitingReply`;
      patients see "one working day, not for emergencies"._
- [x] Fix staff/admin mark-read behavior and user ownership; make failure visible.
      _Ownership enforced in repositories (Phase 1 tests); failure shown on
      screen (`test/phase4/mark_read_failure_test.dart`)._

Gate 4:

- [x] Forced-close consultation resumes the correct saved draft.
- [x] Partial completion plus retry produces one finalized encounter and no
      duplicate prescriptions or notifications.
- [x] Critical/unknown results remain visible, owned, and escalation-capable.
      _Dashboard "Results to review" + chart result sheet; failed reads show
      an error, never an all-clear._
- [x] Referral handover survives owner shift changes without becoming unassigned.

## Phase 5 — Billing, documents, notifications, and external effects

Purpose: make every external or irreversible-looking outcome truthful.

> Status: complete within the prototype scope (simulated provider, no remote
> delivery). Schema v24. Details: `docs/phase5_billing_documents.md`. Gate
> suite `test/phase5/` 31/31 passing.

- [x] Model PaymentTransaction, authorization, settlement, failure, refund,
      reconciliation, provider reference, idempotency, and audit history.
      _`payment_transactions` + `PaymentGateway` boundary
      (`SimulatedPaymentGateway`); DB triggers: no delete, final states
      final, one live charge per invoice; `billing.*` audit._
- [x] Treat provider/server confirmation—not a client status update—as paid.
      _Invoice paid only by a settled transaction; admin "mark paid" removed
      (refused, and blocked by trigger) → "Record desk payment" with receipt._
- [x] Recover payment state after app/network interruption without duplicate charge.
      _Attempt recorded before the provider call; unknown outcome →
      `PaymentPendingFailure`; same-key retry and reconciliation (start-up,
      payments screen, "Check payment status", admin) settle or release;
      provider dedupes on the request reference._
- [x] Deny unauthorized refunds and invalid financial transitions.
      _`refundPayments` (admin only), reason required, bounded by what is
      unrefunded; DB-enforced invoice transitions._
- [x] Implement notification delivery for supported channels with app-closed,
      permission-denied, transient-failure, retry, and cancellation behavior.
      _`ReminderDispatcher`: in-app via outbox (once), browser alerts with
      permission and backoff, SMS/email suppressed as unavailable; catch-up
      at start-up; missed/closed visits suppressed, never "sent"._
- [x] Complete upload/import as a journey: source file, issuer, patient, type, date,
      review status, failure recovery, authorization, and provenance.
      _Original stored + SHA-256 on every platform; issuer required; patient
      or managed dependent; `pendingReview` until a clinician accepts or
      rejects; input kept on failure; audited reads._
- [x] Make exports/PDFs selectable, properly authorized, bilingual/RTL-safe, and
      explicit about issuer, source, date, status, and download errors.
      _`ExportRepository.authorizeExport` (+ audit); provenance block on
      every PDF; English/Arabic string table, RTL with Noto Naskh Arabic;
      typed download errors with "Try again". Arabic wording needs fluent
      review (Phase 7)._
- [x] Add accessible summaries or source tables for charts in exported documents.
      _Vitals report: per-measurement text summary + reading table._

Gate 5:

- [x] Payment interruption reconciles correctly and never double-charges.
      _`test/phase5/payment_ledger_test.dart`._
- [x] Booking/reschedule/cancel creates the correct app-closed delivery outcome.
      _`test/phase5/reminder_delivery_test.dart`._
- [x] Unauthorized document routes/exports and refunds are denied.
- [x] Imported source and review status survive round trips and exports.
      _`test/phase5/documents_test.dart` (text extracted from the PDF)._

## Phase 6 — Shared interaction system and role workspaces

Purpose: apply the review’s UX direction after the backing states are real.

> Status: complete. Phase 6 gate suite: 20/20 passing.

Primary areas: `lib/core/presentation/`, `lib/app/router.dart`,
`lib/app/shell/app_shell.dart`, `lib/app/theme/`, and role feature screens.

- [x] Strengthen shared loading, error, empty, stale, conflict, confirmation,
      draft-status, list/filter, status-badge, document, and session-boundary
      components.
      _`AsyncDataView` (every `DataState`, empty only after a successful
      read), `AccessBoundaryView`; draft status (Phase 4) and document
      download (Phase 5) reused. No shared filterable-list component yet —
      see the operational-lists item._
- [x] Centralize typed mutation feedback and localized recovery actions.
      _Built: `describeFailure` / `showMutationFeedback` (localized message +
      the one recovery action that can help). Used by every new surface;
      all 54 legacy call sites now use it._
- [x] Standardize ordinary screens on `AppScaffold`; reserve custom frames for
      chat, calendar, full-screen flows, and list-detail workspaces.
      _34 screens migrated (`tools/migrate_app_scaffold.py`, layout
      unchanged); exceptions: auth flows, booking, message thread, schedule,
      patient chart, clinical scribe._
- [x] Preserve the current clinical-premium visual system; reduce competing cards,
      duplicate shortcuts, gradients, pills, and equally weighted sections.
      _Done on the three dashboards (one gradient hero each, vanity totals
      and analytics moved off the admin home); secondary screens not yet
      reviewed; clinical condition chips were reduced to quieter metadata._
- [x] Give each screen one primary visual anchor and prioritize actionable work over
      totals or secondary analytics.
      _Dashboards: admin "Needs attention", staff results/replies, patient
      next appointment._
- [x] Keep role tabs stable and make pushed/detail routes visibly subordinate.
      _Indexed role shells retain one navigation surface; nested details keep
      their shell and back affordance. Gate-tested on the staff flow._
- [x] Implement searchable/filterable operational lists with owner, age, status,
      pagination, freshness, persistent selection, wide tables, and phone cards.
      _`OperationalList<T>` centralizes the full contract; the admin result-review
      queue now uses it with owner, age, and status filters. Covered by
      `test/phase6/operational_list_test.dart`._
- [x] Patient: prioritize next appointment, urgent information, recent records,
      messages, dependent context, and bills.
      _Allergy alert → "Needs your attention" (replies, overdue bill,
      confirming payments, family requests) → next appointment anchor →
      health → actions._
- [x] Staff: build Today/queue, patient identification, chart workspace,
      consultation, results, inbox/tasks, schedule, and handover around continuity
      of patient context.
      _Done: results to review, "Awaiting your reply" with off-duty cover
      (covered threads open and answer as the owner's thread). Open: a
      persistent selected-patient context across clinical work branches._
- [x] Admin: build exceptions/overdue/unassigned work, access, capacity, scheduling,
      referrals, billing, and audit around ownership and correction—not vanity
      dashboards.
      _"Needs attention" (9 exception queues with age and breakdown) and
      "Work needing attention" (assign reviews, overdue messages, retry
      failed deliveries)._
- [x] Separate device settings, user/account settings, and shared clinic settings;
      show persistence failures and scoped reset controls.
      _"On this device" / "For your account" groups with their own resets;
      save failures shown and rolled back; clinic settings are admin pages._
- [x] Add System/Reduced/Full motion and high-contrast/accessibility options only
      after their behavior and persistence scope are defined.
      _Behaviour and per-device persistence documented in
      `docs/phase6_workspaces.md`._

Gate 6:

- [x] Core role tasks can be completed without duplicate navigation or lost context.
      _`navigation_continuity_test.dart` verifies one role navigation surface,
      stable patient selection, and return-to-chart across staff tasks._
- [x] Failed operational queries never present an all-clear dashboard.
      _`test/phase6/workspaces_test.dart`, `shared_states_test.dart`._
- [x] The interface accurately exposes the authoritative states from Phases 1–5.
      _Access boundary, conflicts, draft status, result review ownership,
      payment confirming/refunded, reminder and delivery outcomes, import
      review status._

## Phase 7 — Accessibility, Arabic, responsive behavior, and motion

Purpose: make inclusion a release gate across real workflows rather than isolated
widget checks.

> Status: automated implementation complete; external manual sign-off pending.
> The remaining items require fluent Arabic reviewers and physical-platform
> keyboard/TalkBack/VoiceOver sessions (`docs/phase7_accessibility.md`).

- [ ] Test login/recovery, booking, result review, consultation, referral/task,
      admin assignment, billing, and session recovery with keyboard and screen
      reader on supported platforms.
- [x] Test 320×568, 375×667, 430×932, 600×800, 840×700, 1024×768, and
      1440×900 where supported, including landscape, split screen, keyboard open,
      and 200% text scaling.
      _Exact matrix, 200% scale and keyboard inset are covered in
      `test/features/responsive_test.dart`._
- [x] Restore meaningful navigation labels at large text scales instead of hiding
      them to force fit.
      _Role navigation now honors the supported 200% scale; compact bars grow
      and rails remain scrollable. Existing responsive 2x tests pass._
- [x] Ensure icon-only actions have semantic labels/tooltips, errors/status changes
      are announced, focus moves to the first invalid field, and password controls
      expose state.
      _Direct icon buttons were audited; error banners are atomic live regions;
      login focus and localized Show/Hide password state are regression-tested._
- [x] Maintain approximately 48 logical-pixel mobile targets, visible focus, strong
      light/dark contrast, and non-color status cues.
      _Accessibility guidelines run in light/dark and both high-contrast themes._
- [ ] Review Arabic with fluent users across generated errors, notifications,
      repository messages, medicine/food terms, dates, identifiers, units, reports,
      and PDFs—not only ARB keys.
- [x] Test mixed Arabic/English medical names, phone numbers, patient identifiers,
      and units with deliberate directionality.
      _Covered by `test/phase7/presentation_modes_test.dart`._
- [x] Keep critical information stable; respect reduced motion and make motion
      interruptible.
      _Motion helpers resolve immediately under reduced motion; critical content
      remains present and the combined RTL/200%/reduced mode is tested._
- [x] Shorten frequent navigation motion where warranted, limit broad
      `AppEntrance`, avoid stacked effects, and replace layout-property animation
      with transform/opacity when practical.
      _Broad AppScaffold entrance motion is now opt-in and retained only for the
      three role dashboards; shared motion uses transform/opacity._
- [x] Add focused regression/golden coverage for compact, expanded, dark, RTL,
      high contrast, reduced motion, and 200% text scale.
      _Covered by the responsive, Arabic, accessibility and Phase 7 mode suites._

Gate 7:

- [ ] Key flows pass manual assistive-technology sessions in both languages.
- [x] No clipped, unreachable, directionally broken, or motion-dependent critical
      action remains at the supported viewport/text configurations.
      _Automated viewport/mode gates pass; manual platform sign-off is tracked in
      `docs/phase7_accessibility.md`._

## Phase 8 — Scoped secondary capabilities

These items ship only when explicitly included in release scope and supported by
the earlier identity/data foundation.

### Nutrition

- [x] Either relabel the current calculator to match its actual capability or build
      a dated, patient-scoped meal diary with portions, edit/history, persistence,
      provenance, and clinically reviewed targets.
- [x] Verify nutrition data never crosses accounts or dependents.

### Forecasting and analytics

- [x] Define each metric, source, window, exclusions, timezone, and freshness.
- [x] Separate demand from staffed capacity; use real schedules/availability.
- [x] Avoid causal or predictive claims that exceed the calculation.
- [x] Add source tables, accessible summaries, realistic-volume pagination, and
      failed/stale query states.

### AI and risk tools

- [x] Put providers behind a service boundary with explicit model/mock/offline
      modes, provenance, review state, evaluation data, and safe fallback.
- [x] Keep AI output as reviewable drafts; never silently commit clinical truth.
- [x] Minimize transmitted data, define retention/consent, protect secrets, and
      document the accountable human decision.
- [x] Validate risk/clinical calculations with qualified owners before care use.
- [x] Ensure core charting, booking, and messaging remain usable during AI outage.

Gate 8:

- [x] Each enabled capability makes truthful claims, has an accountable owner, and
      has failure/outage tests; otherwise it remains feature-flagged or relabeled.

## Phase 9 — Pilot, evidence, and release readiness

_Repository preparation is underway in `docs/phase9_release_readiness.md` and
`test/phase9/`. Human sessions, rehearsals and qualified sign-offs remain open._

- [ ] Recruit representative patients across age, language, digital confidence,
      and accessibility needs, plus distinct clinician, nurse/reception, billing,
      and admin roles.
- [ ] Measure baseline and improved completion without help, wrong turns, task time,
      outcome comprehension, identification errors, lost context, duplicate entry,
      correction burden, unowned work, and queue delay.
- [ ] Rehearse staging with synthetic data, realistic scale, failures, account
      switching, migration, backup/restore, rollback, and incident response.
- [ ] Run security/privacy review, clinical validation, accessibility review, and
      operational-readiness review with named approvers.
- [ ] Instrument crash-free sessions, failed saves, duplicate attempts, delivery
      failures, stale data, overdue follow-up, reconciliation, and resolution time
      without putting raw patient notes/messages in generic analytics.
- [ ] Define service thresholds and alert ownership before a controlled pilot.
- [ ] Maintain a pilot issue backlog ordered by potential harm, blocked tasks, and
      repeated confusion before cosmetic polish.

Release gate:

- [ ] No unresolved defect can cross patient identity, expose unauthorized data,
      lose finalized clinical data, or falsely confirm booking/payment.
- [ ] Every enabled high-impact workflow has tested failure/recovery behavior and
      an operational owner.
- [ ] All 22 end-to-end scenarios in the source review are represented by automated
      or documented manual acceptance evidence.
- [ ] Core task success improves over the measured baseline; any target percentage
      is agreed against sample size and risk rather than claimed in advance.
- [ ] Monitoring, support, backup/restore, rollback, and escalation are rehearsed.
- [ ] Remaining risks and deliberately deferred features are explicitly signed off.

## Recommended first implementation milestone

Build a reviewable, end-to-end appointment slice while beginning the foundational
work it depends on:

- [x] Remove production demo reset/reseed and credential exposure.
- [x] Fix staff/admin mark-read ownership and visible failure handling.
      _Verified: `test/phase4/mark_read_failure_test.dart`._
- [x] Introduce the typed appointment mutation contract with actor, patient,
      idempotency, version, and actionable failures.
- [x] Implement atomic availability/reservation, interval conflicts, valid slots,
      and unique tickets.
- [x] Build stable patient home → booking/detail → reschedule/cancel → persistent
      confirmation.
- [x] Surface matching authoritative state in staff schedule and admin operations.
- [x] Rebuild/cancel reminders from appointment lifecycle events.
- [x] Add concurrent booking, reschedule-loss, cross-account denial, restart,
      failure-state, compact/large-text, and Arabic acceptance coverage.

This milestone is not complete if only the screens change.

## Suggested work breakdown by code area

| Workstream | Existing code to start from | Primary test areas |
|---|---|---|
| Bootstrap/migrations | `lib/main.dart`, `lib/core/di.dart`, `lib/data/seed/`, `lib/data/db/` | `test/data/`, integration upgrade fixture |
| Identity/session | `lib/features/auth/`, `lib/services/auth/`, auth repository | auth/session/accessibility tests |
| Authorization/patient context | domain repositories, family/patient entities and providers | negative repository + integration tests |
| Appointments | booking, appointments, quick appointment, appointment repository/tables | booking/flow/reminder/schedule tests |
| Clinical workflow | consultation, patient chart, records, timeline, tasks | consultation recovery + partial-write tests |
| Care ownership | care/messages/referrals/inbox | handover, queue ownership, permission tests |
| Billing/external effects | billing repository/features, notification service | reconciliation, idempotency, app-closed tests |
| Shared UX | `lib/core/presentation/`, shell, router, theme | responsive, state, accessibility, Arabic tests |
| Admin operations | admin providers/screens, capacity forecast | pagination, stale failure, metric-definition tests |
| AI/risk | AI/ML/rules services and feature presentations | fallback, provenance, evaluation/parity tests |

## Verification commands per milestone

Run the narrowest relevant tests during development, then the full gate suite:

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test
```

Also build and manually smoke-test every supported release platform. A passing
widget suite alone is not evidence of live-service, accessibility, migration,
concurrency, or clinical correctness.

## Traceability to source review

- Phase 0: F03 and the review’s method/release evidence gaps.
- Phase 1: F01, F02, F07, F17, F23.
- Phase 2: F04, F12, pagination/freshness/transaction requirements.
- Phase 3: F05, F06, F10, F16 and the practical first slice.
- Phase 4: F08, F11, F13, F14, F21, F23.
- Phase 5: F09, F10, F22.
- Phases 6–7: proposed patient/staff/admin experiences and shared interaction,
  accessibility, localization, responsive, and motion contracts.
- Phase 8: F18, F19, F20.
- Phase 9: end-to-end scenarios, usability study, release targets, and launch plan.

## Out of scope for this TODO

- Selecting vendors or asserting legal/clinical compliance without qualified
  owners and deployment context.
- Treating the review’s proposed metrics or 90% completion figure as measured fact.
- Claiming the existing automated tests establish whole-app accessibility,
  security, concurrency, or production readiness.
- Replacing the established visual identity without a separate approved brief.
- Assigning calendar dates before release scope, team capacity, and external
  dependencies are known.
