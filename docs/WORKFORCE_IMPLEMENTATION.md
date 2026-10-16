# Staff workforce implementation

Scope: implement the attached workforce brief in the existing Flutter app, retaining the patient palette, calendar and clinical safeguards. No push/deployment, database reset or credential overwrite is authorized.

## Reproduced cause

`Seeder.run()` previously advanced an older nonempty database's seed marker and returned without adding missing role accounts. A current marker also returned immediately. The regression test creates a nonempty doctor-only database at markers 15 and 17, proves doctor authentication succeeds and the other four staff logins fail, and reruns the seeder. Both tests failed before the fix (preview/workforce-login-reproduction.log) and passed after additive account repair (preview/workforce-login-repair.log).

## Implemented

- One configurable source: assets/demo/workforce.json; generated Dart constants via tools/generate_workforce.mjs; shared expansion in services/shared_api/workforce_manifest.mjs. Targets: 12 doctors, 18 nurses, 6 receptionists, 4 pharmacists, 4 dentists and 2 separate admins.
- Local additive repair in lib/data/seed/demo_workforce.dart. Resolves existing email identities, preserves hashes/passwords/inactive/locked states and edited profiles, fills missing records, avoids schedule overwrites, detects identifier/role conflicts, and exports safe stored-account metadata. Production seeding guard remains mandatory. Normal seeding no longer wipes a nonempty marker-zero database.
- Drift schema 35 adds separate nonclinical shifts, nurse intake assignments (observations use existing Vitals), explicit-member staff conversations/messages and medication clarification state. Shared schema 4 mirrors these additions; backup restore accepts the new schema.
- Connected synthetic visits, intake assignments, a signed prescription and stock are added only for known synthetic accounts and patients; existing clinical data remains intact.

The shipped demo snapshot contains **106 users: 60 patients, 44 staff and 2 admins**. Actual stored metadata is in [demo-workforce-manifest.json](demo-workforce-manifest.json), without passwords, hashes or tokens. Normal authentication rejects unknown staff roles instead of granting doctor access.

- Role Homes show actual next work, full-data statistics, shortcuts, workspace cards, attention and Quick Access. Nurse/reception/pharmacy navigation opens the relevant patient lookup, prescription and schedule workflows. The existing clinical calendar, history and dental chart remain available.
- Nursing intake persists temperature, pulse, oxygen saturation and notes against assigned encounters, with validation, version checks, retained input and safe retry. Participation remains separate from doctor ownership. Nurses cannot prescribe or sign.
- Reception uses fresh availability for appointment operations, assigns nurses and confirms copies of the exact current released document with identity, operator, time and reason.
- Pharmacy requires current signed prescriptions and recorded eligible stock batches. Full/partial supplies update global stock transactionally, enforce known ordered units and record actor history. Hold cannot resolve a clarification; the responsible prescriber must resolve it. Retry keys are bound to the original payload.
- Staff conversations have explicit membership, persisted messages, read/unread state and retry. The safe directory exposes colleague metadata; patient/clinician chat remains separate.
- Shared workforce operations, nursing/vitals, document workflows, handover, expiring coverage and time-off use authenticated server adapters. Coverage requires acceptance, preserves ownership and expires. These features do not fall back to scratch storage.
- Care Tools opens existing calculators and converters. Document replacement/release/revocation, signer checks, exact-copy guards and delivery retry preserve existing authorization safeguards.
- Demo role shortcuts wrap with full labels, without ellipsis. The account picker searches name, role, department and email. Patient blue/navy colors, theme switching and English/Arabic layouts are retained.

## Login instructions

Fresh local demo accounts use `password`; existing custom passwords are preserved. Local emails end in `@myhealth.demo`: `staff1` through `staff12`; `nurse`, `nurse2` through `nurse18`; `reception`, `reception2` through `reception6`; `pharmacy`, `pharmacy2` through `pharmacy4`; `dentist`, `dentist2` through `dentist4`; `admin` and `admin2`. The picker lists the actual accounts.

