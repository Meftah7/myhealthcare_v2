# Patient rebuild — preservation matrix

Every patient-visible feature from the pre-rebuild app (revision 298132e)
mapped to its new entry point. "QA" = Home → Quick Access (directly below the
Services carousel). Routes are unchanged unless noted; old deep links still
resolve.

| Existing feature | Old entry | New primary entry | Quick Access | Access | Verified |
| --- | --- | --- | --- | --- | --- |
| Home | Tab 1 | Tab 1 (Home) | — | Public (private sections signed-in only) | widget test |
| Health Records (timeline, search, filters, record detail) | Tab 4 "Records" `/patient/timeline` | Retained branch, back → Home | Health Records | Signed in | unit (catalogue) |
| Medications | Home quick action, `/patient/timeline?view=medications` | Retained route | Medications | Signed in | unit |
| Documents (issued, downloads) | `/patient/timeline/documents` | Retained route | Documents | Signed in | widget test (guest → sign-in → resume) |
| Sick leave | Home quick action, `/patient/timeline/sick-leave` | Retained route | Sick Leave | Signed in | unit |
| Imaging | `/patient/timeline/imaging` | Retained route | Imaging | Signed in | unit |
| Allergies | Allergy strip, `/patient/timeline/allergies` | Allergy strip on Home (kept) | Allergies | Signed in | unit |
| Vitals & trends | Home quick action, `/patient/home/vitals` | Retained route | Vitals & Trends; Services → Health Tools | Signed in | unit |
| Health summary | `/patient/summary` | Retained full-screen route (back → Home) | Health Summary | Signed in | unit |
| Explain a report (PDF import + chat) | Care Navigator upload button | Home hero CTA (signed in) | Explain a Report | Signed in | unit |
| Care Navigator chat | Floating button | Floating button (unchanged) | — | Signed in | existing tests |
| Nutrition (calculator, targets, presets, foods) | Tab 2 `/patient/nutrition` | Retained branch, back → Home | Nutrition; Services → Health Tools | Signed in | unit |
| Appointments hub (list, history, detail, reschedule, cancel) | Tab 3 | Tab 3 (Appointments) — guests see booking entry | Appointments | Signed in | unit |
| Book appointment wizard | Home quick action, `/patient/appointments/book` | Booking landing `/patient/book` → wizard | Book Appointment | Discovery public, booking signed in | unit |
| Quick appointment (urgent/normal sheet) | Home "more" actions | Covered by Book Appointment (both choices led to Appointments) | Book Appointment | Signed in | — |
| Visited doctors | Home quick action, `/patient/appointments/doctors` | Retained route | Visited Doctors | Signed in | unit |
| Messages / threads | Home quick action, `/patient/home/messages` | Retained route; Virtual Care CTA | Messages; Services → Contact Us | Signed in | unit |
| Notifications | Header bell, `/patient/home/notifications` | Header bell (signed in) | Notifications | Signed in | unit |
| Home visits | Home quick action, `/patient/home/home-visit` | Retained route; Services carousel | Home Visits | Signed in | unit |
| Billing & payments (invoices, wallet, history) | Home quick action, `/patient/home/billing` | Retained route | Billing & Payments | Signed in | unit |
| Profile hub (incl. sign-out with confirmation) | Tab 5 `/patient/settings` | Retained branch, back → Home; header avatar | My Profile | Signed in | unit |
| Personal info / photo | `/patient/settings/personal` | Retained route | Personal Information | Signed in | unit |
| Health details | `/patient/settings/health` | Retained route | Health Details | Signed in | unit |
| Family & linked accounts | `/patient/settings/family[/linked/:id]` | Retained routes | Family & Linked Accounts | Signed in | unit |
| Preferences (language, theme, text size, contrast) | `/patient/settings/preferences` | Retained route; header toggles | Preferences | Signed in | unit |
| Feedback | Profile → Send feedback sheet | Same sheet | Feedback | Signed in | unit |
| Health snapshot metrics (tickets, medicines, last visit) | Home "Your health" | Removed from Home; each metric's destination is in QA (Appointments, Medications) | — | Signed in | — |

## Explicitly unavailable in this build (shown honestly, never as working)

Indoor Navigation, Complete Checkup, E-Referral (patient-started), Blood
Donation, Terms and Conditions, Privacy Policy (no MyHealth documents exist
yet), Region search (single clinic), live video visits, Weather (no provider),
News (no repository or CMS). Emergency shows guidance only; MyHealth does not
dispatch emergency services.

## Behaviour changes made during the rebuild

- **Entry:** a plain launch still opens sign-in (staff and admin always need
  it). Sign-in has "Browse as guest"; onboarding Skip / Get Started land on
  guest Home. Gated tiles send guests to sign-in and resume the tapped
  destination afterwards (internal routes only). An idle timeout always
  returns to sign-in with its notice.
- **Report chat:** the header shows the real mode ("Live AI" or "Offline
  guide · no live AI"; it used to always say "Online") and the report being
  explained, with "View original". Explanations say what produced them.
  The on-device keyword summary is labelled in every mode, and a failed live
  call says so rather than silently falling back. Reports over 12,000
  characters disclose that only the first part was explained. PDF text is
  marked as untrusted data in the prompt. The conversation resets on a new
  report and on account change.
- **Emergency:** the sheet names 999 (Bahrain; matches the existing emergency
  reply and the app's BD billing) and says MyHealth does not dispatch.
