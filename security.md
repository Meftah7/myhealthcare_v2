# Security Audit

Audit started: 2026-09-27

Implementation started: 2026-09-27. Findings marked **FIXED** have code changes
in the current working tree; full analyzer/test verification is still pending
because the local Flutter toolchain stalls before producing output.

Scope is intentionally reviewed in phases. This file currently contains **Phase 1 only: authentication and account recovery**. Findings distinguish exploitable implementation issues from limitations that matter only if this demo is deployed as a production healthcare system.

## Phase 1 — Login, Registration, Forgot/Reset Password, Session, Email Confirmation

### Scope reviewed

- `lib/features/auth/presentation/login_screen.dart`
- `lib/features/auth/presentation/register_screen.dart`
- `lib/features/auth/presentation/forgot_password_screen.dart`
- `lib/features/auth/application/session.dart`
- `lib/data/repositories/auth_repository_impl.dart`
- `lib/services/auth/password_hasher.dart`
- `lib/features/admin/application/admin_providers.dart` reset operations
- `lib/data/db/tables/users.dart`
- Auth route guards in `lib/app/router.dart`

### P0 — Critical

#### SEC-AUTH-01: Client-local authentication is not a production security boundary — REQUIRES BACKEND

Evidence: users, password hashes, salts, roles, lockout state, and sessions are all stored and evaluated in the local Flutter/Drift client.

Impact: anyone able to modify/copy the local database or run a modified client can change roles, replace password hashes, clear lockouts, or directly alter healthcare data. There is no trusted server that can reject the modified client.

Required action: keep this build explicitly demo/offline-only, or move authentication, authorization, session issuance, and protected data access to a trusted backend before production use.

### P1 — High

#### SEC-AUTH-02: Timing defense for unknown accounts uses the wrong PBKDF2 cost — FIXED

Evidence: `lib/data/repositories/auth_repository_impl.dart:36-37` uses `_dummyHash` with 20,000 iterations; `lib/services/auth/password_hasher.dart:25` creates real hashes with 120,000 iterations.

The code deliberately runs a dummy hash for unknown identifiers to prevent account enumeration, but that path performs roughly one-sixth of the work used for a real account.

Impact: repeated timing measurements can distinguish unknown identifiers from existing accounts with wrong passwords.

Fix: generate the dummy hash using the current production work factor, cache its hash/salt, and add timing-distribution tests. Also rehash older accounts after successful login when their stored cost is lower.

#### SEC-AUTH-03: Registration accepts weaker passwords than reset/change-password — FIXED

Evidence: `lib/features/auth/presentation/register_screen.dart:163-165` accepts six characters; `AuthRepositoryImpl.registerPatient()` has no password-policy validation; reset/change-password require eight characters.

Impact: direct repository calls can create even weaker/empty passwords, and the normal UI creates six-character passwords that other flows would reject.

Fix: enforce one policy in the repository/domain layer for registration, change, reset, and temporary passwords. UI validation should mirror—not define—the policy.

#### SEC-AUTH-04: Password length is unbounded before expensive pure-Dart PBKDF2 — FIXED

Evidence: login, registration, change, and reset paths pass the complete password into `PasswordHasher`; no maximum input length is enforced.

Impact: a very large password consumes memory and is processed 120,000 times by a pure-Dart loop, allowing local/UI denial of service and potentially freezing the application.

Fix: reject passwords above a reasonable UTF-8 byte limit before hashing (for example 1 KiB; normal product limits can be lower) and test oversized Unicode input.

#### SEC-AUTH-05: Reset/deactivation does not revoke an authenticated session — FIXED

Evidence: `lib/features/auth/application/session.dart` stores the authenticated `User` in provider state; `UserRepositoryImpl.resetPassword()` and `setActive()` update the database without notifying the session.

Impact: a stolen session remains usable after password reset, and a deactivated account can continue using the current session until logout/inactivity/app restart.

Fix: add a session/password generation or revocation timestamp and continuously validate active account state. Immediately terminate affected sessions.

#### SEC-AUTH-06: Password-reset administration is not protected in the command layer — FIXED

Evidence: `lib/features/admin/application/admin_providers.dart:299-314` resets by user ID without first requiring `currentUser.role == admin`; it uses a nullable current user only after the password update.

Impact: router checks protect the current UI, but any future non-admin caller that obtains the provider can invoke a privileged reset. The command itself fails open with respect to role.

Fix: require and verify an authenticated admin before the reset starts. Keep authorization in the application/service layer, not only navigation.

#### SEC-AUTH-07: No verified-email ownership model exists — REQUIRES BACKEND

Evidence: the user schema has no verification state/token/expiry; auth routes contain no confirm-email route; registration signs the new user in immediately.

Impact: accounts can be registered with mistyped or unowned email addresses. Any future email-based recovery or sensitive notification would go to an address the user never proved they control.

Fix: if email ownership is required, add hashed single-use verification tokens, expiry, resend throttling, `emailVerifiedAt`, and restrictions for unverified accounts. If this remains a demo, label email as an identifier rather than verified contact information.

### P2 — Medium

#### SEC-AUTH-08: Forgot-password requests have no rate limit or deduplication — PARTIALLY FIXED

Evidence: `lib/data/repositories/auth_repository_impl.dart:230-248` inserts a new unresolved request for every submission.

Impact: repeated requests can flood the admin queue and database. In a shared deployment this becomes an abuse/availability issue.

Fix: keep one unresolved request per account, add cooldown/rate limits, and record abuse-safe telemetry without exposing account existence.

Implemented: duplicate unresolved requests are suppressed. Durable per-device/network throttling and abuse telemetry require a trusted backend.

#### SEC-AUTH-09: Any attacker can temporarily lock a known account — REQUIRES BACKEND

Evidence: five failed passwords set a five-minute lockout in `auth_repository_impl.dart:101-109`. There is no device/IP/global throttling or challenge.

Impact: someone who knows a user's email or national ID can repeatedly lock the account. This is especially serious for staff/admin accounts on a shared backend.

Fix: combine progressive throttling with per-device/network controls, notify users of suspicious attempts, and avoid a simple repeatable hard-lock primitive.

