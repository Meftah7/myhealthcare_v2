# MyHealth patient rebuild: complete updated TODO for Claude

Updated 11 October 2026. This is the current specification and supersedes earlier Weather/News navigation, red-theme defaults and above-Services shortcut layouts.

## Copy this brief into Claude

I want you to implement a patient-interface rebuild in my existing Flutter app, MyHealth. Repository: https://github.com/Meftah7/myhealthcare_v2 . Inspect the current checkout and its instructions before editing. The previous analysis used revision 298132e5d407d2ab92cd0cde8fe13d5d835caa4b; verify the current code because it may have changed.

The design was developed from healthcare-app screenshots and my senior-project proposal. I approved the BLUE appearance from the interactive preview. This document describes the design and implementation in text, so you do not need to read the HTML to understand it.

LATEST USER DECISIONS — FOLLOW THESE:
1. Use the approved BLUE light/dark appearance.
2. Bottom navigation: Home → Records → Appointments → Messages → Services. Messages belongs between Appointments and Services.
3. Add a native Flutter Drawer for settings, preferences, profile/account details, family links, billing, feedback, About and sign-out. Use it for less-frequent administrative/account interactions.
4. Place Quick Access directly BELOW the Home Services heading and carousel. Keep daily care features removed from their old navigation here. Relocate low-frequency account features into the drawer; never delete them.
5. Do NOT connect Weather or News sources. Do not create dedicated Weather/News bottom tabs, live feeds, provider credentials or fake live values. Optional catalogue entries may open a Future work explanation only.
6. Any functional addition outside the supplied proposal must show a visible “Future work” label on its entry/button. Existing supplementary features stay functional but are classified outside the proposal. Required report AI is core and must not be reclassified as optional future work simply because its live integration is pending.
7. Implement real Flutter widgets using the existing controllers/repositories. Do not copy the HTML prototype's fictional accounts, sample bookings, scripted responses, sample text downloads, device frame or design controls into production functionality.

CURRENT IMPLEMENTATION STATUS:
Reconciled on 11 October 2026 against the current branch, source, existing redesign commits and fresh tests. Patient navigation now uses bottom tabs below 600px, a rail with Account & preferences at 600–1023px, and a scrollable permanent sidebar at 1024px and above. The latest booking hardening, patient screen redesigns and grounded PDF follow-up chat were already implemented and are preserved. Text-size options are Small (0.85), Default (0.92), Large (1.0); saved wire names preserve existing sizes, including legacy 1.15/1.3 values. New and reset preferences use Default. OS scaling remains independent and unclamped. See patient_rebuild_status.md for exact verification and limits. Live-provider evaluation and approved policy content remain externally blocked. No push, deployment or database reset occurred.

Preserve the proposal's core: patients view records, book appointments and download documents; an AI chatbot explains uploaded PDF medical reports; doctors/nurses manage visits, records and daily tasks; administrators manage users, appointments and clinic activity. Rebuild the patient experience first, and keep its staff/admin integrations working.

Proceed through the checklist in order. Mark an item complete only when implemented and verified. Report a missing integration explicitly and continue independent work. Do not present an unavailable service as operational or replace working features with placeholders.

## 1. Baseline and preservation

- [x] Read applicable AGENTS.md instructions and inspect the current repository state; preserve existing uncommitted work.
- [x] Inspect startup, router, session, patient shell, providers, theme, localization, database and repository contracts.
- [x] Run the existing app and relevant checks when the SDK is available; record pre-existing failures separately.
- [x] Capture the current patient Home, navigation, booking, records, nutrition and profile before changing them.
- [x] Inventory EVERY patient-visible feature, nested destination, overflow menu, sheet and document action. The Quick Access list below is a starting map; extend it for anything found in the current checkout.
- [x] Create a preservation matrix: existing feature → old route/action → new primary entry → Quick Access entry → access policy → verification status.
- [x] Distinguish publicly browsable services from patient-specific data.
- [x] Verify the selected data environment. The reviewed full app uses local Drift; setting SHARED_API_ORIGIN launches a separate shared pilot. Do not assume redesigning one updates the other.
- [x] Retain Flutter, Riverpod, GoRouter and existing repository/domain layers; avoid an unnecessary framework/package migration.
- [x] Establish a reversible implementation branch/checkpoint and an additive migration strategy if data changes are necessary.

## 2. Approved blue design system

Use these values as the initial design specification. They describe the approved preview; use accessible foreground adjustments where necessary. Do not reuse obsolete red/pink theme defaults from the earlier blueprint.

