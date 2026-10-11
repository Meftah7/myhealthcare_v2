# MyHealth patient rebuild — current status

Updated 11 October 2026 on `patient-rebuild-v2`. This replaces the earlier status table, which predates booking hardening, grounded follow-up chat and individual patient-screen redesigns. Existing uncommitted message-thread and capture-test edits were preserved. The full Flutter app uses local Drift; the shared API pilot remains a separate environment.

## Implemented and verified

- Patient navigation is based on application window width: bottom tabs below 600px, NavigationRail at 600–1023px, permanent 272px sidebar from 1024px. Destination order remains Home, Records, Appointments, Messages, Services. Messages has a visible Future work badge; the compact appointment action retains its rounded blue treatment.
- Compact headers expose the native drawer. Medium windows expose a labeled Account & preferences rail control. Expanded windows expose branding, primary destinations and account actions in one scrollable sidebar, with no drawer or header hamburger. All account labels/routes, catalogue permissions, About/policy actions and confirmed sign-out use the same implementation. Core account destinations now have a typed definition in patient_account_action.dart; supplementary destinations retain PatientCatalog definitions.
- The patient content subtree stays in the same position across width changes and drawer opening. Tests verify route, content element and booking-draft preservation; back dismisses the native drawer, and sign-out remains reachable on a 1100×420 window. Dedicated full-screen booking routes remain outside the shell. Staff/admin navigation retains its previous behavior.
- Settings exposes exactly Small, Default, Large, reusing 0.85, 0.92 and 1.0. Persisted names remain xSmall, small and medium, respectively: this migrates meaning without changing a saved user's rendered size. Legacy large/xLarge saves retain 1.15/1.3 internally, displayed as Large, until the user chooses one of the three options. No extra size is exposed. New, missing, invalid and reset preferences select Default (0.92). Save failures roll back. English/Arabic captions explain that OS accessibility scaling still applies; the app multiplies the platform TextScaler without disabling or clamping it.
- Preserved existing completed work: booking invalidation, dependent-access rechecks, bounded doctor availability, duplicate/conflict handling and repository-backed confirmation; individual records/detail/documents, medications/imaging/vitals, notifications/family/messages redesigns; grounded report questions, source authorization, context clearing, coverage disclosure and honest provider failures. See booking_journey_test.dart, report_chat_test.dart and the preservation matrix. Weather/News remain explanation-only catalogue entries, without sources or tabs.
- Fractional Default scaling exposed a 0.28px staff year-calendar overflow. Rounding the calculated month-label height upward fixes it without altering staff navigation or OS scaling.

## Final checkout verification — 11 October 2026

The entire suite was rerun after the six original failures were fixed and after the final added resize/focus tests and privacy-asset corrections. Earlier targeted reruns are not the evidence for this result. No app/test/policy assets changed after this final run began; subsequent edits only record evidence and acceptance instructions.

| Check | Exact command | Final result |
| --- | --- | --- |
| Entire Flutter suite | `flutter test --no-pub --reporter expanded` | **693 passed, 0 failed, 0 skipped; exit 0; 5m32s.** Both opt-in capture tests ran. |
| Flutter analysis | `flutter analyze --no-pub --no-fatal-infos` | Exit 0; no errors or warnings, 146 informational lints. |
| Relevant server tests | `node --test services/report_ai/evaluate.test.mjs services/shared_api/ai.test.mjs services/shared_api/server.test.mjs services/document_verification/server.test.mjs` | **21 passed, 0 failed, 0 skipped; exit 0.** Includes mocked AI contracts, access/ownership, failures, evaluation grading and document verification. |
| Release web | `flutter build web --release --no-pub --no-wasm-dry-run` | Exit 0; output `build/web`. |
| Real-provider evaluator | `node services/report_ai/eval/evaluate.mjs` | **BLOCKED, exit 2:** MYHEALTH_AI_KEY unavailable. No live responses were evaluated. |
| Patch whitespace | `git diff --check` | Exit 0. Git emits existing CRLF normalization notices. |

