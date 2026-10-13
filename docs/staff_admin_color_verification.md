# Staff/admin colour unification

The existing patient theme is the source of truth. `AppTheme.light`, `dark`,
and their high-contrast variants now use `AppColors.patientLight/patientDark`,
`PatientPalette.light/dark` and the existing `ClinicalStatusColors` extension.
They use the same ThemeData builder as patient screens, retaining staff card
radii, button heights, typography, header shapes and navigation layouts.
Patient theme definitions and the approved logo asset are unchanged.

Replaced the old staff/admin scheme, hardcoded navy dashboard feature cards,
white feature-card buttons, fixed light-mode destructive-dialog colours for
staff/admin, and the schedule's tinted header override. Shared-server standalone
UI now supplies both themes, follows system brightness and supports an explicit
ThemeMode. Semantic clinical warning, error and success colours remain distinct.
QR camera-overlay black/white contrast and transparent paint overrides remain
intentional; they are not application palette colours.

Verification:

- Source audit of role/admin/shared screens, shared components and chart colours.
- Role dashboards, role workspaces, admin navigation/access, document workspaces,
  dental charts, schedule templates, Year → Month → Day navigation, calendar
  boundaries, timeline marker, route reachability and patient regression checks.
- Phone/tablet/desktop responsive checks, English/Arabic, 200% text, reduced motion,
  high contrast and Flutter accessibility guidelines.
- Shared theme parity, selected navigation and normal/disabled/pressed/focused/
  hovered action states; main/secondary text, link and action-label contrast.
- Open local and shared-workspace dialogs follow live light/dark changes.
- Flutter analysis: no errors; 164 existing informational diagnostics and one
  existing unused-element warning in `health_tools_directory.dart:25`.

Screenshots are in `rebuild_screenshots/staff_admin_colors/`. The capture matrix
covers doctor, nurse, dentist, receptionist, pharmacist, admin overview, document
registry, finance report, departments, department form dialog, system analytics,
shared login, and schedule day/month/year. Seven configurations cover light/dark,
English/Arabic and phone (390), tablet (800), desktop (1440) widths.

Limitations: screenshots use seeded widget-test data, not physical devices or a
live shared server. Not every nested screen, populated document/PDF preview,
clinical/operational status, loading/error/disabled state or chart interaction was
visually exercised. Camera scanning was not exercised. Existing cramped staff
greetings on narrow Arabic screens remain outside this colour-only change.
Generated document content and the patient-only vitals chart were not recoloured.

No push, deployment, release build or discard of pre-existing work was performed.
