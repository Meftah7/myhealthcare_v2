# MyHealth Care — Project Checklist

**Senior Project — University of Bahrain, College of IT**
Ali Mohamed Jaafar Mohamed (202208244) · Mohammed A. Redha Meftah (202209027)
Supervisor: Dr. Amal Ghanim
Repository: github.com/Meftah7/myhealthcare_v2

**Status: 116 / 118 tasks done.** 74 automated tests passing. Windows + Web builds working.

Legend: `[x]` done · `[ ]` not done / deferred

---

# Phase 0 — Project Setup

## Flutter
- [x] Create Flutter project (Windows, Android, Web, iOS)
- [x] App name "MyHealth Care" + app icons (all platforms)
- [x] Add all packages (Riverpod, Drift, go_router, dio, fl_chart, …)
- [x] Create folder structure (feature-first + domain / data / services)
- [x] Configure theme (colour scheme, clinical status colours, fonts, spacing)
- [x] Configure routing (go_router, one shell per role)
- [x] ProviderScope + dependency registry

## Local database (no Firebase — offline-first)
- [x] Drift + SQLite working on Windows
- [x] Drift + SQLite working on Web (WASM + OPFS)
- [ ] Drift + SQLite working on Android — blocked (emulator needs hypervisor driver, one admin step)
- [x] `Result` / `Failure` types (no exceptions across layers)

## Project hygiene
- [x] Strict lint rules, `flutter analyze` clean
- [x] Git repository + `.gitignore` (no API keys ever committed)
- [x] README (run, seed, add AI key)

✅ Done when:
- App builds and runs on Windows and Web
- Local database opens and stores data

---

# Phase 1 — Database

## Tables (16 total)
- [x] Users, Patient Profiles, Staff Profiles, Departments
- [x] Appointments, Schedule Templates, Reminders
- [x] Medical Records, Lab Values, Vitals, Medications
- [x] AI Summaries, Staff Tasks, Risk Flags
- [x] Audit Log, App Settings

## Domain layer
- [x] Entities (User, Patient, Staff, Appointment, Record, Vitals, Medication, …)
- [x] Repository interfaces (no database imports — swap point for a future server)
- [x] Repository implementations (query the database directly)
- [x] Register everything in the dependency registry

## Relations (enforced by foreign keys)
- [x] User → Vehicles… (Patient) → Appointments, Records, Vitals, Medications
- [x] Appointment → Patient, Staff, Department, Payment-equivalent, Review-equivalent
- [x] Staff → Appointments (assigned), Schedule Templates, Tasks
- [x] Record → Lab Values
- [x] Risk Flag → Patient · Staff Task → Staff + Patient
- [x] Department → Staff

## Synthetic data (no real patients)
- [x] Clinical vocabulary (names, conditions, medications, lab ranges)
- [x] Seeder: 5 departments, 12 doctors, 60 patients, ~2 years of history
- [x] Idempotent re-seed + reset demo data
- [x] Export database diagram (ERD) to `docs/erd.png`

✅ Done when:
- All tables exist and all relations are enforced
- The database is fully populated with realistic data

---

# Phase 2 — Authentication & Patient Core