Shared demo accounts are separate. Configure the existing data/encryption settings and `MYHEALTH_DEMO_PASSWORD` (at least 12 characters), then run `node services/shared_api/cli.mjs init-demo` for an empty database. Use `repair-demo` only for an existing database already marked synthetic, and `demo-manifest` to export safe account metadata. Shared emails end in `@shared.demo`; doctors use `doctor`, `doctor2` through `doctor12`. Other prefixes match local accounts. Use the configured shared password, not the local password. Production databases never auto-seed.

## Files, migrations and API

Provisioning: `lib/data/seed/demo_workforce.dart`, `services/shared_api/workforce_demo.mjs`, the configurable JSON and generated Dart snapshot. UI/repository adapters: `lib/features/workforce/`. Shared document/vitals adapters: `lib/data/remote/`. Existing auth, router, staff dashboard, appointment, medication and pharmacy implementations were updated directly. Generated Drift/Freezed files and `web/demo_seed.sqlite` are included.

Local schema **35** adds workforce tables and nullable prescription ordered units. Shared schema **4** adds corresponding workforce/duty records, document events and exact-copy confirmations. Migrations are additive; existing credentials and histories are retained.

Principal endpoints: `/api/demo/accounts` (synthetic only); `/api/workforce/{home,directory,shifts,activity,intakes,intake-assignments,vitals,conversations,thread,messages,read,clarifications,dispensing-history,document-desk,document-copy}`; `/api/duty/{handover,offers,decide,time-off,cancel-time-off}`. Document workspace, preview, replacement, release, delivery and verification extend the existing document API. Operations enforce role, membership, patient scope and version checks.

## Verification

Final-source verification on 2026-10-16: **871 Flutter tests passed, 110 skipped; 46 Node tests passed**. Formatting checked 592 Dart files with zero changes; manifest validation and `git diff --check` passed. Analyzer exited 0 with 331 informational findings and no warnings/errors. Both the shared release and GitHub Pages release builds exited 0. The final Pages build was served locally and its doctor dashboard rendered correctly with localized visit labels; browser error reporting was empty. Logs are in `preview/workforce-release-*.log` and `preview/workforce-verified-node-tests.log`.

Coverage includes all 46 staff/admin normal logins, repeated repair/preservation, role isolation, nursing idempotency, pharmacy stock/clarification guards, team membership/unread, expiring cover, exact document copy/revocation and dentist lifecycle. Layout tests cover all roles in English/Arabic, narrow/desktop screens and enlarged text. The populated calendar passed at 320px with OS scale 1/2/3; twelve tests verify complete demo labels at 320/390/768px, both languages, scale 1/3. The design detector reported no findings (`preview/workforce-design-check.json`).

Exact CI commands:

```text
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test integration_test test_driver
node tools/generate_workforce.mjs --check
flutter analyze --no-fatal-infos
flutter test --reporter expanded
node --test tools/serve_local.test.mjs services/shared_api/*.test.mjs services/shared_api/load.mjs services/document_verification/server.test.mjs
flutter build web --release --no-web-resources-cdn --dart-define=SHARED_API_ORIGIN=http://localhost:8080
flutter build web --release --base-href /myhealthcare_v2/ --no-web-resources-cdn --dart-define=APP_MODE=demo
```

Real release screenshots in `preview/workforce-*.png` show nurse intake saved, doctor, reception, pharmacy, the Arabic dentist dashboard and all seven full demo labels. They cover light/dark themes and widths 320/390/768/1024/1440. Browser role switching and sign-out were exercised without retaining another role's screen. No browser runtime errors were reported during these checks.

## Manual and deployment limits

GitHub Pages serves the local synthetic demonstration. Shared mode requires its separately configured API, HTTPS origin, encryption/backups and operator credentials. No push/deployment has been performed; GitHub permissions, Pages settings and hosted behavior still require the actual Actions run.

Unrelated legacy shared adapters that were already unavailable are not claimed as implemented. External delivery providers, an Arabic PDF renderer, live AI providers and real clinical credentials require operator configuration/validation. Synthetic observations, schedules and signatures are demonstration data. Existing skipped tests are not counted as passes.
