# Flutter design integration

The approved visual direction is implemented through the app's shared theme, navigation, cards, headers and forms. On 3 October 2026, the source-level audit was followed by another UI upgrade and expansion of the local reference from 78 to 141 frames. Existing business workflows remain in their mapped Flutter screens, sheets and dialogs; reference coverage is not a claim of pixel-perfect parity or runtime verification.

## Current upgrade

- Patient, staff and admin Profile use the same grouped destination rows. Patient photo editing has an explicit menu entry and an accessible camera action; unreadable photos fall back to initials. Photo selection remains device-local, with actual disabled busy controls and a scrollable sheet.
- Preferences keeps working theme, language, five text sizes, motion, contrast, notification/sound and reset controls. Labels are consistent and the text-size slider exposes meaningful spoken values.
- Personal information marks immutable email and National ID fields with lock icons. Account/detail forms across roles have a 720dp reading width.
- Payments puts open invoices and the amount owed before history. Wallet funds, top-up and saved cards load independently of invoice success; invoice failure no longer hides those controls.
- Health Records moves document tools into a sheet while preserving the allergy warning above its filters. Staff task prioritisation and notifications' mark-all-read actions move out of crowded app bars.
- Admin Dashboard adds direct Analytics, Forecast, AI Activity and Audit destinations without displacing its attention queue.
- The local preview now shows missing profile, family, billing, clinical, scheduling, session, notification and admin workflows. Authenticated password changes and staff/admin profile links point to the correct review destinations.

## Current verification

- All 141 local frames pass Chromium geometry checks; all 821 linked review targets resolve.
- Changed Dart files pass a tree-sitter syntax check. Referenced localization keys and route constants were checked against project declarations; these checks do not replace Dart analysis.
- Added three widget regression cases in `test/features/profile_billing_upgrade_test.dart`: malformed photo fallback/edit accessibility, invoice failure preserving wallet/cards, and invoice loading preserving wallet access. Profile navigation tests now scroll to Preferences before tapping.
- Runtime validation now uses the pinned Flutter 3.44.4 / Dart 3.12.2 SDK. Analysis has no errors or warnings, the web release build succeeds, and all 24 English/Arabic main-route readability cases pass at 320px with combined text scales up to 390%. Carousel interaction tests and the existing viewport/keyboard regression checks were also run. See [small-phone audit](../SMALL_PHONE_READABILITY_AUDIT.md) for the precise scope; physical-device and complete visual-state coverage remain pending.
- The expanded local board and plugin bundle have not been written to the remote Figma file. The remote file retains its original 56 frames.

## Integration decisions

- Use the reference's blue palette, white bordered cards, pale-blue mobile headers, 20dp mobile gutters, Lexend semibold headings, Inter body text, and blue heart/ECG mark. Fonts remain bundled.
- Keep real patient and clinical data, permissions, currency formatting, English/Arabic localization, dark theme, keyboard navigation, and large-text support.
- Use a three-stage booking flow and separate recovery code/password steps. Validate recovery codes through the existing repository when the password change is submitted.
- Nutrition shows calculated targets and an example daily split; it never presents example meals as consumed food. Existing calculator and meal generation remain available.
- Keep confirmations and edits in responsive sheets/dialogs where that preserves the existing app workflow. User, department, invoice, referral, and ownership edits retain their existing persistence and permission checks.
- On desktop, the 248dp sidebar and existing dashboard columns/list-detail workspaces provide the wide versions. Extra clinical and operations features remain reachable.

## Historical validation of the first integration

The following results were recorded before this upgrade. They have not been re-run for the current changes.

- Release web build passed with the Pages base path and locally bundled web resources.
- All 48 focused checks passed in one combined run, covering accessibility/contrast, responsive layouts through 200% text size, English/Arabic headers, recovery, booking, nutrition, and task update failures.
- Project analysis reported no errors or warnings; existing informational style findings remain.
- Browser review covered synthetic demo accounts. The source mapping is coverage evidence, not a claim that every individual frame has a screenshot baseline.

## Current screen mapping

Some entries share a source because they describe a dialog, embedded view or state of one route.

