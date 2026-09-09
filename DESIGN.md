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
  `MetricTile`, `StatusPill`, `EmptyState`/`ErrorStateView` — so every screen
  in all three apps is built from the same parts.

## 0.1 What changed in v3

v2 described the system; v3 is the pass that made every screen actually use it.

- **`AppScaffold` exists.** It was specified in v2 and never built, so 54 screens
  hand-rolled the same five layers and drifted. It now owns the page frame,
  the gutter, refresh, entrance stagger and scroll-to-top.
- **Wide windows do something with the width.** `SectionColumns`, `CardColumns`
  and `TwoPane` re-flow dashboards, card lists and list-detail screens from
  `expanded` up, and the rail extends there instead of at `large`.
- **Motion is a real layer, not just tokens.** `AppEntrance`, `AppReveal`,
  `AppCountUp` and `SharedAxisSwitcher` join `Pressable`, and every one degrades
  under reduce-motion.
- **The duplicates are gone.** Five private tile widgets became `NavRow` /
  `EntryCard` / `ListCard`; two status chips became `StatusPill`; three error
  patterns became one.
- **Text scale is a layout input.** Fixed aspect ratios and pixel heights around
  text were replaced with measurements from `MediaQuery.textScalerOf`.

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
red / green), and holds WCAG contrast in both themes.

Generate the **accent** families from the seed with
`ColorScheme.fromSeed(..., dynamicSchemeVariant: DynamicSchemeVariant.fidelity)`
for light **and** dark — `fidelity` keeps the seed's chroma instead of
flattening it to M3's default muted 36.

The **neutral ramp is hand-authored** (`AppColors.light` / `.dark`), because the
generated greys carry the seed's violet cast into every surface and the
container steps land too close together for a card to separate from the page.
The replacement is a cool near-achromatic slate:

| role | light | dark |
| --- | --- | --- |
| `surface` (page) | `#F7F8FB` | `#0E1015` |
| `surfaceContainerLowest` (cards, bars, sheets) | `#FFFFFF` | `#08090C` |
| `surfaceContainerHigh` (dark cards, field fill) | `#ECEEF4` | `#1E2129` |
| `onSurface` | `#161922` | `#E8EAF1` |
| `onSurfaceVariant` | `#585F70` | `#A7AEC0` |
| `outlineVariant` (the hairline) | `#DCDFE8` | `#2E323C` |

A card is always **one step above the page**, which is what lets the hairline be
a definition line rather than the only thing holding the card up. Every text
pair above clears WCAG AA; `test/features/accessibility_test.dart` asserts it, so
re-run it after touching any of these values.

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

- Screen edge padding: `md` compact, `lg` medium+ — supplied by `AppScaffold`,
  never re-typed at the call site.
- Card interior: `lg`. Gap between stacked cards: `sm`.
- Related form fields: `md`; between form groups: `xl`.
- Detail lines *inside* a card: `xs`. Never `xxs` — at 4dp a stack of facts
  reads as one dense paragraph.
- **`SectionHeader` owns the gap above itself** (`lg`). Never put a
  `SizedBox(height: Space.lg)` in front of one; that was how sections ended up
  48dp apart instead of 24. Use `SectionHeader(..., first: true)` for the
  header that opens a screen.

### 4.2 Shape

```dart
Radii.card       22   // the default container
Radii.cardSmall  16   // nested / dense cards, snackbars
Radii.field      14   // text fields
Radii.button     14   // buttons (never a full pill on dense screens)
Radii.chip       10   // filter chips
Radii.pill      999   // status badges only — they are not buttons
Radii.sheet      28   // bottom sheets (top corners)
```

### 4.3 Elevation — flat + border + soft shadow

v2 abandons M3 surface-tint elevation. Depth comes from three things, in order:

1. **Fill contrast** — the page is `surface`, a card is one step above it
   (`surfaceContainerLowest` in light, `surfaceContainerHigh` in dark). This is
   the load-bearing one; the two below only sharpen it.
2. **A hairline border** — `outlineVariant` at *full* strength (the token is
   already a whisper: `#DCDFE8` / `#2E323C`). Never re-alpha it at the call
   site, or the same edge ends up four different weights across the app.