| Token | Light mode | Dark mode |
| --- | --- | --- |
| Primary filled button | #246BFD | #246BFD |
| Primary links/icons | #246BFD | #9ABEFF for readable contrast |
| Primary action foreground | #FFFFFF | #FFFFFF |
| Soft accent surface | #E9F0FF | #213858 |
| Main canvas | #F7F7F8 | #111B28 |
| Card/navigation surface | #FFFFFF | #1C2839 |
| Main text | #2D333C | #EEF3F9 |
| Secondary text starting color | #727A83; use sufficient contrast | #A4B1C2 |
| Divider/border | #EBEDF0 | #2C394A |
| Success accent | #13B881 | Accessible green variant on dark surfaces |
| Success container | #E6F7F0 | #163C36 |
| Emergency/error | Red, semantic use only | Accessible red variant |

- [x] Introduce semantic patient-theme tokens or a ThemeExtension; avoid replacing shared global colors and unexpectedly recoloring staff/admin.
- [x] Use readable light blue for small links/icons on dark surfaces where #246BFD does not provide enough contrast; retain the approved filled-button appearance.
- [x] Use blue for primary CTAs, selected segments, active highlights and the center appointment tile.
- [x] Use pale-blue backgrounds for secondary actions and selected chips; remove pink/purple patient accents.
- [x] Keep charcoal/navy typography, white cards and a soft-gray light canvas; use the dark values for dark mode.
- [x] Use semantic green, amber, blue and red icon/status accents consistently; show a label or icon as well as color.
- [x] Retain MyHealth branding and the existing approved logo. Do not copy HMG naming, social accounts or the reference app's branded media.
- [x] Match the spacious rounded style: page inset around 22 logical pixels; spacing scale 4/8/12/16/24/32; card radius 20–28; button radius 12–16; sheet top radius around 28.
- [x] Use page titles around 26–30 logical pixels, section titles 20–22, body 15–17 and captions 12–13. Avoid shrinking text to fit four columns.
- [x] Use licensed fonts with good English/Arabic support, medium/semibold hierarchy and flexible line heights.
- [x] Make buttons around 50–54 pixels high with touch targets at least 48 × 48, including small icon controls.
- [x] Store appearance/language preferences using the existing preference system.
- [x] Display exactly Small, Default, Large in English/Arabic; reuse 0.85/0.92/1.0, preserve saved sizes, default new/reset users to 0.92, and retain OS accessibility scaling. Verified across phone/tablet/desktop, both languages and themes.
- [x] Do not render the preview's desktop introduction, phone frame, fake clock/battery, color switcher or guest/sample switcher inside the actual patient app.

## 3. Shared patient components

- [x] Build/refactor PatientPageScaffold, PatientHeader and PatientBottomNavigation.
- [x] Build shared SurfaceCard, SectionHeading, PrimaryActionButton and SoftActionButton.
- [x] Build IconTile, QuickActionPager, ServicePromotionCard and ServiceCarousel.
- [x] Build QuickAccessSection and QuickAccessTile with typed destinations and access metadata.
- [x] Build BookingModeSegment, DiscoveryOptionRow, HelpChoosingCard and AssistanceSheet.
- [x] Build a shared FutureWorkBadge and an explanatory sheet; Weather/News are unconnected future entries, not active data components.
- [x] Build shared loading, empty, error, unavailable, stale-data and retry presentation.
- [x] Keep repository/provider access in feature controllers, not in reusable visual components.
- [x] Define one typed catalogue for shortcuts/services where appropriate; avoid duplicating labels, routing strings and capability logic across Home and Services.

## 4. Five-tab patient navigation and authorization

Bottom navigation order MUST be: Home | Records | Appointments | Messages | Services.

- [x] Reconfigure only the patient shell branches. Preserve staff/admin destination sets and role guards.
- [x] Retain StatefulShellRoute.indexedStack behavior or equivalent independent branch state. The current visible-to-actual branch mapping is [0, 3, 2, 6, 5]; Nutrition/Profile remain reachable in their retained legacy branches.
- [x] Give each tab an icon and text label; emphasize Appointments with a rounded blue tile. Keep Messages immediately before Services. Messages is owner-approved current scope (2026-10-13 brief), so it no longer carries a Future work label.
- [x] Give the currently selected tab a distinct indicator, including when the center blue tile is already visible.
- [x] Preserve tab stacks and scroll positions when switching destinations; retain sensible tab-reselection behavior.
- [x] Open the dedicated booking flow full-screen, with a back button and no bottom bar, as in the reference.
- [x] Preserve old private routes through retained routes or explicit aliases; do not break record/profile/nutrition deep links when removing their bottom tabs.
- [x] Route relocated pages so the bottom bar, back behavior and active destination remain consistent. Quick Access pages must return to Home sensibly.
- [x] Preserve the current signed-in/role route policy. Public guest browsing is optional future work; do not weaken existing guards to imitate the old HTML guest preview.
- [x] Keep private records, appointments, documents, messages, family access and account data protected.
- [x] Keep patient-specific providers from loading for guests.
- [x] If a signed-out deep link opens a protected destination, use the existing authentication flow and allowlisted intent handling; never render private patient content before authorization.
- [x] Allowlist internal auth return routes; do not place report text or sensitive visit reasons in URLs.
- [x] Clear patient-scoped providers, retained branch content, chat state and dependent selection on logout/account switch.

