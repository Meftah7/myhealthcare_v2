# Phase 9 release-readiness evidence

Status: engineering evidence complete except the integration-test run;
human validation and sign-off open
Approved scope: synthetic-data, Chromium-web university prototype

A real-data or clinical pilot is not authorized by this document. It reopens
Phase 0 and requires named clinical-safety, privacy/security and operations
owners plus an authoritative shared backend.

## Acceptance scenario matrix

Paths are relative to the repository root. "automated" means the listed
tests exercise the scenario on every `flutter test` run.

| # | Scenario | Evidence | State |
|---:|---|---|---|
| 1 | Sign in, MFA, idle warning and resume | `test/features/auth_flow_test.dart`, `test/features/session_timeout_test.dart`, `test/security/session_security_test.dart` | automated |
| 2 | Recovery request without account disclosure | `test/security/recovery_test.dart` | automated |
| 3 | Cross-account record access is denied | `test/security/authorization_test.dart` | automated |
| 4 | Guardian books for the correct dependent | `test/features/family_link_test.dart` | automated |
| 5 | Find and book an available appointment | `test/features/booking_flow_test.dart`, `test/features/booking_test.dart` | automated |
| 6 | Concurrent booking cannot double-book | `test/phase3/appointment_concurrency_test.dart` | automated |
| 7 | Reschedule/cancel updates every role | `test/features/integration_flow_test.dart`, `test/features/family_link_test.dart` | automated |
| 8 | Reminder changes follow appointment changes | `test/services/reminder_scheduler_test.dart`, `test/phase5/reminder_delivery_test.dart` | automated |
| 9 | Urgent request follows approved routing | no clinical route approved | blocked by scope |
| 10 | Queue to chart to consultation preserves context | `test/phase6/navigation_continuity_test.dart`, `test/phase6/workspaces_test.dart` | automated |
| 11 | Consultation draft survives interruption | `test/phase4/clinical_workflow_test.dart` | automated |
| 12 | Finalizing consultation cannot duplicate orders | `test/phase4/clinical_workflow_test.dart` | automated |
| 13 | Results are assigned, reviewed and handed over | `test/phase4/clinical_workflow_test.dart` ("a review can change owner but never lose one") | automated |
| 14 | Message ownership transfers during absence | `test/phase4/clinical_workflow_test.dart` ("a message to an off-duty doctor gets cover and a reply-by time; the cover can answer it") | automated |
| 15 | Referral is accepted, arranged and closed | `test/phase4/clinical_workflow_test.dart` ("referrals keep an owner through handover": clarify → accept → handover → arrange → close) | automated |
| 16 | Payment uncertainty reconciles honestly | `test/phase5/payment_ledger_test.dart`, `test/features/payments_flow_test.dart` | automated |
| 17 | Import retains provenance and review state | `test/phase5/documents_test.dart` | automated |
| 18 | Nutrition stays account/dependent scoped | `test/features/health_records_nutrition_test.dart`, `test/security/authorization_test.dart` | automated |
| 19 | Analytics exposes source, freshness and failures | `test/phase8/capability_scope_test.dart`, `test/phase6/shared_states_test.dart` | automated |
| 20 | AI outage does not block core work | `test/services/ai_fallback_test.dart`, `test/phase8/ai_governance_test.dart` | automated |
| 21 | English/Arabic, keyboard, screen reader and 200% text | `test/features/arabic_regression_test.dart`, `test/features/accessibility_test.dart`, `test/phase7/presentation_modes_test.dart`; assistive-technology sessions | automated + manual required |
| 22 | Backup, migration, restore, rollback and incident response | `test/data/backup_restore_rehearsal_test.dart`, `test/data/stuck_migration_test.dart`, `test/sync/phase2_test.dart`, `test/phase9/incident_rehearsal_test.dart`; rollback on hosted build | automated + manual required |

## Pilot measurement instrument