3. **A soft shadow** (`Shadows.e1/e2/e3`) — only on surfaces that genuinely lift
   off the page: raised cards, menus, dialogs, the FAB. Every one is tinted
   toward the neutral ramp's deep slate (`#1B1F3B`), never neutral black: a grey
   shadow on a cool page reads as dirt. `Shadows.glow(color)` is the coloured
   bloom for the one brand surface a screen is allowed.

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

- **`AppScaffold`** (`app_scaffold.dart`) — every screen's shell, and the only
  place the page frame is described. Centres content at `maxContentWidth`,
  applies the window-size gutter and the standard scroll padding, hosts the
  title + actions + optional `bottom`, wires pull-to-refresh, staggers its
  children in, and scrolls back to the top when the active nav destination is
  re-tapped (via `ScrollToTopSignal`, which `AppShell` broadcasts).
  Supply exactly one of:
  - `children:` — the common case, a vertical list of sections;
  - `slivers:` — sticky headers, `SliverList.builder` for long lists;
  - `body:` — the escape hatch for a screen that owns its own scrolling
    (a calendar, a chat thread, a two-pane split).
- **`AppBrandLockup`** — logo + wordmark, the app-bar title on each role's home
  screen. A dashboard shows the brand and lets its in-content greeting say
  where you are; it never shows an app-bar title *and* a greeting headline.
- **`PageGreeting`** — the date overline + greeting that opens each dashboard.
  `headlineSmall` compact, `headlineMedium` from medium up.
- **`TwoPane`** (`two_pane.dart`) — list-detail. Below `expanded` it renders the
  list alone and the caller pushes a route on tap; from `expanded` up it puts a
  fixed-width list beside the detail and selection becomes state. A detail
  screen used in the pane takes `embedded: true` so it drops its back button.
- **`SectionColumns` / `CardColumns` / `TileGrid` / `MetricRow`**
  (`responsive.dart`) — the four re-flowing layouts. `SectionColumns` splits a
  dashboard into two columns from `expanded` up (narrow output is
  `[...primary, ...secondary]`, so the compact reading order is whatever the
  caller wrote). `CardColumns` deals variable-height cards round-robin into
  columns. `TileGrid` sizes its rows from the **text scaler**, never a fixed
  `childAspectRatio`. `MetricRow` levels its tiles with `IntrinsicHeight`.
- **`NavRow` / `EntryCard` / `ListCard`** (`app_card.dart`) — the three tappable
  shapes. `NavRow` is any row that opens something (optionally `tinted` for a
  grid of shortcuts); `EntryCard` is a big two-up choice; `ListCard` is a card
  of hairline-separated rows with a built-in empty row. These replaced five
  near-identical private widgets that had drifted to four icon sizes.
- **`AppCard`** — the flat bordered card + optional `Shadows.e1`, optional
  `onTap` (wraps `Pressable` for press feedback), optional header row.
- **`SectionHeader`** — overline + optional trailing action ("See all").
- **`MetricTile`** — one number, its label, and an optional trend/delta. The
  honest replacement for a "score ring": real counts (upcoming appointments,
  open flags, no-show rate). Never invents a composite score.
- **`StatusPill`** — the one badge in the app. `RiskBadge` / `SeverityChip`
  build on it from the clinical ramp; `AppointmentStatusPill` builds on it from
  `ColorScheme` roles for workflow state (booked / confirmed / completed /
  cancelled / no-show). Always container + icon + text. Never icon-only, never
  colour-only, and never a second hand-rolled `Container` pill.
- **`AbnormalValueIndicator`** — inline arrow + coloured value + a
  screen-reader label ("High: 7.9, reference 3.5–5.5").
- **`AiDisclaimerBanner`** — `tertiaryContainer` strip above any AI content.
- **`EmptyState` / `ErrorStateView` / `LoadingSkeleton` + `SkeletonList`** — one
  of each, reused everywhere (`states.dart`). Empty/error render a softly-tinted
  icon medallion + one line + at most one action. `SkeletonList` renders
  card-shaped placeholders; all skeletons drop the shimmer under reduce-motion.
