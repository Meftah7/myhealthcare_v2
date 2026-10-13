# Staff and admin checklist (2026-10-13 brief)

`MyHealth_Staff_Admin_Preview.html` was not found in the repository or Downloads; the written colour/layout spec in the brief was used instead. Owner decisions (2026-10-13): build dental FDI charting, the four calculators, pharmacy stock/batches and shared-server adapters as real features; keep the PDF footer unchanged; add a Dental department and schedule.

## 1. Implemented and verified (automated tests)

Roles and access
- [x] Five validated staff roles (`StaffRole`); `Consultant` is an explicit Doctor alias; missing/unknown titles get no permissions and a "role not set up" workspace. (`test/security/staff_roles_test.dart`)
- [x] Separate permission sets: reception and pharmacy never read charts, prescribe or sign; dentists have a dental scope (no result-review queue) plus `recordDentalChart`; no role both prescribes and dispenses. Enforced in repositories.
- [x] Staff patient picker applies clinical scope (appointments, care assignments, walk-ins) before its limit. (`test/security/patient_picker_scope_test.dart`)
- [x] "Dr" only for doctors and dentists (`staffDisplayName`).

Receptionist
- [x] Front-desk workspace: CPR/ID/name/phone search, desk booking (identity checkbox, real open slots, server reference, idempotent), arrivals with idempotent check-in.
- [x] Issued-copy confirmation by printed reference: lookup shows type, patient, date and status; only valid, rendered copies can be confirmed; SHA-256 checked; who/when/why recorded; never signs or creates versions. (`test/services/front_desk_test.dart`)

Pharmacist
- [x] Prescription queue with prescriber identity; outcomes dispensed/partial/held/clarification; patient verification; never dispensed twice.
- [x] Stock batches: receive (idempotent, expired refused), list with expired / expires-within-30-days / out-of-stock labels, dispense from a batch decrementing exactly once (optimistic version check), short stock refused. (`test/services/pharmacy_and_tasks_test.dart`)
- [x] Future work label kept only for barcode scanning and supplier ordering.

Dentist
- [x] Dental department and Sun–Thu schedule (seed v17); patients can book the dentist.
- [x] FDI dental chart (permanent and primary numbering): append-only observations / planned / completed entries bound to the patient's own visit, completed entries fulfil a plan on the same tooth, author and time recorded; reception cannot read; doctors cannot write. Tooth grid with screen-reader labels and icons (not colour alone). (`test/services/dental_chart_test.dart`, `test/features/dental_chart_screen_test.dart`)

Tasks and handover
- [x] `next_review_at` is a first-class column (v32, backfilled from history); a passed review shows as overdue; waiting work sorts by review time; shown on cards separately from the deadline. (`test/features/task_review_order_test.dart`)
- [x] Handover state derived from history: pending (no transfer), accepted, declined, expired; shown on the task detail.
- [x] Board retry refreshes the list actually displayed, including Team work.

