# Actual Flutter renders

These captures come from `test/features/text_size_layout_test.dart`, with bundled English/Arabic fonts and Material icons loaded. They are widget renders of the real app with synthetic accounts, not design mockups or physical-device evidence. The layout tests exercise every text preference in both languages and themes; Home/Services captures below use the new Default (0.92).

| Layout | English light | English dark | Arabic light | Arabic dark |
| --- | --- | --- | --- | --- |
| Phone / bottom navigation | [Home](home_390_en_light_default.png), [Services](services_390_en_light_default.png) | [Home](home_390_en_dark_default.png), [Services](services_390_en_dark_default.png) | [Home](home_390_ar_light_default.png), [Services](services_390_ar_light_default.png) | [Home](home_390_ar_dark_default.png), [Services](services_390_ar_dark_default.png) |
| Tablet / navigation rail | [Home](home_768_en_light_default.png), [Services](services_768_en_light_default.png) | [Home](home_768_en_dark_default.png), [Services](services_768_en_dark_default.png) | [Home](home_768_ar_light_default.png), [Services](services_768_ar_light_default.png) | [Home](home_768_ar_dark_default.png), [Services](services_768_ar_dark_default.png) |
| Desktop / permanent sidebar | [Home](home_1366_en_light_default.png), [Services](services_1366_en_light_default.png) | [Home](home_1366_en_dark_default.png), [Services](services_1366_en_dark_default.png) | [Home](home_1366_ar_light_default.png), [Services](services_1366_ar_light_default.png) | [Home](home_1366_ar_dark_default.png), [Services](services_1366_ar_dark_default.png) |

| Text preference | English light | English dark | Arabic light | Arabic dark |
| --- | --- | --- | --- | --- |
| Small / 0.85 | [Render](preferences_390_en_light_small.png) | [Render](preferences_390_en_dark_small.png) | [Render](preferences_390_ar_light_small.png) | [Render](preferences_390_ar_dark_small.png) |
| Default / 0.92 | [Render](preferences_390_en_light_default.png) | [Render](preferences_390_en_dark_default.png) | [Render](preferences_390_ar_light_default.png) | [Render](preferences_390_ar_dark_default.png) |
| Large / 1.0 | [Render](preferences_390_en_light_large.png) | [Render](preferences_390_en_dark_large.png) | [Render](preferences_390_ar_light_large.png) | [Render](preferences_390_ar_dark_large.png) |

Preference captures scroll to the size selector. Another 34 actual patient-page captures are in `../final_audit/`, including drawer, booking, records, messages, profile and Home's Quick Access position. See the status document for execution results and the manual acceptance document for unperformed device/screen-reader checks.
