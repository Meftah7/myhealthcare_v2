# MyHealth AI — TODO

Working checklist. Tick items as you go. Details, sizes, and dependencies live in [tasks.md](tasks.md); the reasoning lives in [plan.md](plan.md).

**0 / 118 done** · Phase 0 ░░░░░░░░░░ · Phase 1 ░░░░░░░░░░ · Phase 2 ░░░░░░░░░░ · Phase 3 ░░░░░░░░░░ · Phase 4 ░░░░░░░░░░ · Phase 5 ░░░░░░░░░░ · Phase 6 ░░░░░░░░░░ · Phase 7 ░░░░░░░░░░

> **Now:** P0-01 — `flutter create`
> **Blocked on:** nothing
> **Next gate:** P0-11 (Drift on web) — decide before Phase 1

---

## Phase 0 — Scaffold `0/14`

- [ ] P0-01 · `flutter create` with android, ios, web, windows
- [ ] P0-02 · App name, bundle id `bh.edu.uob.myhealth`, icons
- [ ] P0-03 · Add all dependencies to `pubspec.yaml`
- [ ] P0-04 · Create `lib/` folder tree
- [ ] P0-05 · Theme: colors (light + dark), typography, spacing tokens
- [ ] P0-06 · go_router with placeholder routes
- [ ] P0-07 · ProviderScope + `core/di.dart`
- [ ] P0-08 · `Result<T, Failure>` + failure types
- [ ] P0-09 · Drift spike — Windows
- [ ] P0-10 · Drift spike — Android
- [ ] P0-11 · **Drift spike — Web (WASM + OPFS)** ⚠️ decision gate
- [ ] P0-12 · Strict lints, `flutter analyze` clean
- [ ] P0-13 · `git init` + `.gitignore` (no API keys, ever)
- [ ] P0-14 · README: run, seed, add AI key

---

## Phase 1 — Data foundation `0/22`

**Schema**
- [ ] P1-01 · Tables: users, patient_profiles, staff_profiles, departments
- [ ] P1-02 · Tables: appointments, schedule_templates, reminders
- [ ] P1-03 · Tables: medical_records, lab_values, vitals, medications
- [ ] P1-04 · Tables: ai_summaries, staff_tasks, risk_flags
- [ ] P1-05 · Tables: audit_log, app_settings
- [ ] P1-06 · `app_database.dart` — assemble, v1, migrations, platform connection
- [ ] P1-07 · `build_runner` clean; DB opens on all 3 platforms

**Domain**
- [ ] P1-08 · Entities: user, patient, staff, department
- [ ] P1-09 · Entities: appointment, record, lab value, vitals, medication
- [ ] P1-10 · Entities: AI summary, staff task, risk flag
- [ ] P1-11 · Repository interfaces (no Drift imports)

**Data access**
- [ ] P1-12 · user_dao + auth/user repositories
- [ ] P1-13 · appointment_dao + repository (slot availability)
- [ ] P1-14 · record_dao + repository (merged timeline query)
- [ ] P1-15 · vitals_dao + repository (chart series)
- [ ] P1-16 · task_dao, risk_dao + repositories
- [ ] P1-17 · audit repository + write helper
- [ ] P1-18 · Register everything in `core/di.dart`

**Seeder**
- [ ] P1-19 · Vocab: names, conditions, medications, lab analytes + ranges
- [ ] P1-20 · Seeder: 60 patients, 12 staff, 5 departments, 2y history — correlated, not random
- [ ] P1-21 · Idempotent re-seed + reset demo data
- [ ] P1-22 · Export ERD to `docs/erd.png`

---

## Phase 2 — Auth + patient core `0/18`

- [ ] P2-01 · Salted password hashing
- [ ] P2-02 · Login screen + controller
- [ ] P2-03 · Patient registration
- [ ] P2-04 · Session provider + persistence
- [ ] P2-05 · Role-gated routing (patient / staff / admin)
- [ ] P2-06 · Logout + switch user
- [ ] P2-07 · Patient home
- [ ] P2-08 · Health timeline (merged, grouped, lazy-loaded)
- [ ] P2-09 · Timeline filters + search
- [ ] P2-10 · Record detail (labs render as flagged table)
- [ ] P2-11 · PDF text extractor
- [ ] P2-12 · Import record: pick → copy → extract → save
- [ ] P2-13 · Attachment viewer
- [ ] P2-14 · Vitals list + manual entry
- [ ] P2-15 · Vitals charts (BP, weight, glucose, HR)
- [ ] P2-16 · Medications list
- [ ] P2-17 · Profile + settings
- [ ] P2-18 · Shared widgets: empty, error, loading, confirm dialog

---

## Phase 3 — AI layer · RQ1 `0/14`

