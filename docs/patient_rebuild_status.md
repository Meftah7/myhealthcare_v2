# Patient rebuild — status against the TODO

Status of docs/MyHealth_Patient_Rebuild_TODO.md on branch
`patient-rebuild-v2`. "Done" means implemented and verified by tests and/or
rendered screenshots (test/visual/patient_screens_capture_test.dart). The
spec's note that the work "has not been compiled" no longer applies: this
checkout was built, analysed and tested with Flutter 3.47.2.

| § | Area | Status |
| --- | --- | --- |
| 1 | Baseline & preservation | Done: branch checkpoint, clean-baseline analyzer/test run, preservation matrix (docs/patient_rebuild_preservation.md), and before/after screenshots rendered from revision 298132e and this branch (docs/rebuild_screenshots/). Local Drift environment only; the SHARED_API_ORIGIN pilot gained report explanation but was not redesigned. |
| 2 | Blue design system | Done: PatientPalette extension, patient-only themes (staff/admin unchanged), #246BFD filled actions, #9ABEFF dark links, contrast-adjusted text (#1F5FE0 light links, #5F6770 muted). Existing licensed fonts (Lexend, Inter, Noto Naskh Arabic). |
| 3 | Shared components | Done, including FutureWorkBadge and the explanation sheet. |
| 4 | Five-tab navigation | Done: Home \| Records \| Appointments \| Messages \| Services; Messages has its own branch at its old paths; Nutrition/Profile retained branches; all patient routes need sign-in; signed-out deep links carry an allowlisted `from` only before any sign-in in the launch. Messages' Future work label is visible on the Messages page and announced on the tab; the 5-tab bar has no room for legible label text. |
| 5 | Home | Done in the required order; report hero only; quick tools page 1 = working actions, page 2 = Future work tools. |
| 6 | Quick Access | Done: Records & documents / Care & communication / Wellbeing extensions; account items moved to the drawer. |
| 6B | Native drawer | Done: Drawer on the outer shell Scaffold, menu on Home, root tabs and Services (compact and rail); closes before navigating; confirmed sign-out via the session controller; theme/language moved to Preferences. |
| 7 | Onboarding & login | Done: two pages; Skip/Get Started reveal sign-in; no guest Home. OS notification permission already requested in context from Preferences. |
| 8 | Appointments | Discovery done (landing, clinic/doctor search, region unavailable state, assistance sheet) and converges on the existing wizard. The wizard's slots/review/confirmation/conflict handling are the existing, tested behaviour — not re-verified item by item and not restyled beyond the theme. |
| 9 | Assistance & Virtual Care | Done; Virtual Care labelled Future work, video visits stated as unavailable. |
| 10 | Records & report chat | Done: report in chat header with View original, clipping disclosed, labelled states, untrusted-PDF handling, reset on report/account switch. Provider keys are server-side only: the local app no longer calls any AI provider from the device (labelled on-device summary + offline navigation guide in every mode); live explanations run on the shared server (`POST /api/reports/explain`: patient/care-team access, file ownership, re-check after the reply, coverage, rate limit) with an Explain action in the pilot app. **Remaining gap:** a provider key must be configured on a server (`MYHEALTH_AI_KEY`) and the explanations evaluated with de-identified reports before clinical use; the clinician `live-clinical-ai` capability stays disabled. Records screens use the shared themed components (patient radii), not individual redesigns. |
| 11 | Other workflows | Retained; shared cards, heroes, states and confirmations now take the patient radii/colours, so every existing patient page matches the new tokens without layout changes. Not individually redesigned. |
| 12 | Services | Done: core → promotions → tools → Future work extensions → policies. Contact Us removed (no configured support details). Terms/Privacy "Not available" (no MyHealth documents). |
| 13 | Future work policy | Done: one scope field (core / supplementary / planned) drives every label; Weather/News are planned entries with explanation sheets only — no sources, tabs or data. |
| 14 | Architecture | No database or package changes. |
| 15 | Localization & a11y | English/Arabic for all new strings; 320px readability tests (EN/AR, OS text 1–3×, max app text) cover every new route; contrast/tap-target tests pass. The upcoming-appointment carousel never auto-advances with reduced motion or a screen reader and has pause controls. |
| 17 | Verification | `flutter analyze`: no errors or warnings (138 info lints; baseline 142). Release web build succeeds. `flutter test`: 657 passed, 1 skipped (screenshot capture, opt-in via CAPTURE_DIR). Server: 12 Node tests pass. |
