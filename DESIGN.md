---
name: myhealthcare-design-system
platform: Flutter (Material 3)
version: 2 (redesign)
description: >
  Design system for MyHealth Care — an AI-assisted health-records, appointments,
  and medical-staff app (University of Bahrain senior project). "Clinical
  premium": the discipline of a well-run clinic with the craft of a top-tier
  health product. Original identity — the "MyHealth Care" mark (a gradient
  heart + ECG pulse cupped in a hand). Every token maps to a real Flutter /
  Material 3 construct in lib/app/theme/.
---

# MyHealth Care — Design System (v2)

## 0. What changed in v2, and why

v1 was correct but plain: disciplined, accessible, and visually flat. v2 keeps
every principle and every accessibility guarantee, and raises the craft to
match the new brand and a modern health product:

- **New identity.** Indigo-violet accent drawn from the logo, plus a
  three-stop brand gradient used sparingly and with intent.
- **Flat, bordered surfaces.** Off M3's heavy surface-tint elevation and onto
  flat surfaces + a hairline border + one whisper-soft shadow — the current
  product-UI idiom (Linear / Stripe / Notion), and calmer than tinted layers.
- **Type with optical intent.** Size-specific tracking: headlines tightened,
  body left neutral, micro-text opened up.
- **Motion as a first-class layer.** A real motion module: instant press
  feedback, a quiet page fade-through, list entrances — all interruptible and
  all reduce-motion aware.
- **A shared component vocabulary.** `AppScaffold`, `AppCard`, `SectionHeader`,
  `MetricTile`, `StatusPill`, `AppEmpty/AppError/AppLoading` — so every screen
  in all three apps is built from the same parts.

---

## 1. Identity

MyHealth Care is a **clinical tool** with the polish of a product people are
glad to open. It should feel closer to a well-run clinic than to a wellness
gimmick — but a *modern* clinic.

**Principles** (unchanged from v1 — these are load-bearing)

1. **Legibility before decoration.** A tired nurse on a night shift and a
   70-year-old patient must both read every screen without effort. Type is
   large, contrast is high, spacing is generous.
2. **Calm by default, loud only for risk.** The interface is low-saturation and
   even-toned. Saturated colour has exactly one job: flagging clinical risk.
   When everything is quiet, an alert reads instantly.
3. **Status is never colour alone.** Every risk / abnormality / severity
   indicator carries **colour + icon + text label**. ~8% of men have red–green
   colour-vision deficiency.
4. **Numbers are data.** All clinical figures use **tabular (monospaced)
   figures** so digits align and 98 never looks smaller than 120.
5. **One layout, every screen size.** Phone, tablet, web, Windows desktop run
   the same widgets, re-flowed by Material 3 window size class.

**The brand gradient is not a licence to decorate.** It appears on: the login
mark, one hero surface per role, the primary call-to-action of an empty state,
and the FAB's press ripple. Nowhere else. No gradient backgrounds, no gradient
text, no gradient cards.

**Non-goals:** decorative gradients, drop shadows for style, brand "voltage",
full-bleed marketing heroes, animated flourishes, a fake "health score".

---

## 2. Colour

### 2.1 Brand seed

```dart
// lib/app/theme/app_colors.dart
static const seed = Color(0xFF5B4FE9); // indigo-violet — the centre of the mark
```

The visual centre of the logo gradient. Indigo-violet reads as *considered*
rather than clinical-cold, sits far from every status hue (amber / orange /
red / green), and holds WCAG contrast in both themes. Generate the full scheme
with `ColorScheme.fromSeed` for light **and** dark. Do **not** hand-pick M3
roles — the generated tonal palette is already contrast-checked.

### 2.2 Brand gradient (a token, used sparingly)

```dart
static const brandMagenta = Color(0xFFEC4899);
static const brandViolet  = Color(0xFF7C5CFC);
static const brandBlue    = Color(0xFF3B82F6);
static const brandGradient = LinearGradient(colors: [magenta, violet, blue], …);
```

Allowed uses are listed in §1. Anything else is a bug.

### 2.3 Clinical status ramp (custom — M3 has no role for this)

A `ThemeExtension` so it travels with `Theme.of(context)` and flips with the
theme. Each entry is a triple: **container**, **on-container**, **icon**.

| Token | Meaning | Icon |
|---|---|---|
| `riskLow` / `riskMedium` / `riskHigh` | no-show risk band (<0.33 / 0.33–0.66 / >0.66) | check / error-outline / warning |
| `labNormal` / `labLow` / `labHigh` / `labCritical` | lab value vs reference range | remove / south / north / priority-high |
| `severityInfo` / `severityWarning` / `severityUrgent` | risk-flag severity | info / error-outline / notification-important |