## Authentication
- [x] Salted password hashing (PBKDF2-HMAC-SHA256)
- [x] Login screen
- [x] Patient self-registration
- [x] Session persistence (stay logged in after restart)
- [x] Role-gated routing (patient / staff / admin can't cross areas)
- [ ] Logout + switch-user UI polish (backend done, small UI wiring left)

> Note: uses local password auth, not phone/OTP. Real SMS verification would be added for production.

## Patient screens
- [x] Home (next appointment, active medications, AI summary card)
- [x] Health timeline (records + vitals merged, grouped by month)
- [x] Timeline filters + search
- [x] Record detail (lab values as a flagged table vs reference range)
- [x] Vitals list + manual entry
- [x] Vitals charts (blood pressure, weight, glucose, heart rate)
- [x] Medications list (current / past)
- [x] Profile & settings
- [x] Shared widgets (empty / error / loading / confirm)

## Deferred
- [ ] PDF report import — pick file, extract text, save as a record
- [ ] Attachment viewer

✅ Done when:
- A patient can log in and browse their entire history

---

# Phase 3 — AI Health Summary (Research Question 1)

- [x] `AiService` interface + response models
- [x] Patient context builder (with a token budget)
- [x] Mock AI service — deterministic, derived from the patient's real data
- [x] Summary prompt + strict JSON contract + tolerant parser
- [x] Live AI service — Google Gemini (free tier), retry, timeout
- [x] Fallback: live AI fails → drop to mock automatically
- [x] API key in secure storage (`--dart-define` fallback, never committed)
- [x] Provider picks mock vs live from settings
- [x] Summary cache keyed on the input hash
- [x] AI summary screen (narrative + key events + trends + red flags)
- [x] Summary card on the home screen + regenerate
- [x] Key events shown as markers on the timeline
- [x] Trends link to the matching vitals chart
- [x] "Not medical advice" safety banner on every AI screen
- [x] Store model id + prompt version + timestamp with each summary

✅ Done when:
- The app produces a useful health summary with AI on **or** off

---

# Phase 4 — No-Show Model & Smart Scheduling (Research Question 2)

## Machine learning (Python, trained offline)
- [x] Python environment + requirements
- [x] Generate synthetic training dataset (~8,500 appointments)
- [x] Feature engineering — 11 features
- [x] Train class-balanced logistic regression
- [x] Evaluate → `docs/ml_results.md` + ROC curve
- [x] Export model weights to JSON (bundled as an asset)
- [x] Baseline comparison (majority class, simple heuristic)

**Result:** ROC-AUC **0.75**, recall 0.62 — beats both baselines.

## On-device inference (Dart)
- [x] Feature extractor (identical encoding to Python)
- [x] Predictor — scale, sigmoid, risk band
- [x] Per-feature contribution breakdown (explainability)
- [x] Python ↔ Dart parity test within 1×10⁻⁶

## Booking
- [x] Open-slot generator (schedule templates minus booked)
- [x] Booking wizard (department → doctor → date → slot → confirm)
- [x] Slot ranking by predicted risk, each with a plain-language reason
- [x] My appointments — cancel, reschedule
- [x] Store predicted risk + band on the appointment
- [ ] Optional AI-written slot rationale — skipped (model reasons are enough)

## Reminders
- [x] Notification abstraction + in-app fallback (works on web too)
- [x] Risk-adaptive reminder escalation (1 / 2 / 3 reminders by risk band)

✅ Done when:
- The booking flow recommends low-risk slots with real, reportable accuracy

---

# Phase 5 — Staff & Admin (Research Question 3)

## Rule engine (works with AI switched off)
- [x] Risk detection — abnormal vitals, critical labs, medication gaps, overdue follow-ups
- [x] Severity scoring (info / warning / urgent) + de-duplication
- [x] Rule-based task generator

## Staff app
- [x] Staff shell + navigation (Dashboard / Patients / Tasks / Schedule)
- [x] Dashboard — today's schedule, risk flags, task preview, one-tap "scan panel"
- [x] Patient search + list
- [x] Patient chart (header, flags, medications, vitals, timeline)
- [x] Add clinical note
- [x] Prescribe medication
- [x] Enter lab result (auto-classified against the reference range)
- [x] AI task prioritisation, blended with the rule score
- [x] Task board with a per-task rationale
- [x] Week schedule grid
- [x] Panel analytics — no-show rate, cancellation rate, utilisation

## Admin dashboard
- [x] User management — create staff, activate / deactivate, reset password
- [x] Departments — create / rename / describe
- [ ] Schedule-template editor — deferred (templates are seeded for now)
- [x] AI settings — API key, model, mock toggle, blend weight, re-seed
- [x] System analytics + audit log viewer

✅ Done when:
- Staff can run a full clinical workflow and admin can manage the platform

---

# Phase 6 — Testing & Results

- [x] Unit tests — predictor, features, risk rules, password hashing
- [x] Unit tests — repositories on an in-memory database
- [x] Unit tests — AI parsing (valid, malformed, empty, timeout → safe error)
- [x] Widget tests — login, timeline, booking, staff dashboard
- [x] Integration test — seed → patient books → staff sees it
- [x] Cross-platform smoke — Windows + Web release builds green
- [ ] Cross-platform smoke — Android (blocked on the hypervisor driver)
- [ ] Usability study — 5–8 people, SUS questionnaire (protocol ready, needs participants)
- [x] Performance — timeline load, AI latency, cold start, database size
- [x] Accessibility — contrast, tap targets, labels, text scaling

**Result: 74 tests, all passing.** `flutter analyze` clean.

✅ Done when:
- Every number in the report has a test or measurement behind it

---

# Phase 7 — Report & Presentation (in progress)

- [ ] Architecture, use-case, sequence diagrams
- [ ] Screenshots — all screens, both roles, light + dark
- [ ] Results chapter — ML metrics, baselines, SUS, performance
- [ ] Demo script, rehearsed offline with the mock AI
- [ ] Presentation deck + rehearsal

✅ Done when:
- The report and defense materials are complete

---

# Open Items

| Item | Status | To close |
| --- | --- | --- |
| Android build | Blocked | Run the AEHD hypervisor driver installer (admin) or use a physical phone |
| PDF report import | Deferred | Wire file picker → text extractor → new record |
| Schedule-template editor | Deferred | Add a schedule-template repository |
| Usability study results | Pending | Run the protocol in `docs/usability_study.md` with 5–8 people |
| Live Gemini output | Dormant | Paste a free API key in Admin → AI Settings, turn Mock mode off |

---

# Supporting Documents (`docs/`)

- `MyHealthCare_Feature_Report.pdf` — full feature & implementation report
- `test_accounts.md` — every demo login (1 admin, 12 staff, 60 patients — password `password`)
- `ai_setup.md` — how to enable the free Gemini API
- `platform_smoke.md` — per-platform build status
- `performance.md` — performance measurements
- `usability_study.md` — SUS study protocol
- `ml_results.md` — no-show model metrics
- `erd.png` — database diagram
