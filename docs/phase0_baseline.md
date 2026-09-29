# Phase 0 Baseline

Captured: 2026-09-28  
Workspace: Windows, Flutter/Dart project  
Runtime boundary: debug/profile defaults to `demo`; release defaults to
`production`; either may be selected with `--dart-define=APP_MODE=...`.

## Reproducible checks

| Check | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze --no-pub` | Pass: no issues found. |
| Unit/widget/performance suite | `flutter test --no-pub` | Pass: 282 tests. |
| Focused production/demo regression | `flutter test --no-pub test/features/clinical_scribe_test.dart test/features/care_navigator_test.dart test/features/production_mode_ui_test.dart` | Pass: 14 tests. |
| Production web release | `flutter build web --release --no-pub --no-web-resources-cdn --dart-define=APP_MODE=production` | Pass: `build/web` produced in 95.5 seconds with bundled web resources. |
| Native builds | Not required for the approved web-only prototype release. | Android, iOS, and Windows remain non-release source targets. |
| Backup/restore | `flutter test --no-pub test/data/backup_restore_rehearsal_test.dart` | Pass on schema 18 with RPO 0 at snapshot and restore below the 10-second prototype target. |

The device database smoke test expects schema version 18, matching the current
Drift database. Native device execution is outside the approved web-only scope.

## Defects closed while establishing the baseline

- Terminal appointments cannot be reopened by marking a no-show as arrived.
- The idle timeout updates session state before asynchronous cleanup.
- Schedule-template and clinician/patient fixtures now respect repository
  invariants and care-team authorization.
- The staff patient picker no longer exposes unrelated patients.
- Production mode cannot seed/reset demo data or reveal demo credentials.
- Production AI summaries, chart summaries, scribe, and Care Navigator no
  longer silently substitute deterministic demo output for a live provider.
- The prior 10 analyzer findings were corrected.

## Evidence and limitations

- Automated coverage exercises compact/medium/expanded layouts, Arabic/RTL,
  200% text scaling, theme changes, authentication, role flows, accessibility
  guidelines, and persistence.
- Browser evidence in `docs/phase0_evidence/` confirms the production-mode
  onboarding surface. It is not a substitute for screen-reader, physical
  keyboard, keyboard-open, or real-device review.
- The suite emits Drift warnings in some tests because multiple in-memory
  `AppDatabase` objects overlap. All tests pass; fixture-lifecycle cleanup is
  tracked as technical debt rather than hidden.
- Native platform builds, manual assistive-technology checks, notification
  behavior while the app is closed, and backup/restore execution remain blocked
  by platform infrastructure or product architecture decisions.

## Baseline conclusion

Phase 0 is complete for the approved synthetic-data, web-only university
prototype. Any pilot, production, real-data, native-platform, or live-provider
scope change reopens Phase 0 and its governance/environment gates.