Green → amber → red for severity, blue for "low", neutral for "normal" —
semantically obvious and, with the mandatory icon + label, colour-blind safe.
Dark containers are the same hues darkened, with light on-container text.

**Contrast:** every container / on-container pair clears **WCAG AA 4.5:1**.
A test asserts the whole ramp (P6-09).

### 2.4 Rules

- Never use `primary` (indigo) to signal status — it is navigation / action only.
- Never use `error` red for anything that isn't an error or a critical /
  urgent clinical state.
- The AI disclaimer banner uses `tertiaryContainer` — context, not alarm.

---

## 3. Typography

### 3.1 Families (bundled — offline, no runtime fetch)

| Role | Family | Why |
|---|---|---|
| Display / headline / card + dialog titles | **Lexend** | Engineered to reduce reading friction; warm, accessible identity. |
| Body / label / all UI | **Inter** | Screen-optimised, neutral, complete tabular-figure support. |
| Numeric clinical data | **Inter** + `FontFeature.tabularFigures()` | Column-aligned digits. |
| Monospace (rare — extracted PDF text, debug) | **JetBrains Mono** | Literal character alignment. |

### 3.2 Scale — mapped to Material 3 `TextTheme`, with size-specific tracking

| M3 role | Font | Size / Line | Weight | Tracking | Use |
|---|---|---|---|---|---|
| `displaySmall` | Lexend | 32 / 38 | 500 | −0.8 | Empty-state hero, onboarding |
| `headlineMedium` | Lexend | 26 / 32 | 500 | −0.6 | Screen titles (large windows) |
| `headlineSmall` | Lexend | 22 / 28 | 500 | −0.4 | Screen titles (compact), section heads |
| `titleLarge` | Lexend | 20 / 26 | 500 | −0.2 | Card + dialog titles |
| `titleMedium` | Inter | 17 / 24 | 600 | −0.1 | List primary, form section labels |
| `titleSmall` | Inter | 15 / 20 | 600 | 0 | Dense labels, tab labels |
| `bodyLarge` | Inter | 16 / 24 | 400 | 0 | Primary reading text |
| `bodyMedium` | Inter | 14 / 20 | 400 | 0 | Secondary text, subtitles — **min body size** |
| `bodySmall` | Inter | 12 / 16 | 400 | 0 | Captions, timestamps |
| `labelLarge` | Inter | 15 / 20 | 600 | 0 | Button labels |
| `labelMedium` | Inter | 13 / 16 | 600 | 0 | Chips, badges, nav labels |
| `labelSmall` | Inter | 11 / 16 | 600 | +0.5 | Overline, status-badge text |

### 3.3 Rules

- Body text respects the OS text-scale factor to **2.0×** without clipping.
  Every screen is tested at 2.0×.
- Headlines use weight 400–500, never 700 — this app doesn't shout.
- Clinical numbers always get tabular figures — use `AppText.clinical(...)`.

---

## 4. Spacing, shape, elevation

### 4.1 Spacing — 4dp base

`Space.xxs 4 · xs 8 · sm 12 · md 16 · lg 24 · xl 32 · xxl 48` (+ `maxContentWidth 1120`).

- Screen edge padding: `md` compact, `lg` medium+.
- Card interior: `lg`. Gap between stacked cards: `sm`.
- Related form fields: `md`; between form groups: `xl`.

### 4.2 Shape

```dart
Radii.card       20   // the default container
Radii.cardSmall  14   // nested / dense cards, snackbars
Radii.field      14   // text fields
Radii.button     14   // buttons (never a full pill on dense screens)
Radii.chip       10   // filter chips
Radii.pill      999   // status badges only — they are not buttons
Radii.sheet      28   // bottom sheets (top corners)
```

### 4.3 Elevation — flat + border + soft shadow

v2 abandons M3 surface-tint elevation. Depth comes from three things, in order:

1. **A hairline border** (`outlineVariant` at ~0.7 alpha light / 0.5 dark) —
   the primary separator for cards, dialogs, nav edges.
2. **A whisper-soft shadow** (`Shadows.e1/e2/e3`) — only on surfaces that
   genuinely lift off the page: raised cards, menus, dialogs, the FAB.
3. **Fill contrast** — `surface` for the page, a hair lighter/darker for a
   card in dark mode.