## 5. Home: exact section placement

Required visual sequence:
1. Header.
2. Compact care alerts/upcoming appointment, when applicable.
3. Main assistance/report card.
4. Paged quick tools.
5. Services heading, View All action and horizontal service cards.
6. QUICK ACCESS heading and all relocated patient feature shortcuts.

The actual implementation retains signed-in patient access. If guest browsing is added later, it is Future work and requires a separate public catalogue/guard design. Existing care alerts do not replace Quick Access links.

- [x] Patient header: native drawer menu, greeting/account identity and any supported high-priority actions. Keep settings/theme/language controls in drawer preferences.
- [x] Provide consistent drawer access on compact and wide shell pages; avoid duplicate menu icons or a nonfunctional menu icon on root full-screen booking pages.
- [x] Keep existing allergy alerts, attention items and upcoming appointments when relevant; use real providers.
- [x] Add a white rounded hero card with original illustration, short heading, concise explanation and full blue CTA.
- [x] Do not place an unimplemented symptom checker in the core hero. Specialty/symptom guidance is an optional Future work entry; ordinary existing department/doctor selection is core booking.
- [x] Signed-in hero: “Your reports, made clearer”; CTA opens the PDF-report explanation workflow.
- [x] Keep report explanation and specialty discovery as separate use cases; do not present report chat as symptom diagnosis.
- [x] Recreate the four-item quick-tools pager and small active-page indicator.
- [x] If adding a quick-tools pager, use working doctor/booking/document actions; classify emergency integrations, extra calculators/converters and guidance outside the proposal as Future work.
- [x] Unsupported maps, wearables, water, pharmacy and similar tools open an accurate Future work explanation; they must not pretend to be live services.
- [x] Use reference-style service promotions with large rounded artwork/photo, small service icon, title, two-line description and action.
- [x] Use one horizontal carousel, showing part of the next card intentionally; allow swipe and accessible alternatives.
- [x] “View All” opens Services.
- [x] Every enabled promotion opens a real workflow; unavailable integrations use an explicit unavailable state.
- [x] Place Quick Access immediately after the Services carousel in the SAME Home scroll view. Do not require switching to Services or Profile to find relocated features.
- [x] Ensure all lower Home content clears the bottom navigation/safe area.

## 6. Quick Access: complete feature preservation

Use a responsive grid of rounded icon tiles. Each tile has a recognizable icon, a short label, a valid destination, and the correct permission rule. Suggested subgroup labels are “Records & documents,” “Care & communication,” and “Wellbeing extensions.” These groups stay below Services. Account administration belongs in the drawer.

| Quick Access label | Existing route/foundation to inspect | Preserve |
| --- | --- | --- |
| Health Records | /patient/timeline; timeline/records features | Search, filters, history, record details and originals |
| Medications | /patient/timeline?view=medications | Existing medication view and associated information |
| Documents | /patient/timeline/documents | Original/issued documents and downloads |
| Sick Leave | /patient/timeline/sick-leave | Issued certificates and authorized access |
| Imaging | /patient/timeline/imaging | Imaging records and attachments |
| Allergies | /patient/timeline/allergies | Existing allergy information/actions |
| Vitals & Trends | /patient/home/vitals | Measurements, trends and existing interactions |
| Health Summary | /patient/summary | Existing summary and real capability/fallback state |
| Explain a Report | ai_chat / timeline PDF-import flow | Upload, extraction, explanation and source access |
| Nutrition | /patient/nutrition | Calculator, targets, presets, food reference and preferences |
| Appointments | /patient/appointments | List, history, details, reschedule/cancel |
| Book Appointment | /patient/appointments/book | Existing booking rules and confirmation |
| Visited Doctors | /patient/appointments/doctors | Previous clinician list and existing links |
| Messages | /patient/home/messages | Patient/staff conversation list and threads |
| Notifications | /patient/home/notifications | Read/unread and existing notification actions |
| Home Visits | /patient/home/home-visit | Existing request/history workflow |
| Other patient actions found in inventory | Current router/widgets/menus | An accessible replacement for every existing entry point |