- [ ] P3-01 · `AiService` interface + response models
- [ ] P3-02 · `PatientContext` builder with token budgeting
- [ ] P3-03 · **`MockAiService`** — build this first
- [ ] P3-04 · Summarization prompt template (strict JSON contract)
- [ ] P3-05 · `ClaudeAiService` — Dio, retry, fallback to mock
- [ ] P3-06 · API key in secure storage (never logged, never committed)
- [ ] P3-07 · Provider selects mock vs. real from settings
- [ ] P3-08 · Summary cache keyed on input hash
- [ ] P3-09 · AI summary screen
- [ ] P3-10 · Summary card on home + regenerate
- [ ] P3-11 · Key events as inline timeline markers
- [ ] P3-12 · Trends link to vitals charts
- [ ] P3-13 · ⚠️ Safety banner on every AI surface
- [ ] P3-14 · Persist modelId + promptVersion + timestamp

---

## Phase 4 — ML + scheduling · RQ2 `0/19`

**Python (offline)**
- [ ] P4-01 · venv + requirements
- [ ] P4-02 · `generate_dataset.py` — learnable no-show signal
- [ ] P4-03 · `features.py` — 11 features
- [ ] P4-04 · `train_no_show.py` — balanced logistic regression
- [ ] P4-05 · `evaluate.py` — accuracy, P/R/F1, ROC-AUC, confusion matrix
- [ ] P4-06 · Export `assets/models/no_show_model.json`
- [ ] P4-07 · Baseline comparison (majority class + heuristic)

**Dart**
- [ ] P4-08 · `feature_extractor.dart` — encoding identical to P4-03
- [ ] P4-09 · `no_show_predictor.dart` — scale, sigmoid, risk band
- [ ] P4-10 · Per-feature contributions (explainability)
- [ ] P4-11 · ⚠️ **Python↔Dart parity test (1e-6)**

**Booking**
- [ ] P4-12 · Slot generator from templates minus booked
- [ ] P4-13 · Booking wizard
- [ ] P4-14 · Slot ranking by risk × convenience, with reasons
- [ ] P4-15 · Optional LLM rationale layer
- [ ] P4-16 · My appointments: cancel, reschedule
- [ ] P4-17 · Store risk + band on the appointment

**Reminders**
- [ ] P4-18 · `platform_notifier` (+ in-app fallback on web)
- [ ] P4-19 · Risk-adaptive reminder escalation

---

## Phase 5 — Staff + admin · RQ3 `0/17`

**Rules first**
- [ ] P5-01 · `RiskDetectionService` — vitals, labs, med gaps, overdue follow-ups
- [ ] P5-02 · Severity scoring + de-duplication
- [ ] P5-03 · Rule-based task generator

**Staff**
- [ ] P5-04 · Staff shell + navigation
- [ ] P5-05 · Staff dashboard: schedule + risk badges + tasks + flags
- [ ] P5-06 · Patient search + list
- [ ] P5-07 · Patient chart (reuse Phase 2 widgets)
- [ ] P5-08 · Add clinical note
- [ ] P5-09 · Prescribe medication + enter lab result
- [ ] P5-10 · AI task prioritization blended with rule score
- [ ] P5-11 · Task board with per-task rationale
- [ ] P5-12 · Staff schedule (week grid)
- [ ] P5-13 · Panel analytics: no-show rate, utilization

**Admin**
- [ ] P5-14 · User management
- [ ] P5-15 · Departments + schedule templates
- [ ] P5-16 · AI settings: key, model, mock toggle, re-seed
- [ ] P5-17 · System analytics + audit log viewer

---

## Phase 6 — Testing & results `0/9`

- [ ] P6-01 · Unit: predictor, features, risk rules, hashing
- [ ] P6-02 · Unit: repositories on in-memory DB
- [ ] P6-03 · Unit: AI parsing — valid, malformed, timeout, empty
- [ ] P6-04 · Widget: login, timeline, booking, dashboard
- [ ] P6-05 · Integration: seed → login → book → staff sees it
- [ ] P6-06 · ⚠️ Cross-platform smoke: Windows + Android + Chrome
- [ ] P6-07 · Usability study (5–8 people, SUS)
- [ ] P6-08 · Performance: timeline load, AI latency, cold start, DB size
- [ ] P6-09 · Accessibility: contrast, targets, labels, text scaling

---

## Phase 7 — Report & presentation `0/5`

- [ ] P7-01 · Architecture, use-case, sequence diagrams
- [ ] P7-02 · Screenshots: all screens, both roles, light + dark
- [ ] P7-03 · Results chapter: ML metrics, baselines, SUS, performance
- [ ] P7-04 · ⚠️ Demo script — rehearsed in airplane mode with mock AI
- [ ] P7-05 · Presentation deck + rehearsal

---

## Don't break these

1. **P0-11 gates Phase 1** — settle web/Drift before building on it
2. **P3-03 before P3-05** — mock AI first, so no UI waits on a key
3. **P4-11 before any booking UI** — an unverified model exports wrong numbers *silently*
4. **P5-01 before P5-10** — the dashboard must work with AI switched off

## Split between the two of you

| After | Ali | Mohammed |
|---|---|---|
| Phase 1 | Phase 2 — patient UI | P4-01…P4-07 — Python ML (independent) |
| Phase 3 | Phase 4 — Dart ML + booking | P5-01…P5-06 — rules + staff shell |
| Phase 6 | Tests + performance | Usability study + accessibility |
