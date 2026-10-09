# MyHealth AI improvement to-do list

Created: 7 October 2026.
Source: `MyHealth_AI_Improvement_Plan.md` supplied by the user.

This checklist organizes the report into implementation work. Sections 1 and 2 have been checked against the code and completed, as recorded below. Other findings and estimates have not been independently verified. Unchecked items mean planned work, not necessarily confirmed defects.

## 1. Task correctness and access — first priority

- [x] Confirm the reported task and authorization findings against the current repository.
- [x] Preserve existing task status, original deadline, owner, cover, history and AI fields during regeneration; update only source-derived fields.
- [x] Give genuinely new clinical episodes a distinct source identity.
- [x] Restrict generated tasks to the staff member's authorized patient panel, with enforcement in both generation and persistence.
- [x] Restrict clinical flag details to authorized clinicians; give admins scoped operational task metadata.
- [x] Propagate generation, refresh and prioritization failures; count successful writes only and display partial success accurately.
- [x] Handle version conflicts with a reload action.
- [x] Order tasks deterministically by approved urgency, deadline/overdue state, supporting score and stable tie-breaker.
- [x] Unify care-relationship checks across appointments, assignments and walk-ins; document existing access lifetime after historical visits.
- [x] Reauthorize every emitted subscription update against current account, role and care/proxy access; narrow permissions after staff profile changes.
- [x] Immediately lock the session and discard displayed/cached clinical content when access is reduced or expires, including open preview dialogs.
- [x] Add regression coverage for regeneration, separate patient panels, failed writes, urgency ordering and revoked access.

Implementation update (7 October 2026): task 1 complete. Risk sources now distinguish vital readings, lab reports, relevant medication courses and follow-up encounters. Schema 28 maps existing source records to legacy flag identities without changing existing flag/task IDs or workflow state. Repeated scans preserve completed/dismissed work and original deadlines; new sources create separate tasks.

Access changes are watched independently of clinical-data updates. Reduced account, role, credential, care-team or proxy access locks the session, invalidates user-scoped caches and resets navigation, including open previews. Assignment and credential expirations trigger timed revalidation. Historical appointments and created/claimed walk-ins continue granting access under the existing policy; assignment-only access expires at `endedAt`. Signing in again applies the remaining current permissions.

Validation: the final security/task/risk/storage/workflow regression run passed 89 tests, including real schema migration, backup restoration, source identity collisions, timed expiry and removal of a visible chart/open preview after revocation. Analysis of the changed files found no issues; the release web build and diff whitespace checks passed. Earlier focused checks also covered English/Arabic failure feedback. Regression coverage is in `test/services/task_correctness_test.dart`, `test/services/risk_episode_test.dart` and `test/security/live_access_revocation_test.dart`.

Done when: generation preserves completed/dismissed work and deadlines, unrelated patients are excluded, and failures never report success.

## 2. Patient Records — restore the main workflow

- [x] Mount record history directly on the Records landing screen.
- [x] Add visible search and Upload document actions; keep care-team messaging secondary.
- [x] Provide All records, Results, Medicines, Documents and Uploads views while preserving existing routes and visit links.
- [x] Keep the patient/family subject selector and compact allergy alert visible; show loading/error states for unavailable data.
- [x] Query the entire authorized history, including records beyond loaded pages.
- [x] Add date, type, facility, author and review-state filters; preserve filters and navigation position.
- [x] Show record title, clinical date, source, type and review status; group visit-related records without hiding standalone items.
- [x] Separate originals, recorded information, clinician review and labeled generated summaries in record details.
- [x] Show units and recorded reference ranges; label missing ranges and compare trends only for matching tests/units.
- [x] Separate active from historical medicines and show instructions and prescription links.
- [x] Reuse upload validation, original-file storage, fingerprints and pending-review rules.
- [x] Detect duplicate uploads per patient/fingerprint with an intentional override; preserve entered fields after failures.
- [x] Add read/unread state and correction requests without allowing edits to signed notes.
- [x] Verify proxy permissions and intended subject before uploads and exports.

Done when: a patient can find a record, upload an original and download leave directly from Records.