- **`ProfileHeader`** — gradient monogram + name + email + role pill, on every
  profile screen.
- **`VitalsChart`** — `fl_chart` themed to match: grid `outlineVariant`, axis
  labels `bodySmall`, series in `primary` / `tertiary` / `secondary` (never
  status colours), reference band in `surfaceContainerHighest`.
- **`Pressable`** — wraps any custom tap target to dip to `scale 0.97` on
  press (instant, reduce-motion aware).

---

## 6. Information architecture

One product, three role apps, a shared shell. Every screen answers: *Where am
I? Where can I go? What's here? How do I leave?* (apple-design §16 wayfinding.)

All three shells follow the same shape: a home/dashboard, two or three workflow
tabs, and Profile last as the hub for account, preferences and the screens that
are consulted rather than worked in.

### 6.1 Patient — `Home · Nutrition · Appointments · Records · Profile`

| Tab | Contains |
|---|---|
| **Home** | Date + greeting, the allergy strip, Quick appointment (the one gradient surface), Your health (three figures), Upcoming appointments (ticket carousel), Quick actions. |
| **Nutrition** | Targets from the profile, logging, daily totals. |
| **Appointments** | Book now / Schedule, upcoming, then history grouped by month; reschedule + cancel on upcoming. |
| **Records** | Health Records — timeline and medications, with imaging, allergies and sick-leave beneath it. |
| **Profile** | Personal info, health details, wallet, preferences, family network; feedback and sign out. |

Vitals, Billing, Messages, Home care and the AI summary hang off Home and
Records as pushed routes, reached from Quick actions — they keep the nav bar.

### 6.2 Staff — `Dashboard · Patients · Tasks · Schedule · Profile`

Each is a distinct clinical workflow, so each keeps its tab. Dashboard is the
shift overview (next patient, shift figures, quick actions, today's queue,
open flags, top tasks). **Patients is list-detail**: the panel on the left, the
selected chart beside it from `expanded` up.

### 6.3 Admin — `Dashboard · Users · Departments · Billing · Profile`

| Tab | Contains |
|---|---|
| **Dashboard** | What needs you (the one gradient surface), system counts, quick actions, appointment health, recent activity. |
| **Users** | Patients / Staff / Admins directory with search; role-aware "Add". |
| **Departments** | Create / rename / delete. |
| **Billing** | Invoices and payment state across the clinic. |
| **Profile** | Account, audit log, analytics, forecast, AI settings + log, preferences, sign out. |

Analytics, the audit log and AI settings live under Profile rather than in the
nav bar: they are consulted occasionally, and the bar is for the work.

### 6.4 Responsive — Material 3 window size classes

| Class | Width | Nav | Layout |
|---|---|---|---|
| Compact | < 600 | `NavigationBar` bottom | single column; detail = full-screen push; 2 tile columns |
| Medium | 600–839 | `NavigationRail`, icons + labels | single column, wider gutter; 2 tile columns |
| Expanded | 840–1199 | `NavigationRail` **extended** | `SectionColumns` / `CardColumns` split in two; `TwoPane` shows both panes; 3 tile columns |
| Large | ≥ 1200 | `NavigationRail` extended | as expanded; content capped at `maxContentWidth`, centred; 4 tile columns |

Compact is the baseline. Nothing scrolls horizontally except a scoped
table/chart container. The rail scrolls internally, so a short landscape window
never clips a destination.

**Never pin a height or an aspect ratio that text has to fit inside.** A fixed
`childAspectRatio` or `SizedBox(height:)` around scalable text is the single
most common source of overflow in this app — it breaks at the OS's 2× text
setting, and it breaks again whenever the content pane narrows (the extended
rail did exactly that to the year grid). Measure with
`MediaQuery.textScalerOf(context)` and pass `mainAxisExtent`, or let
`IntrinsicHeight` do it. `test/features/responsive_test.dart` asserts all of
this at four widths and at 2× text.

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

### 7.1 The helpers

