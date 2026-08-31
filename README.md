# MyHealth Care

An AI-assisted application for managing personal health records, appointments,
and medical-staff workflows.

University of Bahrain · College of IT — senior project.
Ali Mohamed Jaafar Mohamed (202208244) · Mohammed A.Redha Meftah (202209027).
Supervisor: Dr. Amal Ghanim.

The project answers three research questions:

| RQ | Goal |
|----|------|
| **RQ1** | Ingest scattered records (PDF reports, clinician notes) into a unified, timeline-based health profile with highlighted key events and trends. |
| **RQ2** | An AI-driven scheduler that predicts no-shows and recommends optimal appointment slots with adaptive reminders. |
| **RQ3** | AI assistance for staff daily task prioritisation and early identification of at-risk patients. |

Storage is **local-only** (Drift/SQLite) — no server, works fully offline. Data
is a **synthetic seeded dataset** (no real patient data). The AI layer is behind
an interface with a **mock implementation**, so the whole app is demoable with no
API key and no internet.

Planning docs: [`todo.todo`](todo.todo) (authoritative task tracker) ·
[`plan.md`](plan.md) (rationale) · [`DESIGN.md`](DESIGN.md) (design system).

---

## Prerequisites

- **Flutter 3.44.4 / Dart 3.12.2** (the pinned toolchain — newer Dart changes the
  dependency set, see the toolchain note in `plan.md`).
- **Windows**: Visual Studio 2022 with "Desktop development with C++".
- **Android**: Android SDK 35, plus a hardware-acceleration driver for the
  emulator (`AEHD`, Hyper-V, or WHPX) — or a physical device with USB debugging.
- **Web**: Chrome or Edge. Web integration tests also need a matching
  `chromedriver`.
- **Python 3.12+** — only for the offline ML training in `tools/ml/` (Phase 4).
- **iOS**: requires a Mac. Configured but not built here.

## Setup

```bash
flutter pub get
dart run build_runner build          # generates *.g.dart (Drift, etc.)
```

Generated files are committed, so this is only needed after changing a table,
entity, or other generated source.

## Run

```bash
flutter run -d windows
flutter run -d <android-emulator-or-device>
flutter run -d chrome
```

### Web hosting note

Drift on web prefers OPFS storage, which needs the page served
**cross-origin-isolated**:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Without those headers it falls back to IndexedDB (still persistent). See
[`web/DRIFT_WEB.md`](web/DRIFT_WEB.md).

## Seed demo data

> Implemented in P1-19…P1-21. The seeder produces a fixed-seed dataset
> (~60 patients, 12 staff, 5 departments, 2 years of history) that is
> byte-identical on every run. Once built: **Admin → AI Settings →
> Re-seed / reset demo data**, or it runs automatically on first launch.

## Add the AI API key

> Implemented in P3-06. The key is entered at **Admin → AI Settings**, stored in
> the platform secure store (`flutter_secure_storage`), and **never written to
> source or committed**. With no key the app uses `MockAiService` — every screen
> still works. `.gitignore` blocks `*.env`, `secrets.dart`, `api_keys.dart`.

## Tests

```bash
flutter analyze                       # must be clean (strict lints)
dart format --set-exit-if-changed lib test integration_test test_driver
flutter test                          # unit + widget

# Platform integration tests (Drift, and later the full smoke path)
flutter test integration_test/drift_spike_test.dart -d windows
flutter test integration_test/drift_spike_test.dart -d <android>

# Web: not supported by `flutter test -d chrome` — use flutter drive
chromedriver --port=4444 &
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/drift_spike_test.dart \
  -d web-server --browser-name=chrome --release
```

## Project layout

```
lib/
  app/        MaterialApp, router, theme (DESIGN.md), adaptive shell
  core/       Result<T> + Failure, DI registry, shared widgets
  domain/     entities + repository interfaces (the swap point)
  data/       Drift DB, DAOs, repository implementations, seeder
  features/   one folder per feature: presentation/ + application/
  services/   ai/ (mock + Claude), ml/ (no-show predictor), notifications/, ingestion/
tools/ml/     Python — offline model training (not shipped in the app)
```
