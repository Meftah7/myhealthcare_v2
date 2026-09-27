# Verified Bug Audit

Re-checked: 2026-09-27

This file replaces the earlier speculative audit. Every item below was checked against the current implementation. Confirmed defects are separated from product/architecture risks.

## Summary

- Confirmed defects: 18; fixed: 18; open: 0
- Product/architecture risks: 6
- Assessment: **REQUEST CHANGES**

## Confirmed defects

### P0 — Critical

#### 1. Linked-account booking reads patient data before authorization — FIXED

Evidence: `lib/features/booking/application/booking_providers.dart:105-118`, `:199-219`

The booking subject providers load any `targetId` patient and appointment history. The active-link/manage check occurs only later in `confirm()`. A patient can alter the `for` query parameter and trigger reads of another patient's profile/history before confirmation is rejected.

Fix: enforce the active manage-link guard before loading either provider.

Resolution (2026-09-27): both booking-subject providers now require an active
`manage` link before reading the target patient's profile or appointment
history. A regression test verifies that view-only access fails during slot
ranking, before either protected read. Formatting completed; the focused test
and analyzer commands produced no output and did not finish, so runtime
verification remains pending until the Flutter toolchain hang is resolved.

### P1 — High

#### 2. Appointment operations do not enforce a state machine — FIXED

Evidence: `lib/data/repositories/appointment_repository_impl.dart:573-649`

Clinician ownership is checked, but `updateStatus()` accepts any status and the specialized methods overwrite status without validating the current state. Cancelled appointments can be completed or moved in progress; completed appointments can be moved back to `noShow`.

Fix: enforce allowed source-to-target transitions transactionally.

#### 3. Consultation completion is not atomic — FIXED

Evidence: `lib/features/consultation/application/consultation_providers.dart:210-286`

Visit note, prescriptions, notifications, appointment completion, walk-in resolution, and audit are separate commits. A later failure leaves partial clinical data; retrying can duplicate records/prescriptions.

Fix: move completion into one transactional, idempotent workflow.

#### 4. Card invoice payments have a check-then-update race — FIXED

Evidence: `lib/data/repositories/billing_repository_impl.dart:97-197`

Both card-payment methods read invoice status and later update by invoice ID outside a transaction. Concurrent calls can both observe unpaid and report success. The wallet path already uses the safer conditional transactional pattern.

Fix: transactionally update only where status is still unpaid and require one affected row.

#### 5. Admin-created appointments do not schedule reminders — FIXED

Evidence: `lib/features/admin/application/admin_providers.dart:319-372`

The admin flow books, audits, and notifies, but never calls the reminder scheduler. Reminder creation is left to other booking callers.

Fix: centralize booking side effects or schedule reminders in this flow.

#### 6. Referral action can create a referral while leaving its request pending — FIXED

Evidence: `lib/features/admin/application/admin_providers.dart:457-484`

`referPatient()` runs first. The subsequent `decide()` result is ignored, and the successful medical record is returned even if request transition fails. Retrying can duplicate records/tickets/notifications.

Fix: make creation and decision atomic, propagate failure, and enforce one result per request.

#### 7. Reset/activation reports success for nonexistent users — FIXED

Evidence: `lib/data/repositories/auth_repository_impl.dart:436-462`

`setActive()` and `resetPassword()` ignore affected-row count, so stale IDs return success.

Fix: require exactly one affected row or return `NotFoundFailure`.

#### 8. Password reset/deactivation does not revoke active sessions — FIXED

Evidence: `lib/features/auth/application/session.dart`, `lib/data/repositories/auth_repository_impl.dart:436-462`

The session persists a local user ID. Password or active-state changes do not invalidate an already-running session.

Fix: add session generation/revocation and terminate affected sessions immediately.

#### 9. Schedule replacement ignores existing appointments — FIXED

Evidence: `lib/data/repositories/appointment_repository_impl.dart:198-253`

Templates are replaced atomically but existing bookings are not checked. Appointments can become off-grid while new booking/rescheduling requires exact grid membership.

Fix: reject conflicts or require explicit rescheduling of affected appointments.

#### 10. Admin commands do not enforce the admin role — FIXED

Evidence: `lib/features/admin/application/admin_providers.dart`

Commands generally use the current user only for audit metadata and do not fail unless the role is admin. Router gating is UI navigation, not command-layer authorization.

Fix: add a fail-closed admin guard to every command or an authorization-aware service.

#### 11. Task and risk mutations do not verify ownership — FIXED

Evidence: `lib/data/repositories/task_repository_impl.dart:84-89`, `:183-193`

Task status updates use only task ID. Risk acknowledgement accepts any staff ID and updates by flag ID without assignment/department validation or affected-row checks.

Fix: include authenticated actor and ownership policy in update predicates.

### P2 — Medium