#### SEC-AUTH-10: Lockout updates are a non-atomic read-modify-write — FIXED

Evidence: login reads `failedLoginAttempts` and `_recordFailedAttempt()` writes `row.failedLoginAttempts + 1` without a transaction or atomic SQL increment.

Impact: concurrent failed attempts can overwrite each other, weakening the threshold and making behavior nondeterministic.

Fix: atomically increment with a conditional database update and calculate lock state from the updated value.

#### SEC-AUTH-11: Forgot-password UI hides real service failures — FIXED

Evidence: `lib/features/auth/presentation/forgot_password_screen.dart:55-59` ignores the returned `Result` and always shows success.

Impact: database/storage failure looks identical to a queued request, leaving users falsely confident that recovery is underway.

Fix: preserve the generic response for unknown identifiers, but show a generic retryable error for infrastructure failures.

#### SEC-AUTH-12: Reset and activation operations succeed for nonexistent IDs — FIXED

Evidence: `lib/data/repositories/auth_repository_impl.dart:436-462` ignores affected-row count.

Impact: admin workflows can claim success against stale IDs and may resolve reset requests even though no password changed.

Fix: require exactly one updated row and return `NotFoundFailure` otherwise.

#### SEC-AUTH-13: Reset-request resolution permits an invalid actor and ignores failure — FIXED

Evidence: `lib/features/admin/application/admin_providers.dart:308-314` uses `currentUser?.id ?? ''`, ignores the resolution result, and returns the reset result.

Impact: reset requests can remain pending after a reported success, or resolution can be attempted with an invalid staff foreign key.

Fix: require a valid admin actor and commit password reset plus request resolution in one transaction.

#### SEC-AUTH-14: Raw reset identifiers duplicate sensitive national-ID/email data — FIXED

Evidence: password-reset requests store `identifierEntered` exactly as submitted.

Impact: national IDs/emails are copied into a second table and retained after resolution, increasing breach surface and retention obligations.

Fix: store the resolved user ID and a masked display value, or encrypt and expire the raw identifier under a documented retention policy.

#### SEC-AUTH-15: Demo credentials are exposed in the login UI — FIXED

Evidence: `login_screen.dart` fills known demo accounts and the literal password `password`; seeded accounts use the same password.

Impact: intentional for a demo, but a production build containing this panel gives immediate access to seeded accounts.

Fix: compile demo accounts/UI only in an explicit demo flavor and add a release assertion/build test that production has neither.

### Verified protections already present

- Password hashes use random 16-byte salts and PBKDF2-HMAC-SHA256.
- Hash comparison is constant-time for equal-length values.
- Stored iteration counts are bounded before computation, limiting database-tampering CPU abuse.
- Login uses a generic wrong-account/wrong-password message.
- Deactivation is revealed only after the supplied password verifies.
- Email identifiers are normalized to lowercase.
- Registration checks duplicate email and national ID.
- Registration writes user/profile rows transactionally.
- Auth routes are role-gated after login.
- Cold starts intentionally clear the local session rather than silently restoring it.

### Phase 1 result

Found 15 security findings: P0: 1, P1: 6, P2: 8.

Next planned phase: **patient pages and patient-data authorization**.

---

## Phase 2 — Patient Pages and Patient-Data Authorization

### Scope reviewed

- Patient routes and route parameters
- Patient profile, timeline, record detail, imports, vitals, medications, and documents
- Appointments and linked-account booking
- Family-link discovery, permissions, acceptance, unlinking, and linked views
- Billing controllers/repository ownership checks
- Patient messages, notifications, home visits, and care providers

### P0 — Critical

#### SEC-PAT-01: Patient record-detail route has a direct-object-reference vulnerability — FIXED

Evidence: `lib/app/router.dart:504-506`, `lib/features/records/presentation/record_detail_screen.dart:22-30`, `lib/data/repositories/record_repository_impl.dart:66-74`.

The patient route accepts `/patient/timeline/record/:id`. `recordDetailProvider` calls `recordRepository.byId(id)`, which selects only by record ID and never checks that `record.patientId` equals the signed-in patient.

Impact: a patient who learns or guesses another record ID can view that patient's record and hydrated lab values. For eligible record types, the screen can also generate a PDF combining the unauthorized record with the attacker's identity.

Fix: query by both record ID and current patient ID. Do not expose a patient record-detail provider that accepts an unscoped ID. Add negative tests with another patient's record.

#### SEC-PAT-02: Linked-account booking discloses profile/history before permission validation — FIXED

Evidence: `lib/features/booking/application/booking_providers.dart:105-118`, `:199-219`.

The route-controlled `targetPatientId` is used to load a full patient and appointment history for slot ranking. The active manage-link check occurs only later when `confirm()` is called.

Impact: changing the `for` query parameter triggers unauthorized reads before booking is rejected.

Fix: authorize the active manage link before loading the booking subject or history; return one authorized booking context from a single provider.

#### SEC-PAT-03: Family-account search exposes complete patient objects and is wildcard-enumerable — PARTIALLY FIXED

Evidence: `lib/features/patient/application/family_link_providers.dart:100-111`, `lib/data/repositories/patient_repository_impl.dart:36-75`.

Any signed-in patient can submit a two-character search. The repository embeds the input in a SQL `LIKE` pattern without escaping `%` or `_`; input such as `%%` matches broadly. Results are hydrated into complete `Patient` objects containing email, phone, DOB, gender, national ID, allergies, chronic conditions, emergency contact, and family-member data, even though the UI needs only identity display fields.

Impact: patient directory and health-profile enumeration from an ordinary patient account.

Fix: search a minimal projection containing an opaque ID plus limited display name; escape wildcard characters; require a stronger exact identifier/invitation code; rate-limit and audit searches.

Implemented: family-link lookup now requires an exact email or national ID and returns only an opaque ID and display name. Durable rate limiting and audit telemetry require a backend.

### P1 — High

#### SEC-PAT-04: Patients can open and message arbitrary staff through the route — FIXED

Evidence: `lib/app/router.dart:433-443`, `lib/features/care/presentation/messages_screen.dart:128-152`, `lib/data/repositories/care_repository_impl.dart:155-188`.

