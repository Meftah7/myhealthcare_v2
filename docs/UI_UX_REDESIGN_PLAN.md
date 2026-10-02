# MyHealth Care — UI/UX review and redesign plan

Prepared: 2 October 2026. Status: planning only; application code has not changed.

## Recommendation

Use the supplied Figma exports as the visual direction: a pale blue page header,
white surfaces on a cool light background, strong blue primary actions, compact
rows, and clear typography. Extend that direction through the existing Flutter
component system and complete workflows before polishing secondary surfaces.

The biggest improvement will come from clearer priorities and more consistent
interactions. The app already has the blue palette and much of the proposed
header treatment. Rebuilding its architecture or repeating that partial work
would add risk without solving the remaining usability problems.

Keep the current five destinations per role for the first redesign. Bring
frequent tasks forward, simplify Profile into a hub, give billing a clear home,
and retain the existing clinical, family-account, payment, and recovery behavior.
Nutrition remains an estimate and example meal-plan tool in this scope.

## 1. Review scope and evidence limits

Reviewed the 20 PNG references visually, extracted the text of all three PDFs,
and rendered the login PDF page because it has no matching PNG. The PDFs contain
21 reference frames in total, including the reset-email template. Reference
filenames do not always identify the actual screen: `admin 1.png` is Profile,
while `admin 2.png` is Dashboard.

Mapped the authored source tree, 64 `GoRoute` declarations, three stateful role
shells, all feature areas, the theme and shared presentation components,
repository/service responsibilities, release decisions, and existing test
coverage. The source inventory contains 283 authored Dart files excluding
generated entity/database files and localization output, and 86 test files.
This is a project-wide UI/UX and architecture review, not a line-by-line security
or clinical correctness audit of every file.

The app has not been run during this review. Flutter and Dart are unavailable
on PATH and were absent from the common installation locations checked. Visual
judgments about the current app therefore come from its widget code; runtime
overflow, visual comparison, and assistive-technology findings remain to be
verified. Existing test and release documents are historical evidence, not
checks rerun for this plan. The Figma sources inspected are the local exports,
not an editable live Figma file with measurable layout variables.

Source of truth when documents disagree: executable behavior, repository
contracts, and the approved scope. Several comments and earlier documents are
stale. For example, `DESIGN.md` and color comments still describe violet/magenta
branding, but `AppColors.seed` is already blue (`#1E5FAF`).

## 2. App structure and constraints

| Layer | Current responsibility | Consequence for redesign |
|---|---|---|
| `lib/main.dart`, `lib/app/app.dart` | Bootstrap, theme, language, text scaling, motion, session monitor and overlays | Keep the global preferences and session behavior working through every screen. |
| `lib/app/router.dart`, `lib/app/shell/app_shell.dart` | Role guards, nested screens, persistent tab stacks, adaptive navigation | Improve presentation while retaining deep links, back behavior and tab state. |
| `lib/app/theme/` | Colors, fonts, spacing, shapes, status colors, Material widget styles and motion | Change tokens centrally; validate their light, dark and high-contrast variants. |
| `lib/core/presentation/` | Page frame, cards, rows, state views, feedback, paging, responsive columns and list-detail layouts | Extend these primitives instead of creating a separate style in every feature. |
| `lib/features/` | Role-specific presentation, providers and workflow controllers | Redesign complete task paths, including sheets, validation and success states. |
| `lib/domain/`, `lib/data/` | Entities, permission rules, repository contracts and local Drift persistence | Let existing rules determine available actions and valid state transitions. |
| `lib/services/` | Recovery delivery, payment gateway, documents, AI, rules, reminders and device alerts | Match labels and confirmations to what the selected provider actually supports. |
| `lib/l10n/` | English and Arabic strings | Every new label needs both languages and review in RTL layouts. |
| `test/`, `integration_test/`, `docs/` | Regression evidence and manual review protocols | Reuse the existing suites and task study; record new visual baselines. |

Approved release scope in `release_scope_decisions.md`: a synthetic-data,
local-only university prototype with web as its release target. Android, iOS
and Windows remain source targets. The redesign should prioritize desktop web
and narrow browser layouts while retaining the adaptive Flutter implementation.

