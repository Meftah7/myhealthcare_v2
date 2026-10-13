# Patient reference screens — IMG_3463–IMG_3472

All ten supplied images were inspected. They guide composition and navigation only. MyHealth retains its approved blue palette, original Material/vector artwork, bundled fonts, bilingual themes and existing patient data environment. No HMG branding, photographs, social accounts, hospitals or service claims were copied.

## Feature inventory and resulting behavior

| Reference | MyHealth implementation | Integration boundary |
| --- | --- | --- |
| 3463 Home | Existing report-explanation hero, Services carousel and Quick Access reused. Emergency, Find a Doctor, Calculators and Converters lead a horizontal shortcut strip with keyboard-operable browse buttons and content-sized height. | PDF explanation remains core; live provider approval/evaluation remains a separate open gate. Bottom destinations stay Home, Records, Appointments, Messages, Services. Weather/News remain disconnected. |
| 3464 Emergency | Dedicated routed screen, large rounded action rows, Bahrain 999 device phone action and visible manual-number fallback on launch failure. | Nearest ER, Rapid Response and Emergency Check-In are visible Future work explanations. No dispatch, reservation, queue skip or payment waiver backend exists. |
| 3465 Doctor | Existing clinician repository, specialty/department filters and bounded availability reused. Added heading, rounded search card, explicit Search/keyboard submission, clinician details sheet and department-filter error/retry state. | Only published directory results are shown. Selecting a clinician continues into the existing booking wizard, which reloads availability and rechecks access. Demo screenshots use the existing synthetic test environment. |
| 3466–3467 Calculators | Collapsible Women’s Health/General Health directories. BMI/BSA uses the existing formula screen; Calories, BMR and Carbs/Protein/Fat open the existing Nutrition calculator/targets. | Ovulation (calendar method, luteal phase 14 days; fertile window per Wilcox et al. 1995), Delivery Due Date (Naegele's rule, cycle-adjusted; ACOG CO 700), Ideal Body Weight (Devine 1974 plus WHO BMI 18.5–24.9 range) and Body Fat (U.S. Navy circumference method, Hodgdon & Beckett 1984) are working estimate screens (owner-approved 2026-10-13) in `lib/features/health_tools/domain/estimates.dart`, with validation, cleared results on edit, estimate labels and population limits. Inputs are never saved. Tested in `test/features/estimates_test.dart`. Nutrition retains its existing device storage behavior, disclosed in the directory. |
| 3468 Converters | Routed directory with three analyte entries and the existing weight/height/temperature tools. | Every supplementary row has a scope badge; the explanation distinguishes project scope from current functionality. These are converters, not trackers. |
| 3469–3471 Converter screens | Glucose, cholesterol and triglycerides accept localized input, immediately convert, preserve physical value when swapped and provide accessible output/copy controls. Empty/invalid/negative/nonfinite inputs cannot produce fabricated results. | Inputs/results are temporary screen state. No history storage or personalized risk interpretation. |
| 3472 Hospital sheet | Rounded root modal with title, close control, unavailable search/filter presentation, honest empty state and a button to the existing clinic-department search. | There is no physical hospital/facility directory or location integration in this environment. No hospitals or distances are invented, and closing the sheet preserves the booking draft. Actual hospital selection awaits a real facility data model and booking location contract. |

The new modal sheets use the root navigator so the floating assistant and background navigation remain behind the modal barrier. Their content scrolls at enlarged text sizes. RTL output keeps numeric values and units in a stable left-to-right order.

## Formula and emergency sources

Verified 11 October 2026 against primary sources:

- [Labcorp SI conversion table](https://www.labcorp.com/test-menu/resources/si-unit-conversion-table): glucose factor is reported rounded as 0.0555; cholesterol 0.0259 and triglycerides 0.0113 convert mg/dL to mmol/L. MyHealth retains the existing glucose factor `1 / 18.016`, consistent with that rounded glucose factor. Each analyte uses its own factor; reverse conversions use the exact reciprocal rather than a second rounded constant.
- [Mayo Clinic Laboratories SI table](https://www.mayocliniclabs.com/order-tests/si-unit-conversion.html): corroborates glucose 0.05551 and triglycerides 0.0113. Laboratory reporting precision can differ; the tool does not interpret the result clinically.
- [Bahrain National Portal emergency information](https://bh.bh/new/en/emergency-fire_en.html): 999 covers ambulance, police and fire. The UI explicitly limits this number to Bahrain and directs users elsewhere to their local number. Opening a phone handler is not proof that a call connected or an ambulance was dispatched.

Display rounds lab output to two decimal places. The underlying canonical mg/dL value is kept separately, so repeated direction changes do not compound display-rounding errors. Tests cover known examples, reciprocal conversions, round-trip tolerance, distinct factors, Arabic/Persian digits, decimal separators, invalid values, clipboard output and repeated swaps.

The reused body calculations remain `BMI = kg / metres²` ([CDC](https://www.cdc.gov/bmi/adult-calculator/)) and Mosteller BSA `sqrt(kg × cm / 3600)` ([published formula comparison](https://pubmed.ncbi.nlm.nih.gov/16546483/)) with the existing validated input ranges. They are general estimates, not a diagnosis or an individual healthy-weight prescription. Nutrition remains the existing Mifflin–St Jeor/target implementation; a second energy or macro formula was not introduced.

## Verification and manual acceptance

Final results and exact commands are recorded in [patient rebuild status](patient_rebuild_status.md). Real Flutter captures are indexed in [the screenshot gallery](rebuild_screenshots/reference_tools/README.md). Render coverage is widget-test evidence, not a physical-device or screen-reader claim.

Changed implementation files:

- Routes and booking: `lib/app/router.dart`, `lib/features/booking/presentation/book_appointment_landing.dart`, new `select_hospital_sheet.dart` beside it.
- Tools: existing `lib/features/health_tools/presentation/health_tools_screens.dart`; new `domain/lab_conversion.dart` and presentation files `emergency_services_screen.dart`, `health_tools_directory.dart`, `lab_converter_screen.dart`, `tool_widgets.dart` under that feature.
- Discoverability: `lib/features/service_catalog/domain/patient_catalog.dart`, `application/catalog_dispatcher.dart`, `presentation/catalog_widgets.dart`.
- Localization/dependency integration: English/Arabic ARBs and three generated localization files in `lib/l10n/`; `pubspec.yaml`, `pubspec.lock`, Windows generated plugin registration. `url_launcher` provides the device phone action; it does not request clinical dispatch or location.
- Tests: new `test/features/lab_conversion_test.dart`, `reference_tools_test.dart`; updated planned-integration assertion in `patient_rebuild_test.dart`; corrected calendar-dependent fresh-day fixture in `booking_flow_test.dart` without relaxing its booking assertions. Checklist/status, this handoff, screenshot indexes and complete execution logs record evidence. The full suite regenerates `docs/performance.md` as test-machine measurements.

Use the existing [device/accessibility checklist](patient_manual_acceptance.md), plus these new checks. Do not test by placing a real emergency call unnecessarily.

| Manual check | Expected result | Result/evidence |
| --- | --- | --- |
| Phone action on a suitable device, without placing a test emergency call | OS phone handler opens with 999; returning preserves the screen. A device without support shows the number and honest failure text. No dispatch success message appears. | Pending |
| Shortcut strip, phone/tablet/laptop and keyboard | Swipe/scroll and Previous/Next buttons reach all entries. Focus is visible and actions open their routes; Quick Access remains below Services. | Pending |
| Tool directories and sheets with TalkBack/VoiceOver | Group expanded/collapsed states, Future work badges and actions are announced. Modal background controls cannot receive focus; closing restores focus. | Pending |
| Converter Arabic/English input and copy | Values/units retain meaning; swap preserves the value; invalid/empty input has no result. Clipboard contains the displayed value plus correct unit. | Pending |
| Doctor search/detail/booking | Name, specialty and department filters match repository data. Search works via keyboard. Availability is rechecked in the existing booking flow. | Pending |
| Hospital sheet in current environment | Clear unavailable state, no invented facility/distance; close preserves draft; clinic fallback reaches real departments. | Pending |

External prerequisites: an owner-maintained verified emergency-facility directory plus coordinates/location/directions; authorized rapid-response/check-in services with operational workflows; a real hospital/facility repository and booking location model; validated formulas/inputs/limitations for the four planned calculators. These are missing integrations, not hidden successes. Live AI, policy-owner approval, manual physical-device/screen-reader acceptance and missing Android SDK packaging remain separately open. No push or deployment is authorized for this task.