- [x] Add all applicable daily-care entries above, even if a feature is also reachable from a main tab. Put infrequent account actions in the drawer and record their replacement in the preservation matrix.
- [x] Keep high-priority Records, Documents, Explain a Report and Nutrition near the beginning of Quick Access.
- [x] Do not collapse everything into a single “More” button; every preserved feature needs a visible destination within the section, with grouping/search if needed.
- [x] Use two or three columns where space/text scaling requires it; four columns are optional where readable.
- [x] Use the existing controller/repository and screen where possible; restyle rather than replacing it with an empty page.
- [x] Preserve authorization and current subject for family-linked pages, including revocation checks after navigation.
- [x] Confirm every feature in the baseline preservation matrix has a working Quick Access, drawer or primary-tab entry. Investigate every unmatched action before completing the rebuild.
- [x] Keep sign-out as a confirmed account action; do not turn it into an ambiguous navigation tile.

## 6B. Native Flutter Drawer and low-frequency actions

Required drawer organization: patient/account header → Account & preferences → Supplementary account tools → About/support → Sign out.

| Drawer entry | Existing destination | Scope |
| --- | --- | --- |
| My Profile | /patient/settings | Core account support |
| Personal Information | /patient/settings/personal | Core account support |
| Health Details | /patient/settings/health | Patient record/account support |
| Settings & Preferences | /patient/settings/preferences | Appearance, language, text size, accessibility preferences |
| Family & Linked Accounts | /patient/settings/family and linked child | Existing supplementary feature; Future work scope badge |
| Billing & Payments | /patient/home/billing | Existing supplementary feature; Future work scope badge |
| Feedback | Existing feedback sheet | Existing supplementary feature; Future work scope badge |
| About MyHealth | About dialog/page | Core application information |
| Sign Out | Existing session controller | Confirmed account action |

- [x] Use Flutter Drawer/NavigationDrawer on the patient shell's Scaffold, not a custom popup pretending to be a drawer.
- [x] Address the outer patient Scaffold when opening the drawer; nested page Scaffolds must not swallow the menu action.
- [ ] Support opening, swipe/dismissal, back, screen-reader focus and wide-screen access. **Implemented / awaiting manual verification:** automated layout/semantics checks cover supported behavior; physical gestures, actual screen-reader order and focus restoration require the owner/tester record in docs/patient_manual_acceptance.md.
- [x] Show actual signed-in identity safely, including empty-name/photo fallback states.
- [x] Close the drawer before navigating; preserve correct route/back behavior and patient subject.
- [x] Move appearance/language and less-used settings into Preferences, preserving existing persistence/rollback behavior.
- [x] Retain high-contrast, text-size and reduced-motion preferences.
- [x] Keep family permissions, simulated billing boundaries and feedback submission functional.
- [x] Mark outside-proposal functional entries Future work without disabling working existing features.
- [x] Confirm sign-out and call the real session controller; clear private caches/panels/dialogs correctly.
- [x] Inventory any additional low-frequency patient actions in the current checkout and add appropriate drawer destinations rather than deleting them.
- [x] Keep staff/admin shell navigation and their account menus unchanged unless a shared regression requires a fix.

## 7. Onboarding, login and account continuity

- [x] Recreate two spacious onboarding pages with original illustrations, large headline, explanation, progress indicator and bottom controls.
- [x] Page one introduces appointment booking; provide Skip and Next.
- [x] Page two introduces records and report explanations; provide Get Started.
- [x] Store onboarding completion independently of login state; avoid showing it on every launch.
- [x] Skip/Get Started follow the existing authentication policy; do not introduce an unauthorized guest clinical Home.
- [x] Restyle real login, register, recovery and relevant authentication states using the blue patient tokens.
- [x] Preserve existing validation, role routing, session timeout and reauthentication behavior.
- [x] Preserve login intent from Quick Access and booking, including cancellation/back behavior.
- [x] Use real OS notification permission UI where supported, requested in context; handle denied permission without blocking the app.

## 8. Appointments: complete flow