Implementation update (7 October 2026): task 2 complete. Records now provides full-history search, subject-specific filters and retained navigation position, family selection, a pinned allergy alert, visit grouping and direct upload/sick-leave actions. Medicines separate active and historical courses with instructions and prescription/visit links. Details distinguish original files, recorded content, clinician review and generated summaries. Lab comparisons require matching tests and units; missing reference ranges are labeled.

Uploads preserve original bytes, fingerprints, pending review and entered fields after errors. Duplicate fingerprints are checked per patient, with an explicit override. Schema 29 adds account-specific read state and audited, retry-safe correction requests, visible to authorized clinicians without changing signed notes. Self/proxy permissions and document ownership are checked at service boundaries; exports use the actual subject and recheck access after rendering.

Validation: 84 Records/document/family/security/migration/backup regression tests passed. Changed implementation files and tests analyze cleanly. English/Arabic patient routes were checked at 320px with enlarged text; Records passed, while the broader check identified an existing Nutrition-screen overflow outside task 2. The release web build, formatting and diff whitespace checks passed.

## 3. Shared services, permissions and migrations

- [ ] Agree document approval rules, disclosure profiles, issuer qualifications and required wording with the clinic before official use.
- [x] Define operational role presets: clinic administrator, reception, billing, document desk and clinical supervisor.
- [x] Add explicit, scoped grants for document preparation, administrative issuance, approved reprints, template management, operational assignment and revocation.
- [x] Keep clinical signing tied to explicit clinician qualifications, including when an administrator is also a doctor.
- [x] Define document/task service contracts and transaction boundaries before building their screens.
- [x] Add versioned Drift migrations for templates, requests, issued versions, delivery events, task source/history/outcomes, record read/correction requests and scoped grants.
- [x] Extend the existing verification registry to bind immutable issued versions and validity/revocation status.
- [x] Keep validation, authorization and audit enforcement in services/repositories.
- [x] Validate migration compatibility and preservation of existing records and document references.

Implementation update (7 October 2026): task 3 engineering foundation implemented. Five operational presets suggest explicit clinic/patient/department grants without granting them automatically. Grants are validated, audited, revocable and time-limited; changes and expiry invalidate active sessions. Clinical document signing separately requires an explicit grant, verified current medical licence, staff profile and care relationship, including for an administrator who is also a clinician.

Schema 30 adds versioned templates, requests, immutable issued snapshots, artifacts, delivery events, scoped grants and task source/history/outcome storage; schema 29 record read/correction tables are reused. Existing record/task identities and verification references are preserved. New verification bindings use frozen subject/issuer details and explicit valid/replaced/revoked status; clinical details are withheld from operational verification without clinical read access. Existing export-generated entries remain labeled legacy.

Six proposed English/Arabic sick-leave templates cover clinic, employer and school disclosure. They start unapproved, and binding official versions is blocked until an authorized administrator approves the template version. User confirmed no clinic-approved rules are available; actual clinic agreement remains unchecked. Proposed wording, role presets and transaction boundaries are documented in [shared_document_foundation.md](docs/shared_document_foundation.md).

Approval workflow update (7 October 2026): Admin > Profile > Document policies now supports explicit audited activation of policy management, review/edit/save of the six English/Arabic drafts, acknowledgement and approval of each saved version, and creation of replacement drafts. Approved wording is locked. Approval checks the reviewed snapshot and atomically retires earlier policies for the same language/audience. Required fields and external disclosure placeholders are validated in the repository; failed saves retain entered wording. No production policy was automatically approved; clinic acceptance remains a manual step. Validation: 23 approval/foundation/document/security tests passed, including 320px English/Arabic layouts with enlarged text, stale review, audit rollback and retry. Analysis, formatting and whitespace checks passed; release web build passed.

DocumentService now defines preparation, approval, atomic/idempotent issuance, rendering, download and revocation contracts. Task 4 below now implements the sick-leave pipeline and screens; richer task workflow/history integration remains Task 5.

Validation: 69 document, task, Records, authorization, live-revocation, migration and backup regressions passed, including populated schema 29 migration, immutable content, audit rollback, timed grant expiry and administrator-clinician access reduction. Changed source/tests analyze cleanly and formatting/whitespace checks passed. The release web build passed.

