# Staff and admin usability implementation

The user explicitly approved implementation on 15 October 2026 after reviewing the HTML proposal. The patient palette and full staff calendar remain the visual and behavioral authority. No push or deployment is authorized.

Implemented in the working tree:

- Staff Home: explicit Ongoing/Upcoming/Completed summary, late upcoming labels, full-schedule entry, aggregate quick statistics; clinical review queues, flags and quick actions preserved. Tasks preview removed.
- Primary Chat shell branch; original inbox URLs and task deep links retained. Clinical work remains accessible in Profile. No group chat or permission expansion.
- Patient history: repository-side completed-visit scope, distinct counts, authorized condition/ID/name filtering, pagination, last visit and clinical labels. Current-care access is independent. Nurses require explicit attributed participation, recorded from the existing chart.
- Manual staff/admin status selectors removed; notifications and persisted theme control remain visible on narrow screens. Underlying presence data retained.
- Admin Home: real account inventories, completed consultations, enabled physical-room count, referrals and prescription counts, clinic-wide selected-day appointments, ledger history, two-section gender donut, hourly scheduled demand, available doctors and daily receipts/refunds. Bahrain boundaries and integer fils.
- Physical rooms and encounter participation added through Drift migration 34 (previously 33); generated bindings regenerated. Completion and prescription issuance timestamps distinguish actual event times from scheduled/treatment dates. Historical unknown dates are disclosed and excluded from period counts.
- Users: contextual role/category/status/department/clinician filters, reset/count, separate selection, visible filtered selection, review and existing local bulk protections. Shared bulk deactivation uses fresh authentication, transaction/version checks, booking/care/task checks, last-admin protection and audit.
- Feedback: full messages, All/Open/Resolved, reporter-role filtering, search and resolve/reopen attribution. Existing local feedback storage retained; remote submission and handling added. No fictitious read/reply state.
- Login: policy links removed only from login; seven seeded role shortcuts, demo runtime only.
- Shared schema 3 and authenticated workspace endpoints/adapters. Admin overview/users/feedback/rooms/appointments/billing use server data; unsupported unrelated routes keep their explicit unavailable behavior. Shared desk receipts/refunds record offline transactions and do not move money.

Final behavior and verification:

- Reports/history react to local source-table changes; shared views poll authenticated endpoints every 30 seconds and expose refresh/retry controls. Audit writes do not trigger a report-read loop. A regression test verifies that saving a physical room refreshes its aggregate without reopening Home.
- Clinical statistics use the clinician's complete scope. Nonclinical staff see authorized message statistics without attempting to read clinical history.
- Local Critical means an unresolved urgent clinical flag. Shared Critical means an unresolved urgent result-review task; scheduling and no-show risk do not qualify. Follow-up means unresolved followUpDue work.
- Revenue uses settlement dates, invoice receipts and their settled refunds, rounded to integer fils. Wallet topups and refunds of topups are excluded. Shared billing records offline settled receipts/refunds with fresh authentication and bounded, idempotent refunds; it does not move money.
- Referral metrics use actual referral-request creation records. Prescription issuance and completed-visit period counts use actual event timestamps. Unknown legacy dates are excluded from period counts; legacy visit dates in patient rows are disclosed.
- Existing task links and work automation remain reachable from Profile. Profile now opens its own root, fixing an integration issue where it initially opened Tasks.
- Search resets clear the query and filter controls; changes clear stale selections. At large text sizes, user filters expand and category tabs scroll.
- Arabic labels cover the new statuses, roles, transaction methods and reporting caveats. Existing clinical/user content remains in its recorded language.

Validation results (15 October 2026):

- 71 Flutter tests passed across the final regression runs: 66 in the broad run plus the five repository tests rerun after correcting a missing test-library import. The final workspace-only run passed all 18 tests (five repository, thirteen UI).
- Coverage includes completed-history scope/deduplication/pagination, explicit nurse participation, authorization, room concurrency/audit/automatic aggregate refresh, settlement-day finance, schedule drilldown, login, Profile, quick actions, Chat/report flow, navigation continuity, migration, payments and live access revocation.
- All 29 shared-server tests passed, including nine workspace tests covering scopes, availability, feedback, rooms, reporting, real referrals, refund replay/overrefund, bulk rollback and last-admin protection, plus existing HTTP/backup/clinic tests.
- The revocation widget test retains its chart/dialog/session assertions and explicitly unmounts the app before closing its database; this fixes its teardown timeout.
- Font-loaded UI captures cover mobile staff Home; admin reports at 320 px English 200%, 390 px Arabic RTL 200%, tablet and desktop dark mode; Patients, Users, Feedback and Rooms at 320 px in both languages at 200%. Screenshots are in preview/app-*.png. Representative desktop/mobile/Arabic captures were visually inspected.
- Dart analysis has no remaining errors or warnings in the final changed-file check. Style-level infos remain, including pre-existing repository issues; analysis is not claimed to be lint-clean. Logs: preview/workspace-release-analyze.log and preview/workspace-final-changed-analyze.log.
- git diff --check passed. Temporary task-created transformation scripts were removed; existing .claude/ work was preserved.
- Final demo web build passed in 91.7 seconds: preview/workspace-final-build.log. The earlier web build also succeeded (preview/workspace-web-build.log).

No deployment, push, physical-device test, assistive-technology session or production data migration has been performed.

Pre-existing shared limitations remain for unrelated clinical-document/result-review/risk adapters and operational correction routes. Those routes retain their explicit unavailable screens instead of falling back to a local scratch database. The new workspace endpoints, room directory, feedback handling, user deactivation, overview, history, participation, referral creation/read and desk billing use authenticated server data.
