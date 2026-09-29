# Phase 7 — accessibility release evidence

## Automated evidence

- `test/features/accessibility_test.dart`: contrast, 48dp targets, labels,
  invalid-field focus, password state, and 200% login layout.
- `test/features/responsive_test.dart`: the exact supported viewport matrix
  (320×568, 375×667, 430×932, 600×800, 840×700, 1024×768, 1440×900),
  landscape/split layouts, keyboard inset, reduced motion, and 200% text.
- `test/features/arabic_regression_test.dart`: real Arabic patient and staff
  shells and navigation.
- `test/phase7/presentation_modes_test.dart`: light, dark, both high-contrast
  themes, RTL, mixed Arabic/English clinical text, LTR identifiers and units,
  reduced motion, and 200% text in combination.
- Existing booking, consultation, result-review, referral/task, admin,
  billing, recovery, and session-security suites exercise the key workflows.

Every direct `IconButton` under `lib/features` and `lib/core` was audited for
a tooltip; shared circle buttons require a tooltip in their constructor.
`InlineBanner.error` is one atomic live region, with its decorative icon
excluded from the accessibility tree.

## Manual assistive-technology release session

This requires a fluent Arabic reviewer and physical supported platforms; it
cannot be truthfully signed off by an automated coding environment.

Run each key workflow in English and Arabic with keyboard plus the platform
screen reader (TalkBack/VoiceOver and desktop screen reader where shipped):

1. Login and recovery.
2. Booking and payment.
3. Result review and consultation.
4. Referral, task ownership and handover.
5. Admin assignment.
6. Session warning, expiry, sign-in and resume.

For each flow record platform, assistive technology/version, language,
viewport, text scale, result, and issue link. Verify focus order and visibility,
announcements, action names/states, Arabic wording, mixed-direction medical
names/identifiers/units, and generated PDF reading order.

The Phase 7 manual gate remains open until those sessions and fluent-language
review are recorded here.