## 4. Documents — complete one sick-leave workflow first

- [x] Introduce an authorized DocumentService with explicit patient subject, visit and document type.
- [x] Decouple PDF templates/renderers from signed-in-patient UI providers.
- [x] Build request, draft, approval, issuance, rendering and delivery states with clear failure/retry behavior.
- [x] Validate patient/visit/issuer relationships, leave dates and required fields; preserve form inputs on errors.
- [x] Allow nurses/admins to prepare requests within their grants; enforce authorized doctor signing at the service boundary.
- [x] Watermark draft previews and block official issuance when required verification fails.
- [x] Make issuance idempotent; commit certificate, issue audit and notification event transactionally.
- [x] Freeze patient/issuer details, qualifications, content, language and template version at issuance.
- [x] Store official PDF bytes and fingerprint; expose pending/failed rendering without claiming readiness.
- [x] Register verification at issuance and keep repeated downloads/reprints stable.
- [x] Implement minimum-data employer/school templates without diagnosis or unrelated clinical history by default.
- [x] Provide English/Arabic previews and accessible A4 layouts that print clearly in grayscale.
- [x] Deep-link patient notifications to Documents; track delivery attempts separately from issuance/downloads.
- [x] Add scoped staff/admin reprints of approved copies.
- [x] Implement correction by replacement with superseded links, and revocation with reason/audit; retain original versions.
- [x] Limit verification output by role and avoid exposing clinical details through operational checks.
- [x] After sick leave passes end to end, add attendance, visit summary, referral, prescription, released lab/imaging, fitness and finance templates according to agreed permissions.
- [x] Treat external verification as a separate feature requiring minimal output, unguessable tokens, rate limits and an agreed file-authenticity/signing approach.

Done when: a doctor issues once, the patient finds the same issued copy, an authorized admin reprints it, and a nurse cannot sign it.

Implementation (9 October 2026): All nine document types use the authorized request, approval, issuance, rendering, delivery and stored-download pipeline. Staff open Documents from the patient chart; administrators use Document policies > Document access and patient copies. Patients receive notifications linking to the issued Documents list. Issued identity, qualifications, policy, content and bytes are frozen; retries do not duplicate issuance. Corrections retain originals and supersede them only when a replacement issues. Existing certificates remain clearly labelled legacy.

Clinical documents require a qualified doctor and explicit signing grant. Attendance and finance use a separate administrative issuance grant, with billing authority additionally required for finance. Source records must match patient, visit and document type; patient imports cannot become official clinic results. Visit summaries require a completed clinician outcome. Lab/imaging release decisions are audited and bound to the exact source fingerprint; amendments invalidate release, and withholding revokes issued copies. Changes after approval require a fresh reviewed request. Templates are proposed English/Arabic drafts: actual clinic approval and appropriate grants remain mandatory before official issuance.

External verification implements the user's selected reference-plus-PDF-fingerprint approach in `services/document_verification`. New PDFs can contain a configured HTTPS verification URL with a random 256-bit token. A read-only, rate-limited verifier accepts minimal registry metadata and a SHA-256 digest; PDFs stay on the verifier's device. Registry publication is an explicit trusted-host operator action, protected by a server-only HMAC key. Valid snapshots expire after five minutes without refresh, and revoked/superseded states cannot be reactivated. Public hosting, HTTPS origin, secret provisioning and authoritative refresh still require configuration; shared automatic publication belongs to Task 7. See `services/document_verification/README.md`. This is registry/file matching, not a certificate-based digital signature, and the local app's export alone is not independently authenticated clinic data.

Validation: 68 document, policy, security, migration, backup and bilingual phone-form tests and 3 standalone verifier tests passed. Tests cover every added type, administrative authority, finance separation, source amendments, release/withholding, frozen copies, minimal manifest output, concurrent idempotency, rendering/delivery retries, replacement, revocation and English/Arabic A4 PDFs. Changed Dart files analyze without issues. The release web build and formatting/whitespace checks passed. Broader auth, payment and consultation checks passed 41 tests, with one auth-flow failure expecting a missing Preferences tooltip; this is recorded separately from the passing document acceptance suite.

## 5. Staff workspace and task workflow