The database is currently schema 25. There is no reason to migrate it for the
initial visual redesign. Adding a nutrition diary or changing recovery delivery
would require a separate functional workstream.

### Navigation map

| Workspace | Primary destinations | Supporting task paths |
|---|---|---|
| Signed out | Sign in, register, recover password | Onboarding, bootstrap failure, verification, session reauthentication |
| Patient | Home, Nutrition, Appointments, Records, Profile | Booking and ticket detail; vitals; medications; imaging; allergies; sick leave; original documents and PDFs; summary; messages; home visits; billing; notifications; personal/health information; preferences; family grants and linked accounts |
| Staff | Dashboard, Patients, Tasks, Schedule, Profile | Chart and summary; consultation, note drafts and signing; results and escalation; clinical write sheets; scribe; walk-ins; inbox and coverage; presence; directory; activity; analytics; notifications; preferences |
| Admin | Dashboard, Users, Departments, Billing, Profile | Work queues and assignment; appointments; referrals; home visits; feedback; account and staff creation; schedules; recovery requests; reconciliation and refunds; audit; analytics and demand; AI settings/activity; clinic hours; notifications; preferences |

### End-to-end journeys to design

1. Patient: sign in → notice the next appointment → inspect its ticket →
   reschedule → understand the confirmed new time.
2. Patient: book → select self or an authorized family account → department →
   clinician → visit reason → date/time → review → confirmation → ticket.
3. Patient: find a record → understand date/type/status → inspect values and
   source → open or export the document.
4. Patient: see a bill → review amount and payment method → submit once →
   distinguish confirmed, pending and failed payment → receipt/history.
5. Staff: identify the next patient → check identity and allergies → open the
   chart or consultation → save a draft → review → sign if permitted.
6. Staff: find assigned/covered results, messages or tasks → act on the right
   patient → retain context → understand saved, failed or conflicting changes.
7. Admin: see an exception → open its filtered queue → assign, correct or
   reconcile it → return without losing filters or position.
8. Every role: change preferences; handle inactivity, reauthentication and
   session expiry; return to an authorized task with clear context.

## 3. What to adopt and adapt from Figma

| Reference | Adopt | Adapt to the app |
|---|---|---|
| Auth | Left-aligned brand/title, calm header, plain fields, strong primary action, subtle demo entry | Use the current verification-code and administrator recovery paths. Do not claim a reset email was sent when no email provider exists. Retain MFA and password policy. |
| Patient Home | One next-appointment anchor, small action tiles, short health snapshot | Keep allergy information and unresolved attention items ahead of routine content. Use actual data with units/dates. |
| Appointments | Upcoming / Past / Cancelled filters and short rows | Map to real appointment states; reveal cancellation/rescheduling rules and detailed ticket data on the detail page. |
| Records | A readable chronological list with simple type controls | Distinguish record type, clinical result flag, review status and download action. Keep medications and vitals accessible. |
| Nutrition | Clear summary and meal-sized rows | Present estimated targets and an example daily split. The references' logged calories, consumed meals and “Add a meal” imply a diary that does not exist. |
| Profile | Identity summary and grouped navigation rows | Move appearance controls into Preferences; retain password, family access, feedback and avatar actions. |
| Staff Dashboard | Next patient, concise shift indicators, short work previews | Preserve result/message ownership, overdue work, walk-ins and doctor/nurse permission differences. |
| Staff Patients | Search and short identity rows | Retain care-team boundaries and desktop list-detail context. “My patients”/“Flagged” need working data filters before being offered. |
| Staff Tasks | A visible primary task action | Replace opaque score emphasis with urgency, due time, patient and task state. Keep explanation/provenance available. |
| Staff Schedule | Day strip and scannable agenda | Generate real dates; the reference contains dates 31, 32 and 33 after September 30. Keep the existing day/month/year tools. |
| Admin Dashboard | Compact attention summary and recent activity | Keep exception work ahead of totals; retain oldest age and failed-source indicators. Do not undo the current attention-first dashboard. |
| Users / Departments / Billing | Search, concise rows, contextual actions | Separate staff presence from account activation; keep dependent-delete rules and transaction-backed payment states. |
| Admin Profile | Clear settings destinations | Bring operations links into the Dashboard/workspace where they are easier to find; keep personal preferences in Profile. |

