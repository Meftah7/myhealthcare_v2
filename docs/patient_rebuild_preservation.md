# Patient rebuild — preservation matrix

Every patient-visible feature from the pre-rebuild app (revision 298132e)
mapped to its entry in the updated design (docs/MyHealth_Patient_Rebuild_TODO.md):
bottom tabs Home | Records | Appointments | Messages | Services, Home Quick
Access directly below the Services carousel, and the native patient drawer.
Routes are unchanged; old deep links still resolve. Every patient route
requires a signed-in patient (guest browsing is future work).

Scope: **Core** = in the proposal. **Supp.** = existing feature outside the
proposal — fully working, shows a visible "Future work" label.

| Existing feature | Old entry | New primary entry | Quick Access / drawer | Scope | Verified |
| --- | --- | --- | --- | --- | --- |
| Home | Tab 1 | Tab 1 Home | — | Core | widget test |
| Health Records (timeline, search, filters, detail, originals) | Tab 4 `/patient/timeline` | Tab 2 Records | QA Health Records; Services core | Core | browse + records tests |
| Medications | Home quick action, `/patient/timeline?view=medications` | Records tab view | QA Medications | Core | records test |
| Documents (issued, downloads) | `/patient/timeline/documents` | Records branch | QA Documents; quick tools; Services core | Core | documents tests |
| Sick leave | `/patient/timeline/sick-leave` | Records branch | QA Sick Leave | Core | unit (catalogue) |
| Imaging | `/patient/timeline/imaging` | Records branch | QA Imaging | Core | unit |
| Allergies | Allergy strip, `/patient/timeline/allergies` | Home allergy strip | QA Allergies | Core | allergies test |
| Explain a report (PDF import + chat) | Care Navigator upload | Home hero CTA; pilot "Explain this report" (server) | QA Explain a Report; quick tools; Services core | Core (needs a server-held provider key) | report_chat_test; server tests |
| Care Navigator chat | Floating button | Floating button | — | Core | care_navigator_test |
| Appointments hub (list, detail, reschedule, cancel) | Tab 3 | Tab 3 Appointments | QA Appointments | Core | booking/appointment tests |
| Book appointment wizard | `/patient/appointments/book` | Landing `/patient/book` → wizard | QA Book Appointment; quick tools; Services core | Core | booking tests |
| Visited doctors | `/patient/appointments/doctors` | Appointments branch | QA Visited Doctors | Core | unit |
| Quick appointment (urgent/normal sheet) | Home "more" actions | Book Appointment (both choices led to Appointments) | QA Book Appointment | Core | — |
| Messages / threads | Home quick action, `/patient/home/messages` | Tab 4 Messages (own branch, same paths) | QA Messages | Supp. | rebuild test |
| Notifications | Header bell, `/patient/home/notifications` | Header bell | QA Notifications | Supp. | notifications tests |
| Vitals & trends | `/patient/home/vitals` | Home branch | QA Vitals & Trends; Services tools | Supp. | browse test |
| Health summary | `/patient/summary` | Full-screen (back → Home) | QA Health Summary | Supp. | unit |
| Nutrition | Tab 2 `/patient/nutrition` | Retained branch (back → Home) | QA Nutrition; Services tools | Supp. | nutrition tests |
| Home visits | `/patient/home/home-visit` | Home branch | QA Home Visits; Services carousel | Supp. | unit |
| Profile hub | Tab 5 `/patient/settings` | Retained branch (back → Home) | Drawer My Profile | Core | profile tests |
| Personal info / photo | `/patient/settings/personal` | Profile branch | Drawer Personal Information | Core | profile tests |
| Health details | `/patient/settings/health` | Profile branch | Drawer Health Details | Core | profile tests |
| Preferences (language, theme, text size, contrast, motion) | `/patient/settings/preferences`; theme toggle in headers | Profile branch | Drawer Settings & Preferences | Core | profile tests |
| Family & linked accounts | `/patient/settings/family[/linked/:id]` | Profile branch | Drawer (Future work label) | Supp. | family tests |
| Billing & payments | `/patient/home/billing` | Home branch | Drawer (Future work label) | Supp. | payments test |
| Feedback | Profile → Send feedback | Same sheet | Drawer (Future work label) | Supp. | rebuild test |
| Sign out (confirmed) | Profile | Profile (unchanged) | Drawer Sign out (confirmed) | Core | rebuild test |
| Health snapshot metrics | Home "Your health" | Removed from Home; destinations in QA | — | — | — |

## Additions outside the proposal (all labelled "Future work")

Working: Emergency guidance sheet (999, no dispatch), Calculators,
Converters, Choosing a clinic (department descriptions), Virtual Care page
(explains what exists today; video visits not built).

Planned, explanation sheet only: Complete Checkup, Indoor Navigation,
E-Referral, Blood Donation, Wearables, Water tracking, Pharmacy, Weather,
News. No Weather/News sources, requests, keys, polling or tabs exist.

Core policy destinations now have English/Arabic owner-replaceable drafts and public pages. Approved policy content remains externally blocked; drafts are visibly labeled (assets/policies/policies.json).

## Adaptive navigation and text-size verification (11 October 2026)

Account actions use the native drawer below 1024px and the same action implementation in the expanded sidebar. The medium rail exposes Account & preferences. Navigation order and all original routes/permissions remain intact. New text options are Small 0.85, Default 0.92, Large 1.0; saved historical factors and independent OS scaling are preserved. See patient_rebuild_status.md for fresh checks, captures and remaining external blockers.