- [x] Signed-in Appointments hub: upcoming/past/cancelled appointments and blue New Appointment action.
- [x] Maintain real authentication for booking. General scheduling is core; Virtual Care is visibly Future work until a supported integration exists.
- [x] General landing: back arrow, “Book Appointment,” two-option segment, and one rounded card containing Clinic/Doctor/Region rows.
- [x] Each row has a soft icon tile, title, blue “Tap to select,” divider and trailing arrow.
- [x] Add the bottom help panel with a blue arrow; avoid keyboard/content overlap.
- [x] Clinic search: use actual facilities; distinguish physical clinics from specialty departments.
- [x] Doctor search: name/specialty filters, published clinician details, supported visit modes, availability and empty/error states.
- [x] Region search: show actual configured regions/facilities; if absent, show a clear unavailable state rather than invented locations.
- [x] Converge all discovery paths into ONE existing booking draft and controller.
- [x] Preserve existing appointment type/reason and patient/dependent selection.
- [x] Present date/slot selection with a blue selected state and fresh availability.
- [x] Clear dependent selections when clinic/doctor/date changes invalidate them.
- [x] Refresh availability after login and recheck dependent manage access at confirmation.
- [x] Review page: patient, doctor, specialty, facility, date, time, type and applicable details; edit/back controls.
- [x] Prevent duplicate submissions; handle slot conflicts and server failures without false success.
- [x] Confirmation comes only from the booking repository result; link to appointment details and Home.
- [x] Preserve detail, reschedule, cancel, status history and linked records/documents.
- [x] Verify patient booking integrates with the staff/admin workflow in the selected environment.

## 9. Assistance and Virtual Care

- [x] Assistance sheet: dimmed backdrop, rounded top, “Need help choosing a clinic?”, explanation, blue “Yes, Please” and soft-blue “No, Thanks.”
- [ ] Dismissal keeps the draft intact and restores focus to its trigger. **Implemented / awaiting manual verification:** automated layout/semantics checks cover supported behavior; physical gestures, actual screen-reader order and focus restoration require the owner/tester record in docs/patient_manual_acceptance.md.
- [x] Accept opens useful specialty descriptions and clinician discovery.
- [x] Any future symptom-based recommendation requires its own reviewed rules/evaluation; do not fake it with a generic chatbot.
- [x] Virtual Care tab: four benefit rows with colored icon tiles, headings, supporting copy and blue CTA.
- [x] Use “Virtual Care”/MyHealth branding; do not claim instant consultation or free medicine delivery without actual support.
- [x] Preserve existing messages/home visits, but do not label them live video.
- [x] If virtual care is unavailable, explain it clearly; build session/queue/provider/authorization/reconnect functionality only when that integration is in scope.

## 10. Records, documents, family access and PDF-report chat

- [x] Restyle existing records list/detail and document screens using the shared blue components.
- [x] Preserve search, paging, filters, medications, imaging, provenance, read markers and correction workflows that already exist.
- [x] Keep View Original, Download and Explain distinct actions.
- [x] Preserve original PDF bytes and authorized access; do not substitute the preview's sample text download.
- [x] Preserve issued documents, sick-leave certificates and visit-linked files from staff.
- [x] Implement/retain PDF selection/upload, size/type validation and extraction status.
- [x] Show a clear scanned/empty/corrupt/unsupported-document state; OCR is separate work unless already supported.
- [x] Provide a source preview and make the selected report visible in the chat header.
- [x] Explain the report in simple language and support questions grounded in that report.
- [x] Preserve generation/source provenance and disclose incomplete extraction/coverage.
- [x] Inspect the existing 12,000-character clipping path; avoid silent truncation or an implied complete explanation of a longer report.
- [x] Inspect current capability gating: live clinical AI was disabled in the reviewed revision. Do not mark the proposal's AI objective complete just because scripted/offline responses appear.
- [x] Keep real provider credentials server-side where a live service is enabled; enforce subject authorization before sending report content.
- [x] Label demo/offline/unavailable/error states accurately and correct the previously identified inconsistent production fallback if still present.
- [x] Keep PDF text as untrusted source content, not instructions overriding the assistant's behavior.
- [x] Keep explanations separate from original records and avoid representing them as diagnosis/prescription.
- [x] Clear source/chat context on report switch, patient switch and logout.
- [ ] Evaluate supported real responses using synthetic/de-identified reports, checking numbers, units, omissions, unsupported questions and failure recovery. **Blocked:** configure a server-held MYHEALTH_AI_KEY and an approved gateway origin/client token; mocked contract tests pass but do not evaluate live clinical responses.
- [x] Preserve household versus authenticated linked-account distinctions and view/manage permissions.

## 11. Nutrition and all other existing patient workflows