| Reference | Flutter implementation |
| --- | --- |
| auth-login — 01 · Sign in | [lib/features/auth/presentation/login_screen.dart](../../lib/features/auth/presentation/login_screen.dart) |
| auth-register-1 — 02 · Register / account | [lib/features/auth/presentation/register_screen.dart](../../lib/features/auth/presentation/register_screen.dart) |
| auth-register-2 — 03 · Register / details | [lib/features/auth/presentation/register_screen.dart](../../lib/features/auth/presentation/register_screen.dart) |
| auth-register-3 — 04 · Register / health | [lib/features/auth/presentation/register_screen.dart](../../lib/features/auth/presentation/register_screen.dart) |
| auth-recover — 05 · Recovery / identify | [lib/features/auth/presentation/forgot_password_screen.dart](../../lib/features/auth/presentation/forgot_password_screen.dart) |
| auth-code — 06 · Recovery / verification | [lib/features/auth/presentation/forgot_password_screen.dart](../../lib/features/auth/presentation/forgot_password_screen.dart) |
| auth-password — 07 · Recovery / new password | [lib/features/auth/presentation/forgot_password_screen.dart](../../lib/features/auth/presentation/forgot_password_screen.dart) |
| auth-success — 08 · Recovery / complete | [lib/features/auth/presentation/forgot_password_screen.dart](../../lib/features/auth/presentation/forgot_password_screen.dart) |
| auth-help — 09 · Recovery / assisted | [lib/features/auth/presentation/forgot_password_screen.dart](../../lib/features/auth/presentation/forgot_password_screen.dart) |
| p-home — 01 · Home | [lib/features/patient_home/presentation/patient_home_screen.dart](../../lib/features/patient_home/presentation/patient_home_screen.dart) |
| p-appointments — 02 · Appointments | [lib/features/appointments/presentation/appointments_screen.dart](../../lib/features/appointments/presentation/appointments_screen.dart) |
| p-ticket — 03 · Appointment ticket | [lib/features/appointments/presentation/appointment_detail_screen.dart](../../lib/features/appointments/presentation/appointment_detail_screen.dart) |
| p-booking — 04 · Book / choose | [lib/features/booking/presentation/booking_screen.dart](../../lib/features/booking/presentation/booking_screen.dart) |
| p-slot — 05 · Book / time | [lib/features/booking/presentation/booking_screen.dart](../../lib/features/booking/presentation/booking_screen.dart) |
| p-review — 06 · Book / review | [lib/features/booking/presentation/booking_screen.dart](../../lib/features/booking/presentation/booking_screen.dart) |
| p-confirmed — 07 · Book / success | [lib/features/appointments/presentation/appointment_detail_screen.dart](../../lib/features/appointments/presentation/appointment_detail_screen.dart) |
| p-cancel — 08 · Appointment / cancel | [lib/features/appointments/presentation/appointments_screen.dart](../../lib/features/appointments/presentation/appointments_screen.dart) |
| p-records — 09 · Health records | [lib/features/timeline/presentation/health_records_screen.dart](../../lib/features/timeline/presentation/health_records_screen.dart) |
| p-result — 10 · Lab result detail | [lib/features/records/presentation/record_detail_screen.dart](../../lib/features/records/presentation/record_detail_screen.dart) |
| p-medications — 11 · Medications | [lib/features/records/presentation/medications_screen.dart](../../lib/features/records/presentation/medications_screen.dart) |
| p-vitals — 12 · Vital signs | [lib/features/vitals/presentation/vitals_screen.dart](../../lib/features/vitals/presentation/vitals_screen.dart) |
| p-import — 13 · Import record | [lib/features/timeline/presentation/import_record_sheet.dart](../../lib/features/timeline/presentation/import_record_sheet.dart) |
| p-nutrition — 14 · Nutrition overview | [lib/features/nutrition/presentation/nutrition_screen.dart](../../lib/features/nutrition/presentation/nutrition_screen.dart) |
| p-nutrition-edit — 15 · Nutrition / inputs | [lib/features/nutrition/presentation/nutrition_screen.dart](../../lib/features/nutrition/presentation/nutrition_screen.dart) |
| p-foods — 16 · Nutrition / foods | [lib/features/nutrition/presentation/nutrition_screen.dart](../../lib/features/nutrition/presentation/nutrition_screen.dart) |
| p-profile — 17 · Profile | [lib/features/patient/application/profile_screen.dart](../../lib/features/patient/application/profile_screen.dart) |
| p-personal — 18 · Personal information | [lib/features/patient/presentation/personal_info_section.dart](../../lib/features/patient/presentation/personal_info_section.dart) |
| p-health — 19 · Health details | [lib/features/patient/presentation/health_details_section.dart](../../lib/features/patient/presentation/health_details_section.dart) |
| p-family — 20 · Family access | [lib/features/patient/presentation/family_network_section.dart](../../lib/features/patient/presentation/family_network_section.dart) |
| p-linked — 21 · Linked account | [lib/features/patient/presentation/linked_account_screen.dart](../../lib/features/patient/presentation/linked_account_screen.dart) |
| p-preferences — 22 · Preferences | [lib/features/settings/presentation/preferences_section.dart](../../lib/features/settings/presentation/preferences_section.dart) |
| p-payments — 23 · Payments overview | [lib/features/billing/presentation/payments_screen.dart](../../lib/features/billing/presentation/payments_screen.dart) |
| p-pay — 24 · Pay invoice | [lib/features/billing/presentation/pay_invoice_sheet.dart](../../lib/features/billing/presentation/pay_invoice_sheet.dart) |
| p-payment-pending — 25 · Payment pending | [lib/features/billing/presentation/pay_invoice_sheet.dart](../../lib/features/billing/presentation/pay_invoice_sheet.dart) |
| p-messages — 26 · Care messages | [lib/features/care/presentation/messages_screen.dart](../../lib/features/care/presentation/messages_screen.dart) |
| p-thread — 27 · Message thread | [lib/features/care/presentation/message_thread_screen.dart](../../lib/features/care/presentation/message_thread_screen.dart) |
| p-homevisit — 28 · Home care request | [lib/features/care/presentation/home_visit_screen.dart](../../lib/features/care/presentation/home_visit_screen.dart) |
| s-home — 01 · Dashboard | [lib/features/staff_dashboard/presentation/staff_dashboard_screen.dart](../../lib/features/staff_dashboard/presentation/staff_dashboard_screen.dart) |
| s-patients — 02 · Patients | [lib/features/staff_dashboard/presentation/staff_patients_screen.dart](../../lib/features/staff_dashboard/presentation/staff_patients_screen.dart) |
| s-chart — 03 · Patient chart | [lib/features/patient_chart/presentation/patient_chart_screen.dart](../../lib/features/patient_chart/presentation/patient_chart_screen.dart) |
| s-consultation — 04 · Consultation | [lib/features/consultation/presentation/consultation_screen.dart](../../lib/features/consultation/presentation/consultation_screen.dart) |
| s-referral — 04b · Create referral | [lib/features/consultation/presentation/consultation_screen.dart](../../lib/features/consultation/presentation/consultation_screen.dart) |
| s-signed — 05 · Consultation signed | [lib/features/consultation/presentation/consultation_screen.dart](../../lib/features/consultation/presentation/consultation_screen.dart) |
| s-result — 06 · Result review | [lib/features/patient_chart/presentation/result_review_sheet.dart](../../lib/features/patient_chart/presentation/result_review_sheet.dart) |
| s-handover — 06b · Handover / escalate | [lib/features/patient_chart/presentation/result_review_sheet.dart](../../lib/features/patient_chart/presentation/result_review_sheet.dart) |
| s-tasks — 07 · Task board | [lib/features/tasks/presentation/task_board_screen.dart](../../lib/features/tasks/presentation/task_board_screen.dart) |
| s-schedule — 08 · Schedule | [lib/features/staff_dashboard/presentation/staff_schedule_screen.dart](../../lib/features/staff_dashboard/presentation/staff_schedule_screen.dart) |
| s-inbox — 09 · Staff inbox | [lib/features/care/presentation/staff_inbox_screen.dart](../../lib/features/care/presentation/staff_inbox_screen.dart) |
| s-thread — 10 · Covered thread | [lib/features/care/presentation/message_thread_screen.dart](../../lib/features/care/presentation/message_thread_screen.dart) |
| s-profile — 11 · Staff profile | [lib/features/staff_dashboard/presentation/staff_profile_screen.dart](../../lib/features/staff_dashboard/presentation/staff_profile_screen.dart) |
| s-preferences — 12 · Staff preferences | [lib/features/settings/presentation/preferences_section.dart](../../lib/features/settings/presentation/preferences_section.dart) |
| a-home — 01 · Dashboard | [lib/features/admin/presentation/admin_dashboard_screen.dart](../../lib/features/admin/presentation/admin_dashboard_screen.dart) |
| a-work — 02 · Work queue | [lib/features/admin/presentation/admin_work_queue_screen.dart](../../lib/features/admin/presentation/admin_work_queue_screen.dart) |
| a-assign — 03 · Assign work | [lib/features/admin/presentation/admin_work_queue_screen.dart](../../lib/features/admin/presentation/admin_work_queue_screen.dart) |
| a-users — 04 · User directory | [lib/features/admin/presentation/user_management_screen.dart](../../lib/features/admin/presentation/user_management_screen.dart) |
| a-user — 05 · Staff account | [lib/features/admin/presentation/user_management_screen.dart](../../lib/features/admin/presentation/user_management_screen.dart) |
| a-create — 06 · Create staff | [lib/features/admin/presentation/user_management_screen.dart](../../lib/features/admin/presentation/user_management_screen.dart) |
| a-departments — 07 · Departments | [lib/features/admin/presentation/departments_screen.dart](../../lib/features/admin/presentation/departments_screen.dart) |
| a-department — 08 · Edit department | [lib/features/admin/presentation/departments_screen.dart](../../lib/features/admin/presentation/departments_screen.dart) |
| a-billing — 09 · Billing overview | [lib/features/admin/presentation/admin_billing_screen.dart](../../lib/features/admin/presentation/admin_billing_screen.dart) |
| a-invoice — 10 · Invoice & ledger | [lib/features/admin/presentation/admin_billing_screen.dart](../../lib/features/admin/presentation/admin_billing_screen.dart) |
| a-desk — 11 · Desk payment | [lib/features/admin/presentation/admin_billing_screen.dart](../../lib/features/admin/presentation/admin_billing_screen.dart) |
| a-referrals — 12 · Referral requests | [lib/features/admin/presentation/admin_referral_requests_screen.dart](../../lib/features/admin/presentation/admin_referral_requests_screen.dart) |
| a-referral — 13 · Review referral | [lib/features/admin/presentation/admin_referral_requests_screen.dart](../../lib/features/admin/presentation/admin_referral_requests_screen.dart) |
| a-homevisits — 14 · Home visit queue | [lib/features/care/presentation/admin_home_visits_screen.dart](../../lib/features/care/presentation/admin_home_visits_screen.dart) |
| a-profile — 15 · Admin profile | [lib/features/admin/presentation/admin_profile_screen.dart](../../lib/features/admin/presentation/admin_profile_screen.dart) |
| a-analytics — 16 · Analytics | [lib/features/admin/presentation/system_analytics_screen.dart](../../lib/features/admin/presentation/system_analytics_screen.dart) |
| a-audit — 17 · Audit log | [lib/features/admin/presentation/audit_log_screen.dart](../../lib/features/admin/presentation/audit_log_screen.dart) |
| a-hours — 18 · Clinic hours | [lib/features/admin/presentation/clinic_hours_screen.dart](../../lib/features/admin/presentation/clinic_hours_screen.dart) |
| a-ai — 19 · AI settings | [lib/features/admin/presentation/ai_settings_screen.dart](../../lib/features/admin/presentation/ai_settings_screen.dart) |
| a-preferences — 20 · Admin preferences | [lib/features/settings/presentation/preferences_section.dart](../../lib/features/settings/presentation/preferences_section.dart) |
| p-empty — 29 · State / no appointments | [lib/features/appointments/presentation/appointments_screen.dart](../../lib/features/appointments/presentation/appointments_screen.dart) |
| p-error — 30 · State / wallet failure | [lib/features/billing/presentation/payments_screen.dart](../../lib/features/billing/presentation/payments_screen.dart) |
| s-error — 13 · State / save failure | [lib/features/consultation/presentation/consultation_screen.dart](../../lib/features/consultation/presentation/consultation_screen.dart) |
| a-error — 21 · State / queue failure | [lib/features/admin/presentation/admin_work_queue_screen.dart](../../lib/features/admin/presentation/admin_work_queue_screen.dart) |
| p-desktop — 31 · Desktop / patient overview | [lib/features/patient_home/presentation/patient_home_screen.dart](../../lib/features/patient_home/presentation/patient_home_screen.dart) |
| s-desktop — 14 · Desktop / staff workspace | [lib/features/staff_dashboard/presentation/staff_patients_screen.dart](../../lib/features/staff_dashboard/presentation/staff_patients_screen.dart) |
| a-desktop — 22 · Desktop / admin work queue | [lib/features/admin/presentation/admin_work_queue_screen.dart](../../lib/features/admin/presentation/admin_work_queue_screen.dart) |
| auth-onboarding-1 — Added · Welcome to MyHealth Care | [lib/features/auth/presentation/onboarding_overlay.dart](../../lib/features/auth/presentation/onboarding_overlay.dart) |
| auth-onboarding-2 — Added · Your care team | [lib/features/auth/presentation/onboarding_overlay.dart](../../lib/features/auth/presentation/onboarding_overlay.dart) |
| auth-onboarding-3 — Added · Make it comfortable | [lib/features/auth/presentation/onboarding_overlay.dart](../../lib/features/auth/presentation/onboarding_overlay.dart) |
| auth-session — Added · Still there? | [lib/features/auth/presentation/session_activity_monitor.dart](../../lib/features/auth/presentation/session_activity_monitor.dart) |
| auth-reauth — Added · Confirm your password | [lib/features/auth/presentation/reauth_prompt.dart](../../lib/features/auth/presentation/reauth_prompt.dart) |
| p-photo — Added · Profile photo | [lib/features/patient/presentation/avatar_photo_sheet.dart](../../lib/features/patient/presentation/avatar_photo_sheet.dart) |
| p-photo-error — Added · Photo could not be saved | [lib/features/patient/presentation/avatar_photo_sheet.dart](../../lib/features/patient/presentation/avatar_photo_sheet.dart) |
| p-password — Added · Change password | [lib/features/patient/application/profile_screen.dart](../../lib/features/patient/application/profile_screen.dart) |
| p-feedback — Added · Send feedback | [lib/features/feedback/presentation/feedback_sheet.dart](../../lib/features/feedback/presentation/feedback_sheet.dart) |
| p-visited — Added · Visited doctors | [lib/features/patient/presentation/visited_doctors_screen.dart](../../lib/features/patient/presentation/visited_doctors_screen.dart) |
| p-imaging — Added · Imaging results | [lib/features/records/presentation/radiology_screen.dart](../../lib/features/records/presentation/radiology_screen.dart) |
| p-allergies — Added · Allergies | [lib/features/patient/presentation/allergies_screen.dart](../../lib/features/patient/presentation/allergies_screen.dart) |
| p-sickleave — Added · Sick leave certificates | [lib/features/care/presentation/sick_leave_screen.dart](../../lib/features/care/presentation/sick_leave_screen.dart) |
| p-summary — Added · Health summary | [lib/features/ai_summary/presentation/ai_summary_screen.dart](../../lib/features/ai_summary/presentation/ai_summary_screen.dart) |
| p-assistant — Added · Care Navigator | [lib/features/ai_chat/presentation/care_navigator_panel.dart](../../lib/features/ai_chat/presentation/care_navigator_panel.dart) |
| p-topup — Added · Top up wallet | [lib/features/billing/presentation/wallet_topup_sheet.dart](../../lib/features/billing/presentation/wallet_topup_sheet.dart) |
| p-methods — Added · Payment methods | [lib/features/billing/presentation/payment_methods_section.dart](../../lib/features/billing/presentation/payment_methods_section.dart) |
| p-card-add — Added · Add payment card | [lib/features/billing/presentation/payment_methods_section.dart](../../lib/features/billing/presentation/payment_methods_section.dart) |
| p-pay-history — Added · Transaction history | [lib/features/billing/presentation/payment_history.dart](../../lib/features/billing/presentation/payment_history.dart) |
| p-family-member — Added · Family member | [lib/features/patient/presentation/family_network_section.dart](../../lib/features/patient/presentation/family_network_section.dart) |
| p-family-request — Added · Request account access | [lib/features/patient/presentation/linked_family_accounts_section.dart](../../lib/features/patient/presentation/linked_family_accounts_section.dart) |
| p-family-consent — Added · Review access request | [lib/features/patient/presentation/linked_family_accounts_section.dart](../../lib/features/patient/presentation/linked_family_accounts_section.dart) |
| p-family-revoke — Added · Who has access to me | [lib/features/patient/presentation/linked_family_accounts_section.dart](../../lib/features/patient/presentation/linked_family_accounts_section.dart) |
| p-linked-manage — Added · Manage linked account | [lib/features/patient/presentation/linked_account_screen.dart](../../lib/features/patient/presentation/linked_account_screen.dart) |
| p-reschedule — Added · Reschedule appointment | [lib/features/appointments/presentation/slot_picker_sheet.dart](../../lib/features/appointments/presentation/slot_picker_sheet.dart) |
| p-no-slots — Added · No available times | [lib/features/booking/presentation/booking_screen.dart](../../lib/features/booking/presentation/booking_screen.dart) |
| p-booking-conflict — Added · That time is no longer available | [lib/features/booking/presentation/booking_screen.dart](../../lib/features/booking/presentation/booking_screen.dart) |
| p-homevisits-history — Added · Home care requests | [lib/features/care/presentation/home_visit_screen.dart](../../lib/features/care/presentation/home_visit_screen.dart) |
| p-notifications — Added · Notifications | [lib/features/notifications/presentation/notifications_screen.dart](../../lib/features/notifications/presentation/notifications_screen.dart) |
| p-reset-prefs — Added · Reset preferences | [lib/features/settings/presentation/preferences_section.dart](../../lib/features/settings/presentation/preferences_section.dart) |
| s-notifications — Added · Notifications | [lib/features/notifications/presentation/notifications_screen.dart](../../lib/features/notifications/presentation/notifications_screen.dart) |
| s-reset-prefs — Added · Reset preferences | [lib/features/settings/presentation/preferences_section.dart](../../lib/features/settings/presentation/preferences_section.dart) |
| a-notifications — Added · Notifications | [lib/features/notifications/presentation/notifications_screen.dart](../../lib/features/notifications/presentation/notifications_screen.dart) |
| a-reset-prefs — Added · Reset preferences | [lib/features/settings/presentation/preferences_section.dart](../../lib/features/settings/presentation/preferences_section.dart) |
| s-account — Added · Staff account | [lib/features/staff_dashboard/presentation/staff_profile_pages.dart](../../lib/features/staff_dashboard/presentation/staff_profile_pages.dart) |
| s-activity — Added · My activity | [lib/features/staff_dashboard/presentation/staff_activity_screen.dart](../../lib/features/staff_dashboard/presentation/staff_activity_screen.dart) |
| s-directory — Added · Staff directory | [lib/features/staff_dashboard/presentation/staff_directory_screen.dart](../../lib/features/staff_dashboard/presentation/staff_directory_screen.dart) |
| s-analytics — Added · Panel analytics | [lib/features/staff_dashboard/presentation/panel_analytics_screen.dart](../../lib/features/staff_dashboard/presentation/panel_analytics_screen.dart) |
| s-tools — Added · Clinical actions | [lib/features/staff_dashboard/presentation/staff_quick_actions.dart](../../lib/features/staff_dashboard/presentation/staff_quick_actions.dart) |
| s-summary — Added · Patient summary | [lib/features/patient_chart/presentation/patient_summary_screen.dart](../../lib/features/patient_chart/presentation/patient_summary_screen.dart) |
| s-scribe — Added · Clinical scribe | [lib/features/ai_scribe/presentation/clinical_scribe_screen.dart](../../lib/features/ai_scribe/presentation/clinical_scribe_screen.dart) |
| s-note — Added · New clinical note | [lib/features/patient_chart/presentation/chart_write_sheets.dart](../../lib/features/patient_chart/presentation/chart_write_sheets.dart) |
| s-prescribe — Added · Medication order | [lib/features/patient_chart/presentation/chart_write_sheets.dart](../../lib/features/patient_chart/presentation/chart_write_sheets.dart) |
| s-lab-entry — Added · Enter lab result | [lib/features/patient_chart/presentation/chart_write_sheets.dart](../../lib/features/patient_chart/presentation/chart_write_sheets.dart) |
| s-transfer — Added · Transfer visit | [lib/features/staff_dashboard/presentation/staff_quick_actions.dart](../../lib/features/staff_dashboard/presentation/staff_quick_actions.dart) |
| s-calendar-month — Added · Month schedule | [lib/features/staff_dashboard/presentation/staff_schedule_screen.dart](../../lib/features/staff_dashboard/presentation/staff_schedule_screen.dart) |
| s-calendar-year — Added · Year schedule | [lib/features/staff_dashboard/presentation/staff_schedule_screen.dart](../../lib/features/staff_dashboard/presentation/staff_schedule_screen.dart) |
| s-feedback — Added · Send feedback | [lib/features/feedback/presentation/feedback_sheet.dart](../../lib/features/feedback/presentation/feedback_sheet.dart) |
| s-access-denied — Added · Patient access unavailable | [lib/features/patient_chart/presentation/patient_chart_screen.dart](../../lib/features/patient_chart/presentation/patient_chart_screen.dart) |
| s-conflict — Added · The chart changed | [lib/features/consultation/presentation/consultation_screen.dart](../../lib/features/consultation/presentation/consultation_screen.dart) |
| a-account — Added · Administrator account | [lib/features/admin/presentation/admin_profile_pages.dart](../../lib/features/admin/presentation/admin_profile_pages.dart) |
| a-forecast — Added · Capacity forecast | [lib/features/admin/presentation/admin_forecast_screen.dart](../../lib/features/admin/presentation/admin_forecast_screen.dart) |
| a-ai-log — Added · AI activity | [lib/features/admin/presentation/admin_ai_log_screen.dart](../../lib/features/admin/presentation/admin_ai_log_screen.dart) |
| a-appointments — Added · All appointments | [lib/features/admin/presentation/admin_appointments_screen.dart](../../lib/features/admin/presentation/admin_appointments_screen.dart) |
| a-feedback — Added · Feedback queue | [lib/features/admin/presentation/admin_feedback_screen.dart](../../lib/features/admin/presentation/admin_feedback_screen.dart) |
| a-create-patient — Added · Create patient account | [lib/features/admin/presentation/user_management_screen.dart](../../lib/features/admin/presentation/user_management_screen.dart) |
| a-broadcast — Added · Send announcement | [lib/features/admin/presentation/admin_quick_actions.dart](../../lib/features/admin/presentation/admin_quick_actions.dart) |
| a-create-invoice — Added · Create invoice | [lib/features/admin/presentation/admin_quick_actions.dart](../../lib/features/admin/presentation/admin_quick_actions.dart) |
| a-staff-schedule — Added · Clinician schedule | [lib/features/admin/presentation/user_management_screen.dart](../../lib/features/admin/presentation/user_management_screen.dart) |
| a-book-patient — Added · Book for patient | [lib/features/admin/presentation/user_management_screen.dart](../../lib/features/admin/presentation/user_management_screen.dart) |
| a-refer-patient — Added · Refer patient | [lib/features/admin/presentation/user_management_screen.dart](../../lib/features/admin/presentation/user_management_screen.dart) |
| a-refund — Added · Refund settled payment | [lib/features/admin/presentation/admin_billing_screen.dart](../../lib/features/admin/presentation/admin_billing_screen.dart) |
| a-reconcile — Added · Check pending payments | [lib/features/admin/presentation/admin_billing_screen.dart](../../lib/features/admin/presentation/admin_billing_screen.dart) |