The Figma dollar amounts and example totals are placeholders. Current billing
renders BD amounts; redesign labels must use the existing monetary data and a
shared formatter rather than changing currency based on a mockup. Do not add
fake summary metrics just to reproduce the image.

## 4. Findings and priorities

“Confirmed” means visible in source/reference evidence. “Validate” means a
plausible usability or layout issue that needs runtime measurement.

| ID / priority | Evidence and finding | Proposed improvement | Acceptance |
|---|---|---|---|
| UX-01 / P1 | Confirmed: blue palette and `hero: true` headers exist, while login still has a centered gradient medallion and multiple other components retain gradient/glow decoration. `app_colors.dart`, `auth_scaffold.dart`, `login_screen.dart`, `app_card.dart`. | Finish one coherent visual system; use the shared auth header for sign in and neutral surfaces for ordinary content. | All auth pages and role roots share the specified type, spacing and surface roles in every theme. |
| UX-02 / P1 | Confirmed: PatientTopActions has notification/theme/profile actions; staff adds presence; admin renders status, notifications, theme and profile. AppScaffold hero titles use a fixed 104dp toolbar and one-line ellipsis. Validate crowding at narrow widths/200% text. | Keep notifications and essential role context visible. Put theme and language together in Preferences with a compact access menu where needed. Let heading height respond to content. | Long English/Arabic titles remain understandable and every action remains reachable at 320dp and 200% text. |
| UX-03 / P1 | Confirmed: `staff_quick_actions.dart:118` and `admin_quick_actions.dart:108` use `childAspectRatio: 2.6`, despite the shared TileGrid accounting for text size. | Use available-width and content-driven tile sizing, with fewer columns when labels need space. | No clipped or overlapping shortcut labels with Arabic, long strings, 200% text or keyboard/split layouts. |
| UX-04 / P1 | Confirmed: Home exposes a dedicated Quick Appointment hero alongside a large appointment ticket and a separate actions block. Its carousel has position controls and an unbounded page sequence. | One static next-appointment summary with a clear detail action; show a concise “View all” entry for additional visits; turn booking into an ordinary shortcut. | Patient can find the next visit, book, and see attention items without navigating a carousel; no automatic motion is introduced. |
| UX-05 / P1 | Confirmed: Appointments renders upcoming and all history together; each card repeats booking date, ticket metadata, reason and actions. | Filter by Upcoming / Past / Cancelled; compact clinician/date/status rows; move secondary facts and destructive actions to detail. | Status definitions cover all existing states, history remains paged, and returning restores filter/scroll. |
| UX-06 / P1 | Confirmed: HealthRecords has a documents grid, Timeline/Medications/Bills switch, then the timeline's own search/filter controls. | Give records a single coherent filter/search region. Move primary billing discovery to Profile/Home, retain a legacy bills link during transition. | Patient can find labs, imaging, medications, allergies, sick leave and vital reports; no old billing link breaks. |
| UX-07 / P1 | Confirmed: all three profile hubs expose language/theme controls inline and also a Preferences destination. Profile surfaces use elevated cards. | One identity card, grouped navigation rows and a clear Preferences row; quieter surfaces. | Every existing account, accessibility and notification setting is reachable with consistent grouping. |
| UX-08 / P1 | Confirmed: Staff dashboard stacks shift metrics and the whole quick-action grid before queue, flags, result reviews, messages and tasks on compact layouts (`SectionColumns` concatenates primary before secondary). | Keep next patient first, then urgent owned/covered work and queue. Limit shortcuts to a few frequent tasks, with a “More actions” entry. | Overdue results/messages are discoverable before routine shortcuts; work remains usable when AI is unavailable. |
| UX-09 / P1 | Confirmed: task actions are in an overflow menu; the UI calls `StaffOps.setTaskStatus`, whose repository result is discarded. Scores/tags take more space than patient context. | Expose the primary action, patient and due time; move scores/explanation into details. Return and display mutation outcomes, with busy state and conflict recovery. | Failed transitions show feedback and preserve the task; duplicate taps are blocked; terminal transitions remain final. |
| UX-10 / P1 | Confirmed: wallet `_BalanceCard` returns a loading skeleton whenever `walletBalanceProvider` has no value, including an initial error (`payments_screen.dart:127`). | Render explicit loading, failed, ready and stale states through shared state components. | A failing wallet read shows retry rather than an endless skeleton or a fabricated zero balance. |
| UX-11 / P1 | Confirmed: TwoPane uses a 380dp list width and the global expanded breakpoint while the navigation rail also takes width. Validate remaining detail space near 840dp. | Select list-detail mode from the actual content width; use minimum viable list/detail widths and fall back to a single pane. | Chart/forms fit at 840/1024dp with the rail, including 200% text; selection and back context survive resizing. |
| UX-12 / P2 | Confirmed: operational tables/state components exist but many directories and billing screens render custom cards and independent `.when` branches. | Adopt the existing OperationalList/AsyncDataView where their contracts fit, preserving feature-specific behavior. | Desktop rows support scan/search/filter; phone cards show the same facts; errors and stale states have consistent recovery. |
| UX-13 / P2 | Confirmed: lab values are a horizontally scrolling DataTable on narrow screens (`lab_values_table.dart`). | Use stacked analyte/value/unit/range/status rows on phones; retain a table on wide screens. | A patient can associate every value with its unit and range without horizontal panning; “No range” stays distinct from Normal. |
| UX-14 / P2 | Confirmed: separate page FABs coexist with a draggable Care Navigator overlay on patient shell pages. Validate occlusion and keyboard/focus behavior. | One predictable assistant entry with reserved placement, accessible dismiss/open actions and a coherent action area. | Import, message and home-visit actions never overlap the assistant, bottom nav or keyboard. |
| UX-15 / P2 | Confirmed: reference language icon, current theme/profile shortcuts, custom calendar frame and profile-specific actions are inconsistent. | Define an explicit action policy per page class and share it across roles. | Root pages, details and focused workflows have consistent back/menu/action placement. |

