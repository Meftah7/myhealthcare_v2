# Cross-platform smoke test (P6-06)

Date: 2026-08-31 · Flutter 3.44.4 / Dart 3.12.2 · Windows 11 dev machine.

| Platform | Build | Launch + core flow | Notes |
|---|---|---|---|
| **Windows** | ✅ `flutter build windows --release` → `build\windows\x64\runner\Release\myhealthcare.exe` (365 s) | ✅ seeded DB, login (all 3 roles), patient timeline/booking, staff dashboard + panel scan | Primary demo target. Also covered by 74 `flutter test` cases on the Windows VM. |
| **Web (Chrome)** | ✅ `flutter build web --release` → `build\web` (292 s); Wasm dry-run also passes | ✅ Drift runs on `sql.js` (verified in P0-11 spike); AI in-app fallback covers the no-`dart:io` path (P4-18) | Icons tree-shaken 99 %. Use `flutter run -d chrome` or serve `build\web`. Integration tests run via `flutter drive -d web-server --browser-name=chrome` (`flutter test -d chrome` is unsupported). |
| **Android** | ⛔ blocked | — | Emulator needs the AEHD hypervisor driver, which requires an elevated `silent_install.bat` run the sandbox can't perform. Code is platform-clean (no desktop-only APIs on the hot path; `path_provider` + `sqlite3_flutter_libs` are in `pubspec`). Needs a physical device or the driver installed to verify. Tracked in `todo.todo` (P0-10). |
| iOS | ⛔ not attempted | — | Needs macOS + Xcode. Out of scope for this project's hardware. |

## What "core flow" means here

1. First launch seeds the local database (12 staff, ~60 patients, full history).
2. Sign in as `patient1@myhealth.demo` / `staff1@myhealth.demo` / `admin@myhealth.demo` (password `password`).
3. Patient: home shows next appointment; timeline lists records with abnormal-lab
   indicators; booking wizard ranks slots by no-show risk.
4. Staff: dashboard shows today's schedule; "scan panel" produces risk flags and
   tasks; task board shows per-task rationale; patient chart allows note +
   prescription entry.
5. Admin: user management, departments, system analytics, audit log, AI settings.

## Re-running

```
flutter build windows --release
flutter build web --release
flutter test                       # 74 cases, ~2 min
flutter test test/performance/performance_test.dart   # writes docs/performance.md
```