#### 12. Forgot-password UI reports success after storage failure — FIXED

Evidence: `lib/features/auth/presentation/forgot_password_screen.dart:53-59`

The returned `Result` is ignored and the confirmation page is always shown. Unknown accounts should remain generic, but infrastructure errors need a retryable error.

#### 13. Password-reset requests are unbounded duplicates — FIXED

Evidence: `lib/data/repositories/auth_repository_impl.dart:230-248`

Every submission inserts a new unresolved row. There is no cooldown, deduplication, or rate limit.

#### 14. Reset-request resolution can use an invalid actor and hides failure — FIXED

Evidence: `lib/features/admin/application/admin_providers.dart:299-314`

The flow uses `currentUser?.id ?? ''`, ignores the resolution result, and returns reset success. A missing session or failed resolution can leave the request pending.

Fix: require a valid admin actor and perform reset/resolution atomically.

#### 15. Rescheduling silently changes appointment duration — FIXED

Evidence: `lib/features/appointments/presentation/appointments_screen.dart:355-380`

Rescheduling uses `newEnd: slot.end` rather than preserving `appt.duration`. A visit changes duration when the selected template slot differs.

Fix: offer compatible slots or explicitly confirm the duration change.

#### 16. Failed record imports leave orphan PDF files — FIXED

Evidence: `lib/features/timeline/presentation/import_record_sheet.dart:128-193`

The PDF is copied before the record insert. On `Err`, the copied sensitive file is not removed.

Fix: delete it on failure or use a cleanup-aware persistence service.

#### 17. Invoice status permits invalid transitions — FIXED

Evidence: `lib/data/repositories/billing_repository_impl.dart:63-82`

`setStatus()` accepts any status and rewrites `paidAt`. It can reopen paid/cancelled invoices or mark one paid without payment evidence.

Fix: use explicit settle, cancel, and reverse commands with transition rules.

#### 18. Currency uses floating-point storage/calculation — FIXED

Evidence: billing entities/tables and `lib/data/repositories/billing_repository_impl.dart:328-336`

Invoice, tax, wallet transaction, and balance values use `double`, allowing minor-unit rounding drift.

Fix: store integer fils/cents and convert only for display.

## Product and architecture risks

These are verified properties, but release severity depends on whether this is a local academic demo or a production healthcare system.

1. **Unencrypted health database:** Drift/SQLite stores IDs, records, vitals, medications, messages, and billing data without database encryption.
2. **Client-local security:** credentials, roles, authorization, and session state are client-local and are not a production trust boundary.
3. **No email verification:** no verification token, status, or confirmation route exists. This is a missing feature unless verified ownership is required.
4. **Admin-mediated recovery:** forgot password intentionally creates an admin queue, not a self-service reset token. A manual identity-verification policy is required.
5. **No explicit clinic timezone:** schedules use local minutes and appointments use ordinary `DateTime`; multi-timezone/DST deployment is unsafe.
6. **Simulated card charging:** format validation directly updates local payment state; no payment gateway authorization exists.

## Earlier findings removed after verification

- Linked-account views and manage writes do re-check active links.
- Patient cancel/reschedule checks appointment ownership.
- Staff appointment mutations now check clinician ownership through `_ownedByStaff`.
- Wallet invoice payment is transactional and conditionally settles unpaid invoices.
- Notification reads include recipient ownership.
- Department deletion checks staff and appointment references.
- Schedule templates reject invalid lengths and overlap.
- Booking runs in a Drift transaction; the earlier blanket concurrency claim was not proven for the current single local connection.
- Exact `DateTime` slot equality is intentional for repository-generated slots; no failing path was demonstrated.
- Unsupported cache, analytics, AI, and hypothetical future-feature claims were removed.

## Verification status

- Implementation pass completed on 2026-09-27: all 18 confirmed defects now
  have code fixes. Added/updated regression coverage for linked booking access,
  terminal appointment states, invoice transitions, and ownership-aware task
  mutations.
- Consultation completion and referral approval now use database transactions;
  password reset and request resolution share one transaction; active sessions
  watch account-row changes and terminate after reset/deactivation.
- Monetary writes and balance calculations are normalized through integer BHD
  fils. Existing `double` entity fields remain for API compatibility, but
  persisted values and arithmetic are quantized at the repository boundary.
- Static verification covered auth, booking, appointments, consultation, linked accounts, staff mutations, billing, notifications, imports, tasks, referrals, departments, admin commands, and routing.
- Focused `dart analyze` and `flutter test --no-pub` runs were attempted after
  implementation but stalled before producing output and were stopped. Diff
  validation passes; this report does not claim a clean analyzer/test run.
- Existing uncommitted source changes were preserved.

## Recommended next step

Resolve the local Flutter/Dart toolchain stall, then run the complete analyzer
and test suite before release.
