# MyHealth AI — Implementation Plan

## Context

**Senior Project Proposal** (University of Bahrain, College of IT — Ali Mohamed Jaafar Mohamed 202208244 & Mohammed A.Redha Meftah 202209027, Supervisor Dr. Amal Ghanim) defines *"MyHealth: Develop an application to manage health records, appointments, and medical staff with the power of AI."*

The proposal identifies three problems and turns each into a research question with a matching objective:

| RQ | Problem | Objective |
|----|---------|-----------|
| **RQ1** | Records are scattered across hospitals and clinics; patients can't find them | Ingest heterogeneous data (PDF reports, clinician notes) and produce a **unified, timeline-based health profile** with highlighted key events and trends |
| **RQ2** | Booking is manual and frustrating; no-shows waste clinic capacity | An **AI-driven scheduler** using a predictive model (history, visit type) to recommend optimal slots and drive dynamic reminders |
| **RQ3** | Staff buried in paperwork instead of care | AI assistance for **daily task prioritization and early identification of patient risks** |

`C:\Users\m7mef\OneDrive\Desktop\flutter_senior` currently contains only the proposal PDF — this is a greenfield build. Toolchain verified present: **Flutter 3.44.4 / Dart 3.12.2**, Python 3.14.4, Node 24.11.0.

**Decisions locked in with the user:**
- **Storage: local-only (Drift/SQLite).** No server, no cloud account, no network dependency for core function.
- **AI: real API behind an interface.** An `AiService` abstraction; the API key gets dropped in later, and a mock implementation makes the whole app work with zero key.
- **Data: synthetic seeded dataset.** No ethics/IRB exposure, fully reproducible demos.
- **Roles: patient, staff, admin.**
- **Platforms: all of them** (Android, Windows, Web, iOS).

### One architectural consequence to state up front

Local-only storage means "doctor opens patient's chart" happens **within one device's database**, not across a network. This is a legitimate and defensible design for the project — but it must be *named* in the report rather than glossed over. The plan handles it by:

1. Building a **repository layer** (`domain/repositories/*.dart`) that all features talk to, with Drift as the only implementation. A future networked implementation is a swap of one class, not a rewrite. This is the answer to "how would this scale to a real hospital?" at the defense.
2. Framing it in the report as **offline-first architecture** — a real and current pattern in clinical software, where the device works with no connectivity and reconciles later.
3. Listing "multi-device synchronization" explicitly under Future Work.

---

## Architecture

**Pattern:** feature-first structure over a three-layer core (presentation → domain → data), Riverpod for state, Drift for persistence, go_router for navigation.

```
lib/
  main.dart
  app/
    app.dart                    MaterialApp.router, theme wiring
    router.dart                 go_router: role-gated route guards
    theme/                      color scheme, typography, spacing tokens
  core/
    result.dart                 Result<T, Failure> — no raw exceptions across layers
    failures.dart
    di.dart                     Riverpod provider registry
    utils/                      date, formatting, validators, id gen
  domain/
    entities/                   Patient, Appointment, MedicalRecord, StaffTask, RiskFlag…
    repositories/               abstract interfaces ONLY (the swap point)
  data/
    db/
      app_database.dart         Drift DB, schema version + migrations
      tables/                   one file per table group
      daos/                     query logic, kept out of widgets
    repositories/               Drift implementations of domain interfaces
    seed/
      seeder.dart               synthetic data generator (idempotent, seeded RNG)
      vocab/                    condition/med/lab name lists
  features/
    auth/  patient_home/  timeline/  records/  ai_summary/
    booking/  appointments/  vitals/
    staff_dashboard/  patient_chart/  tasks/
    admin/  settings/
      └ each: presentation/ (screens, widgets) + application/ (controllers/notifiers)
  services/
    ai/
      ai_service.dart           the interface — 3 methods, one per RQ
      claude_ai_service.dart    HTTP implementation, key injected
      mock_ai_service.dart      deterministic canned responses
      prompts/                  versioned prompt templates
      ai_result_cache.dart
    ml/
      no_show_predictor.dart    pure-Dart inference
      feature_extractor.dart    Appointment+history → feature vector
    notifications/
      reminder_scheduler.dart   risk-adaptive reminder logic
      platform_notifier.dart    local notifications + in-app fallback
    ingestion/
      pdf_text_extractor.dart   PDF → text for RQ1
assets/
  models/no_show_model.json     trained weights (see tools/ml)
  seed/
tools/ml/                       Python — offline training, NOT shipped in app
  generate_dataset.py
  train_no_show.py
  evaluate.py
  RESULTS.md                    metrics table for the report
docs/                           ERD, use-case diagrams, screenshots, demo script
test/
```