P1 items are the first redesign milestone. P2 follows after the first complete
patient workflow and role dashboard examples are validated. These are product
priorities for this redesign, not asserted clinical severity ratings.

## 5. Proposed visual and interaction system

### Visual rules

- Retain `#1E5FAF` as the current blue primary, with pale blue header/container
  roles, a cool light page and white cards. Final token values come from
  measurement and contrast checks, not screenshot pixel guessing.
- Keep bundled Inter for UI/body, Lexend where it provides a useful heading
  hierarchy, and the bundled Arabic fallback. Make heading weight choices
  explicit in the type tokens; stop overriding them independently per page.
- Use 4dp spacing tokens: 16dp compact gutters, 24dp wider gutters, 12–16dp
  interiors for list rows and 20–24dp for larger content panels.
- Use approximately 14–16dp corners for dense rows/fields, larger corners for
  hero panels and sheets. Keep pills for statuses and appropriate filter
  controls. Final radii require one comparison pass across adjacent components.
- Define separate surfaces for ordinary rows, grouped lists, metrics and the
  main hero. Remove resting glow from routine cards. Use blue emphasis for the
  principal action rather than making every shortcut a hero.
- Body text should remain readable at normal and 200% scale. Preserve 48dp
  interaction targets. Do not recreate the exports' tiny navigation labels.
- Show statuses with words and color. Separate urgency, workflow state,
  account activation, staff availability and payment confirmation.
- Implement equivalent dark and high-contrast roles rather than hardcoding
  the light screenshot colors into widgets.

### Component changes

| Existing primitive | Planned work |
|---|---|
| AppScaffold / AuthScaffold | Shared header contract with root, detail and focused-task variants; adaptive title/action space; predictable scroll/action padding. |
| AppShell | Preserve indexed tab stacks; regular selected-state styling; size from available space; keep meaningful labels. |
| AppCard / ListCard / NavRow | Quiet row and grouped-list variants; consistent icon leading area, metadata, chevrons and focus/hover/press states. |
| GradientHeroCard / appointment ticket | Solid or restrained blue anchor variant; support real explicit actions; retain full ticket on its detail page. |
| MetricTile | A number, label, unit/period and optional source/date. Missing data has a readable state. |
| TileGrid | Shared content-aware shortcut layout adopted by staff/admin too; no feature-level aspect-ratio sizing. |
| Status pills / badges | A documented mapping per domain state; no universal “normal” badge for unrelated conditions. |
| AsyncDataView / feedback | Stable loading, inline refresh, failed/stale/empty/conflict/access-lost states and feature-appropriate recovery. |
| OperationalList / TwoPane | Reuse search, filters, selection and paging; constrain pane layouts from actual width. |
| Sheets / dialogs | Standard heading, explanatory text, validation, action row, pending state, scroll and keyboard behavior. |