- [x] Keep existing nutrition calculator, daily targets, meal split, macro presets and searchable food reference accessible through Quick Access.
- [x] Preserve existing account-specific settings and calculations; validate numeric inputs and explain errors instead of accepting invalid values.
- [x] Do not claim a food diary already exists: the reviewed feature estimates targets, not logged intake.
- [x] Do not add water or micronutrient tracking to Nutrition merely to imitate the reference; preserve existing nutrition behavior. A separate water module is optional.
- [x] Restyle vitals/trends, medications, allergies, imaging, health details and summary without losing actions.
- [x] Restyle messages/inbox access and notification list while preserving read/unread/thread behavior.
- [x] Preserve billing invoices, payment history, wallet and existing simulated payment boundaries; never imply a real charge was made by a simulated gateway.
- [x] Preserve home-visit request/history and feedback submission.
- [x] Preserve personal information, avatar/photo, visited doctors, family links, preferences and account controls.
- [x] Update titles/icons/empty states consistently; each page must have a sensible back path to its Home Quick Access entry.

## 12. Services catalogue

Required order: core clinical services → MyHealth service promotions → clearly grouped Future work extensions. Core links cover booking, records, document downloads and report explanation. Optional care links can repeat Quick Access; the drawer holds infrequent account/support actions.

- [x] Core service actions: Book Appointment, Health Records, Documents, Explain a Report. Future work entries: emergency-service integration, checkup packages, indoor navigation, e-referral and blood donation.
- [x] Service promotion cards reuse the Home carousel design and catalogue definitions.
- [x] Health Tools: existing trackers/vitals, calculators, converters; separate water/watch modules only if supported.
- [x] Do not connect Latest News to a feed. Any News entry shows Future work; add Contact Us only with real configured support details and classify extra service functionality correctly.
- [ ] Policies: actual MyHealth Terms and Conditions and Privacy Policy destinations; do not copy HMG policies. **Partial / externally blocked:** English/Arabic destinations and owner-replaceable drafts are implemented and tested. Owner-approved operator/contact, legal, hosting/retention, provider, consent and appointment-policy details remain missing (assets/policies/policies.json).
- [x] Social links only for real MyHealth destinations; omit invented accounts.
- [x] Typed item definitions include stable id, localized title, group/order, icon/media, action, access policy and capability status.
- [x] Dispatch internal routes and external links explicitly and safely; centralize actions rather than embedding arbitrary strings in widgets.
- [x] Emergency opens verified appropriate local contact/info, not the ordinary booking flow and not a pretend dispatch action.
- [x] Give unavailable reference-only services an honest status; never replace existing working care features with unavailable placeholders.

## 13. Future work policy; Weather/News source exclusion

- [x] Centralize scope/capability metadata so every visible extra uses the same Future work label and behavior.
- [x] Distinguish “existing supplementary feature” from “planned/unavailable service.” Scope labels must not falsely imply a functioning existing module is broken.
- [x] Do not relabel the required PDF-report chatbot Future work because its live service is pending; record it as a core integration gap.
- [x] Include supplementary messaging, nutrition, vitals/trends, family access, home visits, billing, notification integrations and health summaries in the scope review.
- [x] Include planned virtual care, maps, wearables, water tracking, pharmacy, converters, checkup packages, donation, referrals and symptom-based guidance in the future catalogue.
- [x] Future work labels must be visible on the relevant entry/button, not only in a report or tooltip; preserve readable layout in Arabic/large text.
- [x] Do NOT add Weather or News sources, API requests, keys, background polling or automatic feed synchronization.
- [x] Do NOT add Weather/News as bottom navigation destinations.
- [x] If catalogue buttons remain, show “Weather — Future work” and “News — Future work” and open explanation sheets only.
- [x] Do not display fake temperatures, timestamps, disease risk indices or published headlines as live app data.
- [x] Keep all future integrations isolated from core Home, records, booking and document loading.

## 14. Architecture and file targets

Paths are relative to the repository. New folder names are proposals; fit them to the actual conventions.

| Area | Files/folders to inspect or change |
| --- | --- |
| Routing | lib/app/router.dart |
| Adaptive shell | lib/app/shell/app_shell.dart |
| Patient theme | lib/app/theme/ and a patient ThemeExtension |
| Shared patient UI | lib/core/ui/patient/ or equivalent new shared folder |
| Home / Quick Access | lib/features/patient_home/presentation/patient_home_screen.dart; new Quick Access component |
| Existing upcoming carousel | lib/features/patient_home/presentation/upcoming_appointment_carousel.dart |
| Header | lib/features/patient/presentation/patient_top_actions.dart |
| Onboarding / auth | lib/features/auth/presentation/onboarding_overlay.dart and existing auth screens |
| Booking UI/state | lib/features/booking/presentation/booking_screen.dart; lib/features/booking/application/booking_providers.dart |
| Appointment list/detail/slots | lib/features/appointments/ |
| Existing private patient pages | lib/features/patient/, timeline/, records/, vitals/, nutrition/, billing/, notifications/, care/ |
| Documents | lib/features/patient/application/patient_documents.dart; existing care document screens |
| Report chat | lib/features/ai_chat/ and existing PDF-import/source services |
| Capability policy | lib/core/capabilities/capability_registry.dart |
| New catalogue/directory | lib/features/service_catalog/ and directory/ if needed |
| Excluded source integrations | No Weather/News sources or active tab modules in this delivery |
| Localization | lib/l10n/ English/Arabic ARB files |
| Assets | assets/ and pubspec.yaml |
| Verification | test/ and integration_test/ |

