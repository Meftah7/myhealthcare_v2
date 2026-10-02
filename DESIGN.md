# MyHealth Care — Figma design system

The approved visual reference is `docs/figma-redesign/design.js` and its generated `preview.html`. Implement the design through Flutter widgets with real application data. The preview's synthetic names, dates, balances, and records are examples.

## 1. Identity

Use the blue square with a white heart and ECG line, plus the MyHealth Care wordmark. Patient, staff, admin, and authentication belong to one visual system. Prioritize clinical legibility and working tasks.

## 2. Colour

| Role | Light value | Flutter role |
| --- | --- | --- |
| Page | #F3F6FB | surface |
| Card / navigation | #FFFFFF | surfaceContainerLowest |
| Primary action | #1E5FAF | primary |
| Primary dark | #174C8E | supporting brand shade |
| Mobile header | #E3ECF8 | primaryContainer |
| Main text | #152C49 | onSurface / onPrimaryContainer |
| Secondary text | #586A81 | onSurfaceVariant |
| Border | #DFE7F1 | outlineVariant |
| Blue inset | #EEF4FC | surfaceContainer |
| Success | #E4F3EA / #216746 | clinical riskLow |
| Warning | #FFF2DD / #8A5109 | clinical riskMedium / severityWarning |
| Urgent | #FCE8E7 / #A13432 | clinical riskHigh / severityUrgent |

Use solid primary hero cards. Ordinary cards are flat and bordered. Gradients are not used for dashboard surfaces. Dark and high-contrast schemes preserve the meaning and contrast of every role. Status always includes a text label and, where appropriate, an icon.

## 3. Typography

Bundle fonts; do not fetch them at runtime. Lexend semibold (600) carries headings; Inter regular/medium/semibold/bold carries body, labels, and controls. Noto Naskh Arabic provides Arabic glyphs. Clinical figures use tabular numerals.

| Role | Size / line | Weight |
| --- | --- | --- |
| Display | 32 / 38 | 600 |
| Wide page title | 26 / 32 | 600 |
| Compact page title | 22 / 28 | 600 |
| Card / dialog title | 20 / 26 | 600 |
| List primary | 17 / 24 | 600 |
| Section / dense title | 15–16 / 20 | 600 |
| Primary body | 16 / 24 | 400 |
| Secondary body | 14 / 20 | 400 |
| Caption | 12 / 16 | 400 |

## 4. Spacing and shape

Use the 4dp spacing scale in `dimens.dart`. Compact page gutters are 20dp; larger windows use 24dp. Standard card radius is 16dp, primary hero radius 18dp, compact row radius 12–14dp, field/button radius 12dp, mobile header bottom radius 24dp, and sheet top radius 28dp. Standard controls have at least 48dp touch targets. Content determines height; large text must wrap or scroll.

## 5. Components

`AppScaffold` provides the page frame, responsive title, pale-blue rounded mobile header, neutral desktop heading, refresh, and bounded content. `AuthScaffold` provides the signed-out header and form column. `AppCard`, `NavRow`, `ListCard`, `MetricTile`, and shared state views cover lists, forms, readouts, empty states, and errors. `QuickActionTile` places an icon above its label; `QuickActionGrid` measures width and lets labels determine height. Profile pages use one identity card and grouped destination rows. Selected filters use blue with white text.

## 6. Responsive layouts

Phones use the existing persistent bottom navigation; tablets use an icon rail; expanded and large windows use a 248dp sidebar with full-row selected destinations. Dashboards use `SectionColumns`; directories and work queues retain their working list-detail surfaces. Keep tab state, guarded routes, deep links, and back navigation.

## 7. Motion

Retain the app's interruptible press feedback, transitions, and confirmation overlay. Honor reduced motion. Animation must not delay actions or conceal saved/error states.

## 8. Accessibility and localization

Support English and Arabic, RTL layout, keyboard focus, labelled controls, visible loading/error/disabled states, 48dp touch targets, and 200% text scaling. Contrast must meet the existing accessibility tests. Preserve all clinical warning text, real units, dates, Bahrain currency formatting, and role restrictions.

## 9. Screen and flow coverage

The 78 reference frames map to executable surfaces in `docs/figma-redesign/implementation-map.json`. Some are steps, dialogs, sheets, or states within a route. Booking follows clinician → time → review → persistent ticket. Recovery follows identify → code → new password → outcome, with the existing assisted path when email delivery is unavailable. Nutrition starts with daily targets and an example split, retaining the calculator and food browser. Staff tasks expose primary actions, keep scoring details secondary, and display mutation failures. Existing payments, ownership, referral, clinical signing, and administration flows remain functional.

See `docs/figma-redesign/IMPLEMENTATION.md` for integration decisions and verification evidence.