### Interaction rules

- Give each page/task a clear primary action. Use text or menu actions for
  secondary work; destructive actions appear in context with the existing
  confirmation and permission rules.
- Show the patient/account being acted on during family booking, linked-account
  billing and clinical work. Do not collapse view-only and manage grants into
  the same affordances.
- Keep input and selection after a failure. Focus the relevant field or error;
  allow retry without re-entering the whole form.
- Treat “empty”, “not loaded”, “failed”, “unavailable” and “pending” separately.
  Success messages follow confirmed repository/provider outcomes.
- Preserve filters, selected patient and scroll position through detail views.
  Store new persistent preferences only in their appropriate account/device scope.
- Keep reduced motion supported; use short transitions for context changes.
  Avoid decorative stagger across every dashboard section.
- Generated summaries and scribe content retain draft/provenance/review wording;
  appointment slot presentation respects the existing capability gates.

## 6. Screen-by-screen implementation coverage

The first row groups reference screens; following rows cover the secondary
surfaces missing from the Figma exports. Each work package includes all read,
mutation and empty states relevant to that screen.

| Work package / source area | Planned treatment |
|---|---|
| Auth: login, registration, password recovery | One auth frame; consistent field labels, visibility toggles, progress, validation, demo entry and real recovery steps. Design all registration steps, not only the supplied first step. |
| Auth: onboarding, splash, reauth and inactivity | Short, skippable relevant onboarding; unobtrusive splash; readable timeout and MFA/reauth dialogs; correct focus and resume behavior. |
| Patient Home and attention strip | Allergy/attention → next appointment → frequent actions → health snapshot, with honest source/loading states. Desktop can split secondary content without altering task priority. |
| Appointments, detail, slot picker and booking | Compact filtered list, complete detail/ticket, focused progressive booking, explicit review/confirm, clear no-availability/conflict/blocked-change outcomes. |
| Timeline / HealthRecords and import sheet | Unified search/type controls; chronological rows; medication access; recognizable document actions; import progress and provenance. Retain access to source files and exports. |
| Record detail, lab table, imaging and sick leave | Consistent detail summary; readable values/units/ranges; verified/review state; original and PDF actions with progress/retry. |
| Vitals and medications | Latest value/date/unit and history; readable trend/status information; current/past medications with dose and relevant instructions. |
| Nutrition calculator, meal plan and food database | Overview of estimates, current inputs and example split; edit inputs as a focused task; search foods using consistent filters. No consumed-calorie or diary claim. |
| Patient Profile, personal/health pages and avatar sheet | Quiet identity/menu hub; focused forms; password/feedback/appearance entry points retained; reliable save/error behavior. |
| Family network, linked grants and linked-account view | Clear owner, request/accept/revoke states, permission scope and expiry where modeled; persistent acting-for context. |
| Patient payments, wallet top-up and payment methods | Outstanding amount first; then payment/transaction history and methods. Distinguish wallet balance, amount owed, pending payment and settled receipt. |
| Patient/staff message lists and thread | Readable participant/unread/last-update rows; accessible composer and keyboard behavior; patient reply-time/non-emergency copy; staff owner/coverage context. |
| Home visit request/history | Focused request form; status timeline and next step; visible cancellation constraints. |
| Notifications and feedback sheet | Shared grouped rows and clear unread/read actions; dependable link destination; distinct send/acknowledgement state for feedback. |
| Staff Dashboard, quick actions and next patient | Compact queue/owned work, urgent results/messages and a bounded task preview. Presence remains available without crowding titles. |
| Staff Patients and persistent patient context | Search/filters, clear identity rows, selected state and available-width list-detail layout; reduce unused context chrome where safe. |
| Chart, clinical write sheets and result review | Persistent identity/allergy context, quiet sections, obvious action labels, source/range/verification detail, owner/due/escalation controls. |
| Consultation | Distinguish editing, saving, saved, conflict and signed states. Group clinical note/medications/referral tasks; retain durable drafts and doctor/nurse permissions. |
| Task board | Patient + task + due/priority + state + primary action; secondary reasoning/AI metadata; explicit mutation feedback. |
| Staff Schedule, queue strip and appointment cards | Scannable daily agenda with date navigation; retain month/year drilldown and queue lifecycle actions. Give Today and selected day consistent treatment. |
| Scribe and patient/staff summary | Reviewable content with source and mode; busy/unavailable/failure states; clear return to the originating chart/consultation. |
| Staff Profile, activity, directory and analytics | Shared profile hub and subpage framing; operational links also reachable from the workspace; consistent rows and scoped metrics. |
| Admin Dashboard and attention list | Exception ownership/age first; filtered links to the matching queues; activity preview and secondary analytics entry. |
| Admin work queue, referrals and home-visit decisions | Shared responsive list/filter/detail patterns; explicit assignment, decision, reason, busy/error and handover states. |
| User directory, account creation and staff schedules | Consistent role filters/search; contextual add action; account activation separate from presence; focused account/schedule/recovery panels. |
| Departments | Quiet rows and contextual edit; lower emphasis for delete; retain relation-dependent failure explanation. |
| Admin Billing | True summary metrics where supported, searchable/filtered invoice rows, responsive transaction details, reconciliation/refund/desk-payment tasks. |
| Admin appointments and feedback | Consistent operational lists, lifecycle controls, context and clear resolved/reopened feedback states. |
| Audit, system analytics, demand view and AI activity | Clear period/source/freshness; useful filters/paging; no forecasting or AI claims beyond supported capability. |
| Admin Profile, account, clinic hours and AI settings | Separate personal preferences from clinic controls; group configuration forms and show actual save/unavailable states. |
| Preferences across all roles | Device appearance/language/text/motion/contrast vs account notifications/sounds; scoped reset actions and save rollback/error feedback. |
| Global bootstrap, access boundary and confirmation overlays | Match the visual system; make outcomes accessible; preserve session guards and prevent confirmations from covering unresolved tasks. |

