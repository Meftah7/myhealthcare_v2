# MyHealth patient rebuild — current status

Updated 12 October 2026. The reference-screen iteration continues on `main` after the prior rebuild merge. Existing work is preserved. The full Flutter app uses local Drift; the shared API pilot remains a separate environment. After local verification, the owner explicitly requested committing and pushing the verified changes to `main`. GitHub Pages execution is a subsequent CI check; local success does not certify remote deployment.

## Implemented and verified

- Patient navigation is based on application window width: bottom tabs below 600px, NavigationRail at 600–1023px, permanent 272px sidebar from 1024px. Destination order remains Home, Records, Appointments, Messages, Services. Messages has a visible Future work badge; the compact appointment action retains its rounded blue treatment.
- Compact headers expose the native drawer. Medium windows expose a labeled Account & preferences rail control. Expanded windows expose branding, primary destinations and account actions in one scrollable sidebar, with no drawer or header hamburger. All account labels/routes, catalogue permissions, About/policy actions and confirmed sign-out use the same implementation. Core account destinations now have a typed definition in patient_account_action.dart; supplementary destinations retain PatientCatalog definitions.
- The patient content subtree stays in the same position across width changes and drawer opening. Tests verify route, content element and booking-draft preservation; back dismisses the native drawer, and sign-out remains reachable on a 1100×420 window. Dedicated full-screen booking routes remain outside the shell. Staff/admin navigation retains its previous behavior.
- Settings exposes exactly Small, Default, Large, reusing 0.85, 0.92 and 1.0. Persisted names remain xSmall, small and medium, respectively: this migrates meaning without changing a saved user's rendered size. Legacy large/xLarge saves retain 1.15/1.3 internally, displayed as Large, until the user chooses one of the three options. No extra size is exposed. New, missing, invalid and reset preferences select Default (0.92). Save failures roll back. English/Arabic captions explain that OS accessibility scaling still applies; the app multiplies the platform TextScaler without disabling or clamping it.
- Preserved existing completed work: booking invalidation, dependent-access rechecks, bounded doctor availability, duplicate/conflict handling and repository-backed confirmation; individual records/detail/documents, medications/imaging/vitals, notifications/family/messages redesigns; grounded report questions, source authorization, context clearing, coverage disclosure and honest provider failures. See booking_journey_test.dart, report_chat_test.dart and the preservation matrix. Weather/News remain explanation-only catalogue entries, without sources or tabs.
- Fractional Default scaling exposed a 0.28px staff year-calendar overflow. Rounding the calculated month-label height upward fixes it without altering staff navigation or OS scaling.

## First launch and service detail pages (2026-10-12)

**Working**
- Startup splash: the MyHealth mark on the patient light/dark surface, shown only until bootstrap finishes and the session is restored (no fixed delay). After 8 s it switches to a "taking longer than usual" state with Try again; a failed bootstrap keeps the router's existing error/retry screen. The router's own loading screen uses the same mark.
- Onboarding (existing overlay, improved, not duplicated): two swipeable pages with original vector illustrations — (1) find a doctor and book, with a progress indicator, Skip and an arrow Next; (2) records, documents and PDF report explanations, with Get Started. Shown only while no completion preference exists; Skip/Get Started save it. The preference is independent of the session, so it is not shown again after sign-out. Sign-in is routed underneath, so a protected deep link keeps its `?from=` destination; no patient data renders for signed-out users.
- Service detail page: one shared layout (back, small original icon image, soft-blue category label, Future work badge, heading, description, bottom action bar that never covers content; 640 px max width on tablet/desktop), opened from the Services catalogue at `/patient/services/detail/:id`.
- Health Trackers (new Services entry, Future work badge kept): **View Vitals** opens the working Vitals & Trends screen. Copy lists only stored readings; no continuous monitoring claim.
- Home: the "Needs your attention" strip was removed from the patient dashboard at the owner's request.

**Planned (Future work explanation only — no action beyond "About Future work")**
- Blood Donation: no donor registration, eligibility, appointments or blood-drive claims.
- E-Referral: no record transfer to another hospital; no referral integration.
- Complete Checkup: no checkup package is configured (the routine check-up visit type is not a package), so no booking link and no promised tests.
- Water tracking: not built; not added to the Nutrition calculator.
- Wearables / Smart Watches: no device integration or permissions; no Connect/Sync action.

**Evidence**: `test/features/onboarding_test.dart` (first launch, Skip, Next, swipe, Get Started, returning launch, Arabic RTL, sign-out, protected deep link, stalled and failed startup) and `test/features/service_detail_test.dart` (all six entries open and return, Future work sheet, View Vitals, signed-out deep link resumes, short-phone Arabic dark Large + OS 1.3× and desktop Small layouts). Renders: [first_launch_services](rebuild_screenshots/first_launch_services/).

## Latest checkout: GitHub Pages test portability

The supplied Ubuntu CI log failed in `text_size_layout_test.dart` setUpAll (676 passed, one failed, two skipped). Test icon loading depended on a Windows SDK fallback and lowercase SDK font filename. All four affected layout/capture helpers now load the bundled Material Icons asset through shared `test/support/fonts.dart`; CI uses the expanded test reporter to expose exception details.

