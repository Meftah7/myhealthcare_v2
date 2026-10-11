# Final checkout execution evidence

11 October 2026. Exact commands, capture environment and limitations are in [patient rebuild status](../patient_rebuild_status.md).

- [Entire Flutter suite](flutter_full_suite.txt): 693 passed, 0 failed, 0 skipped; exit 0. Includes the six previously failing tests and both opt-in capture tests.
- [Flutter analysis](flutter_analysis.txt): exit 0; 146 informational lints, no errors/warnings.
- [Server tests](server_tests.txt): 21 passed, 0 failed/skipped; exit 0.
- [Release web build](web_release.txt): successful `build/web`; exit 0.
- [Live AI evaluation attempt](live_ai_blocked.txt): missing MYHEALTH_AI_KEY; blocked, exit 2; no live evaluation performed.

These complete terminal logs use synthetic test data. No provider credential was available or printed. Debug Drift/PDF notices remain visible in the passing test log; PowerShell's stderr `NativeCommandError` wrapper around informational analyzer output does not override the separately recorded native exit code.