## 7. Layout plan by available space

| Situation | Proposed behavior |
|---|---|
| Compact phone / narrow browser | Single column, five labeled navigation destinations, content-driven headers, short list rows, full-screen detail/task flows, keyboard-aware actions. |
| Medium window | Existing rail where it fits; single working pane; bounded forms and two-column shortcuts only if labels fit. |
| Wide workspace | Extended rail when usable; dashboard columns ordered by task importance; searchable operational tables; persistent list-detail only when both panes fit. |
| Short landscape / split window | Reduce header chrome, retain scrollable/reachable navigation and content, prioritize actual height and content width. |
| 200% text / Arabic | Wrap text and expand rows/header regions; reduce columns and actions; directional alignment; preserve LTR identifiers, amounts and clinical units where needed. |

The current width classes are useful navigation defaults, but pane layouts and
toolbar action density should use their local constraints. A breakpoint at the
whole-window level is insufficient after subtracting a rail and list pane.

## 8. Delivery sequence

### Phase A — Record the current baseline

Run the pinned toolchain, capture current screenshots of all role roots and
the critical journeys at phone and desktop widths. Include English/Arabic,
light/dark, 200% text and key error states. Establish a route/screen checklist
from this plan and distinguish current bugs from intended design changes.

Deliverable: current screenshots, reproducible commands and the initial issue
list. This has not happened in the current environment.

### Phase B — Foundations and representative screens

Finalize color/type/spacing/surface tokens; fix action density, dynamic headers,
shortcut sizing and actual-width panes. Build the shared row, grouped-list,
anchor and focused-form treatments. Update `DESIGN.md` and stale comments to
describe the resulting system.

Use Sign in, Patient Home, Appointments, Staff Dashboard and Admin Users as
representative examples. They exercise auth, dashboard, patient list, role
context, actions, filters and forms. Review them at phone and desktop widths
before propagating changes to every page.

