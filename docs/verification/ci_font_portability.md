# GitHub Pages test setup portability fix — 12 October 2026

The supplied GitHub log reports 676 passing tests, one failing `text_size_layout_test.dart` setUpAll and two skipped capture tests. It does not include the underlying exception stack. Inspection found that the failing setup reads Material Icons from `FLUTTER_ROOT` or the Windows-only fallback `C:/flutter`, using a lowercase SDK filename. GitHub's Ubuntu runner cannot rely on that Windows path or case-insensitive filename lookup. The same assumption also appeared in reference-screen tests and both optional capture helpers.

All four helpers now call `test/support/fonts.dart`, which loads `fonts/MaterialIcons-Regular.otf` through Flutter's test asset bundle and registers the existing `MaterialIcons` font family. The SDK directory and environment variable are no longer needed. Both affected setup paths passed their targeted checks. No tests, font rendering, accessibility assertions or application functionality were removed. `.github/workflows/static.yml` uses `flutter test --reporter expanded` so future CI failures include readable exception details.

Changed files for this fix:

- `test/support/fonts.dart` (new shared loader).
- `test/features/text_size_layout_test.dart` and `test/features/reference_tools_test.dart`.
- `test/visual/patient_screens_capture_test.dart` and `test/visual/patient_pages_audit_capture_test.dart`.
- `.github/workflows/static.yml` (test reporter only).

Local verification uses the pinned Flutter SDK on Windows. Actual Ubuntu/GitHub execution remains to be confirmed by rerunning Pages after committing and pushing the intended changes, including the new shared loader. Following verification, the owner explicitly requested pushing the verified implementation and fix to `main`; this does not certify the subsequent remote run. Existing reference-screen implementation is preserved.

Exact checks:

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test test_driver
flutter test --no-pub --reporter expanded
flutter analyze --no-pub --no-fatal-infos
flutter build web --release --no-pub --base-href /myhealthcare_v2/ --no-web-resources-cdn --dart-define=APP_MODE=demo
```

Capture variables are unset for the CI-style entire-suite run. The two optional visual capture tests are therefore skipped as in GitHub; normal bilingual text/layout tests still execute. Previous actual app screenshots remain valid because no app source or font asset changed.

## Final local verification

| Check | Result/evidence |
| --- | --- |
| Full suite, CI-style environment | [722 passed, 0 failed, 2 expected optional-capture skips](ci_font_full_suite.txt); exit 0; 6m01s. |
| Both affected setup paths | [Two targeted tests passed](ci_font_targeted.txt), exit 0. These supplement the entire suite. |
| Optional capture helpers, separately enabled | [Both tests passed](ci_font_optional_captures.txt), 0 failed/skipped; exit 0. Actual PNGs written to `tmp_ci_font_captures/`, then moved to ignored temporary `.tmp/ci_font_captures/`; this is separate from the CI-style full run. |
| Formatting guard | [530 files, 0 changes](ci_font_format.txt); exit 0. |
| Analysis | [0 errors/warnings, 146 informational lints](ci_font_analysis.txt); exit 0. |
| Pages build flags above | [Successful build/web](ci_font_pages_build.txt); exit 0; 87.1s compiler step. |

The newer-version dependency notices in the pasted log are informational; this fix does not upgrade dependencies or bypass the test gate.