After the final portability changes, `flutter test --no-pub --reporter expanded` passed **722 tests, 0 failures, 2 expected skips; exit 0; 6m01s**, with capture environment variables unset as in CI. Only the two optional screenshot-output tests were skipped; bilingual text/layout and reference-screen tests executed. Formatting passes for **530 files, 0 changes**. Analysis passes with no errors/warnings and 146 informational lints. Application source and font assets did not change, so the actual screenshot evidence below remains applicable. [Portability diagnosis, changed files and verification](verification/ci_font_portability.md) records the current checks. Actual Ubuntu execution remains to be confirmed after committing/pushing and rerunning Pages; no push or deployment was performed here.

The release build with actual Pages flags also passed: `flutter build web --release --no-pub --base-href /myhealthcare_v2/ --no-web-resources-cdn --dart-define=APP_MODE=demo` produced `build/web`, exit 0 (87.1s compiler step). Complete current command logs are linked in the portability evidence.

## Reference-screen implementation and verification

The reference-screen iteration adds the Home shortcut strip, routed Emergency Services, clinician search/detail refinements, grouped calculator and converter directories, three lab converters and a hospital unavailable-state sheet with the existing clinic fallback. [Feature inventory and changed files](patient_reference_tools.md) maps all ten supplied images to working, reused or unavailable capabilities. [Actual Flutter gallery](rebuild_screenshots/reference_tools/README.md) contains 78 captures across phone/tablet/desktop, English light and Arabic dark. Automated checks additionally exercise all three preferences, both languages/themes and independent OS scaling.

Verification caught long new headings splitting words at 320px with legacy maximum app text and OS 2×/3×. They now reuse `ReadableLabel`, which preserves the OS scaler and makes oversized intact words horizontally scrollable. All six affected patient readability cases passed. Screenshot captures wait for the Copy-button enable animation. A repeat across midnight exposed a booking fixture that assumed today's +3 day was empty; it now selects a weekday without seeded visits while retaining opening-time, slot-count and confirmed-booking assertions. Both booking tests passed, and no database data is deleted. Final entire-suite results after these corrections are recorded below; historical results and targeted reruns are not current-checkout proof.

Final checkout checks on 12 October 2026, after the heading, capture-timing and booking-fixture corrections:

| Check | Exact command | Result |
| --- | --- | --- |
| Entire Flutter suite | `flutter test --no-pub --reporter expanded` | **724 passed, 0 failed, 0 skipped; exit 0; 6m56s.** All three capture suites enabled. |
| Formatting CI guard | `dart format --output=none --set-exit-if-changed lib test integration_test test_driver` | **529 files, 0 changes; exit 0.** |
| Flutter analysis | `flutter analyze --no-pub --no-fatal-infos` | **Exit 0; 0 errors, 0 warnings, 146 informational lints.** |
| Relevant server tests | `node --test services/report_ai/evaluate.test.mjs services/shared_api/ai.test.mjs services/shared_api/server.test.mjs services/document_verification/server.test.mjs` | **21 passed, 0 failed, 0 skipped; exit 0.** |
| Release web | `flutter build web --release --no-pub --no-wasm-dry-run` | **Exit 0; output `build/web`; 78.3s compiler step.** |
| Live AI evaluation attempt | `node services/report_ai/eval/evaluate.mjs` | **Blocked, exit 2:** MYHEALTH_AI_KEY unavailable. No live evaluation performed. |

Set capture variables before the full-suite command:

```powershell
$env:REFERENCE_TOOLS_CAPTURE_DIR = 'docs/rebuild_screenshots/reference_tools'
$env:TEXT_SIZE_CAPTURE_DIR = 'docs/rebuild_screenshots/text_size'
$env:CAPTURE_DIR = 'docs/rebuild_screenshots/final_audit'
```

[Complete current execution evidence](verification/README.md) separates these results from historical logs. New coverage includes all three analyte factors, reverse/round-trip conversions, localized/invalid input, swaps/copy, emergency launch failure, calculator reuse/collapse, directory loading/error/empty contracts, clinician detail/booking continuation, hospital dismissal/fallback/draft preservation, authorization and the bilingual/theme/OS-scale layout matrix. The 78 new renders and 73 existing navigation/page captures use real Flutter widgets, bundled fonts and synthetic accounts. Visually inspected phone/tablet/desktop captures confirm readable numeric units, working-control contrast, blue branding, modal barriers and Quick Access below Services. They do not certify physical devices or TalkBack/VoiceOver. Informational analyzer debt and debug Drift/PDF notices remain disclosed.

## Previous rebuild verification — before the reference-screen iteration

The entire suite was rerun after the six original failures were fixed and after the final added resize/focus tests and privacy-asset corrections. Earlier targeted reruns are not the evidence for this result. No app/test/policy assets changed after that historical run began; subsequent edits only recorded evidence and acceptance instructions.

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

The project is not marked fully complete while these external acceptance gates remain open. Verification did not deploy, reset the database or discard existing work. The owner's subsequent request authorizes publication to `main`; remote CI/deployment results must be checked separately.
