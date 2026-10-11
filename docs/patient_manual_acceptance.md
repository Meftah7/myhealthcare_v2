# Patient device and accessibility acceptance

Status: **NOT PERFORMED — owner/tester execution required.** Automated Flutter renders, layout checks and semantics guidelines are separate evidence. Do not change these rows to Pass based on automated tests alone.

Use synthetic/demo accounts and reports. Record tester, date, app revision, OS/browser, device, assistive technology and any screenshot/issue link. Test the release web build on an approved HTTPS host or localhost; test installed native builds when device SDKs/signing are available. No host was published for these checks. APK generation is separately blocked by the missing Android SDK.

Repeat the navigation checks in English/Arabic, light/dark, and Small/Default/Large. Repeat with device accessibility text enlarged independently of the app preference. On the web, also test browser zoom; browser zoom is not evidence of Android/iOS OS-text behavior.

| Check | Steps and expected result | Result / evidence |
| --- | --- | --- |
| Phone portrait | At approximately 360×800 and 390×844, see Home → Records → Appointments → Messages → Services. Appointment action is rounded blue; selected state is distinct. Messages has visible Future work text. Open exactly one native drawer from the header. | Pending |
| Phone landscape | Rotate while viewing a report or chat. Navigation follows available window width, not device type. Current report/conversation and back behavior remain intact; no obscured buttons. | Pending |
| Tablet portrait/landscape | At 768×1024 use the rail and labeled Account & preferences control. At 1024×768 use the permanent sidebar. Never show bottom navigation and rail/sidebar together. | Pending |
| Laptop resizing | Cross 599/600 and 1023/1024px while scrolled on Home and Services, with a booking draft, selected report and open conversation. Route, scroll and active selections remain; no disconnected hamburger on wide windows. | Pending |
| Short desktop | Resize to about 1100×420. Scroll the sidebar to all account actions and Sign Out. Pinned controls never overlap content. Cancel Sign Out and retain the session. | Pending |
| Drawer dismissal | Open by mouse/touch/keyboard; dismiss by scrim, swipe where supported, Escape and system Back. The current page stays selected. Focus returns to the trigger after dismissal; it moves sensibly to a destination after selecting a row. | Pending |
| Keyboard and focus | Tab/Shift+Tab through navigation, account actions, forms, cards and buttons. Focus is visible, follows reading order, and activates with Enter/Space as appropriate. No trap in the drawer, sidebar or sheets. | Pending |
| TalkBack / VoiceOver | Enable the actual device screen reader. Hear destination names, selected states, Account & preferences, Future work labels and text-size values. Drawer/sheet entry, dismissal and focus restoration are understandable; background controls do not receive focus while a modal is open. | Pending |
| Arabic RTL | Switch to Arabic. Sidebar/rail appear on the appropriate side; drawer and directional arrows mirror. Read mixed report numbers, units, dates and English fragments without reordered meanings. | Pending |
| Text preference choices | Settings shows exactly Small, Default, Large (صغير، افتراضي، كبير). Test all three; cards, drawer entries, buttons and Future work badges remain readable. Enlarging the OS text setting continues to affect text independently. | Pending |
| Existing-user migration | Upgrade with saved xSmall, small and medium preferences. Actual text remains at 0.85, 0.92 and 1.0 respectively; labels become Small, Default and Large. Historical large/xLarge saves retain 1.15/1.3 until a new choice. Relaunch and verify. | Pending |
| New user / reset | Fresh preferences and reset select Default, using 0.92. Relaunch retains selection. Never reset clinical data to test a preference. | Pending |
| Home placement | Scroll Home. Quick Access is immediately below Services. Existing daily-care actions remain reachable; account actions remain in the drawer/sidebar. Weather/News open only Future work explanations, without live values. | Pending |
| Booking | With synthetic accounts, choose clinic/doctor/date/slot, edit/back, review and confirm. Change selections to invalidate stale choices; test conflicts/retry and double taps. Confirmation comes from the repository. Verify dependent permissions, appointment detail, reschedule/cancel and staff visibility in the declared environment. | Pending |
| Report/chat | Open an authorized synthetic PDF, view the original, explain it and ask follow-ups. Check numbers/units, unsupported questions, partial coverage and retry after failure. Change report/account and log out: earlier context disappears. An unavailable provider must be labeled; this does not substitute for live evaluation. | Pending |
| Document download | Download the intended original and an issued document. Open the downloaded PDF, compare ownership/content and keep explanations distinct. Denied/revoked access must not expose another patient's document. Verify device save/share behavior and downloaded filename. | Pending |

Execution record:

| Tester / date | Revision / build | Device / OS / browser | Screen reader / OS text setting | Overall status / issue links |
| --- | --- | --- | --- | --- |
| To be supplied | To be supplied | To be supplied | To be supplied | Pending |

Completion rule: failures need issue/evidence and a repeat check after correction. Record N/A with a reason, never Pass for a check not executed. Keep physical-device and screen-reader gates open until this record is filled.