Capture role, language, accessibility setup, completion without help, assistance,
wrong turns, elapsed seconds, outcome comprehension, identification errors, lost
context, duplicate entry and correction effort. For operational tasks also
capture unowned-work minutes and queue delay.

Baseline and improved sessions use the same tasks and comparable participants.
Targets are agreed only after sample size, baseline and risk are recorded. Raw
recordings and notes are not generic analytics. Templates:
`docs/phase9_usability_kit.md`.

## Staging and incident rehearsal

Automated (every test run, synthetic data):

- Populated migration: `test/sync/phase2_test.dart`, `test/data/stuck_migration_test.dart`.
- Backup and restore with relationships intact, under 10 seconds:
  `test/data/backup_restore_rehearsal_test.dart`.
- Concurrent booking and duplicate submission:
  `test/phase3/appointment_concurrency_test.dart`,
  `test/phase9/incident_rehearsal_test.dart`.
- Provider outage detected by operational signals, threshold breach with
  owner, recovery by retry with no duplicate delivery, evidence export:
  `test/phase9/incident_rehearsal_test.dart`.
- Interrupted payment reconciles: `test/phase5/payment_ledger_test.dart`.

Manual (record build hash, schema version and operator):

1. Account switch with drafts and cached state on the hosted build.
2. Rollback to the last compatible build and verify the restored snapshot.
3. Identity alert: stop, preserve evidence (Admin → System analytics →
   Copy evidence), contain, recover and verify.

Pass requires RPO 0 at snapshot and restore in under 10 seconds.

## Reviews and approvals

| Review | Required approver | Status |
|---|---|---|
| Product/release scope | Workspace owner | prototype scope approved |
| Security and privacy | Named qualified reviewer | open |
| Clinical safety | Named qualified reviewer | blocked for clinical use |
| Accessibility and Arabic | Fluent reviewers using supported AT | open |
| Operational readiness | Named operations reviewer | open |

## Release blockers

Release stops for identity crossing, unauthorized disclosure, finalized-data
loss, false booking/payment confirmation, or an enabled high-impact workflow
without tested recovery and an owner.

## Privacy-safe monitoring

`lib/core/observability/operational_metrics.dart`. Events accept only
allowlisted signals, short lowercase tokens, counts and durations. There are
no fields for names, identifiers, notes, messages, document text or
credentials; an invalid token is dropped, never recorded.

| Signal | Recorded at |
|---|---|
| sessionStarted, appCrash | `lib/main.dart` (framework and async errors) |
| saveFailed, reconciliationPending | `showMutationFeedback` (payment pending → reconciliationPending) |
| deliveryFailed | outbox dispatcher, reminder runs (`lib/core/di.dart`) |
| duplicatePrevented | `IdempotencyGuard.prior` |
| staleDataShown | `AsyncDataView` stale/offline states (throttled) |
| followUpOverdue | `overdueMessagesProvider` (throttled) |
| workResolved | start-up payment reconciliation |

Thresholds with owner and response are evaluated on Admin → System analytics,
which also shows crash-free sessions and copies the JSON evidence. Signals
live in memory for the session only. This is prototype evidence with limited
support during demonstrations, not 24/7 monitoring. Thresholds for stale data
and overdue follow-up are deferred until a usability baseline exists.

## Release gate (engineering)

Run and record output:

```
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test integration_test -d windows
flutter build web --release
```

Last run 2026-09-29 (workspace owner's machine):

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed` | pass (0 files changed) |
| `flutter analyze` | pass — no errors or warnings; style infos only |
| `flutter test` | pass — 457 tests |
| `flutter build web --release` | pass |
| `integration_test/` | not run — needs the Windows desktop toolchain (`-d windows`) or chromedriver with `flutter drive`; neither is installed |

The integration test must be run on a machine with one of those before the
gate is signed.

## Human work still required

- Recruit the representative role/accessibility/language sample.
- Run baseline and improved sessions.
- Perform English/Arabic assistive-technology sessions.
- Run the three manual rehearsals above on the hosted build.
- Obtain named review decisions and deferred-risk signatures.
