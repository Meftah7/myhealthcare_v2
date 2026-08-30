---
name: myhealthcare-design-system
platform: Flutter (Material 3)
description: >
  Design system for MyHealth Care — an AI-assisted health-records, appointments,
  and medical-staff app (University of Bahrain senior project). Calm, high-legibility,
  low-saturation clinical UI. Original identity — not derived from any existing product.
  Every token here maps to a real Flutter / Material 3 construct and is implemented
  in lib/app/theme/. This file is the spec for task P0-05.
---

# MyHealth Care — Design System

## 1. Identity

MyHealth Care is a **clinical tool**, not a marketing surface. The visual language is
the language of *care*: unhurried, precise, quietly confident. It should feel closer
to a well-run clinic than to a consumer wellness app.

**Principles**

1. **Legibility before decoration.** A tired nurse on a night shift and a 70-year-old
   patient must both read every screen without effort. Type is large, contrast is high,
   spacing is generous.
2. **Calm by default, loud only for risk.** The interface is low-saturation and even-toned.
   Saturated colour is reserved for one job: flagging clinical risk. When everything is
   quiet, an alert reads instantly.
3. **Status is never colour alone.** Every risk / abnormality / severity indicator carries
   a **colour + an icon + a text label**. ~8% of men have red–green colour-vision
   deficiency; a red/green badge alone is invisible to them. (Feeds P6-09.)
4. **Numbers are data.** All clinical figures — lab values, vitals, doses — use
   **tabular (monospaced) figures** so digits align in columns and 98 never looks
   smaller than 120.
5. **One layout, every screen size.** Phone, tablet, web, Windows desktop run the same
   widgets, re-flowed by Material 3 window size class — not separate designs.

**Non-goals:** gradients as decoration, drop shadows for style, brand "voltage",
full-bleed hero moments, animated flourishes. None of that belongs here.

---

## 2. Colour

### 2.1 Brand seed

```dart
// lib/app/theme/app_colors.dart
static const seed = Color(0xFF00696E); // deep teal — "clinical calm"
```

An original deep teal. Teal reads as medical without being the over-used "hospital blue",
sits far from every status hue (amber / orange / red / green), and holds contrast well in
both light and dark. Generate the full scheme with `ColorScheme.fromSeed`.

```dart
static final light = ColorScheme.fromSeed(
  seedColor: seed,
  brightness: Brightness.light,
);
static final dark = ColorScheme.fromSeed(
  seedColor: seed,
  brightness: Brightness.dark,
);
```

Let Material 3 derive `primary`, `secondary`, `tertiary`, `surface`,
`surfaceContainer*`, `outline`, `error`, and all `on*` roles. Do **not** hand-pick these —
the generated tonal palette is already contrast-checked. Override a role only with a
documented reason.

### 2.2 Clinical status ramp (custom — M3 has no role for this)

Defined as a `ThemeExtension` so it travels with `Theme.of(context)` and flips with the
theme. Each entry is a triple: **container colour**, **on-container colour**, **icon**.

| Token | Light container | Meaning | Icon | Used by |
|---|---|---|---|---|
| `riskLow` | teal-tinted `#DCF2EE` | no-show risk < 0.33 | `Icons.check_circle_outline` | P4-14, P4-17, P5-05 |
| `riskMedium` | amber-tinted `#FFF1D6` | 0.33–0.66 | `Icons.error_outline` | " |
| `riskHigh` | red-tinted `#FCE4E4` | > 0.66 | `Icons.warning_amber_rounded` | " |
| `labNormal` | neutral `surfaceContainerHighest` | within reference range | `Icons.remove` | P2-10 |
| `labLow` | blue-tinted `#E1ECF7` | below reference low | `Icons.south` | P2-10 |
| `labHigh` | amber-tinted `#FFF1D6` | above reference high | `Icons.north` | P2-10 |
| `labCritical` | strong red `#F4C7C7` | critical value | `Icons.priority_high` | P2-10, P5-01 |
| `severityInfo` | neutral | informational flag | `Icons.info_outline` | P5-01 |
| `severityWarning` | amber-tinted | needs review | `Icons.error_outline` | P5-01 |
| `severityUrgent` | strong red | act now | `Icons.notification_important` | P5-01, P5-05 |