- [x] Connect widgets to existing providers/repositories; do not create competing booking, document ownership or family-permission systems.
- [x] Add feature controllers/repositories only for genuinely new domains.
- [x] Use additive versioned database migrations only where persistence is needed; no database reset for visual changes.
- [x] Keep service configuration/design tokens out of the clinical database unless there is a real persistence requirement.
- [x] If connecting the full app remotely, define explicit adapters/API contracts; do not silently fall back to local data after remote errors.
- [x] Keep implementation details out of patient-facing copy except when needed to explain a real unavailable condition.

## 15. Localization, responsive design and accessibility

- [x] Localize every new title, action, state, validation message and accessibility label in English and Arabic.
- [x] Use directional alignment/padding and RTL-aware arrows; verify mixed Arabic/numbers/dates.
- [x] Use real date/time formatting and facility timezones where applicable; do not hardcode prototype dates, locations or patient data.
- [x] Verify phone, tablet and desktop layouts; keep the adaptive navigation approach and constrain content widths.
- [x] Let tile columns change for screen size/large text and use flexible card heights.
- [ ] Keep touch targets, contrast, semantic labels, screen-reader order and keyboard access usable. **Implemented / awaiting manual verification:** automated layout/semantics checks cover supported behavior; physical gestures, actual screen-reader order and focus restoration require the owner/tester record in docs/patient_manual_acceptance.md.
- [ ] Make modal focus entry/exit, dismissal and keyboard avoidance correct. **Implemented / awaiting manual verification:** automated layout/semantics checks cover supported behavior; physical gestures, actual screen-reader order and focus restoration require the owner/tester record in docs/patient_manual_acceptance.md.
- [x] Respect reduced motion; avoid mandatory auto-moving service/appointment carousels.
- [x] Decode media at suitable sizes, load long lists lazily and avoid fetching an entire clinical history just to populate Home.
- [x] Use original/licensed assets with consistent fallbacks; do not make final screens depend on screenshot crops.

## 16. Implementation order and completion gates

- [x] Phase 1: baseline audit and preservation matrix; choose the current target environment.
- [x] Phase 2: blue tokens, shared components, patient shell and route guards.
- [x] Phase 3: onboarding, Home, Services, COMPLETE below-Services Quick Access and native drawer.
- [x] Phase 4: booking discovery, auth resume, slots, confirmation and appointment management.
- [x] Phase 5: restyle/reconnect records, documents, report chat and all preserved patient pages.
- [x] Phase 6: complete proposal scope badges and future explanation sheets; leave Weather/News sources excluded.
- [x] Phase 7: localization, visual refinement, accessibility, regressions and cross-role verification.
- [x] Deliver the working booking journey early: real login → patient Home → discovery → booking → appointment details.
- [x] Deliver the report journey next: authorized patient → PDF → extraction → explanation → original download.
- [x] Finish with the preservation matrix: every old feature remains reachable and works with its original policy/data.

## 17. Required verification before declaring completion

- [x] Flutter analysis/build and relevant existing tests pass, or unresolved pre-existing/environment failures are explicitly recorded.
- [x] Five-tab branch navigation, old deep links, back/reselect and scroll restoration work; Messages activates its own preserved-path branch and thread navigation.
- [x] Quick Access is immediately below Services on Home and includes relocated daily-care features; all infrequent account actions have working drawer replacements.
- [x] Signed-out users cannot retrieve private data through routes or provider initialization; existing role guards remain enforced.
- [x] Login resumes allowed destinations; logout/account switching never shows another patient's cached data.
- [x] Booking handles stale availability, incompatible selections, duplicate taps, failures and revoked dependent permissions.
- [x] Real document downloads retrieve the intended authorized PDF; original/source and explanation stay distinct.
- [x] PDF empty extraction, long reports, AI errors and disabled capability states are handled accurately.
- [x] Existing records, nutrition, billing, messaging, notifications, family and profile workflows remain usable.
- [x] Patient booking/visit/document flow still works with staff/admin in the declared environment.
- [x] No sample-account button, scripted prototype answer or pretend confirmed booking is used as production implementation.
- [x] English/Arabic, light/dark and normal/large text are checked; optional service failure does not block care workflows.
- [x] Compare screenshots of the actual Flutter rebuild against this textual design and the approved blue preview when available.
- [x] Add meaningful unit/widget/integration tests for access, draft invalidation, booking and PDF journeys; use a small stable visual regression set.
- [x] Provide final changed-file summary, completed checklist, verification results and remaining genuinely missing integrations.