The normal picker lists visited doctors, but the route accepts any `staffId`. The thread and send repository methods verify neither that the target is staff nor that the patient has a prior care relationship with that clinician.

Impact: a patient can alter the URL to read/create a thread with arbitrary user IDs accepted by foreign keys, bypassing the intended “visited doctors” restriction and potentially harassing staff.

Fix: validate the target's staff role and an eligible care relationship at thread-read and send time. Derive the patient from session state.

#### SEC-PAT-05: Generic message commands permit sender/identity spoofing — FIXED

Evidence: `lib/features/care/application/care_providers.dart:101-128`, `lib/data/repositories/care_repository_impl.dart:173-188`.

`MessageActions.send()` accepts caller-provided `patientId`, `staffId`, and `fromStaff`, then writes them directly. It does not compare these values with the authenticated user/role.

Impact: any reused or exposed call path can send as a clinician, send as another patient, and generate a misleading notification naming the spoofed sender.

Fix: replace the generic command with `sendAsCurrentUser()`, derive sender ID/role from session, and authorize the patient-staff relationship in the same service.

#### SEC-PAT-06: Profile update trusts the patient ID inside the supplied object — FIXED

Evidence: `lib/data/repositories/patient_repository_impl.dart:79-103`; patient screens call this repository directly.

`updateProfile(Patient patient)` updates user/profile rows using `patient.id` and has no authenticated actor parameter or ownership check.

Impact: a future/tampered client call can update another patient's identity and clinical profile. Because authorization is absent at the mutation boundary, every caller must remain perfectly scoped.

Fix: expose a self-service update command that derives the patient ID from the session; use a separate explicitly authorized staff/admin command for other patients.

#### SEC-PAT-07: Patients can change identity/login fields without reauthentication or verification — PARTIALLY FIXED

Evidence: `lib/features/patient/presentation/personal_info_section.dart:139-149`, `lib/data/repositories/patient_repository_impl.dart:91-102`.

The profile form changes email and national ID through `updateProfile()` without requesting the current password, verifying the new email, or enforcing national-ID uniqueness.

Impact: an unattended authenticated session can change login identity; duplicate national IDs can make `_rowForIdentifier().getSingleOrNull()` fail for affected accounts and create identity ambiguity.

Fix: require recent reauthentication for email/national-ID changes, verify new email ownership, enforce normalized unique national IDs in the database, and audit old/new values.

Implemented: self-service profile updates are session-bound, and email/national-ID fields are read-only and excluded from repository updates. A verified identity-change workflow requires a trusted backend.

#### SEC-PAT-08: Imported health documents are stored unencrypted with indefinite retention — PARTIALLY FIXED

Evidence: `lib/features/timeline/presentation/import_record_sheet.dart:126-180`.

Original PDFs and extracted text are stored in application support storage/database without file encryption or a deletion/retention workflow.

Impact: device backup, filesystem access, or database compromise exposes uploaded medical documents and extracted text.

Fix: encrypt files with a keystore-protected key, define retention/deletion behavior, minimize extracted text, and exclude sensitive files from insecure backups where supported.

Implemented: imported PDFs are sealed with AES-256-GCM (random nonce per file, tamper-evident) under a 256-bit key held in platform secure storage (`lib/services/crypto/`). Extracted text is protected by database encryption (SEC-XCUT-02). A retention/deletion policy is still open.

#### SEC-PAT-09: Failed imports leave sensitive orphan documents — FIXED

Evidence: `lib/features/timeline/presentation/import_record_sheet.dart:147-193`.

The PDF is written before the record insert. When insertion returns `Err`, the file is retained without a corresponding database record or cleanup path.

Impact: repeated failures accumulate undiscoverable medical files that users cannot delete through the app.

Fix: delete the stored file on failure or perform storage through a cleanup-aware document service.

### P2 — Medium

#### SEC-PAT-10: Untrusted PDFs are parsed on the application isolate — FIXED

Evidence: `lib/features/timeline/presentation/import_record_sheet.dart:75-105`.

Extension filtering and a 20 MiB compressed-size cap are present, but arbitrary PDF bytes are passed to `PdfDocument` and fully extracted on the UI isolate. A compact decompression/structure bomb or parser bug can exhaust CPU/memory and freeze the app.

Fix: validate the file signature, parse in an isolate/sandbox where supported, enforce page/object/text limits and timeout, and keep the PDF dependency patched.

#### SEC-PAT-11: Family-link requests have no anti-abuse controls — PARTIALLY FIXED

Evidence: `lib/data/repositories/family_link_repository_impl.dart:95-134`.

Duplicate pairs are blocked, but there is no request rate limit, block list, invitation secret, or notification-abuse protection. A patient can send requests to many accounts found through search.

Impact: account discovery can be turned into unsolicited access-request spam.

Fix: use invitation codes or exact verified identifiers, add per-user rate limits and blocking, and avoid exposing broad search.

Implemented: exact-identifier lookup (SEC-PAT-03) and a 10-requests-per-day cap per requester. Blocking and durable throttling require a backend.

#### SEC-PAT-12: Linked-account read authorization can remain cached after revocation — FIXED

Evidence: linked providers call `_requireActiveLink()` only when evaluated; `_invalidateAll()` invalidates link lists but not every `linkedPatient/Timeline/Vitals/Medications` provider family instance.

Impact: if access is revoked elsewhere while a linked screen remains mounted, already-loaded protected data can remain visible until provider disposal/refresh. Writes correctly re-check manage permission.

Fix: watch link state reactively, invalidate all owner-scoped providers on unlink/revoke/session change, and clear sensitive screen state immediately.

#### SEC-PAT-13: Patient-generated PDFs accept records/certificates without ownership checks — FIXED

Evidence: `lib/features/patient/application/patient_documents.dart`.

PDF builders combine the signed-in patient's identity with caller-supplied `MedicalRecord` or `SickLeaveCertificate` objects without verifying their patient ID. The record IDOR currently makes this reachable for record documents.

Impact: unauthorized data can be exported into a misleading document bearing the attacker's identity.

