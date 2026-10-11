# Actual MyHealth reference-screen renders

Captured from `test/features/reference_tools_test.dart` with real Flutter widgets, bundled fonts/Material icons and the repository's synthetic test accounts. These are not design mockups, live production clinician data or physical-device evidence.

The automated matrix exercises English/Arabic, light/dark, all three app text preferences, phone/tablet/desktop widths, and independent OS 2× text scaling. Gallery captures use the new Default preference (0.92). Some pages require scrolling; the General Health and shortcut captures show those lower sections separately.

| Screen | Phone: English light | Tablet: English light | Desktop: Arabic dark |
| --- | --- | --- | --- |
| Home | [Render](home_390_en_light_default.png) | [Render](home_768_en_light_default.png) | [Render](home_1366_ar_dark_default.png) |
| Shortcut strip | [Render](shortcuts_390_en_light_default.png) | [Render](shortcuts_768_en_light_default.png) | [Render](shortcuts_1366_ar_dark_default.png) |
| Emergency | [Render](emergency_390_en_light_default.png) | [Render](emergency_768_en_light_default.png) | [Render](emergency_1366_ar_dark_default.png) |
| Doctor search | [Render](doctors_390_en_light_default.png) | [Render](doctors_768_en_light_default.png) | [Render](doctors_1366_ar_dark_default.png) |
| Calculator directory | [Render](calculators_390_en_light_default.png) | [Render](calculators_768_en_light_default.png) | [Render](calculators_1366_ar_dark_default.png) |
| General Health group | [Render](calculators_general_390_en_light_default.png) | [Render](calculators_general_768_en_light_default.png) | [Render](calculators_general_1366_ar_dark_default.png) |
| Existing BMI/BSA | [Render](bmi_390_en_light_default.png) | [Render](bmi_768_en_light_default.png) | [Render](bmi_1366_ar_dark_default.png) |
| Converter directory | [Render](converters_390_en_light_default.png) | [Render](converters_768_en_light_default.png) | [Render](converters_1366_ar_dark_default.png) |
| Blood sugar | [Render](glucose_390_en_light_default.png) | [Render](glucose_768_en_light_default.png) | [Render](glucose_1366_ar_dark_default.png) |
| Cholesterol | [Render](cholesterol_390_en_light_default.png) | [Render](cholesterol_768_en_light_default.png) | [Render](cholesterol_1366_ar_dark_default.png) |
| Triglycerides | [Render](triglycerides_390_en_light_default.png) | [Render](triglycerides_768_en_light_default.png) | [Render](triglycerides_1366_ar_dark_default.png) |
| Existing general converters | [Render](general_390_en_light_default.png) | [Render](general_768_en_light_default.png) | [Render](general_1366_ar_dark_default.png) |
| Hospital sheet | [Render](hospital_390_en_light_default.png) | [Render](hospital_768_en_light_default.png) | [Render](hospital_1366_ar_dark_default.png) |

Every row also has English/light and Arabic/dark captures at all three widths in this directory. Full results and remaining gates: [status](../../patient_rebuild_status.md). Feature/integration inventory and manual steps: [reference-screen handoff](../../patient_reference_tools.md).