### Packages

| Concern | Package |
|---|---|
| State | `flutter_riverpod` (2.x, hand-written providers — see note) |
| DB | `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `drift_dev`, `build_runner` |
| Models | `freezed`, `json_serializable` |
| Nav | `go_router` |
| Charts | `fl_chart` (vitals trends, admin analytics) |
| Notifications | `flutter_local_notifications`, `timezone` |
| HTTP | `dio` |
| Security | `crypto` (password hash+salt), `flutter_secure_storage` (API key) |
| Files | `file_picker`, `path_provider`, `syncfusion_flutter_pdf` (pure-Dart PDF text extraction) |
| Misc | `intl`, `uuid`, `shared_preferences`, `google_fonts` |

> **Toolchain note (P0-03).** On the locked toolchain (Flutter 3.44.4 / Dart 3.12.2)
> the modern codegen stack does not co-resolve: `freezed` 4.x needs Dart ≥ 3.13, while
> `drift_dev` ≥ 2.34.1 and `riverpod_generator` 4.x require `analyzer` 13, which
> `freezed` 3.x (analyzer ≤ 11) cannot share. Chosen resolution: **Riverpod 2.6.1 with
> hand-written providers** (no `riverpod_generator`/`@riverpod`), `drift`/`drift_dev`
> pinned just below the analyzer-13 bump, `freezed` 3.x kept for entity generation.
> `riverpod_lint`/`custom_lint` dropped. Re-evaluate if Flutter is upgraded to a
> Dart ≥ 3.13 release.

---

## Data model (Drift)

Core tables — this doubles as the ERD chapter of the report:

- **users** — id, role (`patient`/`staff`/`admin`), fullName, email, passwordHash, passwordSalt, phone, dob, gender, nationalId, isActive, createdAt
- **patient_profiles** — userId FK, bloodType, allergies, chronicConditions, emergencyContact
- **staff_profiles** — userId FK, specialty, departmentId FK, licenseNo, jobTitle
- **departments** — id, name, description
- **schedule_templates** — staffId, weekday, startTime, endTime, slotMinutes
- **appointments** — id, patientId, staffId, departmentId, slotStart, slotEnd, visitType, status (`booked`/`confirmed`/`completed`/`cancelled`/`noShow`), reasonText, bookedAt, **noShowRisk** (double), **riskBand**, remindersSent, checkedInAt
- **medical_records** — id, patientId, authorStaffId, recordType (`visitNote`/`labResult`/`imaging`/`prescription`/`vaccination`/`discharge`/`referral`), title, body, occurredAt, sourceFacility, attachmentPath, extractedText
- **lab_values** — id, recordId FK, analyte, value, unit, refLow, refHigh, abnormalFlag
- **vitals** — id, patientId, recordedAt, systolic, diastolic, heartRate, tempC, weightKg, heightCm, spo2, glucose
- **medications** — id, patientId, prescriberId, name, dose, frequency, startDate, endDate, isActive
- **ai_summaries** — id, patientId, generatedAt, modelId, promptVersion, summaryMarkdown, keyEventsJson, trendsJson, redFlagsJson, inputHash *(cache keyed on inputHash → identical demo output every run, and no wasted API calls)*
- **staff_tasks** — id, staffId, patientId, title, kind, dueAt, status, **aiPriorityScore**, **aiRationale**, ruleScore
- **risk_flags** — id, patientId, kind, severity, rationale, detectedAt, source (`rule`/`ai`), acknowledgedBy
- **reminders** — id, appointmentId, scheduledFor, channel, sentAt, kind (`standard`/`escalated`/`confirmRequest`)
- **audit_log** — id, actorUserId, action, entityType, entityId, at *(feeds the security/privacy chapter)*
- **app_settings** — singleton row: aiEnabled, mockMode, modelId, seedVersion

---

## The three AI modules

Interface (`services/ai/ai_service.dart`) — exactly three methods, one per research question, so the code maps 1:1 onto the report:

```dart
abstract class AiService {
  Future<Result<HealthSummary>>  summarizeRecords(PatientContext ctx);      // RQ1
  Future<Result<SlotRanking>>    rankSlots(BookingContext ctx);             // RQ2 (LLM rationale layer)
  Future<Result<TaskRanking>>    prioritizeTasks(StaffWorkloadContext ctx); // RQ3
}
```

Two implementations, chosen by a Riverpod provider reading `app_settings.mockMode`:
- `MockAiService` — deterministic, plausible responses. **The app is fully demoable with no key and no internet.** This is the defense insurance policy.
- `ClaudeAiService` — Dio → Anthropic Messages API. Key read from `flutter_secure_storage`, entered in Admin → AI Settings (never hardcoded, never committed). Requests JSON-structured output, parses into typed models, degrades to mock on any failure.

### RQ1 — Record summarization
Pipeline: gather records for a patient → PDF attachments passed through `pdf_text_extractor` → build a **compact structured context** (chronological, token-budgeted, most-recent-weighted) → prompt → parse `{summary, keyEvents[], trends[], redFlags[]}` → persist to `ai_summaries` keyed by `inputHash`.
UI: patient Health Timeline shows the AI summary card at top; key events render as highlighted markers inline in the timeline; trends link to the corresponding `fl_chart` vitals graph.

### RQ2 — No-show prediction + smart scheduling
**This is the one place where a real trained model belongs**, because RQ2 is the question that demands measurable accuracy in the report.

- Trained **offline in Python** (`tools/ml/train_no_show.py`) — logistic regression, class-balanced, with a proper train/test split.
- Exported as **`assets/models/no_show_model.json`** (coefficients + intercept + feature schema + scaler params).
- Inference is **pure Dart** (`no_show_predictor.dart`) — no Python at runtime, no server, works offline on every platform. Small enough to be transparent, and a linear model gives you **per-feature contributions** → an explainable "why is this patient high-risk" panel, which is far stronger at a defense than an opaque score.

Features: lead-time days, patient prior no-show rate, prior appointment count, age band, visit type, day-of-week, hour-of-day, is-first-visit, days-since-last-visit, has-chronic-condition, reminders-acknowledged.

Consumed in three places:
1. **Booking** — candidate slots ranked by predicted risk × patient convenience; top suggestions surfaced first with a plain-language reason.
2. **Staff dashboard** — risk badge on each of today's appointments; overbooking suggestion when a block is high-risk.
3. **Reminders** — `reminder_scheduler` escalates by risk band: low = one reminder; medium = two; high = early reminder + confirm-or-release prompt.

### RQ3 — Task prioritization + risk detection
- `RiskDetectionService` — **deterministic rules first**: out-of-range vitals, abnormal lab flags, medication gaps, overdue follow-ups → writes `risk_flags`. Runs with no AI at all, so the staff dashboard is never empty.
- `AiService.prioritizeTasks` — LLM ranks the staff's open tasks *with a written rationale per task*, blended with the rule score (configurable weight) so output is never wholly unexplainable.
- Staff dashboard: prioritized task board, risk-flag panel, today's schedule with no-show badges.

### Clinical safety (deliberate, and worth a report subsection)
Every AI-generated surface carries a **"AI-generated — informational only, not medical advice; verify with your clinician"** banner. AI never auto-books, auto-cancels, auto-prescribes, or auto-diagnoses — every action needs human confirmation. Every stored AI output records `modelId` + `promptVersion` + timestamp for traceability.

---

## Feature scope by role

**Patient** — login/register · home (next appointment, active meds, latest AI summary) · unified health timeline w/ type filters + search · record detail + PDF import · AI health summary · vitals charts · book appointment (department → doctor → AI-recommended slots → confirm) · my appointments (cancel/reschedule) · risk-adaptive reminders · profile & settings

**Staff** — dashboard (today's schedule + no-show badges, AI-prioritized tasks, risk-flag panel) · patient search → patient chart (timeline, AI summary, vitals, meds) · add clinical note / prescription / lab order · task board with AI rationale · my schedule · panel analytics (no-show rate, utilization)

**Admin** — user management (create/deactivate staff, reset passwords) · departments & schedule templates · system analytics dashboard · audit log viewer · **AI settings (API key entry, model, mock-mode toggle)** · re-seed / reset demo data

---

## Platform strategy (all four requested)

| Platform | Status | Notes |
|---|---|---|
| **Windows** | Primary dev target | Fastest iteration loop; `sqlite3_flutter_libs` bundles the DLL. Best defense fallback. |
| **Android** | Primary demo target | Emulator + physical phone. Full notification support. |
| **Web** | Supported | Drift needs `sqlite3.wasm` + `drift_worker.js` in `web/` with OPFS storage — **verify this in Phase 0, not Phase 6.** Local notifications unavailable on web → `platform_notifier` falls back to in-app banners. |
| **iOS** | Configured, build deferred | Project structure and plugins are all iOS-compatible, but building requires a Mac. If no Mac is available, this is stated as a known limitation rather than silently skipped. |

`platform_notifier.dart` exists specifically to keep this from leaking into feature code: one capability check, notifications where supported, in-app banners where not.

---

## Build phases (keyed to the proposal's W1–W16, not calendar dates)

**Phase 0 — Scaffold (proposal W1–3, alongside requirements/lit review)**
`flutter create` with all platforms · package install · folder structure · theme + design tokens · go_router shell with role guards · **spike: verify Drift runs on Windows, Android, and Web-WASM before anything else is built on top of it.**

**Phase 1 — Data foundation (W4–6, "Design")**
All Drift tables + migrations · domain entities (freezed) · repository interfaces + Drift implementations · DAOs · **synthetic seeder**: ~60 patients, 12 staff, 5 departments, 2 years of appointment history with realistic no-show patterns, records, labs, vitals, meds. Seeded RNG → byte-identical data every run. · ERD exported to `docs/`.

**Phase 2 — Auth + patient core (W7)**
Registration/login (salted hash), session, role routing · patient home · health timeline · record detail · PDF import + text extraction · vitals charts.

**Phase 3 — AI layer (W7–8)**
`AiService` interface · `MockAiService` first (so UI is never blocked on a key) · `ClaudeAiService` · prompt templates · summary caching · **RQ1 fully wired end to end.**

**Phase 4 — ML + scheduling (W8–9)**
Python: `generate_dataset.py` → `train_no_show.py` → `evaluate.py` → export weights JSON + `RESULTS.md` · Dart `NoShowPredictor` + `FeatureExtractor` + unit tests asserting Dart inference matches Python within tolerance · booking flow with ranked slots · reminder scheduler · **RQ2 fully wired.**

**Phase 5 — Staff + admin (W9)**
Rule-based risk detection · staff dashboard · patient chart · task board with AI prioritization · clinical note entry · admin screens incl. AI settings · audit logging · **RQ3 fully wired.**

**Phase 6 — Testing & results (W10–12)**
Unit tests (predictor, feature extractor, repositories, prompt parsing) · widget tests on key screens · integration test of the booking flow · ML metrics table · small usability test (5–8 users, SUS questionnaire) · performance measurements · accessibility pass.

**Phase 7 — Report & presentation (W13–16)**
`docs/`: ERD, use-case + sequence diagrams, architecture diagram, screenshots · results chapter · **demo script with an exact click path** · presentation deck.

---

## Verification

**Every phase:**
```
flutter analyze          # must be clean
dart format --set-exit-if-changed lib test
flutter test
```

**Cross-platform smoke (run at the end of Phase 1 and again at Phase 6 — not only at the end):**
```
flutter run -d windows
flutter run -d <android-emulator>
flutter run -d chrome
```
Each must: launch → seed → log in as patient → open timeline → book an appointment → log in as staff → see the dashboard.

**ML verification:**
```
cd tools/ml
python generate_dataset.py && python train_no_show.py && python evaluate.py
```
`evaluate.py` prints accuracy / precision / recall / F1 / ROC-AUC + confusion matrix into `RESULTS.md`. A Dart unit test then feeds fixed feature vectors through `NoShowPredictor` and asserts the output matches the Python model's prediction to within 1e-6 — this is what proves the exported weights are correct.

**AI verification:** run the full app once in mock mode and once with a live key; confirm identical UI behaviour, that failures fall back to mock cleanly, and that `ai_summaries` caching prevents duplicate API calls for unchanged input.

**Defense readiness:** rehearse the full demo script on Windows *and* Android, in **airplane mode with mock AI**, to prove the app cannot fail from a bad conference-room network.

---

## Risks

| Risk | Mitigation |
|---|---|
| Drift-on-Web WASM setup fights back | Spiked in Phase 0, before dependent work exists. Web is the drop-candidate if it proves costly — Android + Windows carry the demo. |
| No API key / no internet at defense | Mock mode is a first-class implementation, not a stub. Rehearsed in airplane mode. |
| iOS needs a Mac | Configured but deferred; declared as a limitation if no Mac materializes. |
| Scope creep across 3 roles | Patient → staff → admin, in that order. Admin is the thinnest surface and the first to be trimmed. |
| Synthetic data looks fake at defense | Seeder uses realistic clinical vocab, plausible value distributions, and correlated histories (chronic patients have more visits, etc.). |
| LLM returns malformed JSON | Typed parsing with validation, one retry, then automatic mock fallback. Never crashes a screen. |

---

## Open item

---

## Design, layout, and animation audit backlog

This section records the design review so future implementation instructions can refer to one durable source instead of relying on chat history.

### Overall direction

Keep the existing **clinical premium** direction: calm, structured, trustworthy, and modern. Do not replace it with a louder wellness aesthetic, generic AI visuals, or decorative glassmorphism.

The central objective is: make every screen communicate priority faster, with fewer competing surfaces, clearer hierarchy, and restrained motion.

The current foundation is strong: Material 3, Lexend headings, Inter UI text, semantic colors, light/dark themes, responsive window classes, shared scaffolds, and reduced-motion support.

### Design priorities

#### P1 — Reduce competing surfaces

Cards, borders, containers, chips, hero panels, quick-action grids, and dashboard sections are individually reasonable but can collectively make screens feel like collections of panels.

- Give each screen one primary visual anchor.
- Use whitespace and section headers before adding another card.
- Reserve strong borders for interactive or important content.
- Limit each screen to one main gradient/hero surface.
- Avoid making every information group look equally important.

#### P1 — Simplify information architecture

The three role apps have clear primary destinations, but secondary features can create too many routes and duplicate entry points.

- Keep the primary role tabs stable.
- Make pushed/detail routes visibly subordinate to primary destinations.
- Keep dashboard quick actions only for frequent or urgent tasks.
- Remove duplicate shortcuts when they do not add meaningful context.
- Make dashboard summary, workflow, and detail visually distinct.

#### P1 — Stress-test responsive layouts

Verify important screens at 320×568, 375×667, 430×932, 600×800, 840×700, 1024×768, and 1440×900, plus portrait/landscape phone, 200% text scaling, Arabic/RTL, and keyboard-open states.

Check navigation labels, charts, appointment cards, schedule grids, profile headers, bottom sheets, long translations, and buttons beside expanded text.

#### P1 — Standardize page framing

`AppScaffold` should own standard screen framing: gutters, max width, scrolling, refresh, bottom padding, and entrance behavior. Use custom framing only for genuinely specialized screens such as calendars, chat threads, split panes, or full-screen workflows.

Review screens that still hand-roll `ListView`, `GridView`, `Center`, padding, and width constraints for visual drift.

#### P2 — Simplify the login surface

The login screen currently includes the brand lockup, two fields, helper text, forgot password, error banner, sign-in, registration, demo accounts, demo password, and theme/language actions.

- Hide demo accounts behind a demo/development mode in production builds.
- Keep the authentication task visually dominant.
- Make “email or national ID” consistent between label and helper text.
- Preserve user input after errors.
- Give loading, error, and success states clear hierarchy.

#### P2 — Strengthen hierarchy

Use three levels: screen purpose, section/task group, and supporting metadata.

Prioritize urgent and actionable content over totals and secondary analytics. Patient priority should generally be next appointment, urgent health information, recent records, then optional tools. Staff/admin priority should be what needs attention now, today’s workflow, then analytics/reference information.

#### P2 — Reconsider navigation indicators

The rounded selected navigation indicator is functional but adds to the repeated soft/pill language used by cards, fields, buttons, chips, and status elements.

Consider a quieter selected navigation treatment such as a tinted structural background, rail marker, or underline. Preserve pill shapes primarily for semantic status badges.

#### P2 — Validate subtle surface contrast

The system relies on fill contrast plus hairline borders. This may be too subtle for older users, low-vision users, and dark-mode users.

- Check light and dark screenshots at reduced brightness.
- Increase page/card contrast slightly if adjacent cards merge visually.
- Use stronger separation for interactive and priority surfaces.
- Never communicate selected, focused, or urgent state with border color alone.

#### P2 — Keep gradients rare

Use the brand gradient for recognition and exceptional moments, not as a general accent. Preferred uses are login identity, onboarding, one role hero, and one meaningful empty-state action. Routine buttons should usually use a flat semantic primary color.

### Accessibility checklist

- Every icon-only action has a meaningful tooltip and semantic label.
- Form errors are announced to screen readers.
- Focus moves to the first invalid field after submission.
- Loading states announce “Signing in” or equivalent status.
- Password visibility controls expose their current state.
- All screens remain usable at 200% text scaling.
- Arabic/RTL layouts are tested, not only translated.
- Keyboard traversal works on Windows and web.
- Touch targets remain at least 48dp where possible.
- Selected/focused/error states do not depend on color alone.
- Session timeout notices are announced when the user returns to login.
- Bottom sheets and forms remain usable when the keyboard is open.

### Animation direction

Motion should communicate state, location, hierarchy, and touch feedback. It should not make routine healthcare work feel theatrical.

| Context | Motion level | Direction |
|---|---:|---|
| Login/authentication | Very low | Short fade or instant state change |
| Routine dashboard navigation | Low | Near-instant or subtle fade |
| Modal/bottom sheet | Medium | Short scale/fade from trigger |
| List/detail transition | Medium | Shared-axis transition |
| Clinical alert | Low | Restrained emphasis; never playful |
| Onboarding/first visit | Medium-high | Strongest brand expression |

#### Motion findings to address

- `Motion.slow` is 320ms in `lib/app/theme/motion.dart`; consider 240–280ms for frequent navigation and reserve 320ms for larger, rare transitions.
- `AnimatedSize` in `motion.dart` animates layout height and can shift nearby content; prefer opacity plus transform where possible.
- `AnimatedPositioned` in draggable/overlay areas can trigger layout work; prefer transform-based movement for drag and settle motion when feasible.
- `AppEntrance` is applied broadly through `AppScaffold`; use it selectively so routine navigation does not feel delayed.
- Use `AppCountUp` only for meaningful dashboard arrival or explicit updates, not every rebuild of a clinical value.
- Avoid stacking multiple fades, scales, and size animations in one region.
- Preserve reduced-motion behavior across every new animation.
- Use trigger-origin animation for sheets, popovers, and menus.
- Prefer transform and opacity over width, height, margin, padding, top, and left animations.

#### Motion acceptance criteria

- Every animation has a one-sentence purpose.
- Frequent actions complete visually within roughly 300ms.
- No animation uses `transition: all` or equivalent unbounded properties.
- No interaction depends on hover.
- Reduced motion removes movement and unnecessary delay.
- Animations are interruptible where the user can act again quickly.
- Clinical numbers do not visually change in a way that undermines trust.

### Suggested implementation order

1. Run a responsive and accessibility pass on login, patient home, staff dashboard, admin dashboard, schedule, timeline, and profile.
2. Reduce unnecessary cards and repeated rounded surfaces.
3. Standardize remaining screens on `AppScaffold`.
4. Simplify navigation and remove duplicate entry points.
5. Verify light/dark contrast and Arabic/RTL behavior.
6. Reduce motion on routine flows and remove layout-property animations where practical.
7. Add focused visual regression tests at compact, expanded, dark, RTL, and 200% text-scale configurations.
8. Run one final polish pass after structural changes.

### Suggested review commands

- `$impeccable audit` — technical accessibility, performance, responsiveness, and theming audit.
- `$impeccable critique` — heuristic UX and information-hierarchy review.
- `$impeccable layout` — spacing, rhythm, width, and hierarchy refinement.
- `$impeccable adapt` — compact/medium/expanded/large layout fixes.
- `$impeccable animate` — purposeful motion improvements.
- `$impeccable typeset` — typography and text-scale refinement.
- `$impeccable clarify` — labels, helper text, errors, and action copy.
- `$impeccable polish` — final visual quality pass.

Re-run the audit after fixes and update this section with completed items and remaining risks.

## Settings and appointments audit backlog

This section records the settings and appointment-flow review. Appointment
reliability is a primary product priority because it is the main patient-facing
workflow.

### Appointment bugs and risks

#### P0 — Rescheduling can create conflicts

`lib/data/repositories/appointment_repository_impl.dart` updates an appointment
without checking whether the new interval overlaps another appointment, is part
of the clinician's schedule, falls within clinic hours, or is on an open day.
Rescheduling must use the same availability rules as booking.

#### P1 — Reschedule results are ignored

`lib/features/appointments/presentation/appointments_screen.dart` calls the
reschedule repository method without inspecting its `Result`. A failed
reschedule can appear to do nothing and gives the patient no explanation.

Add loading, success, and error states while preserving the original appointment.

#### P1 — Rescheduling does not rebuild reminders

Booking schedules reminders, but the patient reschedule flow does not rebuild
them. Reminders can remain attached to the old appointment time.

After a successful reschedule, delete unsent reminders and call the reminder
scheduler with the new start time and risk band.

#### P1 — Booking conflict check is not atomic

Booking checks for a clash and inserts later. Concurrent requests can both pass
the check. Use a transaction and a database-level uniqueness/locking strategy
where possible.

#### P1 — Overlapping appointments are not detected

The current booking check compares only identical start times. It must reject
interval overlap using the standard condition:

```text
existing.start < requested.end && existing.end > requested.start
```

Cancelled appointments should remain excluded from the conflict check.

#### P1 — Reschedule allows arbitrary minutes

The time picker can produce times such as 10:07 even when the clinician uses
20-minute slots. Rescheduling must display valid `OpenSlot` values rather than a
free-form clock picker.

#### P1 — Reschedule validates only the selected hour

The current UI does not fully validate future time, open day, staff schedule,
slot alignment, appointment duration, or closing-time boundaries. All of these
must be checked in the repository as well as the UI.

#### P1 — Appointment mutations lack repository-level authorization

`cancel`, `reschedule`, and `updateStatus` accept only an appointment ID. The
repository boundary does not verify acting user, patient ownership, assigned
clinician, role, or valid status transition.

The application layer may perform some checks, but the data boundary must not
trust callers. Introduce an authorization-aware mutation API or require actor
and ownership context for mutations.

#### P1 — Cancellation failures are ignored

The patient appointment card calls cancel and immediately refreshes the list
without checking the result. Add loading protection, success feedback, and an
error message. Prevent repeated cancellation taps.

#### P2 — “Book Now” has a misleading no-availability fallback

The quick-book flow searches 14 days and returns today if no slot is found. This
can make the UI describe today as the soonest opening while no slot exists.

Return an explicit empty result and show “No opening found in the next 14 days,”
with a later-date or alternate-clinician action.

#### P2 — Overlapping schedule templates can duplicate slots

Admin schedule-template saving must reject overlapping templates for the same
clinician and weekday. Otherwise the booking UI can show duplicate slots.

#### P2 — Ticket generation is race-prone

Ticket numbers are generated by counting existing appointments and adding one.
Concurrent bookings can receive the same ticket. Use a transaction-backed counter
or unique constraint/retry strategy.

#### P2 — Appointment history is silently limited

The patient UI displays only the latest 40 past appointments without pagination
or a “load more” action. Add pagination or explain the limit and provide a way to
load older history.

#### P2 — Upcoming actions depend only on date

Reschedule and cancel actions are shown for every future appointment. Also check
status, check-in state, time-to-appointment, and business rules before exposing
each action.

### Appointment UX improvements

#### Booking flow

The preferred flow is:

1. Choose visit type/reason.
2. Choose department or clinician.
3. Choose a day with availability counts.
4. Choose from valid slots only.
5. Review date, time, clinician, department, reason, room, and reminders.
6. Confirm with a loading state and an idempotent request.
7. Show a confirmation containing date, time, clinician, room, ticket, and
   reminder details.

Improve the flow by showing next available day, preventing past slots, clearly
   indicating timezone/local time, making the selected slot unmistakable, and
   providing retryable errors.

#### Appointment detail

Add a dedicated appointment detail surface containing date/time, clinician,
department, room, ticket, visit type, reason, status, check-in instructions,
reminder settings, reschedule/cancel, calendar export, and help/contact action.

#### Cancellation

Validate status and ownership, optionally collect a reason, cancel unsent
reminders, show success feedback, write an audit entry, and distinguish patient
cancellation from staff no-show marking.

#### Staff lifecycle

Enforce valid status transitions:

```text
booked → confirmed
confirmed → inProgress
inProgress → completed
booked/confirmed → cancelled
booked/confirmed → noShow
```

Reject invalid transitions such as completed → booked, cancelled → inProgress,
or noShow → completed.

#### Reminder lifecycle

Rebuild reminders after booking, rescheduling, cancellation, and risk-band
changes. Cancel or suppress unsent reminders when an appointment is cancelled.

### Settings architecture findings

#### P1 — Push notification setting is not visible

`NotificationPrefs` stores a push preference, but the preferences UI exposes only
SMS, email, and sound. Add a push toggle or remove the unused state. The visible
settings model and stored settings model must agree.

#### P1 — Notification settings do not control reminder scheduling

The reminder scheduler always creates push reminders and does not read SMS,
email, push, or operating-system permission state. Wire notification preferences
into reminder creation and delivery.

#### P1 — Device, user, and clinic settings are mixed

Theme, language, text scale, and sounds are device preferences. Notification and
account preferences should be associated with the signed-in user. Clinic hours,
open days, slot duration, holidays, and staff schedules are shared operational
data and should live in the database rather than device-local preferences.

The current local-only demo can keep them local temporarily, but the UI must make
the scope explicit.

#### P2 — No in-app reduced-motion preference

The app follows the operating-system reduced-motion setting but does not provide
System / Reduced / Full motion choices. Add this under Accessibility, with System
as the default.

#### P2 — No high-contrast/accessibility mode

Add optional high contrast, stronger borders, larger touch targets, and simplified
visual density for patients with low vision or motor limitations.

#### P2 — Notification settings lack explanation

Explain what each channel delivers, whether the channel is supported, whether OS
permission is enabled, and whether the local demo simulates delivery.

#### P2 — Settings persistence failures are not surfaced

Controllers update visible state before awaiting persistence. If storage fails,
the UI can display a value that was not saved. Add error handling, rollback, and a
small failure message where persistence can fail.

#### P2 — No scoped reset controls

Add reset-to-default actions for appearance, notifications, clinic schedule, and
all device preferences. Avoid a single destructive reset without clear scope.

### Settings structure recommendation

Organize settings into:

1. Appearance — theme, language, text size, reduced motion.
2. Notifications — push, email, SMS, sounds, appointment reminders.
3. Appointments — default visit type, reminder timing, calendar preferences.
4. Account and security — password, logout/session, privacy.
5. Clinic administration — open days, hours, holidays, slot duration, staff
   schedules.
6. AI settings — model, mock mode, API key, data handling, disclaimers.
7. Accessibility — high contrast, larger targets, screen-reader support.

### Required appointment tests

- Rescheduling into an occupied slot fails.
- Rescheduling into an overlapping interval fails.
- Rescheduling outside clinic hours fails.
- Rescheduling on a closed day fails.
- Rescheduling to a non-slot minute fails.
- Rescheduling an already completed appointment fails.
- Cancelling an appointment twice fails cleanly.
- A patient cannot mutate another patient's appointment.
- A clinician cannot mutate an appointment assigned to another clinician.
- Concurrent identical bookings create only one appointment.
- Ticket numbers remain unique.
- Rescheduling rebuilds reminders.
- Cancellation removes unsent reminders.
- Notification preferences affect reminder channels.
- “Book Now” shows an explicit empty state when no opening exists.
- Changing clinic hours updates booking availability correctly.
- Clinic schedule changes persist according to their intended scope.

### Recommended implementation order

1. Harden appointment repository validation and authorization.
2. Replace free-form rescheduling with valid-slot selection.
3. Make booking/rescheduling/cancellation transactional and result-aware.
4. Rebuild and cancel reminders as appointment state changes.
5. Add appointment detail and clear loading/success/error states.
6. Separate device, user, and clinic settings.
7. Connect visible notification preferences to actual reminder behavior.
8. Add the appointment and settings regression tests listed above.

### Existing open item

The proposal is dated Semester 2, 2025/2026 (submitted 1/2/2026), but the current date is August 2026. All phases above are keyed to the proposal's **relative** week numbers (W1–W16) rather than calendar dates. Confirm the actual deadline and the phases can be re-scaled to fit.