Fix: accept an authorized record ID, load it through a patient-scoped query, and assert ownership before generation.

#### SEC-PAT-14: Medical message content is copied into notifications — FIXED

Evidence: `lib/features/care/application/care_providers.dart:131-160`.

The first 120 characters of a care message are copied into a notification body. Depending on platform lock-screen settings, sensitive health text may be visible without unlocking the app.

Fix: use a generic “You have a new secure message” notification by default, with previews only after explicit informed opt-in.

### Verified protections already present

- Patient dashboard providers derive the patient ID from the authenticated patient session.
- Appointment cancellation/rescheduling verifies the appointment's patient ID.
- Linked-account read providers check an accepted link before initial loading.
- Linked-account mutations re-check `canManage` immediately before writing.
- Billing controllers derive patient ID from the current patient session.
- Invoice/card/wallet repository operations include patient ownership predicates.
- Saved cards persist masked metadata, not full PAN/CVC.
- Notification reads and updates are scoped to the authenticated recipient.
- Home-visit cancellation checks patient ownership and open status.
- PDF import caps input at 20 MiB and restricts the picker to PDF extensions.

### Phase 2 result

Found 14 patient security findings: P0: 3, P1: 6, P2: 5.

Next planned phase: **staff pages, staff-to-patient authorization, consultation, scribe, tasks, and inbox**.

---

## Phase 3 — Staff pages and clinical workflows

### P0 — Critical

#### SEC-STAFF-01: Any staff account can read any patient chart by changing the route ID — FIXED

Evidence: `lib/app/router.dart` (`/staff/patients/:id`) and `lib/features/patient_chart/application/chart_providers.dart`.

The staff role gate is the only authorization check. The route-supplied patient ID is passed directly to providers that load the patient profile, timeline, vitals, medications, and risk flags. No assignment, care-team, department, appointment, or other treatment-relationship check is performed.

Impact: every staff account effectively has organization-wide chart access, and an attacker can enumerate or substitute patient IDs to disclose PHI.

Fix: enforce patient-level authorization in the repository/backend for every chart query. Require a valid care relationship or narrowly defined emergency-access workflow, and record audited break-glass access.

#### SEC-STAFF-02: Any staff account can write clinical data to any patient chart — FIXED

Evidence: `lib/features/patient_chart/application/chart_providers.dart` (`ChartActions`).

`addNote`, `prescribe`, `addLabResult`, `issueSickLeave`, and `acknowledgeFlag` trust the patient ID supplied by the screen. They attach the current user as author but never prove that the author may treat that patient.

Impact: an unauthorized staff user can alter medical history, prescribe medication, create lab results or sick leave, and acknowledge safety flags for arbitrary patients. These are patient-safety and record-integrity failures, not only privacy defects.

Fix: centralize clinical-write authorization server-side and check staff role, active status, scope, and patient relationship inside the same transaction as each write.

#### SEC-STAFF-03: Consultation routes disclose appointments and patient identity before clinician ownership is checked — FIXED

Evidence: `lib/app/router.dart` (`/staff/consultation/:appointmentId`) and `lib/features/consultation/application/consultation_providers.dart` (`consultationAppointmentProvider`, `consultationPatientProvider`).

The consultation page fetches an appointment by arbitrary route ID and then fetches its patient. The later appointment mutations correctly check `_ownedByStaff`, but the initial reads do not.

Impact: staff can enumerate appointment IDs and disclose another clinician's appointment and associated patient information.

Fix: replace `byId` with an authorized consultation query scoped to the authenticated clinician or an explicitly permitted covering role. Return indistinguishable not-found/forbidden results.

#### SEC-STAFF-04: The clinical-scribe route can target and modify an arbitrary patient — FIXED

Evidence: `lib/app/router.dart` (`/staff/scribe?patient=...`) and `lib/features/ai_scribe/presentation/clinical_scribe_screen.dart`.

The patient query parameter is loaded through `chartPatientProvider` and saved through `chartActionsProvider(patientId).addNote`. Neither path establishes an appointment or care relationship.

Impact: staff can view an arbitrary patient's identity and attach AI-generated clinical notes to that patient's chart.

Fix: launch scribe only from an authorized encounter, pass an opaque encounter identifier, and revalidate clinician ownership and encounter state when loading and saving.

### P1 — High

#### SEC-STAFF-05: The staff patient directory exposes the full patient population

Evidence: `lib/features/staff/application/staff_providers.dart` (`staffPanelProvider`, patient search providers).

The panel loads up to 500 patients and search runs across all patients. Results are not restricted by clinician assignment, department, facility, or active encounter.

Impact: a minimally privileged staff account receives broad identity and health-profile access beyond minimum necessary use.

Fix: return only assigned/recently treated patients by default, restrict search by organizational scope, minimize result fields, and require a documented access reason for broader lookup.

#### SEC-STAFF-06: Staff inbox routes allow access to or creation of conversations with arbitrary patients — FIXED

Evidence: `lib/app/router.dart` (`/staff/dashboard/inbox/:patientId`), staff thread providers, and the care repository thread/send methods.

The route patient ID is paired with the current staff ID without checking an existing authorized relationship. Changing the URL can reveal an existing pairwise thread or permit initiating a new one.

Impact: unauthorized staff may access sensitive conversations or contact patients outside their care scope.

Fix: authorize thread membership server-side using an active care relationship or explicit messaging assignment; do not infer authorization from the requested participant IDs.

#### SEC-STAFF-07: Task and risk-flag mutations are not scoped to the acting staff member — FIXED

Evidence: `lib/features/staff/data/task_repository_impl.dart` and `lib/features/staff/application/staff_providers.dart`.

Task status and AI-priority updates use only a task ID. Risk acknowledgements accept a flag ID and staff ID but do not verify assignment, department, patient access, or affected-row ownership. Unacknowledged risk flags are loaded globally.

Impact: staff can manipulate other users' work queues and acknowledge patient-safety alerts they are not authorized to manage.

Fix: add ownership/scope predicates to every mutation, restrict risk queries by authorized patient panel, and reject zero or multiple affected rows.

