# Final checkout execution evidence

Latest checkout: [GitHub Pages test font portability](ci_font_portability.md), 12 October 2026. Entire CI-style suite: **722 passed, 0 failed, 2 expected optional-capture skips; exit 0**. This supersedes the earlier capture-enabled full-suite run below for the final test-helper checkout; application source and font assets are unchanged.

12 October 2026, reference-screen iteration. Current logs:

- [Entire final Flutter suite](reference_flutter_full_suite.txt): **724 passed, 0 failed, 0 skipped; exit 0; 6m56s**, after every final code/test change. All three opt-in capture suites ran.
- [Flutter analysis](reference_flutter_analysis.txt): exit 0; no errors/warnings, 146 informational lints.
- [CI formatting guard](reference_format.txt): 529 files, 0 changes; exit 0.
- [Server tests](reference_server_tests.txt): 21 passed, 0 failed/skipped; exit 0.
- [Release web build](reference_web_release.txt): successful `build/web`, exit 0; 78.3s compiler step.
- [Credential availability](reference_ai_configuration.txt) and [live evaluation attempt](reference_live_ai_blocked.txt): missing MYHEALTH_AI_KEY; blocked, exit 2, no live responses evaluated. No secret values printed.
- [Narrow-phone readability rerun](reference_readability_fix.txt): six cases passed; [booking fixture rerun](reference_booking_fixture_fix.txt): two tests passed. These targeted logs supplement the entire-suite evidence.

Actual screenshots: [reference-screen gallery](../rebuild_screenshots/reference_tools/README.md). Exact commands, limitations and remaining external gates: [current status](../patient_rebuild_status.md) and [reference handoff](../patient_reference_tools.md).

## Historical evidence before this iteration

11 October 2026. Exact commands, capture environment and limitations are in [patient rebuild status](../patient_rebuild_status.md).

- [Entire Flutter suite](flutter_full_suite.txt): 693 passed, 0 failed, 0 skipped; exit 0. Includes the six previously failing tests and both opt-in capture tests.
- [Flutter analysis](flutter_analysis.txt): exit 0; 146 informational lints, no errors/warnings.
- [Server tests](server_tests.txt): 21 passed, 0 failed/skipped; exit 0.
- [Release web build](web_release.txt): successful `build/web`; exit 0.
- [Live AI evaluation attempt](live_ai_blocked.txt): missing MYHEALTH_AI_KEY; blocked, exit 2; no live evaluation performed.

These complete terminal logs use synthetic test data. No provider credential was available or printed. Debug Drift/PDF notices remain visible in the passing test log; PowerShell's stderr `NativeCommandError` wrapper around informational analyzer output does not override the separately recorded native exit code.
