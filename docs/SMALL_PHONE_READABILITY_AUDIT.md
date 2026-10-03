# Small phones and enlarged text

Reviewed on 3 October 2026 against the current Flutter app. The source scan
covered 114 presentation files, followed by actual Flutter widget layout checks.

## Changes

- Cards and metric groups now use their content height and drop columns as text grows.
- Paired form fields and actions stack when a small phone cannot fit them side by side.
- Headings can use the full width below the toolbar actions. Tall headers and filters
  scroll, leaving room for the screen body.
- Compact navigation opens a scrollable destination menu when the labels cannot fit
  across the bottom. It preserves the chosen text size and all destinations.
- Confirmed problem labels keep whole words. If one word is wider than the available
  width at extreme text sizes, the label scrolls horizontally rather than splitting
  that word or reducing the font size.
- Fixed cramped date/gender/blood-type fields, account headings, notification rows,
  directory phone numbers, audit timestamps and summary disclaimer layouts.
- Upcoming appointments again include every active booking, ordered by date. Cards
  slide left every four seconds, wrap to the first appointment, and support swipes,
  previous/next controls and pause/resume. A single appointment stays still. Automatic
  movement respects reduced motion, accessible navigation, background app state and
  inactive routes. Selection follows the appointment ID when the data refreshes.

## Verified coverage

`test/features/small_phone_readability_test.dart` loads the bundled English and Arabic
fonts and renders 56 route locations across auth, patient, staff and admin.
Each runs at 320 × 568 logical pixels in both languages with maximum app text (1.3×)
and system scales of 1×, 2× and 3×: 336 initial screen renders across 24 test cases.
The resulting combined scales are 130%, 260% and 390%.

All 24 cases pass without captured Flutter layout errors or detected long words
breaking across lines. Detection inspects text-selection boxes, including Latin
words of five or more letters and Arabic words of four or more letters.

Carousel tests cover four-second timing, wraparound, swiping, arrows, pause/resume,
timer disposal, one appointment, reduced motion and 320px layouts at 390% text in
English and Arabic. A separate patient-home integration test verifies section order,
ticket/room data, position count and automatic/manual advancement.

The existing responsive suite also exercises phone, tablet and desktop sizes,
keyboard insets and reduced motion. The dependency lock is aligned with the
repository's pinned Flutter 3.44.4 / Dart 3.12.2 toolchain.

## Build and regression results

- Flutter analysis completes with no errors or warnings; 103 informational style
  diagnostics remain in the repository.
- `flutter build web --no-pub --release` succeeds.
- The full 500-case test run initially passed 487 cases. Thirteen UI cases still
  expected earlier uppercase headings, old toolbar buttons or a permanently visible
  navigation bar, or needed to expand additional quick actions. Those selectors were
  corrected without removing their workflow assertions. Affected-file reruns passed
  30 cases, and the remaining payments case passed separately after waiting for its
  scroll layout before tapping. The entire 500-case suite was not repeated after
  those test-only corrections.
- `git diff --check` passes.

## Scope limits

The route sweep checks the initial viewport of seeded states. It does not constitute
a visual sign-off of every scrolled row, dynamic-ID detail route, calendar mode,
dialog, validation message, permission failure or theme. Physical Android/iOS maximum
text settings still need device verification, particularly nonlinear text scaling,
keyboard interactions and screen-reader navigation. Figma was not changed by this work.

At extreme text sizes, more scrolling is necessary: a fixed-size phone cannot display
all enlarged content at once. The implementation preserves font size and access to
content instead of promising that everything fits in one viewport.