#### SEC-STAFF-08: Walk-in claiming is race-prone and lacks department/claim-state enforcement

Evidence: `lib/features/staff/data/consultation_repository_impl.dart` and `StaffOps.startWalkIn` in `lib/features/staff/application/staff_providers.dart`.

Claiming updates a ticket by ID without requiring its current state to be `waiting`, matching the clinician's department, or remaining unclaimed. Appointment creation and ticket claim are separate operations.

Impact: concurrent or out-of-scope staff can create duplicate visits, overwrite a claim, or leave an unclaimed ticket with an orphan appointment.

Fix: perform claim and appointment creation in one backend transaction using a conditional update/lock on waiting, unclaimed, in-scope tickets.

#### SEC-STAFF-09: Consultation completion can leave contradictory or duplicated clinical records — FIXED

Evidence: `lib/features/consultation/application/consultation_providers.dart` consultation completion flow.

Notes, prescriptions, notifications, appointment completion, walk-in resolution, and audit events are written independently. There is no transaction or idempotency key.

Impact: a failure or retry can mark only part of the encounter complete or duplicate prescriptions/notifications, undermining clinical integrity.

Fix: commit the encounter through one transactional backend operation with an idempotency key and deterministic retry behavior.

#### SEC-STAFF-10: Scribe dictation and chart summaries can disclose PHI to secondary systems

Evidence: `lib/features/ai_scribe/domain/clinical_scribe.dart` and `lib/features/patient_chart/application/chart_summary_provider.dart`.

When real AI is enabled, dictated text and assembled chart context are sent to Gemini. In addition, the AI usage log stores the first 80 characters of raw dictation as its summary, creating another persistent PHI copy.

Impact: highly sensitive clinical content may be disclosed to an external processor and exposed through administrative logs beyond the original treatment context.

Fix: obtain and document the required consent/legal basis, minimize and redact payloads, configure an approved healthcare data-processing boundary, and never store raw dictation excerpts in telemetry.

#### SEC-STAFF-11: Consultation drafts can survive logout and leak to the next session

Evidence: non-`autoDispose` `StateProvider.family` consultation draft state in `lib/features/consultation/application/consultation_providers.dart`.

Drafts are intentionally retained across navigation but are not keyed by authenticated user or invalidated on logout. A subsequent user in the same provider container can reopen the appointment and inherit the prior clinician's unsaved note/prescription state.

Impact: PHI and authorship context can cross user sessions on shared devices.

Fix: scope drafts by authenticated user and encounter, encrypt persistence if needed, and invalidate all clinical drafts synchronously on logout/session replacement.

### P2 — Medium

#### SEC-STAFF-12: Appointment mutations do not enforce a valid state transition graph — FIXED

Evidence: staff appointment status methods in the appointment repository.

Ownership is checked, but callers can request statuses without consistently proving the current status or allowed transition.

Impact: stale or malicious clients can move appointments into contradictory states and bypass workflow controls that other authorization decisions may rely on.

Fix: enforce allowed transitions with conditional updates against the expected current state, ideally inside the backend datastore.

#### SEC-STAFF-13: Clinical writes and their audit records are not atomic

Evidence: chart actions and consultation flows write business records first and audit records separately; audit results are not used to roll back or block completion.

Impact: successful sensitive actions can exist without a corresponding audit event after an audit failure, weakening accountability and incident investigation.

Fix: write the clinical change and immutable audit event in the same backend transaction or reliable transactional outbox; monitor delivery failures.

#### SEC-STAFF-14: Router diagnostics may log sensitive record identifiers

Evidence: router configuration enables `debugLogDiagnostics: true`, while staff paths include patient and appointment IDs.

Impact: production logs may collect linkable patient/encounter identifiers and expose them to personnel or systems with logging access.

Fix: disable router diagnostics in release builds and redact identifiers from navigation telemetry.

### Verified protections already present

- Staff routes are protected by a staff-role redirect.
- Staff appointment mutations verify that the appointment belongs to the acting clinician.
- Staff identity for schedule, presence, and dashboard operations is derived from the authenticated session.
- Transfer handling verifies source ownership and validates that the target account has a staff role.
- The Gemini API key is sent in a header rather than embedded in a URL.
- Clinical-scribe screen controllers are disposed when the screen is destroyed.

### Phase 3 result

Found 14 staff security findings: P0: 4, P1: 7, P2: 3.

Next planned phase: **admin pages, privilege boundaries, account administration, audit access, configuration, and system-wide data exposure**.

---

## Phase 4 — Admin pages and privileged operations

### P0 — Critical

#### SEC-ADMIN-01: Admin authorization exists only in navigation, not at privileged command boundaries — FIXED

Evidence: `lib/app/router.dart`, `lib/features/admin/application/admin_providers.dart`, `lib/features/admin/application/settings_providers.dart`, and the underlying repositories.

The router prevents ordinary navigation into `/admin`, but admin commands and repositories do not require an authenticated admin actor. Account creation/deactivation, password reset, billing changes, broadcasts, schedules, referrals, settings, and destructive seeding can be called directly from any in-process code with provider/database access. This is the admin-specific consequence of `SEC-AUTH-01`.

Impact: a modified client, injected code, or future non-admin call site can perform system-wide privileged actions without crossing an independently enforced authorization boundary.

Fix: move privileged operations behind an authenticated backend/service boundary. Require an active admin principal and explicit permission for every command; never treat route visibility as authorization.

#### SEC-ADMIN-02: “Reseed demo data” wipes all operational and security data outside one transaction — FIXED

Evidence: `lib/features/admin/presentation/ai_settings_screen.dart`, `lib/features/admin/presentation/admin_quick_actions.dart`, and `lib/data/seed/seeder.dart` (`reset`, `_wipe`).

After a normal confirmation dialog, `Seeder.reset()` deletes users, patient/staff profiles, appointments, clinical records, medications, vitals, invoices, notifications, payment methods, audit logs, and other tables. `_wipe()` runs before the generation transaction, so a crash or generation failure leaves the database partially or completely empty. The action itself also erases the audit trail and does not create a durable audit event.

Impact: one compromised or mistaken admin action can cause total clinical-data loss and remove evidence of the action.