## Reference-screen iteration (IMG_3463–IMG_3472)

- [x] Fix GitHub/Linux font setup portability: shared bundled icon loader replaces SDK paths in layout and capture helpers; entire CI-style suite passes **722 tests, 0 failures, 2 optional capture skips**. See [portability evidence](verification/ci_font_portability.md). Remote Ubuntu execution awaits a committed/pushed workflow rerun; no push/deployment performed here.

- [x] Preserve the CORE PDF hero, approved blue design, adaptive navigation, three text preferences and Quick Access below Services; make Home shortcuts horizontally browsable with keyboard-accessible controls.
- [x] Connect Emergency Services with verified Bahrain 999 phone action and honest launch failure; keep ER location, rapid response and check-in visibly Future work.
- [x] Reuse the real clinician directory, filters, loading/error/empty states, clinician details and authorized booking continuation.
- [x] Add collapsible calculator groups; reuse BMI/BSA and Nutrition; keep ovulation, due date, ideal weight and body fat as explanation-only Future work without collecting pregnancy inputs.
- [x] Implement three analyte-specific bidirectional converters, localized input, validation, physical-value-preserving swap and clipboard output; retain scope badges and existing general converters.
- [x] Provide a dismissible hospital sheet with honest unavailable state and real clinic-department fallback; preserve booking draft and omit invented facilities/distances.
- [x] Add unit/widget/layout coverage and actual Flutter screenshot galleries; preserve system scaling even at 320px/3×, using intact horizontally scrollable words where necessary.
- [x] Rerun the entire final suite after the heading and test-fixture corrections: **724 passed, 0 failed/skipped**. Analysis and formatting pass; final release-build evidence is recorded in the current status. Targeted reruns alone do not satisfy this gate.
- [ ] Complete the added device/screen-reader checks in [reference tools handoff](patient_reference_tools.md).
- [ ] Supply authorized ER/facility/location services, hospital booking model, rapid-response/check-in operations and validated specifications for four planned calculators before enabling those Future work entries.

## Remaining external acceptance gates

The IMG_3463–IMG_3472 implementation inventory and new manual checks are in [patient reference tools](patient_reference_tools.md). Latest checkout verification appears in [patient rebuild status](patient_rebuild_status.md); the earlier 693-test result below is historical evidence from before this iteration.

Previous rebuild verification on 11 October 2026, before this reference-screen iteration: the entire Flutter suite passed **693 tests, 0 failures, 0 skips**, with captures enabled; relevant server tests passed **21/21**. Analysis had no errors/warnings (146 informational lints); release web build passed. Latest results, exact commands, complete logs, actual Flutter screenshots and status categories are recorded in [patient rebuild status](patient_rebuild_status.md). Checked implementation items do not certify the outstanding external checks below.

- [ ] Perform physical-device and TalkBack/VoiceOver checks; record actual pass/fail evidence in docs/patient_manual_acceptance.md.
- [ ] After approved server configuration, run live report evaluation and live failure/recovery checks using docs/patient_external_review.md; mocked tests are not live evidence.
- [ ] Obtain owner approval of bilingual Terms/Privacy after filling the policy facts in docs/patient_external_review.md. Keep assets/policies/policies.json as draft until approved.

Android APK generation remains a separate packaging limitation: the Android SDK is unavailable. It does not block Flutter implementation or web verification.

## Definition of done

The patient app has the reference-style rounded layout with approved blue light/dark branding, Home/Records/Appointments/Messages/Services navigation and connected workflows. Quick Access directly below Services preserves everyday care features; the native drawer preserves infrequent account/settings workflows. Records, booking, PDF downloads and report explanations remain central and accessible. Existing data, permissions and staff/admin workflows continue to work. All additions outside the proposal show Future work labels, Weather/News sources remain excluded, and unresolved required integrations are recorded rather than marked complete.

## 2026-10-13 brief delta

- [x] Onboarding copy matches the brief exactly (EN/AR): "Book appointments with ease" / "Your health records, in one place".
- [x] Messages Future work badge removed from tab and screen (approved scope; real repository-backed messaging, draft kept on failed send, duplicate taps blocked).
- [x] Text size verified: Small/Default/Large map to stored xSmall/small/medium; name-based, no double migration; new users get Default.
- [x] Existing approved blue/navy palette kept (no purple).