Deliverable: one consistent component system and five representative screens.

### Phase C — Complete the patient journeys

Booking/detail/reschedule; Records/import/detail/export; Profile/Preferences/
family grants; payments and pending/failure states; messaging/home visits;
nutrition and notifications. Resolve billing discovery and preserve existing
deep links, including the medications query route and old records bills entry.

Deliverable: coherent patient workflows, including states absent from Figma.

### Phase D — Complete the staff workspace

Dashboard/Patients/Chart → consultation/result review → tasks/inbox/schedule.
Preserve patient context, draft persistence, covered work and permission-gated
actions. Use the same forms/rows/states; keep specialist workflow layouts where
they help complete the task.

Deliverable: consistent doctor and nurse task paths with reliable feedback.

### Phase E — Complete administration

Dashboard/work queues → Users/Departments/Billing → referral/home-visit/
appointment/feedback actions → analytics/audit/settings. Keep operations
reachable from the workspace while preserving profile aliases and deep links.

Deliverable: scannable administrative queues and focused correction tasks.

### Phase F — Verify and polish

Run the regression matrix, compare against baseline images, then review focus,
screen-reader behavior, Arabic text and real browser resizing. Use the existing
usability tasks to measure improvements. Polish spacing, icon consistency and
motion after task completion and state comprehension are sound.

Deliverable: updated design documentation, screenshot evidence, test results
and a record of remaining manual findings.

## 9. Validation and completion criteria

### Automated and browser checks

Use the Flutter 3.44.4 / Dart 3.12.2 toolchain pinned in README/CI. On a prepared
checkout, run:

```bash
flutter analyze
dart format --set-exit-if-changed lib test integration_test test_driver
flutter test
flutter build web --release --no-web-resources-cdn --dart-define=APP_MODE=demo
flutter build web --release --no-web-resources-cdn --dart-define=APP_MODE=production
```

During each implementation phase, run the relevant existing suites first:
auth/recovery/session; booking/appointments/family; records/documents/billing;
consultation/results/tasks; admin actions; theme/preferences; navigation
continuity/shared states. Add targeted regression cases for the wallet error,
task mutation feedback, local pane width and shortcut scaling findings.
Add visual baselines only after the component direction is settled.

Test at the existing matrix: 320×568, 375×667, 430×932, 600×800, 840×700,
1024×768 and 1440×900; include short landscape/split layouts and keyboard
insets. Cover light/dark/high contrast, English/Arabic, default/200% text and
reduced motion. Existing coverage under `test/features/` and `test/phase6/`,
`phase7/`, `phase8/` is a starting point, not proof that every screen fits.

### Task review

Use `phase9_usability_kit.md` and `usability_study.md` for comparable baseline
and improved sessions. Record completion without help, task time, wrong turns,
misunderstood outcomes, lost patient context and duplicate entry. Agree numeric
improvement targets after collecting the baseline, rather than inventing a
percentage gain before observation.

Completion means:

- Every route/work package has a specified and reviewed layout and its relevant
  loading, empty, error, pending, success, conflict and access states.
- Patient appointment/record/payment/family tasks and staff/admin work paths
  remain complete and permission-correct.
- Primary actions and status meanings are clear; preferences and billing have
  understandable locations.
- Header, navigation, forms, lists, sheets and feedback use the same component
  rules, with no clipped essential content in the supported matrix.
- Runtime checks and screenshots are recorded for the changed revision;
  manual Arabic/assistive-technology review is recorded separately.

## 10. Deferred scope and implementation boundaries

Keep a food diary, reset-email integration, shared clinical backend, live
payments/notifications and new release platforms as separate product changes.
Keep Nutrition as a primary tab in this first pass because the references and
current app agree on that structure. Reconsider its position only if task study
shows it is less useful than a proposed alternative.

A pure presentation milestone should not change database schema, authorization,
signed-note immutability, payment settlement rules or capability gates. UI fixes
that need controller changes (for example returning task mutation outcomes)
should be small, explicit and covered by the corresponding workflow test.

No design implementation, SDK installation, remote Figma edit, commit or
deployment was performed for this planning review.