Fix: exclude demo reset functionality from production builds. In development, require explicit environment gating and reauthentication; make replacement atomic, back up first, and store immutable audit evidence outside the database being erased.

#### SEC-ADMIN-03: General AI-settings updates can alter `seedVersion` and trigger an automatic full wipe — FIXED

Evidence: `SettingsRepositoryImpl.update` in `lib/data/repositories/system_repository_impl.dart` writes `s.seedVersion`; `Seeder.run` wipes and regenerates whenever the stored version differs from its constant.

`seedVersion` is internal migration/seeding state but is accepted as part of a general mutable `AppSettings` object. A malformed/stale caller can change it; the next bootstrap interprets the mismatch as a reason to call `_wipe()`.

Impact: an unrelated settings update or future UI/API bug can become a delayed full-database deletion.

Fix: remove `seedVersion` from public settings updates. Manage schema/demo seed state in a dedicated, internal migration mechanism that never wipes non-demo data automatically.

### P1 — High

#### SEC-ADMIN-04: An admin can deactivate themselves or the final active administrator

Evidence: `AdminActions.setActive`, `UserRepositoryImpl.setActive`, and the admin tab in `lib/features/admin/presentation/user_management_screen.dart`.

The operation updates any user ID without checking whether it is the current user or whether another active admin remains. Affected-row success is not checked either.

Impact: administrators can lock the organization out of administration, accidentally or after account compromise.

Fix: prohibit self-deactivation, atomically require at least one other active privileged administrator, check affected rows, and require step-up authentication for admin-account changes.

#### SEC-ADMIN-05: Privileged identity and access changes are missing reliable audit events

Evidence: `AdminActions.createStaff`, `createPatient`, `createAdmin`, `setActive`, and `resetPassword`; `ScheduleTemplateActions.save`; `SettingsController`; clinic-hours and feedback actions.

These high-impact operations generally write no audit event. Other admin events often omit `actorUserId`, and `AuditRepository.record` accepts a caller-supplied nullable actor without binding it to the authenticated session.

Impact: account elevation, deactivation, credential replacement, schedule/configuration changes, and AI-key changes can be untraceable or incorrectly attributed.

Fix: generate audit identity from the authenticated server session, require it for privileged actions, and commit business changes plus immutable audit events atomically or through a transactional outbox.

#### SEC-ADMIN-06: Admin password replacement is a shared-secret workflow with no forced rotation

Evidence: `AdminActions.resetPassword`, `UserRepositoryImpl.resetPassword`, and `_promptPassword` in `lib/features/admin/presentation/user_management_screen.dart`.

An administrator chooses and sees the user's new password. The account is not marked “must change password,” and existing sessions are not revoked (also covered by `SEC-AUTH-05`). The same flow can target another administrator.

Impact: the resetting administrator retains reusable credentials, and a compromised existing session remains valid after reset.

Fix: issue a short-lived, single-use reset token; require the user to choose the replacement secret; revoke all sessions and recovery tokens; require step-up authentication and stronger controls for admin targets.

#### SEC-ADMIN-07: Referral approval is non-atomic and can be actioned more than once — FIXED

Evidence: `AdminActions.actionReferralRequest`, `AdminActions.referPatient`, and `ReferralRequestRepositoryImpl.decide`.

The code creates a medical record, optionally creates a walk-in ticket, sends a notification, and only then changes the request status. `decide` updates by ID without requiring the current state to remain `pending`. Concurrent admins or retries can both act on the same request.

Impact: duplicate referrals, queue tickets, records, and notifications can be created; failures can leave a referral performed while its request remains pending.

Fix: use one transactional/idempotent backend command that conditionally claims a pending request and creates all dependent records once.

#### SEC-ADMIN-08: Invoice administration permits invalid and race-prone status transitions — FIXED

Evidence: `AdminActions.setInvoiceStatus` and `BillingRepositoryImpl.setStatus`.

The repository reads an invoice and then updates it by ID without an expected-current-status predicate. It permits transitions such as paid to cancelled or cancelled to paid and clears/replaces `paidAt` accordingly. Concurrent updates are last-writer-wins.

Impact: financial history can be rewritten, payment state can contradict actual settlement, and concurrent administrators can silently overwrite each other.

Fix: define an allowed transition graph, use conditional atomic updates/versioning, preserve immutable payment events, and require reversal/refund records instead of rewriting settled status.

#### SEC-ADMIN-09: The audit trail is stored with—and erased alongside—the data it is meant to police

Evidence: `AuditLog` and `AuditRepositoryImpl` in `lib/data/db/tables/system.dart` and `lib/data/repositories/system_repository_impl.dart`; `Seeder._wipe` deletes `auditLog`.

“Append-only” is only an application convention. The same local database and privilege domain can modify or delete audit rows, and the built-in reset explicitly removes all of them.

Impact: a privileged or local attacker can destroy forensic evidence, so the log cannot provide tamper-evident accountability.

Fix: stream signed/append-only events to a separately controlled remote audit store with retention controls, sequence/integrity checks, monitoring, and restricted deletion authority.

### P2 — Medium

#### SEC-ADMIN-10: AI provider configuration lacks validation, separation of duties, and change auditing

Evidence: `AiSettingsScreen`, `SettingsController`, `AiKeyStore`, and `capacity_forecast.dart`.

Any administrator can replace/remove the device-wide Gemini key and submit an arbitrary model identifier without reauthentication, allowlisting, or audit. The key is correctly stored in secure storage and sent in a header, but configuration integrity is not protected.

Impact: a compromised admin session can disable AI, consume a different model/cost tier, or replace a shared credential without traceability.

Fix: allowlist approved models, validate lengths/characters, apply step-up authentication and a dedicated configuration permission, and audit key rotation without logging the key.

#### SEC-ADMIN-11: Department deletion uses a check-then-delete sequence without a transaction

Evidence: `DepartmentRepositoryImpl.delete` in `lib/data/repositories/patient_repository_impl.dart`.

Staff and appointment references are checked first, then the department is deleted separately. A concurrent assignment between those operations can invalidate the check.