| Token | Use |
|---|---|
| `Shadows.e1` | resting `AppCard`, raised list item |
| `Shadows.e2` | menus, active search, popovers |
| `Shadows.e3` | dialogs, modal sheets, FAB |

`AppBar` and `NavigationBar`/`Rail` are **flat** (elevation 0, no scroll tint).
Structure comes from the hairline, not a shadow strip.

---

## 5. Components

### 5.1 Material widgets — themed once in `app_theme.dart`

`FilledButton` (primary, 50dp min, one per region) · `FilledButton.tonal`
(secondary) · `OutlinedButton` (tertiary / cancel) · `TextButton` (inline) ·
`Card` (flat, bordered, `Radii.card`) · `ListTile` (`minVerticalPadding: 12`)
· `FilterChip` · `SegmentedButton` (range / mode toggles) · `NavigationBar` /
`NavigationRail` (flat) · `SearchBar` · `DataTable` (tabular figures, scrolls
inside its own container) · `TextField` (`filled`, `Radii.field`, always-visible
label, 2px primary focus ring) · `SnackBar` (floating, `Radii.cardSmall`).

### 5.2 App components — `lib/core/presentation/`

- **`AppScaffold`** — every screen's shell. Centres content at `maxContentWidth`
  on large windows, applies the standard gutter, hosts the page title +
  actions, and provides the pull-to-refresh + scroll-to-top wiring.
- **`AppCard`** — the flat bordered card + optional `Shadows.e1`, optional
  `onTap` (wraps `Pressable` for press feedback), optional header row.
- **`SectionHeader`** — overline + optional trailing action ("See all").
- **`MetricTile`** — one number, its label, and an optional trend/delta. The
  honest replacement for a "score ring": real counts (upcoming appointments,
  open flags, no-show rate). Never invents a composite score.
- **`StatusPill`** — the unified badge for `RiskBadge` / `SeverityChip`:
  `Radii.pill`, container + icon + text from the status ramp. Never
  icon-only, never colour-only.
- **`AbnormalValueIndicator`** — inline arrow + coloured value + a
  screen-reader label ("High: 7.9, reference 3.5–5.5").
- **`AiDisclaimerBanner`** — `tertiaryContainer` strip above any AI content.
- **`AppEmpty` / `AppError` / `AppLoading`** — one of each, reused everywhere.
  Empty = icon + one line + at most one action. Loading = skeleton that
  matches the content it replaces. Error = message + a single "Try again".
- **`VitalsChart`** — `fl_chart` themed to match: grid `outlineVariant`, axis
  labels `bodySmall`, series in `primary` / `tertiary` / `secondary` (never
  status colours), reference band in `surfaceContainerHighest`.
- **`Pressable`** — wraps any custom tap target to dip to `scale 0.97` on
  press (instant, reduce-motion aware).

---

## 6. Information architecture

One product, three role apps, a shared shell. Every screen answers: *Where am
I? Where can I go? What's here? How do I leave?* (apple-design §16 wayfinding.)

### 6.1 Patient — `Home · Health · Appointments · Profile`

| Tab | Contains |
|---|---|
| **Home** | Greeting, next appointment, active medications, the AI summary card, quick actions. The at-a-glance screen. |
| **Health** | The record. Sub-tabs: **Timeline** (records + vitals merged, filterable), **Vitals** (charts + manual entry), **Medications**, **AI summary** (full). |
| **Appointments** | Upcoming + history (grouped by month), book / reschedule / cancel. |
| **Profile** | Account details, preferences (theme + language), sign out. |

*Was 5 tabs (Home / Timeline / Appointments / Vitals / Profile) with Medications
and the AI summary stranded on standalone routes. "Health" is the fix.*

### 6.2 Staff — `Dashboard · Patients · Tasks · Schedule · Profile`

