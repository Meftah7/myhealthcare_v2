# Flutter design integration

The supplied design is integrated into the existing Flutter app through shared tokens, headers, navigation, cards, forms, shortcuts, and state views. The table maps all 78 reference frames to their executable Flutter surfaces; some frames are steps, sheets, dialogs, or states within a screen rather than separate routes.

## Integration decisions

- Use the reference's blue palette, white bordered cards, pale-blue mobile headers, 20dp mobile gutters, Lexend semibold headings, Inter body text, and blue heart/ECG mark. Fonts remain bundled.
- Keep real patient and clinical data, permissions, currency formatting, English/Arabic localization, dark theme, keyboard navigation, and large-text support.
- Use a three-stage booking flow and separate recovery code/password steps. Validate recovery codes through the existing repository when the password change is submitted.
- Nutrition shows calculated targets and an example daily split; it never presents example meals as consumed food. Existing calculator and meal generation remain available.
- Keep confirmations and edits in responsive sheets/dialogs where that preserves the existing app workflow. User, department, invoice, referral, and ownership edits retain their existing persistence and permission checks.
- On desktop, the 248dp sidebar and existing dashboard columns/list-detail workspaces provide the wide versions. Extra clinical and operations features remain reachable.

## Validation

- Release web build passes with the Pages base path and locally bundled web resources.
- All 48 focused checks pass in one combined run, covering accessibility/contrast, responsive layouts through 200% text size, English/Arabic headers, recovery, booking, nutrition, and task update failures.
- Project analysis reports no errors or warnings; existing informational style findings remain.
- Browser review covers synthetic demo accounts. The source mapping is coverage evidence, not a claim that every individual frame has a screenshot baseline.

## Screen mapping

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