Impact: orphaned references or inconsistent authorization/scheduling scope may be created.

Fix: enforce foreign keys and deletion policy in the database, and perform the check plus delete in one transaction or conditional operation.

#### SEC-ADMIN-12: Admin broadcasts have no payload limits or operational safeguards

Evidence: `AdminActions.broadcast` and `NotificationRepositoryImpl.broadcast`.

Title/body sizes are unbounded, and a single command inserts one notification per active patient/staff user. There is no rate limit, idempotency key, preview/approval workflow, or cancellation protection.

Impact: repeated or oversized broadcasts can flood users, grow the database rapidly, expose sensitive text on lock screens, and cause resource exhaustion at scale.

Fix: enforce strict length/rate/recipient limits, idempotency, preview and approval for large audiences, generic lock-screen-safe content, and scalable queued delivery.

#### SEC-ADMIN-13: The audit viewer silently hides events older than the newest 200

Evidence: `auditLogProvider` in `lib/features/admin/application/admin_providers.dart` uses `AuditQuery(limit: 200)`; the UI has no pagination or complete export.

Impact: high event volume can push relevant evidence out of the only admin view, impairing investigations and compliance review.

Fix: implement cursor pagination, server-side filters, retention-aware export, and alerts for high-risk events rather than relying on a fixed recent window.

### Verified protections already present

- The router redirects non-admin sessions away from `/admin` routes.
- The Gemini API key uses platform secure storage and is sent in an HTTP header, not a URL query parameter.
- Department deletion refuses known departments that already have staff or appointments assigned.
- Schedule-template replacement is transactional and rejects overlapping time blocks.
- Patient invoice payment paths enforce patient ownership and valid unpaid state.
- The reseed UI displays a destructive confirmation warning, although that is not sufficient protection for production data.

### Phase 4 result

Found 13 admin security findings: P0: 3, P1: 6, P2: 4.

Next planned phase: **cross-cutting security review of storage, database schema, dependencies, platform configuration, logging, backups, and release hardening**.

---

## Phase 5 — Cross-cutting storage, platform, and release security

### P0 — Critical

#### SEC-XCUT-01: The Android release build is signed with the debug key — FIXED

Evidence: `android/app/build.gradle.kts` assigns `signingConfigs.getByName("debug")` to the `release` build type.

The debug signing key is not an appropriate production trust identity and is commonly available/predictable in development environments.

Impact: release authenticity, secure upgrade ownership, and distribution trust are compromised. A build signed by an exposed debug key may be impersonated or replaced by another APK signed with that key.

Fix: create a protected production keystore, load credentials only from the CI secret store, configure release signing separately, restrict signing access, and rotate/reissue before any production distribution.

#### SEC-XCUT-02: The complete clinical database is stored without application-level encryption — PARTIALLY FIXED

Evidence: `lib/data/db/app_database.dart` opens a normal Drift/SQLite database through `driftDatabase`; no SQLCipher, encrypted VFS, field encryption, or database key management is configured.

The database contains identity data, national IDs, password hashes/salts, diagnoses, notes, lab values, medications, messages, invoices, family links, and audit events.

Impact: filesystem access through a compromised/rooted device, desktop profile access, extracted backup, malware, or forensic acquisition exposes the entire clinic dataset at rest.

Fix: do not place an organization-wide database on clients. Store authoritative PHI in an access-controlled backend; encrypt necessary offline data with platform-keystore-protected keys, minimize its scope, and define key rotation and secure deletion.

Implemented (native only): the database uses SQLite3MultipleCiphers (ChaCha20-Poly1305) keyed by a random 256-bit key in platform secure storage; existing plaintext databases are encrypted in place on first open. Web remains unencrypted (SEC-XCUT-03), and moving authoritative data to a backend is still required.

#### SEC-XCUT-03: The web build stores the entire multi-user database in browser-controlled OPFS/IndexedDB

Evidence: `AppDatabase._webOptions` in `lib/data/db/app_database.dart` and `web/DRIFT_WEB.md`.

The web app persists the same database used by patients, staff, and admins in the browser. Authorization and password verification also execute in that client. Browser-profile access, injected same-origin script, malicious extensions, devtools, or copied site storage can read or alter all records directly. This compounds `SEC-AUTH-01`.

Impact: a single client compromise discloses or modifies the entire organization’s PHI, credentials, billing data, roles, and audit trail—not merely the signed-in user's cached data.

Fix: use a server-side database and server-enforced authorization. Browser storage should contain only minimal, user-scoped, short-lived encrypted cache data; deploy a strict origin and content security policy.

### P1 — High

#### SEC-XCUT-04: Android backups can include PHI because backup is not explicitly disabled or scoped — FIXED

Evidence: `android/app/src/main/AndroidManifest.xml` has no `android:allowBackup`, `android:fullBackupContent`, or `android:dataExtractionRules` policy.

The app therefore relies on platform defaults while storing its clinical database and preferences in app data.

Impact: PHI and password hashes may be copied into device/cloud backup and migration channels outside the app's authorization, retention, and deletion controls.

Fix: disable backup for sensitive local data or define explicit modern and legacy backup rules excluding databases, preferences, caches, and secure material; test backup/restore behavior on supported Android versions.

#### SEC-XCUT-05: The AI credential can be compiled into distributable client binaries — FIXED

Evidence: `lib/services/ai/ai_key_store.dart` uses `String.fromEnvironment('GEMINI_API_KEY')` as a fallback with no release-build prohibition.

`--dart-define` is build-time configuration, not secret storage. A key embedded in a shipped web/mobile/desktop client can be extracted or used by an attacker independently of the application.

Impact: credential theft can cause unauthorized model usage, cost/quotas exhaustion, and abuse attributed to the clinic's project.

Fix: reject embedded API keys in production builds. Proxy approved AI requests through a backend that authenticates users, authorizes purpose, rate-limits usage, protects the provider credential, and minimizes PHI.

#### SEC-XCUT-06: There is no recoverable backup or disaster-recovery path for the authoritative local database

Evidence: the database connection, repository layer, and project documentation contain no encrypted backup, restore, replication, point-in-time recovery, or integrity-verification workflow.