Each is a distinct clinical workflow, so each keeps its tab. Dashboard is the
shift overview (today's schedule, unacked flags, top tasks, panel scan).

### 6.3 Admin — `Overview · People · Departments · System · Profile`

| Tab | Contains |
|---|---|
| **Overview** | System counts, appointment health, recent activity, quick links. |
| **People** | Patients / Staff / Admins directory with search; role-aware "Add". |
| **Departments** | Create / rename / delete. |
| **System** | Sub-tabs: **Analytics**, **Audit log**, **AI settings**. |
| **Profile** | Account + preferences + sign out. |

*Was Users / Departments / Analytics / Audit / AI (5 flat tabs). Folding
Analytics + Audit + AI into "System" gives the bar room and a clearer story.*

### 6.4 Responsive — Material 3 window size classes

| Class | Width | Nav | Layout |
|---|---|---|---|
| Compact | < 600 | `NavigationBar` bottom | single pane; detail = full-screen push |
| Medium | 600–839 | `NavigationRail` icons | single pane, wider gutter |
| Expanded | 840–1199 | `NavigationRail` extended | list-detail where it helps |
| Large | ≥ 1200 | `NavigationRail` extended | list-detail + persistent detail; content capped at `maxContentWidth`, centred |

Compact is the baseline. Nothing scrolls horizontally except a scoped
table/chart container.

---

## 7. Motion — `lib/app/theme/motion.dart`

Functional, not decorative. Every helper honours OS "reduce motion".

| Token | Value | Use |
|---|---|---|
| `Motion.fast` | 120 ms | press feedback, hover, tiny flips |
| `Motion.medium` | 220 ms | cards settling, switchers, list items, sheet content |
| `Motion.slow` | 320 ms | page transitions, larger reveals |
| `Motion.standard` | `easeOutCubic` | the house curve — entrances, settles |
| `Motion.emphasized` | `easeOutBack` | momentum-driven moves only (flicked sheet, FAB) |

- **Press feedback is instant and on pointer-down** (`Pressable`, scale 0.97).
  apple-design §1: the moment feedback waits for release, directness "falls off
  a cliff".
- **Page transitions** are a quiet fade + 1.2% rise (`AppPageTransitions`),
  same on every platform — this app runs on desktop and web, not just a phone.
- **State changes**: implicit animations / `AnimatedSwitcher` at
  `Motion.medium`, `Motion.standard`.
- **List entrances**: fade + 8px rise, subtle, capped so long lists don't
  cascade.
- Reduce-motion: every slide/scale collapses to an opacity cross-fade.
- No parallax, no staggered hero reveals, no decorative loops.

---

## 8. Accessibility checklist (pre-committed)

- [x] Contrast: all text ≥ WCAG AA 4.5:1 (3:1 for ≥24px / bold ≥19px). Status
      ramp + key screens asserted in tests.
- [x] Touch targets ≥ **48 × 48 dp** (`materialTapTargetSize: padded`).
- [x] Every icon-only control has a `Semantics` label / `tooltip`.
- [x] Status conveyed by colour **+ icon + text**, always.
- [x] Text scales to 2.0× without clipping on every screen.
- [x] Charts + images have a text alternative.
- [x] Form fields have persistent visible labels + inline error text.
- [x] Logical focus order; full keyboard operability (Windows / web).
- [x] Dark theme is a first-class parity target.
- [x] Motion respects `MediaQuery.disableAnimations`.

---

## 9. Implementation map

```
lib/app/theme/
  app_colors.dart      seed, brand gradient, ColorScheme.light/dark
  status_colors.dart   ClinicalStatusColors ThemeExtension {container, onContainer, icon}
  app_typography.dart  TextTheme (Lexend headlines + Inter body, size-specific tracking),
                       AppText.clinical()
  dimens.dart          Space, Radii, Shadows
  motion.dart          Motion tokens, Pressable, AppPageTransitions
  app_theme.dart       ThemeData light/dark — every *Theme config, registers the
                       status extension, page transitions, a11y defaults
  window_size.dart     WindowSize enum + WindowSize.of(context)

lib/core/presentation/
  app_scaffold.dart    AppScaffold (shell, max-width, gutter, refresh)
  app_card.dart        AppCard, SectionHeader, MetricTile
  states.dart          AppEmpty / AppError / AppLoading (+ skeletons)
  status_badges.dart   StatusPill / RiskBadge / SeverityChip / AbnormalValueIndicator
  confirm_dialog.dart  confirm()
```

`MaterialApp.router` consumes `AppTheme.light` / `AppTheme.dark` with the
device theme-mode + locale preference (`lib/app/settings/ui_prefs.dart`).

---

## 10. Do / Don't

**Do** — anchor on the neutral `surface`; separate with a hairline, lift with a
soft shadow. Reserve saturated colour for the status ramp. Use `AppText.clinical`
for measured values. Build from the shared components in §5.2. Design
compact-first. Pair every status colour with an icon and a word. Give every tap
target instant press feedback.

**Don't** — hand-pick `ColorScheme` roles. Use the brand gradient anywhere not
listed in §1. Use `primary` or `error` to mean "status". Ship placeholder-only
labels. Add heavy shadows or decorative motion. Build separate phone/desktop
layouts. Let any surface scroll horizontally except a scoped table/chart.
Invent a composite "health score".