Dashboards (patient design language)
- [x] Shared kit `lib/core/ui/patient/workspace_home.dart`: navy feature card (#102D51 / #172F4E, white text > 12:1), four shortcut tiles with real badges, rounded workspace cards (1–3 columns by width).
- [x] Clinician Today: feature card with role and department, shortcuts, role-aware workspace cards, Quick Access directly below, owned work and attention panels side by side on wide screens; loading/failed figures show "—", never 0.
- [x] Admin overview: one feature card for operational work (loading/failed states explicit), filter chips, shortcuts, People & access / Clinic / Documents / Finance / Referrals / Reports cards, Quick Access, attention and activity panels.
- [x] Layout tests at 320 dp and 200% text in English and Arabic. (`test/features/figma_design_test.dart`, `test/features/role_workspaces_test.dart`, `test/features/admin_profile_test.dart`)

Schedule (existing structure kept)
- [x] Year / month / day views, zoom, queue and actions unchanged.
- [x] Mini-month tile height measured from the real label style and text scale (fixed an overflow at 320 dp, 200%); month labels never wrap.
- [x] Month cells and mini-months have screen-reader labels (date, today, visit count, selected) in English and Arabic; month cells scale down instead of overflowing.
- [x] Tests: six-week grid for every month 2024–2030, leap-year and year boundaries, labelled cells, today marked, now-line only on today, no overflow. (`test/features/schedule_calendar_test.dart`, `test/features/staff_schedule_test.dart`)

Documents, finance, reports
- [x] Admin work queue filters document requests, reminders and outbox in SQL (no whole-table scans); the verification-manifest export reads all versions by design.
- [x] One BHD formatter (`fmtBhd`, three decimals). Finance CSV is labelled as a copy and reports failure.
- [x] Reports/forecast, integrations and backup screens already state their limits (no predictions, simulated payments, no backup worker).

Shared server (section 20)
- [x] Server v2 schema: appointments, messages, invoices, append-only payments; backups record their schema version.
- [x] Endpoints with server-side authorization, versions and idempotency: book (patient for self, desk for anyone; clash → 409), cancel, desk check-in; threads, messages (care relationship required, admins excluded), mark read; invoices and desk payments in integer fils (never above what is due, `recordedOnly`). (`services/shared_api/clinic_ops.test.mjs`)
- [x] Shared workspace views for appointments, messages and billing; never shows success the server did not confirm; failed sends keep the draft and retry with the same key. (`test/features/shared_clinic_views_test.dart`)
- [x] Shared workspace header uses the myhealth lockup.

Branding
- [x] See `docs/branding.md`.

Round 4 (2026-10-13, owner decisions: full app on the shared server; block schedule changes until resolved)
- [x] Encounter context bar on every staff screen while a visit is open (patient, ID, visit, status, responsible clinician, stage); clears on completion and on account change. Stages: not started / draft / draft saved — awaiting a doctor's signature / save failed / signed and completed. (`test/features/encounter_context_test.dart`)
- [x] People & Access: staff profile sections (identity, role & assignment, clinical credentials, scoped permissions, temporary cover); patient and department pickers replace raw ID fields; lists show dates/status instead of record IDs. (`test/features/admin_people_access_test.dart`)
- [x] Schedule change preview: lists the bookings a change would uncover; saving is blocked (inside the transaction) until they are moved to an authorized, available replacement; bookings already outside the current slot grid never block. (`test/services/schedule_change_test.dart`)
- [x] Referral/home-visit wording: "Arranged in clinic" / "Actioned in clinic" and a local-only notice on both admin screens.
- [x] Audit log entries link to the admin screen for the record where authorized (none for clinical entries); actor names instead of IDs.
- [x] Every-button audit: code scan found no empty callbacks, placeholder messages or TODO handlers (one intentional tap-swallow); every linked route (60+) resolves. (`test/features/route_reachability_test.dart`)
- [x] Patient re-check: 11 sections × 320/768/1024 dp × Small/Default/Large render without layout errors; 99 screenshots in `docs/rebuild_screenshots/patient_widths/`. Messages and calculators no longer carry a Future work label (owner-approved scope). (`test/visual/patient_widths_test.dart`)
- [x] Full app on the shared server (see `services/shared_api/README.md`): server repositories for accounts, directory, slots, appointments, consultations, prescriptions, pharmacy, dental, messages, billing and tasks; visible "Not available in shared mode" everywhere else; direct-database screens replaced by an explanation; shared admin home. Verified end to end against the real Node server (`test/shared/shared_mode_e2e_test.dart`, `services/shared_api/clinical_ops.test.mjs`).

## 2. Implemented, awaiting manual/device verification

- [ ] TalkBack/VoiceOver order and focus return for the new sheets (desk booking, copy confirmation, dispensing, receive stock, dental tooth sheet) and the calendar labels.
- [ ] On-screen keyboard behaviour of those sheets on phones.
- [ ] Launcher icons and native splash on real Android/iOS/Windows devices (resources generated only).

## 3. Blocked by toolchains, credentials or external integrations

- [ ] Android, iOS and Windows builds: this machine has no Android SDK, no Visual Studio, and iOS needs macOS (`flutter doctor`). Web release build verified.
- [ ] Live report-AI evaluation (server-held `MYHEALTH_AI_KEY`).
- [ ] Shared mode still lacks server adapters for records/timeline, vitals, documents/sick leave, referrals, home visits, walk-ins, result reviews, family links, notifications, audit and the local admin workspace; these show "Not available in shared mode" (by design, never local data).
- [ ] Payment gateway (none); external referral transport and home-visit dispatch (none).

## 4. Awaiting owner approval

- [ ] Terms/Privacy drafts; PDF footer contact details (kept unchanged by owner decision).
- [ ] Clinic policy for which roles may reprint/release copies beyond confirmation.

## 5. Future work (outside current scope)

- Barcode scanning and supplier ordering for pharmacy stock.
- AI prioritization and predictive capacity/no-show models beyond the documented offline model.