Impact: device loss, browser storage eviction, uninstall, corruption, migration failure, or the destructive seed paths can permanently remove the only copy of clinical and financial records.

Fix: move authoritative data to a managed backend with encrypted versioned backups, tested restore procedures, retention objectives, integrity checks, and documented RPO/RTO. Client caches must be disposable.

#### SEC-XCUT-07: Database foreign keys do not enforce user-role or clinical-domain invariants

Evidence: tables in `lib/data/db/tables/` reference the generic `Users.id` for fields such as `patientId`, `staffId`, `prescriberId`, and admin actors. The schema cannot ensure that the referenced user has the required role. Many clinical numeric/status invariants also have no database checks.

Impact: malformed, compromised, or future code can attach records to the wrong account type, attribute actions to patients as clinicians/admins, or persist impossible clinical/financial values. Once stored, downstream authorization and safety logic may trust corrupted relationships.

Fix: model role-specific principals/relationships server-side, enforce constraints and allowed state transitions at the database/service boundary, and add invariant-validation migration tests.

#### SEC-XCUT-08: The project depends on an explicitly end-of-life SQLite native package

Evidence: `pubspec.yaml` declares `sqlite3_flutter_libs: ^0.6.0+eol` and comments it as part of the database stack.

Impact: an EOL native dependency may stop receiving security and compatibility maintenance, increasing future exposure in the component that parses and stores all sensitive data.

Fix: migrate to the currently maintained SQLite packaging recommended by Drift/sqlite3, verify platform binaries and licenses, run dependency/security scanning in CI, and keep the lockfile reviewed and updated.

### P2 — Medium

#### SEC-XCUT-09: Sensitive screens remain visible in screenshots and app-switcher snapshots

Evidence: no Android `FLAG_SECURE`, iOS background privacy overlay, or equivalent sensitive-screen protection exists in `android/`, `ios/`, or `lib/`.

Impact: charts, diagnoses, messages, IDs, and admin information can appear in screenshots, screen recordings, or recent-app previews, including on shared devices.

Fix: obscure sensitive content when backgrounded, provide policy-driven screenshot protection for clinical/admin screens, and balance accessibility/support needs explicitly.

#### SEC-XCUT-10: The web entry point defines no Content Security Policy — PARTIALLY FIXED

Evidence: `web/index.html` has no CSP meta policy, and `web/DRIFT_WEB.md` documents COOP/COEP hosting headers but no CSP or related production security headers.

Impact: if script injection is introduced elsewhere or hosting is misconfigured, arbitrary same-origin script can access the browser-resident clinical database. The missing defense is especially consequential because of `SEC-XCUT-03`.

Fix: deploy a tested header-based CSP with restrictive `default-src`, `script-src`, `connect-src`, `worker-src`, `object-src`, and framing policy; also configure HSTS, `nosniff`, referrer policy, and permissions policy at the host.

#### SEC-XCUT-11: Startup exposes raw exception text to unauthenticated users — FIXED

Evidence: the bootstrap failure UI in `lib/app/router.dart` renders `'${bootstrap.error}'` inside an expandable “technical details” section.

Impact: database, migration, filesystem, plugin, or platform errors may reveal internal schema names, paths, implementation details, or environment information before authentication.

Fix: show a correlation/reference ID and sanitized message in release builds; send detailed diagnostics to a privacy-safe restricted channel and retain raw details only in debug builds.

#### SEC-XCUT-12: The Android production manifest lacks network permission while security-sensitive AI features expect HTTPS access — FIXED

Evidence: `android/app/src/main/AndroidManifest.xml` has no `INTERNET` permission; it appears only in `src/debug` and `src/profile`, while Gemini clients are included in production code.

Impact: release AI operations fail even though administrators may configure a key and enable real AI. Silent fallback behavior can cause users to mistake mock/generated local output for a live protected service and undermines availability controls.

Fix: either add the permission intentionally for production with documented network/data handling, or compile out live AI and its credential UI. Clearly label fallback output and audit provider failures.

#### SEC-XCUT-13: Vendored web database binaries have provenance notes but no enforced integrity verification

Evidence: `web/sqlite3.wasm` and `web/drift_worker.js` are committed binaries; `web/DRIFT_WEB.md` records source/version but no checksum verification or reproducible validation step exists in CI.

Impact: accidental or malicious replacement may execute unreviewed code in the origin that can access all browser-held health data.

Fix: pin expected cryptographic hashes, verify them in CI/build scripts against trusted release artifacts, document the update process, and review binary changes separately.

#### SEC-XCUT-14: Sensitive data has no defined retention or secure-deletion lifecycle

Evidence: database tables and repositories provide broad creation and reset behavior but no per-record retention policy, account erasure workflow, archival boundary, or cryptographic deletion mechanism for PHI, messages, AI logs, feedback, and reset identifiers.

Impact: data can remain indefinitely beyond its operational/legal need, increasing breach scope and making deletion/consent obligations difficult to satisfy.

Fix: define retention by data class and jurisdiction, implement authorized deletion/anonymization with legal holds and audit evidence, and ensure backups/caches age out consistently.

### Verified protections already present

- SQLite foreign-key enforcement is explicitly enabled on database open.
- Database schema upgrades run in a transaction.
- User emails are unique, and a partial unique index protects non-null national IDs.
- Passwords use random salts, PBKDF2-HMAC-SHA256, bounded stored iteration counts, and constant-time hash comparison.
- The application has a 24-minute inactivity monitor and does not restore authenticated sessions after a cold start.
- `pubspec.lock` pins resolved hosted packages with SHA-256 package hashes.
- The full payment card number and CVC are not persisted.
- AI endpoints use HTTPS with connection/receive timeouts, and API keys are placed in headers.

### Phase 5 result

Found 14 cross-cutting security findings: P0: 3, P1: 5, P2: 6.

### Full security-audit result

Across all five phases, the review documented **70 findings**: P0: 14, P1: 30, P2: 26.

The application should be treated as a local/demo prototype, not a production healthcare security architecture, until the P0 authorization, storage, destructive-reset, web trust-boundary, and release-signing findings are resolved and independently tested.
