# Staff and admin checklist (2026-10-13 brief)

Scope chosen by the owner: **core first**. Items not done here remain open below.
`MyHealth_Staff_Admin_Preview.html` was not found in the repository or Downloads; the written colour/layout spec was used instead.

## 1. Implemented and verified (automated tests)

- [x] Explicit staff roles: Doctor, Nurse, Receptionist, Pharmacist, Dentist (`StaffRole` in `lib/domain/enums.dart`). Stored `jobTitle` is parsed; the seeded `Consultant` title is an explicit Doctor alias. Missing/unknown titles get **no permissions**. (`test/security/staff_roles_test.dart`)
- [x] One permission set per role (`RolePermissions.forStaff`). Reception and pharmacy never get chart, prescribing or signing permissions; dentists get a dental scope (no result-review queue); no role holds both prescribing and dispensing.
- [x] Enforcement in repositories: reception/pharmacy chart reads are denied; signer qualification and credential snapshots use the role table instead of "not a nurse".
- [x] Receptionist: desk booking on a patient's behalf (`desk.appointment.book` audit, idempotent retry), desk reschedule/cancel, idempotent desk check-in (`deskCheckIn`). (`test/services/front_desk_test.dart`)
- [x] Issued-copy confirmation (`DocumentService.confirmIssuedCopy`): requires identity check and reason, refuses revoked/unrendered copies, checks the stored SHA-256, records who/when/why in `document_copy_confirmations`, never creates a version or signature, idempotent per key.
- [x] Pharmacist: prescription queue with prescriber identity and latest outcome; dispensing outcomes (dispensed / partial / held / clarification) in `medication_dispenses`, separate from the order; patient verification required; expired batch refused; never dispensed twice; retries are idempotent. (`test/services/pharmacy_and_tasks_test.dart`)
- [x] Task next review is a first-class `staff_tasks.next_review_at` column (set for waiting/blocked, cleared otherwise; v32 migration backfills from history), distinct from the original due date and shown on task cards.
- [x] Role-specific Today workspaces for reception, pharmacy and unknown roles, built from the patient components (`role_workspaces.dart`). Layout tested at 320 and 1440 dp, English/Arabic, 200% text. (`test/features/role_workspaces_test.dart`)
- [x] Admin staff creation offers all five roles (EN/AR labels); credential kind follows the role.
- [x] "Dr" prefix only for doctors and dentists (`staffDisplayName`) in the staff directory, profile, quick actions, dashboard title and admin pickers.
- [x] Schema v32 + seed v16; demo snapshot regenerated.
- [x] Task board retry refreshes the list actually shown (Team work included); prioritise reload refreshes the displayed queries.
- [x] Next review drives the board: a passed review shows as overdue; waiting work is ordered by review time. (`test/features/task_review_order_test.dart`)
- [x] One BHD formatter (`fmtBhd`, three decimals) for displayed money in patient payments, admin billing, finance report and people profile; amount inputs use three decimals. (`test/features/bhd_format_test.dart`)
- [x] Finance CSV is labelled as a copy and now reports failures instead of failing silently.
- [x] Existing (verified present): self-deactivation protection, deactivation preview and blocking until bookings/tasks are reassigned (`booking_safety.dart`).
- [x] myhealth branding across the app, platforms and PDFs — see `docs/branding.md`.

## 2. Implemented, awaiting manual/device verification

- [ ] Front desk and pharmacy sheets with the on-screen keyboard on phones; screen-reader order and focus return after closing a sheet.

## 3. Blocked by external integrations / credentials

- [ ] Live report-AI evaluation (server-held `MYHEALTH_AI_KEY`).
- [ ] Shared-server adapters for appointments, consultations, messaging, billing and full documents (section 20) — not started.

## 4. Awaiting owner approval

- [ ] Terms/Privacy drafts.
- [ ] Clinic policy for which roles may reprint/release copies beyond confirmation.

## 5. Not done in this pass (remaining brief items)

- Full visual redesign of staff/admin shells, admin overview, People & Access sections, reports/audit/settings wording (sections 2, 4, 14–17, 19).
- Schedule redesign and new schedule tests (section 11) — existing schedule left unchanged.
- Handover state UI (pending/accepted/rejected/expired) review (section 12).
- Patient-access shortcut picker pagination audit (section 13).
- Receptionist document lookup by human-readable reference (confirmation currently takes the issued-version ID).
- Dentist schedule/department seed; advanced dental charting stays **Future work**.
- Pharmacy stock/barcode/expiry alerts — shown as **Future work** in the pharmacy workspace.