- [x] Organize staff navigation around Today, Patients, Tasks, Schedule and Inbox.
- [x] Make Today items open their exact patient, visit or source and preserve return position.
- [x] Add patient-chart overview, visits, results, medicines, documents and care-team views with consistent capability checks.
- [x] Preserve consultation drafts/amendments and show note, orders, review, follow-up and document completion steps.
- [x] Offer document creation during/after consultations with explicit visit selection.
- [x] Make a task list the primary mobile view with urgent, overdue, due-today and upcoming groups.
- [x] Add My work, Covering, authorized Team work and Completed views plus relevant filters/search.
- [x] Show patient, reason, next action, owner, deadline and source/chart links on each task.
- [x] Expose reassignment, escalation, cover acceptance and assignment history with scoped access and receiver notifications.
- [x] Record completion outcomes and dismissal reasons; add waiting/blocked only with an owner, reason and review time.
- [x] Keep urgency above AI ranking, bound supporting scores and explain them under “Why this task?”.
- [x] Accurately label deterministic/mock/offline prioritization and prevent AI from closing work or making clinical decisions.
- [x] Add canonical generation rules for results, unsigned notes, follow-ups, referrals, document approvals and overdue replies without duplicate ownership.
- [x] Show schedule cover, time off and conflicts; prepare notifications and delivery status for affected bookings.
- [x] Prioritize overdue inbox threads and support reply-to-task creation without automatically resolving clinical work.
- [x] Add shift handover for unfinished tasks, urgent reviews and unanswered threads with accepted responsibility and temporary care access.

Done when: staff can complete and hand over work with its context, history and authorization intact.

Implemented (9 October 2026): Today links open exact visits, patients and task details with return navigation preserved. Patient charts offer Overview, Visits, Results, Medicines, Documents and Care team sections. Consultation steps retain autosaved drafts and signed originals, support immutable amendments and explicit follow-up tasks, and show note, orders, review and document progress.

Tasks provide My work, Covering, explicitly authorized Team work and Completed views, filters/search, source context, deadlines, owners and immutable assignment/outcome history. Completion/dismissal requires a recorded outcome; waiting/blocked requires a reason and future review. Cover, escalation, reassignment and shift handover use explicit receiver acceptance, optimistic versions, transactional bundles, minimal in-app notifications and task-specific care access. Expired cover and revoked assignment grants cannot act; mismatched source patients reject the entire handover. Clinical outcome text stays in authorized task history rather than general audit details.

Canonical source links generate result reviews, unsigned notes, referrals, document approvals and overdue replies once; follow-ups are created explicitly from the visit. Regeneration preserves ownership, final status and original deadlines. Inbox orders unanswered work by reply deadline and creates linked tasks without closing clinical work. Schedule tools preview time-off conflicts and affected bookings, preserve booking ownership, and create idempotent in-app notices with delivery/read status. External delivery remains dependent on Task 7 configuration.

Validation: 51 focused checks passed across workflow, task correctness, risk generation, clinical workflow and English/Arabic phone tests, including all six staff route checks at 320px and OS text scales 1/2/3. Final Task 5 files analyze without errors or warnings; chart lint cleanup analyzes cleanly. The full suite recorded 612 passes and 10 failures before final fixes; both Task 5 failures subsequently passed focused reruns. Eight remaining failures concern appointment filter setup, the patient Preferences tooltip, patient home carousel/browse, record-upload test inputs and patient nutrition layouts. These are recorded separately; the entire suite is not claimed green. Release build and whitespace validation passed.

## 6. Admin workspace

