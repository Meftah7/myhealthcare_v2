# myhealth branding (2026-10-13)

Approved mark: navy rounded square, white crescent, teal flowing M with a
stethoscope. Displayed name: **myhealth** (lowercase, no "AI"). Master image:
`assets/branding/myhealth-logo-original.png` (unchanged copy of the supplied
file). Asset list and generator: `assets/branding/README.md`,
`tool/branding/generate_brand_assets.py`.

## Where the branding is applied

| Area | Location | How |
| --- | --- | --- |
| Shared component | `AppLogo`, `AppBrandLockup`, `kBrandName` in `lib/core/presentation/app_scaffold.dart` | Real asset, `BoxFit.contain`, never tinted; `decorative` avoids double announcements beside the wordmark. |
| Flutter splash | `splash_overlay.dart` | `AppLogo(height: 112)` + "myhealth". |
| Onboarding | `onboarding_overlay.dart` | `AppBrandLockup`. |
| Sign-in / registration / recovery | `auth_scaffold.dart` (all auth screens) | Decorative logo + "myhealth" wordmark. |
| Patient, staff (all five roles), admin shells | `app_shell.dart` | Drawer/sidebar lockup; rail shows the logo. |
| Patient drawer | `patient_drawer.dart` | `AppBrandLockup`; About dialog name "myhealth". |
| Shared-server workspace | `shared_workspace_app.dart` | App-bar lockup with "Shared workspace" subtitle; window title "myhealth". |
| Generated PDFs | `lib/services/pdf/brand_pdf.dart` (shared), `clinic_pdf.dart` (invoices, visit summaries, records, reports), `issued_sick_leave_pdf.dart` | Embedded `myhealth-logo-pdf.png` beside the name in the header only; never behind text, never a seal/signature. |
| Text | ARB values (EN/AR), Dart string literals, draft policies | "MyHealth Care" / "MyHealth" / "ماي هيلث" → "myhealth". |
| Android | launcher (legacy + adaptive), native splash (`launch_background.xml` + `splash_logo`), `android:label` | Generated; adaptive background `#012D5E`. Monochrome `ic_stat_myhealth` prepared; no notification code uses a small icon yet. |
| iOS | `AppIcon.appiconset` (opaque, full bleed), `LaunchImage` (120 pt), display name | Generated. |
| Web | `favicon.png`, `icons/Icon-*.png`, maskable icons, `manifest.json`, `index.html` title | Generated; theme colour `#012D5E`. |
| Windows | `app_icon.ico`, window title, `Runner.rc` product name | Generated. |

macOS and Linux runners do not exist in this repository.

## Document authenticity

- New issuances freeze `brandMark: myhealth-logo-2026-10` in the template snapshot; only those (and drafts) render the logo.
- Versions issued earlier have no mark and keep their frozen clinic name (fallback "MyHealth Care" for snapshots that predate it); already-rendered copies are stored bytes and are never regenerated (`test/features/branding_test.dart`).
- No template approval was changed; template wording is untouched.
- Uploaded and third-party PDFs are not modified.

## Intentional remaining old-name references

- Identifiers: `MyHealthCareApp`, l10n keys such as `paAboutMyHealth`, package `myhealthcare`, database/bundle IDs.
- `PRODID:-//MyHealth Care//…` in calendar exports (technical product identifier).
- Historical snapshot fallback in `document_service_impl.dart`.
- Code comments.

## Owner review

- The PDF footer (pre-existing, not added here) shows "Manama, Kingdom of Bahrain · +973 1700 0000 · care@myhealth.demo". Confirm or replace with approved contact details.
- Terms/Privacy remain drafts awaiting approval (only the product name changed).

## Clearing cached icons after rebuilding

- Android: uninstall the app, then `flutter clean && flutter run` (launchers cache icons by package). Some launchers need a restart.
- iOS: delete the app from the device/simulator, then rebuild; restart the simulator if the old icon persists.
- Web/PWA: `flutter build web --release`, then hard-reload (Ctrl+Shift+R). An installed PWA needs uninstall/reinstall for the new manifest icon; the Flutter service worker updates on the next load.
- Windows: `flutter clean`, rebuild; if Explorer shows the old icon, run `ie4uinit.exe -show` or sign out/in to refresh the icon cache.
