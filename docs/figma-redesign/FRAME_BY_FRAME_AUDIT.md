# Source-level comparison of all 78 design frames

Baseline record: this comparison was prepared before the subsequent upgrade. The local design now has 141 frames; see the [implementation and verification status](IMPLEMENTATION.md) for changes made and remaining runtime checks.

Checked 3 October 2026 against `design.js`, `implementation-map.json`, `lib/app/router.dart`, and the mapped Flutter presentation files. Each row records the material feature/state difference to preserve or correct. The ID is the design frame ID; the Flutter file is listed in `implementation-map.json`. A frame marked as an example is a state or sheet within a route, not necessarily a separate Flutter page.

This is a **complete frame-by-frame source comparison**, not a live pixel or interaction test. The current checkout has no Flutter SDK or current-app screenshots. Fixed names, dates, counts and monetary amounts in the design are synthetic; they must remain dynamic in the app.

| Frame | Current Flutter behavior and difference from design |
| --- | --- |
| `auth-login` | Login, demo accounts, theme/language and validation exist; mockup cannot show busy, bad credentials or role redirect. |
| `auth-register-1` | Same account step; preserve password policy, field errors and entered values when moving backward. |
| `auth-register-2` | Same personal step; DOB picker, optional fields and National ID validation need their real controls/states. |
| `auth-register-3` | Same optional health step; keep blood type, allergies, conditions, emergency contact and save failure. |
| `auth-recover` | Identifier step exists; design must distinguish the simulated demo inbox from unavailable real delivery. |
| `auth-code` | Code entry exists; add invalid/expired/resend and 10-minute expiry behavior to the design. |
| `auth-password` | Recovery password step exists; it must never stand in for authenticated Profile password change. |
| `auth-success` | Recovery outcome exists within one screen; show actual repository success before this state. |
| `auth-help` | Assisted recovery exists; match the real administrator-contact path and unavailable-delivery wording. |
| `p-home` | Home already has allergy/attention, one next visit and more shortcuts than shown; preserve linked account, quick-appointment choice, assistant and error states. |
| `p-appointments` | Three filters exist; retain in-progress visits, paging and all booking entry modes. |
| `p-ticket` | Detail has status, ticket/room, calendar export and support; mockup's “Download ticket” is not the existing calendar export. Correct label/action or specify a new export feature. |
| `p-booking` | Booking has self/family target, visit type and reason plus department/clinician; mockup shows only a simplified selection. |
| `p-slot` | Real slots depend on clinic hours, availability and ranking; add loading, no slots and conflict/refresh states. |
| `p-review` | Review is a sheet, not a third route; show acting-for person, final details and confirm failure without losing draft. |
| `p-confirmed` | Successful booking currently opens the appointment detail with a confirmation notice; separate success page is illustrative, not an existing destination. |
| `p-cancel` | Current action is a confirmation dialog with permission/status checks; mockup's optional reason is not captured by the app. |
| `p-records` | Records include document strip, timeline, medications and legacy bills plus filters; mockup omits imaging, allergies, sick leave and the bills entry. |
| `p-result` | Detail has provenance, abnormal flags, range and original/PDF actions; keep unverified/unknown-range distinctions. |
| `p-medications` | Current/past data and prescribing details exist; design needs empty, loading and historical states. |
| `p-vitals` | Current and previous measures plus report export exist; retain units, timestamps and unavailable-data states. |
| `p-import` | PDF import is a sheet with file selection and provenance; include progress, size/type errors and review status. |
| `p-nutrition` | Overview is an estimate and example meal split; keep actual calculator and generation actions, with no diary claim. |
| `p-nutrition-edit` | Real inputs/calculation live in the Nutrition route; show validation and recalculation outcomes. |
| `p-foods` | Real food search/data lives in Nutrition; show filter/search, units and allergy guidance without inventing consumption history. |
| `p-profile` | Real profile has editable photo badge/sheet, feedback and authenticated password change; all three are missing or mislinked in mockup. |
| `p-personal` | Real CPR/National ID and email are read-only. Distinguish them visually from editable fields; show cancel/save/errors. |
| `p-health` | Editable health details and clinician-sharing note exist; preserve save/cancel and failed-save feedback. |
| `p-family` | App has family members *and* consent-based linked accounts, incoming/outgoing requests and viewers; mockup combines them. |
| `p-linked` | View/manage grants govern booking and editing; show grant, owner and restricted actions in every linked-account state. |
| `p-preferences` | Replace self-linked summary rows with real theme, scale, language, motion, contrast, notification, sound and reset controls. |
| `p-payments` | App also has wallet top-up, payment methods and transaction history; preserve owed vs available amounts and failures. |
| `p-pay` | Real payment sheet supports method choice and payment states; show card validation, insufficient wallet, pending and failure. |
| `p-payment-pending` | Pending is a transaction state in the existing payment flow; prevent duplicate charge and show status refresh. |
| `p-messages` | Preserve real thread list, unread status, clinician identity, non-emergency guidance and empty/error states. |
| `p-thread` | Preserve actual message history, keyboard/composer and send failure; static chat bubbles are examples only. |
| `p-homevisit` | Request form and history/status coexist in the app; add review, cancellation limits and failed-request state. |
| `p-empty` | Appointments empty state is within filtered list; provide booking action and distinguish no upcoming from no history. |
| `p-error` | Wallet read failure shows retry in Flutter; keep invoices if separately available rather than implying a zero balance. |
| `p-desktop` | App uses responsive shell and dashboard sections; design is a fixed 1440px example. Verify actual rail/content widths and access to all shortcuts. |
| `s-home` | App includes presence, queue, result/message/task attention and a larger clinical shortcut set; mockup shows only a subset. |
| `s-patients` | Preserve permission-filtered search, patient selection and desktop list/detail; mock filters must reflect real data. |
| `s-chart` | Chart has records, medications, history, allergies and write actions; show role/ownership gates and unavailable data. |
| `s-consultation` | Actual draft/edit/sign behavior and clinician permissions need saving, conflict, failed and signed variants. |
| `s-referral` | Referral is part of consultation/write flows; show valid destination, patient context and submission failure. |
| `s-signed` | Signed visit is an outcome of consultation, with immutable note rules; do not suggest signed content can be edited. |
| `s-result` | Result review depends on owner, source, units/range and abnormal flag; include permitted/covered/blocked states. |
| `s-handover` | Handover/escalation uses real role and owner rules; do not promise recipient acceptance unless a corresponding state exists. |
| `s-tasks` | Task board has status mutations, due/priority and explanations; add busy, failure and terminal states. |
| `s-schedule` | App has day, month and year navigation; mockup only illustrates one day strip. Keep queue lifecycle actions. |
| `s-inbox` | Preserve owned vs covered threads, unread/overdue, permission and empty/error states. |
| `s-thread` | Keep actual owner/coverage context, reply composer, send state and conversation history. |
| `s-profile` | Real Account, Activity, Directory and Analytics routes exist; design's Account/Activity links point back to Profile and omit feedback. |
| `s-preferences` | Same real shared controls as patient, including sound, unavailable channels and resets; mockup uses summary rows. |
| `s-error` | Consultation save failure keeps the draft; show retry and retained content without implying save succeeded. |
| `s-desktop` | Real rail, patient pane and clinical queue are responsive; measure selection, pane widths and role-gated actions. |
| `a-home` | Real dashboard aggregates source-specific attention with loading/errors; keep operational quick actions and avoid fixed counts. |
| `a-work` | Preserve actual queue filters, ownership, source failures and return context; mockup's rows are examples. |
| `a-assign` | Real assignment requires an authorized active owner and reports failures; show selected item and confirmed outcome. |
| `a-users` | App manages patients, staff and admins with different actions; preserve account activation separately from presence. |
| `a-user` | Account detail also supports schedule, password recovery, booking/referral for patient where permitted; mockup only sketches them. |
| `a-create` | App has separate patient/staff creation sheets and validation; design only shows staff creation. |
| `a-departments` | Real list/new/edit flows exist; retain loading/error and dependent-delete constraints. |
| `a-department` | Edit/delete are dialogs with persistence and error results; keep confirmation and blocked-delete explanation. |
| `a-billing` | Preserve invoice filters, pending/settled/refunded/cancelled states and reconciliation action. |
| `a-invoice` | Ledger and transaction history matter; mockup omits full refund/reconciliation and cancellation outcomes. |
| `a-desk` | Desk payment uses a receipt and note dialog; show validation and settlement result before marking paid. |
| `a-referrals` | Current queue has decision actions and source state; keep permission and failure handling. |
| `a-referral` | Review action sheet has arrange/reject details; show reason/owner validation and confirmed outcome. |
| `a-homevisits` | Preserve request status, scheduling/decline reasons and error/retry states. |
| `a-profile` | Real Forecast and AI Activity links are omitted; AI activity mock link incorrectly opens Audit. |
| `a-analytics` | Actual metrics depend on period and sources; replace fixed synthetic totals with loading, empty, freshness and failure states. |
| `a-audit` | Keep real actor/action filters and paging; mock events are illustrative only. |
| `a-hours` | Clinic schedule controls affect slots; retain actual day/time validation and save failure. |
| `a-ai` | Real AI settings/activity routes and capability state exist; mock activity links to Audit and omits actual log view. |
| `a-preferences` | Same shared functional controls as other roles; mockup only contains self-linked summary rows. |
| `a-error` | Attention sources can fail independently; preserve successful sources and per-source retry. |
| `a-desktop` | Fixed mock table/pane represents a dynamic work queue; verify real filters, selection, rail space and narrow fallback. |

## Current app surfaces without a dedicated frame

These are already reachable in Flutter and must be designed or explicitly represented as an embedded sheet/state: onboarding, bootstrap/splash, inactivity warning, reauthentication, authenticated password change, patient photo management, notification lists, patient feedback, visited doctors, allergies, imaging, sick leave, AI summaries, Care Navigator, wallet top-up, saved-card management, payment history, family member editing, linked-account request/consent/revoke, staff clinical write sheets, transfer, AI scribe, staff activity/directory/panel analytics, staff month/year calendar, admin appointments, admin feedback, patient creation, broadcast, invoice creation, patient booking/referral from Users, staff schedule editing, capacity forecast, AI activity log, and payment refund/reconciliation.

Use the [prioritized app-wide plan](../CURRENT_UI_VS_REDESIGN_AUDIT.md) to close these gaps. The editable Figma file still needs its Admin frames and prototype links, while the local preview contains all 78 frames.