- [ ] Add Overview, Work, People, Clinic, Documents, Finance, Reports and Settings navigation; adapt to Overview/Work/People/More on phones.
- [ ] Add permission-aware global search for people, appointments and document references.
- [ ] Build actionable dashboard counts for unassigned/overdue work, pending approvals and failures; link each to its filtered queue.
- [ ] Distinguish loading/errors from zero, avoid duplicate combined counts, and show owner, waiting time and next action.
- [ ] Add configurable frequent actions and readable audit activity labels.
- [ ] Unify operational queues for referrals, home visits, reviews, replies, documents, delivery failures and feedback.
- [ ] Support owner assignment, due dates, information requests and resolution from queue items.
- [ ] Add responsive people management with role/department/status/clinician filters and scoped profile tabs.
- [ ] Manage staff schedules, cover, service hours and capacity under Clinic.
- [ ] Preview affected bookings and require replacement ownership before deactivating staff or changing relevant availability.
- [ ] Add a document center for templates, requests, approvals, issued copies, replacements, delivery and verification.
- [ ] Organize finance exceptions and operational reports around recorded reasons and useful exports.
- [ ] Configure clinic identity, languages, integrations, AI capabilities, grants, audits and backups under Settings.
- [ ] Protect the last active admin, preview bulk changes and confirm deactivation, refunds, revocation and resets while preserving history/recovery.
- [ ] Split large presentation files into coherent sections only as needed for these workflow changes.

Done when: admins can find common controls and assign/resolve operational work from consistent queues.

## 7. Shared deployment — required for separate devices

- [ ] Choose the target: synthetic single-browser university demo or shared multi-device application.
- [ ] For the local demo, visibly explain device-local data and demonstrate role changes within one database.
- [ ] For shared use, implement an authenticated API with SQLite on durable application-server storage.
- [ ] Enforce sessions, current authorization and mutations on every server request/event.
- [ ] Add remote repository adapters and deliberate version/change handling; start online-first.
- [ ] Store originals and issued files securely and implement shared document registry/delivery workers.
- [ ] Scope any local caches per account and clear/revalidate them after access changes.
- [ ] Move AI/provider secrets to the backend and keep payment/delivery simulations accurately labeled until configured.
- [ ] Load-test representative writes, transaction duration, contention and safe retries.
- [ ] Back up database, files and required keys; define recovery goals, encrypt scheduled backups and test restore.
- [ ] Add admin health indicators for backups, delivery failures, storage and migrations; separate restore privileges.

Done when: separate staff, patient and admin devices observe the same authorized issuance and task updates.

## 8. Acceptance and release checks

- [ ] Rerun generation after completion/dismissal: state and original deadline remain unchanged.
- [ ] Use non-overlapping doctor panels: no unrelated tasks or clinical rationale leak.
- [ ] Force storage/version failures: generation and prioritization report accurate outcomes.
- [ ] Verify urgent work stays ahead of higher AI scores and ordering is stable.
- [ ] Retry issuance: exactly one certificate, issue audit and delivery event exist.
- [ ] Reject mismatched patient/visit/issuer and invalid dates while preserving inputs.
- [ ] Refuse nurse/admin signing; permit explicitly authorized approved reprints.
- [ ] Change patient/issuer profiles: issued identity/bytes remain unchanged; replacements retain old versions.
- [ ] Revoke documents and force render/verification failures: status stays accurate and no failed copy appears official/ready.
- [ ] Verify employer copies and minimal verification omit unrelated clinical information.
- [ ] Search beyond the initial page and confirm imports preserve original bytes/review state.
- [ ] Test proxy subjects and access revocation during active screens/downloads.
- [ ] Verify covering staff can access the needed source and record outcomes while unrelated staff cannot.
- [ ] Check English/Arabic UI and PDFs, long names/notes, mixed direction, pagination, accessibility and grayscale printing.
- [ ] For shared deployment, test cross-device updates and interrupted delivery retries without duplicates.
- [ ] Run pinned formatting checks, `flutter analyze`, `flutter test`, release web build and appropriate platform integration tests.
- [ ] Keep existing auth, scheduling, consultation, payment and authorization suites passing; test migrations and backup restoration.

## Recommended milestones

1. Task correctness and a direct Records history entry point.
2. One complete, authorized sick-leave issue/download/reprint workflow.
3. Staff task actions and handover, then unified admin controls.
4. Shared backend before presenting workflows as cross-device.
5. Final role, language, accessibility, migration and recovery validation.

The report estimates 3–5 developer-days for correctness, 4–6 for Records, 6–10 for documents, 5–8 for staff, 5–8 for admin, 10–20+ for shared deployment and 3–5 for final validation. These are unverified planning estimates, not delivery commitments. Backend contracts can begin alongside early work; each feature should be tested as it is implemented.