| Helper | What it does |
|---|---|
| `Pressable` | Scale 0.97 on **pointer-down**, plus the pointer cursor and a whisper of hover lift on desktop. |
| `AppEntrance` | Fade + 8dp rise on first build. `index:` staggers siblings by 40ms, capped at 6 so a long list never cascades. `AppScaffold` applies it to its `children` automatically. |
| `AppReveal` | Cross-fade between states of one region (loading → data, empty → list), top-aligned and size-animated so a taller replacement grows downwards. Children need distinct keys. |
| `AppCountUp` | Rolls a figure up to its value, always with tabular figures. Used by `MetricTile`. |
| `SharedAxisSwitcher` / `sharedAxisTransition` | Horizontal move *within* a section — the two-pane detail swapping records, a wizard advancing. |
| `AppPageTransitions` | The route transition: fade-through with a 2% Z move, and the outgoing page dims and recedes as it is covered. |

Every one is built on `TweenAnimationBuilder` / `AnimatedSwitcher` rather than a
hand-rolled controller or a `Timer`, so nothing can outlive its element — which
is also why the widget tests don't trip over pending timers.

### 7.2 The rules

- **Press feedback is instant and on pointer-down.** apple-design §1: the moment
  feedback waits for release, directness "falls off a cliff".
- **Reduce-motion is not optional.** Every helper checks `Motion.reduced`:
  slides and scales collapse to a fade, entrances become instant, the home
  carousel stops auto-advancing (motion nobody asked for), and chart lines are
  drawn rather than animated. `responsive_test.dart` asserts the tree renders
  and leaves no timers running with `disableAnimations: true`.
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
  app_scaffold.dart    AppScaffold (shell, max-width, gutter, refresh, stagger,
                       scroll-to-top), AppBrandLockup, PageGreeting,
                       ScrollToTopSignal
  responsive.dart      SectionColumns, CardColumns, TileGrid, MetricRow
  two_pane.dart        TwoPane, PaneSelection
  app_card.dart        AppCard, GradientHeroCard, SectionHeader, ProfileHeader,
                       InlineBanner, MetricTile, NavRow, EntryCard, ListCard
  states.dart          EmptyState / ErrorStateView / LoadingSkeleton / SkeletonList
  status_badges.dart   StatusPill / RiskBadge / SeverityChip /
                       AppointmentStatusPill / AbnormalValueIndicator
  confirm_dialog.dart  confirm()
```

Tests that hold the system in place:
`test/features/accessibility_test.dart` (contrast, tap targets, labels, 2× text)
and `test/features/responsive_test.dart` (nav class at four widths, the column
split, two-pane, 2× text at three widths, reduce-motion).

`MaterialApp.router` consumes `AppTheme.light` / `AppTheme.dark` with the
device theme-mode + locale preference (`lib/app/settings/ui_prefs.dart`).

---

## 10. Do / Don't

**Do** — anchor on the neutral `surface`; separate with a hairline, lift with a
soft shadow. Reserve saturated colour for the status ramp. Use `AppText.clinical`
for measured values. Build from the shared components in §5.2 — start every
screen with `AppScaffold`. Design compact-first. Pair every status colour with
an icon and a word. Give every tap target instant press feedback. Size anything
holding text from the text scaler.

**Don't** — hand-pick `ColorScheme` roles. Use the brand gradient anywhere not
listed in §1. Use `primary` or `error` to mean "status". Ship placeholder-only
labels. Add heavy shadows or decorative motion. Build separate phone/desktop
layouts. Let any surface scroll horizontally except a scoped table/chart.
Invent a composite "health score".

**And specifically, don't re-grow what §5.2 already owns.** Every one of these
was in the codebase before this pass, and each cost a real inconsistency:

- a private card/tile/row widget that duplicates `NavRow`, `EntryCard` or
  `ListCard` — five of them had drifted to four different chevron sizes;
- a hand-rolled `Container` status pill next to `StatusPill`;
- a third inline-error or empty-state pattern beside `ErrorStateView` /
  `EmptyState`;
- a `Scaffold` + `Center` + `ConstrainedBox` + `ListView` stack instead of
  `AppScaffold` — nine screens forgot the max-width and the page silently
  stretched to the window;
- a `SizedBox(height: Space.lg)` in front of a `SectionHeader`;
- a fixed `childAspectRatio` or pixel height wrapped around text;
- a weight above 500 on display or headline type.