Before the full-suite command, set these PowerShell environment variables to include real captures:

```powershell
$env:TEXT_SIZE_CAPTURE_DIR = 'docs/rebuild_screenshots/text_size'
$env:CAPTURE_DIR = 'docs/rebuild_screenshots/final_audit'
```

Complete execution logs are in [verification](verification/). The successful test run also emits debug-only Drift multiple-instance notices and PDF Helvetica Unicode notices. The capture helpers create separate `NativeDatabase.memory()` executors; they do not share a production database. These notices are recorded, not counted as failed tests. Analysis findings remain informational technical debt, not an analyzer-clean claim.

Automated layout evidence covers all three preferences × English/Arabic × light/dark at 360×800, 390×844, 599/600px and 1023/1024px breakpoint edges, 768×1024, 1366×768, 1920×1080 and 1100×420. Home, Services, drawer/sidebar, settings, badges, cards and navigation render without framework overflow errors. Badge text remains within its line bounds. Preferences also support independent OS 2× scaling on phone/tablet/desktop. Tests explicitly preserve route/content, Home scroll offset and booking drafts during resizing, and verify drawer Back/Escape dismissal, keyboard opening, focus restoration and short-sidebar sign-out. Preference tests cover every legacy stored value, new/reset defaults and save rollback. Policy tests load both languages, assert draft status and exercise signed-out policy access. Booking/report-chat/access tests remain part of the full run.

There are 39 text/navigation captures and 34 patient-page audit captures, produced from actual Flutter widgets with bundled fonts and Material icons, using synthetic accounts. [Screenshot gallery](rebuild_screenshots/text_size/README.md) links phone, tablet and desktop in both languages/themes and all three preference choices. Actual inspected Home Quick Access captures show it immediately below Services. Weather/News remain explanation-only entries with no source integration. These renders are not physical-device or manual screen-reader evidence.

## Implemented but awaiting manual verification

Physical phone/tablet portrait/landscape, browser/device interaction, native OS text behavior, TalkBack/VoiceOver, full keyboard/focus order, drawer gestures, actual device PDF save/share and end-to-end booking/report-chat acceptance remain open. Automated resize and focus tests provide partial evidence, not a substitute. Use [manual acceptance checklist](patient_manual_acceptance.md), which contains expected results and Pending pass/fail/evidence fields. Verify active report/chat workflows through real device resizing as part of that checklist.

## Blocked by credentials

Process configuration was checked without displaying secrets: MYHEALTH_AI_KEY, MYHEALTH_AI_MODEL, REPORT_AI_ORIGIN, REPORT_AI_CLIENT_TOKEN and REPORT_AI_CLIENT_TOKENS were unavailable; no checkout .env configuration was found. Mocked integration contracts passed, but live grounding, values/units, missing information, unsupported questions, malicious embedded instructions, long reports and live failure/recovery remain **unverified**. [External review instructions](patient_external_review.md) give exact masked-terminal/secret-manager configuration, gateway/app commands, evaluator commands and recovery exercises. Never put the provider key in Flutter or source control.

## Awaiting owner approval

Bilingual Terms/Privacy screens and draft banners work. Privacy drafts now match native/browser/shared storage, exports, AI text/history processing, camera use, configured vendors and simulated payment fields. Terms remain clearly labeled drafts. [Owner decisions](patient_external_review.md) list required operator/contact, jurisdiction, hosting, retention, AI contract/location, consent, vendors, age/dependent authority, booking/payment rules and incident facts. `assets/policies/policies.json` remains draft with no approver. Approval, legal/clinical review and effective dates were not invented.

## Separate packaging limitation

Android APK generation is **blocked by the missing Android SDK**. Install/configure the Android SDK and required toolchain, resolve `flutter doctor -v`, then run `flutter build apk --release`. This does not block the verified implementation or web build. No physical native installation is claimed.

The project is not marked fully complete while these external acceptance gates remain open. No push, deployment, database reset or existing-work discard was performed.