Dark-theme containers: same hues at ~16–24% opacity over `surface`, with light
on-container text. Exact dark values live in `app_colors.dart`.

**Contrast:** every on-container / container pair must clear **WCAG AA 4.5:1** for the
label text. The `test/` folder includes a contrast assertion over the ramp (P6-09).

### 2.3 Rules

- Never use `primary` (teal) to signal status — it is navigation / action only.
- Never use `error` red for anything that isn't an error or a critical/urgent clinical state.
- The AI disclaimer banner (P3-13) uses `tertiaryContainer`, not a status colour — it is
  context, not alarm.

---

## 3. Typography

### 3.1 Families (via `google_fonts`)

| Role | Family | Why |
|---|---|---|
| Display / headline | **Lexend** | Engineered to reduce reading friction; gives the app a warm, accessible identity. Defensible choice for a patient-facing health app. |
| Body / label / UI | **Inter** | Screen-optimised, neutral, complete tabular-figure support. |
| Numeric clinical data | **Inter** with `FontFeature.tabularFigures()` | Column-aligned digits in tables and vitals. |
| Monospace (rare — extracted PDF text, debug) | **JetBrains Mono** | Only where literal character alignment matters. |

Bundle the fonts (don't fetch at runtime) so the app works offline — `google_fonts`
with assets declared in `pubspec.yaml`, or `GoogleFonts.config.allowRuntimeFetching = false`.

### 3.2 Scale — mapped to Material 3 `TextTheme` roles

Build with `GoogleFonts.lexendTextTheme` / `interTextTheme` then override sizes:

| M3 role | Font | Size / Line | Weight | Use |
|---|---|---|---|---|
| `displaySmall` | Lexend | 32 / 40 | 400 | Onboarding, empty-state hero only |
| `headlineMedium` | Lexend | 26 / 34 | 500 | Screen titles (large windows) |
| `headlineSmall` | Lexend | 22 / 30 | 500 | Screen titles (compact), section heads |
| `titleLarge` | Lexend | 20 / 28 | 500 | Card titles, dialog titles |
| `titleMedium` | Inter | 17 / 24 | 600 | List item primary, form section labels |
| `titleSmall` | Inter | 15 / 20 | 600 | Dense list labels, tab labels |
| `bodyLarge` | Inter | 16 / 24 | 400 | Primary reading text, record bodies |
| `bodyMedium` | Inter | 14 / 20 | 400 | Secondary text, list subtitles |
| `bodySmall` | Inter | 12 / 16 | 400 | Captions, timestamps, metadata |
| `labelLarge` | Inter | 15 / 20 | 600 | Button labels |
| `labelMedium` | Inter | 13 / 16 | 600 | Chips, badges |
| `labelSmall` | Inter | 11 / 16 | 600 · +0.5 tracking | Overline, status badge text |

Minimum on-screen body size is **14** (`bodyMedium`). Nothing below `bodySmall` (12).

### 3.3 Rules

- Body text respects the OS text-scale factor up to **2.0×** without clipping (P6-09).
  Test every screen at 2.0×.
- Headlines use weight 400–500, never 700 — this app doesn't shout.
- Clinical numbers always get `fontFeatures: [FontFeature.tabularFigures()]`. Provide a
  `AppText.clinical(...)` helper so this can't be forgotten.

---

## 4. Spacing, shape, elevation

### 4.1 Spacing — 4dp base

```dart
// lib/app/theme/dimens.dart
abstract final class Space {
  static const double xxs = 4;
  static const double xs  = 8;
  static const double sm  = 12;
  static const double md  = 16;   // default screen gutter (compact)
  static const double lg  = 24;   // screen gutter (medium+), card padding
  static const double xl  = 32;
  static const double xxl = 48;
}
```

- Screen edge padding: `Space.md` compact, `Space.lg` medium and up.
- Card interior: `Space.lg`.
- Gap between stacked cards: `Space.sm`.
- Related form fields: `Space.md`; between form groups: `Space.xl`.

### 4.2 Shape

```dart
abstract final class Radii {
  static const card   = BorderRadius.all(Radius.circular(16));
  static const sheet  = BorderRadius.vertical(top: Radius.circular(28));
  static const field  = BorderRadius.all(Radius.circular(12));
  static const chip   = BorderRadius.all(Radius.circular(8));
  static const button = BorderRadius.all(Radius.circular(12));
}
```

Feed these into `cardTheme`, `inputDecorationTheme`, `filledButtonTheme`, etc. No fully
circular ("pill") buttons — they waste horizontal space on dense clinical screens.

### 4.3 Elevation (Material 3 tonal)

| Level | dp | Use |
|---|---|---|
| 0 | 0 | Page background, `AppBar` at rest |
| 1 | 1 | `Card` at rest, `NavigationBar` |
| 2 | 3 | `AppBar` on scroll, raised `Card` |
| 3 | 6 | `NavigationRail`, menus, `SearchBar` active |
| 4 | 8 | (rare) |
| 5 | 12 | Dialogs, modal sheets |

M3 tonal elevation (surface tint) is the primary depth cue. Real shadows stay subtle —
don't fight the tint with heavy `BoxShadow`.

---

## 5. Components (Flutter widgets → app usage)

### 5.1 Material widgets — themed once, in `app_theme.dart`

| Widget | Notes |
|---|---|
| `FilledButton` | Primary action, one per screen region. `labelLarge`, `Radii.button`, 48 min height. |
| `FilledButton.tonal` | Secondary emphasis (e.g. "Reschedule" next to "Cancel"). |
| `OutlinedButton` | Tertiary / cancel. |
| `TextButton` | Inline / low-priority ("View all"). |
| `Card` | Default container. `clipBehavior: antiAlias`, `Radii.card`, elevation 1. |
| `ListTile` | Timeline rows, appointment rows, task rows. `minVerticalPadding: 12`. |
| `Chip` / `FilterChip` | Timeline type filters (P2-09), tags. |
| `NavigationBar` | Compact width primary nav. |
| `NavigationRail` | Medium+ width primary nav (`extended` on large). |
| `SearchBar` | Patient search (P5-06), timeline search (P2-09). |
| `DataTable` | Lab result panels (P2-10). Tabular figures. Horizontal scroll inside its own container on compact. |
| `TextField` | `InputDecorationTheme`: `filled: true`, `Radii.field`, `bodyLarge` input text, always-visible label. |
| `SegmentedButton` | Vitals chart range selector (P2-15). |

### 5.2 App-specific components (build in `lib/features/*/presentation/widgets/` or shared)

- **`AiDisclaimerBanner`** (P3-13) — full-width strip above any AI-generated content.
  `tertiaryContainer` background, `Icons.auto_awesome` + text:
  *"AI-generated — informational only, not medical advice. Verify with your clinician."*
  Not dismissible on first view of a summary.
- **`RiskBadge`** (P4-17, P5-05) — `{icon, label, container}` from the status ramp.
  Renders as: coloured pill + icon + text ("High risk"). Never icon-only, never colour-only.
- **`SeverityChip`** (P5-01) — same contract, severity ramp.
- **`AbnormalValueIndicator`** (P2-10) — inline with a lab value: arrow icon (↑/↓),
  coloured text, and a screen-reader label ("High: 7.9, reference 3.5–5.5").
- **`TimelineEventMarker`** (P2-08, P3-11) — dot + connector line on the left rail of
  the health timeline; AI-highlighted key events get a filled `primary` dot + ring,
  ordinary events a hollow `outline` dot.
- **`VitalsChart`** wrapper (P2-15) — `fl_chart` `LineChart` themed to match:
  grid lines `outlineVariant`, axis labels `bodySmall`, series in `primary` /
  `tertiary` / `secondary` (never status colours), reference band in
  `surfaceContainerHighest`.
- **`EmptyState`**, **`ErrorState`**, **`LoadingSkeleton`** (P2-18) — one each, reused
  everywhere. Empty state = icon + one line + optional single action.

---

## 6. Responsive — Material 3 window size classes

Detect with `MediaQuery.sizeOf(context).width`. Central helper `WindowSize.of(context)`.

| Class | Width (dp) | Primary nav | Layout |
|---|---|---|---|
| Compact | < 600 | `NavigationBar` (bottom) | Single pane. Detail = full-screen push. |
| Medium | 600–839 | `NavigationRail` (icons) | Single pane, wider gutters. |
| Expanded | 840–1199 | `NavigationRail` `extended` | List-detail: 40/60 split where it helps (timeline, patient chart). |
| Large | ≥ 1200 | `NavigationRail` `extended` | List-detail with a persistent detail pane; max content column ~1100, centred. |

- Staff dashboard (P5-05) and patient chart (P5-07) are the screens that most benefit
  from list-detail on Expanded+ — build them pane-aware from the start.
- Compact is the design baseline. If it works at 360dp wide it works everywhere.
- `DataTable` and wide content scroll horizontally **inside their own container**; the
  page itself never scrolls sideways.

---

## 7. Motion

Minimal and functional. Use Flutter defaults:

- Page transitions: platform default (`PageTransitionsTheme`).
- State changes: `AnimatedSwitcher` / implicit animations at **150–200 ms**, `Curves.easeOut`.
- Loading: `LoadingSkeleton` shimmer, or a plain `CircularProgressIndicator` for < 1s waits.
- No parallax, no staggered reveals, no decorative motion.
- Respect `MediaQuery.disableAnimations` (OS "reduce motion").

---

## 8. Accessibility checklist (pre-committed — makes P6-09 an audit, not a rescue)

- [ ] Contrast: all text ≥ WCAG AA 4.5:1 (3:1 for ≥ 24px or bold ≥ 19px). Status ramp asserted in tests.
- [ ] Touch targets ≥ **48 × 48 dp** (`materialTapTargetSize: padded`).
- [ ] Every icon-only control has a `Semantics` label / `tooltip`.
- [ ] Status conveyed by colour **+ icon + text**, always.
- [ ] Text scales to 2.0× without clipping or overlap on every screen.
- [ ] All images/charts have a text alternative (`Semantics(label:)`).
- [ ] Form fields have persistent visible labels (not placeholder-only) and inline error text.
- [ ] Logical focus order; full keyboard operability (matters for the Windows/web builds).
- [ ] Dark theme is a first-class parity target, not an afterthought.

---

## 9. Implementation map (task P0-05)

```
lib/app/theme/
  app_colors.dart      seed, ColorScheme.light/dark, dark status-ramp values
  status_colors.dart   ClinicalStatus ThemeExtension  {container, onContainer, icon} x ramp
  app_typography.dart  TextTheme (Lexend headlines + Inter body), AppText.clinical() helper
  dimens.dart          Space, Radii
  app_theme.dart       ThemeData light/dark: colorScheme, textTheme, all *Theme configs,
                       registers ClinicalStatus extension, materialTapTargetSize, visualDensity
  window_size.dart     WindowSize enum + WindowSize.of(context)
```

`MaterialApp.router` (P0-06) consumes `AppTheme.light` / `AppTheme.dark` with
`themeMode: ThemeMode.system`.

---

## 10. Do / Don't

**Do**
- Anchor on the neutral M3 `surface`; let tonal elevation create depth.
- Reserve saturated colour for the clinical status ramp.
- Use `AppText.clinical()` for every measured value.
- Design compact-first, then let window size classes expand the layout.
- Pair every status colour with an icon and a word.

**Don't**
- Don't hand-pick `ColorScheme` roles — trust `fromSeed`.
- Don't use teal (`primary`) or `error` red to mean "status".
- Don't ship placeholder-only form labels.
- Don't add gradients, heavy shadows, or decorative motion.
- Don't build separate phone / desktop layouts — one widget tree, re-flowed.
- Don't let any surface scroll horizontally except a scoped table/chart container.
