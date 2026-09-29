/// Admin providers: user directory, departments, audit log, system stats
/// (P5-14, P5-15, P5-17).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/data/contracts.dart';
import '../../../core/di.dart';
import '../../../core/failures.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/appointment_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/billing_repository.dart';
import '../../../domain/repositories/consultation_repository.dart';
import '../../../domain/repositories/notification_repository.dart';
import '../../../domain/repositories/record_repository.dart';
import '../../../domain/repositories/system_repository.dart';
import '../../auth/application/session.dart';

final usersByRoleProvider = FutureProvider.family<List<User>, UserRole>((
  ref,
  role,
) async {
  return _unwrap(await ref.watch(userRepositoryProvider).byRole(role));
});

final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  return _unwrap(await ref.watch(departmentRepositoryProvider).all());
});

/// Active staff in a department — the "choose a doctor" list for the admin's
/// book-for-patient sheet. Nurses are excluded (they don't take appointments).
final adminDepartmentDoctorsProvider =
    FutureProvider.family<List<Staff>, String>((ref, departmentId) async {
      final staff = _unwrap(
        await ref.watch(userRepositoryProvider).staffInDepartment(departmentId),
      );
      return staff.where((s) => s.isDoctor && s.user.isActive).toList();
    });

/// A staff member's weekly working blocks — the admin schedule editor.
final staffScheduleTemplatesProvider =
    FutureProvider.family<List<ScheduleTemplate>, String>((ref, staffId) async {
      return _unwrap(
        await ref.watch(appointmentRepositoryProvider).templatesFor(staffId),
      );
    });

class ScheduleTemplateActions {
  ScheduleTemplateActions(this._ref);
  final Ref _ref;

  Future<Result<List<ScheduleTemplate>>> save({
    required String staffId,
    required List<NewScheduleTemplate> templates,
  }) async {
    final actor = _ref.read(currentUserProvider);
    if (actor == null || !actor.isAdmin || !actor.isActive) {
      return const Err(AuthFailure('Administrator access is required.'));
    }
    final result = await _ref
        .read(appointmentRepositoryProvider)
        .setTemplates(staffId: staffId, templates: templates);
    if (result.isOk) _ref.invalidate(staffScheduleTemplatesProvider(staffId));
    return result;
  }
}

final scheduleTemplateActionsProvider = Provider<ScheduleTemplateActions>(
  ScheduleTemplateActions.new,
);

/// Pending doctor→admin referral requests — the admin queue + a dashboard
/// count.
final pendingReferralRequestsProvider = FutureProvider<List<ReferralRequest>>((
  ref,
) async {
  return _unwrap(await ref.watch(referralRequestRepositoryProvider).pending());
});

final pendingReferralRequestCountProvider = Provider<int>((ref) {
  return ref.watch(pendingReferralRequestsProvider).valueOrNull?.length ?? 0;
});

/// requesting staff id → display name, for the referral-request queue rows.
final referralRequesterNamesProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final staff = _unwrap(
    await ref.watch(userRepositoryProvider).byRole(UserRole.staff),
  );
  return {for (final s in staff) s.id: clinicianName(s.fullName)};
});

/// Hospitals the admin can refer a patient out to. A short fixed list for the
/// demo — the same facilities the seeded external records use.
const kReferralHospitals = [
  'Salmaniya Medical Complex',
  'King Hamad University Hospital',
  'BDF Hospital',
  'Bahrain Specialist Hospital',
  'Al Kindi Specialised Hospital',
  'Ibn Al-Nafees Hospital',
];

/// How many pages of the audit log are shown ("Load more" adds one).
final auditLogPagesProvider = StateProvider<int>((ref) => 1);

/// The audit log, paged — it says when older entries exist rather than
/// silently stopping at a cap.
final auditLogPageProvider = FutureProvider<Page<AuditEntry>>((ref) async {
  final pages = ref.watch(auditLogPagesProvider);
  final repo = ref.watch(auditRepositoryProvider);
  var request = const PageRequest();
  Page<AuditEntry>? all;
  for (var i = 0; i < pages; i++, request = request.next) {
    final page = _unwrap(
      await repo.queryPage(const AuditQuery(), page: request),
    );
    all = all == null ? page : all.append(page);
    if (!page.hasMore) break;
  }
  return all!;
});

final auditLogProvider = FutureProvider<List<AuditEntry>>(
  (ref) async => (await ref.watch(auditLogPageProvider.future)).items,
);

/// User feedback / issue reports, optionally filtered by status.
final feedbackProvider =
    FutureProvider.family<List<UserFeedback>, FeedbackStatus?>((
      ref,
      status,
    ) async {
      return _unwrap(
        await ref.watch(feedbackRepositoryProvider).all(status: status),
      );
    });

/// Count of open feedback reports — a dashboard stat.
final openFeedbackCountProvider = FutureProvider<int>((ref) async {
  final list = await ref.watch(feedbackProvider(FeedbackStatus.open).future);
  return list.length;
});

/// The AI usage log, optionally filtered to one feature.
final aiUsageProvider = FutureProvider.family<List<AiUsageEntry>, AiFeature?>((
  ref,
  feature,
) async {
  // The newest page; the screen states the limit (PageLimits.maxSize).
  final page = _unwrap(
    await ref
        .watch(aiUsageRepositoryProvider)
        .recentPage(
          feature: feature,
          page: const PageRequest(size: PageLimits.maxSize),
        ),
  );
  return page.items;
});

class SystemStats {
  const SystemStats({
    required this.patients,
    required this.staff,
    required this.admins,
    required this.departments,
    required this.openFlags,
  });

  final int patients;
  final int staff;
  final int admins;
  final int departments;
  final int openFlags;
}

/// Every invoice, optionally filtered by status — the admin billing overview.
final allInvoicesProvider =
    FutureProvider.family<List<Invoice>, InvoiceStatus?>((ref, status) async {
      return _unwrap(
        await ref.watch(billingRepositoryProvider).all(status: status),
      );
    });

/// Payment history for one invoice — charges, desk payments and refunds.
final invoicePaymentsProvider =
    FutureProvider.family<List<PaymentTransaction>, String>((
      ref,
      invoiceId,
    ) async {
      return _unwrap(
        await ref
            .watch(billingRepositoryProvider)
            .transactions(invoiceId: invoiceId),
      );
    });

/// User IDs with an unresolved password-reset request — backs the "reset
/// requested" badge on their row in User management.
final pendingPasswordResetUserIdsProvider = FutureProvider<Set<String>>((
  ref,
) async {
  return _unwrap(
    await ref
        .read(userRepositoryProvider)
        .userIdsWithPendingPasswordResetRequests(),
  );
});

/// Count of unpaid (pending) invoices — a dashboard stat.
final unpaidInvoiceCountProvider = FutureProvider<int>((ref) async {
  final list = await ref.watch(allInvoicesProvider(null).future);
  return list.where((i) => i.status == InvoiceStatus.pending).length;
});

/// Every appointment in a ±1 year window — the admin all-appointments view.
final allAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final now = DateTime.now();
  return _unwrap(
    await ref
        .watch(appointmentRepositoryProvider)
        .inRange(
          now.subtract(const Duration(days: 365)),
          now.add(const Duration(days: 365)),
        ),
  );
});

/// Patient id → full name, for the cross-patient admin lists.
final adminPatientNamesProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final patients = _unwrap(
    await ref.watch(userRepositoryProvider).byRole(UserRole.patient),
  );
  return {for (final p in patients) p.id: p.fullName};
});

/// Staff id → full name, for the admin appointment list.
final adminStaffNamesProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final staff = _unwrap(
    await ref.watch(userRepositoryProvider).byRole(UserRole.staff),
  );
  return {for (final s in staff) s.id: clinicianName(s.fullName)};
});

final systemStatsProvider = FutureProvider<SystemStats>((ref) async {
  final users = ref.watch(userRepositoryProvider);
  final patients = _unwrap(await users.byRole(UserRole.patient));
  final staff = _unwrap(await users.byRole(UserRole.staff));
  final admins = _unwrap(await users.byRole(UserRole.admin));
  final depts = _unwrap(await ref.watch(departmentRepositoryProvider).all());
  final flags = _unwrap(
    await ref.watch(riskRepositoryProvider).unacknowledged(),
  );
  return SystemStats(
    patients: patients.length,
    staff: staff.length,
    admins: admins.length,
    departments: depts.length,
    openFlags: flags.length,
  );
});

class AdminActions {
  AdminActions(this._ref);
  final Ref _ref;

  /// Idempotency keys for in-flight consequential actions, kept until they
  /// succeed so a retry is the same action, not a second one.
  final Map<String, IdempotencyKey> _attempts = {};

  Result<T>? _denyUnlessAdmin<T>() {
    final actor = _ref.read(currentUserProvider);
    if (actor == null || !actor.isAdmin || !actor.isActive) {
      return const Err(AuthFailure('Administrator access is required.'));
    }
    return null;
  }

  Future<Result<Staff>> createStaff({
    required String fullName,
    required String email,
    required String temporaryPassword,
    String? specialty,
    String? departmentId,
    String? jobTitle,
  }) async {
    final denied = _denyUnlessAdmin<Staff>();
    if (denied != null) return denied;
    final result = await _ref
        .read(userRepositoryProvider)
        .createStaff(
          fullName: fullName,
          email: email,
          temporaryPassword: temporaryPassword,
          specialty: specialty,
          departmentId: departmentId,
          jobTitle: jobTitle,
        );
    _invalidateUsers();
    return result;
  }

  Future<Result<Patient>> createPatient({
    required String fullName,
    required String email,
    required String temporaryPassword,
  }) async {
    final denied = _denyUnlessAdmin<Patient>();
    if (denied != null) return denied;
    final result = await _ref
        .read(authRepositoryProvider)
        .registerPatient(
          PatientRegistration(
            fullName: fullName,
            email: email,
            password: temporaryPassword,
          ),
        );
    _invalidateUsers();
    return result;
  }

  Future<Result<User>> createAdmin({
    required String fullName,
    required String email,
    required String temporaryPassword,
  }) async {
    final denied = _denyUnlessAdmin<User>();
    if (denied != null) return denied;
    final result = await _ref
        .read(userRepositoryProvider)
        .createAdmin(
          fullName: fullName,
          email: email,
          temporaryPassword: temporaryPassword,
        );
    _invalidateUsers();
    return result;
  }

  Future<Result<void>> setActive({
    required String id,
    required bool active,
  }) async {
    final denied = _denyUnlessAdmin<void>();
    if (denied != null) return denied;
    final result = await _ref
        .read(userRepositoryProvider)
        .setActive(id: id, active: active);
    _invalidateUsers();
    return result;
  }

  Future<Result<void>> resetPassword({
    required String id,
    required String newPassword,
  }) async {
    final denied = _denyUnlessAdmin<void>();
    if (denied != null) return denied;
    final adminId = _ref.read(currentUserProvider)!.id;
    final r = await _ref
        .read(userRepositoryProvider)
        .resetPasswordAndResolve(
          id: id,
          newPassword: newPassword,
          adminId: adminId,
        );
    if (r.isOk) {
      // Clears the "reset requested" badge — this is the resolution.
      _ref.invalidate(pendingPasswordResetUserIdsProvider);
    }
    return r;
  }

  /// Book a visit on a patient's behalf. Goes straight in as `booked`; the
  /// clinician accepts it from their queue like any other.
  Future<Result<Appointment>> bookForPatient({
    required String patientId,
    required String staffId,
    required DateTime start,
    required Duration duration,
    required VisitType visitType,
    String? departmentId,
    String? reason,
  }) async {
    final denied = _denyUnlessAdmin<Appointment>();
    if (denied != null) return denied;
    final adminId = _ref.read(currentUserProvider)?.id;
    final attempt = '$patientId|$staffId|${start.toIso8601String()}';
    final key = _attempts.putIfAbsent(attempt, IdempotencyKey.generate);
    final r = await _ref
        .read(appointmentRepositoryProvider)
        .book(
          BookingRequest(
            patientId: patientId,
            staffId: staffId,
            start: start,
            end: start.add(duration),
            visitType: visitType,
            departmentId: departmentId,
            reasonText: reason,
            idempotencyKey: key,
            enabledReminderChannels: const {ReminderChannel.push},
            // Recorded with the booking, delivered through the outbox.
            notify: [
              NewNotification(
                recipientId: patientId,
                category: NotificationCategory.appointment,
                title: 'Appointment booked for you',
                body:
                    'The clinic booked you a visit on ${fmtDateTime(start)}. '
                    'Your ticket and room are in Appointments.',
                deepLink: AppRoutes.patientAppointments,
              ),
            ],
          ),
        );
    if (r.isOk) {
      _attempts.remove(attempt);
      await deliverPendingSideEffects(_ref);
    }
    if (r case Ok(:final value)) {
      await _ref
          .read(auditRepositoryProvider)
          .record(
            action: 'appointment.book.admin',
            entityType: 'appointment',
            entityId: value.id,
            actorUserId: adminId,
          );
      _ref.invalidate(allAppointmentsProvider);
    }
    return r;
  }

  /// Refer a patient — to another department inside the clinic, or out to
  /// another hospital. Both land as a `referral` record on the patient's
  /// history and notify the patient. A **department** referral also opens a
  /// walk-in queue ticket in that department; an **external** referral's record
  /// is downloadable by the patient as a referral letter (`sourceFacility` set,
  /// `body` = the reason).
  ///
  /// [departmentId] must be set for a department referral (its walk-in ticket).
  /// [sourceAppointmentId] links back to the visit a doctor requested it from.
  Future<Result<MedicalRecord>> referPatient({
    required String patientId,
    required String destination,
    required bool external,
    required String reason,
    String? departmentId,
    String? sourceAppointmentId,
  }) async {
    final denied = _denyUnlessAdmin<MedicalRecord>();
    if (denied != null) return denied;
    final adminId = _ref.read(currentUserProvider)?.id;
    final trimmedReason = reason.trim();
    // The referral letter, the walk-in ticket (department referrals) and the
    // patient's notice commit together; the notice is then delivered from
    // the outbox. A retry of the same referral returns the same letter.
    final attempt = '$patientId|$destination|$external|$trimmedReason';
    final key = _attempts.putIfAbsent(attempt, IdempotencyKey.generate);
    final r = await Result.guardAsync(
      () => _ref.read(appDatabaseProvider).transaction(() async {
        final record = _unwrap(
          await _ref
              .read(recordRepositoryProvider)
              .add(
                NewRecord(
                  patientId: patientId,
                  recordType: RecordType.referral,
                  title: external
                      ? 'Referral — $destination'
                      : 'Department referral — $destination',
                  occurredAt: DateTime.now(),
                  authorStaffId: adminId,
                  body: trimmedReason,
                  sourceFacility: external ? destination : null,
                  idempotencyKey: key,
                ),
              ),
        );
        await _ref
            .read(auditRepositoryProvider)
            .record(
              action: external
                  ? 'patient.refer.external'
                  : 'patient.refer.dept',
              entityType: 'medical_record',
              entityId: record.id,
              actorUserId: adminId,
              detail: destination,
            );

        String notice;
        if (external) {
          notice =
              'To $destination. Reason: $trimmedReason. A referral letter is '
              'in your Records.';
        } else {
          // Department referral → a walk-in queue ticket.
          final ticket = departmentId == null
              ? null
              : (await _ref
                        .read(walkInTicketRepositoryProvider)
                        .create(
                          NewWalkInTicket(
                            patientId: patientId,
                            departmentId: departmentId,
                            createdByStaffId: adminId ?? patientId,
                            reason: trimmedReason,
                            sourceAppointmentId: sourceAppointmentId,
                          ),
                          idempotencyKey: IdempotencyKey('${key.value}.walkin'),
                        ))
                    .valueOrNull;
          notice = ticket == null
              ? 'To the $destination department. Reason: $trimmedReason.'
              : 'To the $destination department — walk-in ticket '
                    '${ticket.ticketTag}. Please proceed to the $destination '
                    'desk.';
        }

        _unwrap(
          await _ref
              .read(notificationRepositoryProvider)
              .send(
                NewNotification(
                  recipientId: patientId,
                  category: NotificationCategory.appointment,
                  title: 'You have been referred',
                  body: notice,
                ),
              ),
        );
        return record;
      }),
    );
    if (r.isOk) {
      _attempts.remove(attempt);
      await deliverPendingSideEffects(_ref);
      _ref.invalidate(pendingReferralRequestsProvider);
    }
    return r;
  }

  /// The admin queue calls this: run the referral, then close the request.
  Future<Result<MedicalRecord>> actionReferralRequest({
    required ReferralRequest request,
    required String destination,
    required bool external,
    String? departmentId,
    String? decisionNote,
  }) async {
    final denied = _denyUnlessAdmin<MedicalRecord>();
    if (denied != null) return denied;
    final adminId = _ref.read(currentUserProvider)!.id;
    final result = await Result.guardAsync(
      () => _ref.read(appDatabaseProvider).transaction(() async {
        final current = await _ref
            .read(referralRequestRepositoryProvider)
            .pendingForAppointment(request.appointmentId ?? '');
        if (request.appointmentId != null &&
            current.valueOrNull?.id != request.id) {
          throw const ValidationFailure(
            'This referral request is no longer pending.',
          );
        }
        final referral = await referPatient(
          patientId: request.patientId,
          destination: destination,
          external: external,
          reason: request.reason,
          departmentId: departmentId,
          sourceAppointmentId: request.appointmentId,
        );
        if (referral case Err(:final failure)) throw failure;
        final decision = await _ref
            .read(referralRequestRepositoryProvider)
            .decide(
              id: request.id,
              status: ReferralRequestStatus.actioned,
              adminId: adminId,
              note: decisionNote,
            );
        if (decision case Err(:final failure)) throw failure;
        return referral.valueOrNull!;
      }),
    );
    if (result.isOk) {
      _ref.invalidate(pendingReferralRequestsProvider);
    }
    return result;
  }

  Future<Result<ReferralRequest>> rejectReferralRequest({
    required String id,
    String? note,
  }) async {
    final denied = _denyUnlessAdmin<ReferralRequest>();
    if (denied != null) return denied;
    final adminId = _ref.read(currentUserProvider)?.id ?? '';
    final r = await _ref
        .read(referralRequestRepositoryProvider)
        .decide(
          id: id,
          status: ReferralRequestStatus.rejected,
          adminId: adminId,
          note: note,
        );
    if (r.isOk) _ref.invalidate(pendingReferralRequestsProvider);
    return r;
  }

  Future<Result<void>> saveDepartment({
    required String name,
    String? id,
    String? description,
  }) async {
    final denied = _denyUnlessAdmin<void>();
    if (denied != null) return denied;
    final r = await _ref
        .read(departmentRepositoryProvider)
        .upsert(
          Department(
            id: id ?? newId('dept'),
            name: name,
            description: description,
          ),
        );
    _ref.invalidate(departmentsProvider);
    _ref.invalidate(systemStatsProvider);
    return r;
  }

  /// Send a message to every patient / every staff member / everyone.
  Future<Result<int>> broadcast({
    required NotificationAudience audience,
    required NotificationCategory category,
    required String title,
    required String body,
  }) async {
    final denied = _denyUnlessAdmin<int>();
    if (denied != null) return denied;
    final r = await _ref
        .read(notificationRepositoryProvider)
        .broadcast(
          audience: audience,
          category: category,
          title: title,
          body: body,
        );
    if (r.isOk) {
      await _ref
          .read(auditRepositoryProvider)
          .record(
            action: 'notification.broadcast',
            entityType: 'notification',
            detail: '${audience.name}: $title',
          );
    }
    return r;
  }

  /// Raise a bill for a patient — 10% tax, due in 30 days.
  Future<Result<Invoice>> issueInvoice({
    required String patientId,
    required double subtotal,
    String? notes,
  }) async {
    final denied = _denyUnlessAdmin<Invoice>();
    if (denied != null) return denied;
    final r = await _ref
        .read(billingRepositoryProvider)
        .issue(
          NewInvoice(
            patientId: patientId,
            subtotal: subtotal,
            dueDate: DateTime.now().add(const Duration(days: 30)),
            notes: notes,
          ),
        );
    if (r case Ok(:final value)) {
      await _ref
          .read(auditRepositoryProvider)
          .record(
            action: 'invoice.issue',
            entityType: 'invoice',
            entityId: value.id,
          );
    }
    _ref
      ..invalidate(allInvoicesProvider)
      ..invalidate(unpaidInvoiceCountProvider);
    return r;
  }

  void _refreshBilling([String? invoiceId]) {
    _ref
      ..invalidate(allInvoicesProvider)
      ..invalidate(unpaidInvoiceCountProvider);
    if (invoiceId != null) _ref.invalidate(invoicePaymentsProvider(invoiceId));
  }

  /// Record money taken at the desk against an open invoice.
  Future<Result<Invoice>> recordDeskPayment({
    required String invoiceId,
    required String receipt,
    required IdempotencyKey key,
    String? note,
  }) async {
    final denied = _denyUnlessAdmin<Invoice>();
    if (denied != null) return denied;
    final r = await _ref
        .read(billingRepositoryProvider)
        .recordOfflinePayment(
          invoiceId: invoiceId,
          receiptReference: receipt,
          note: note,
          idempotencyKey: key,
        );
    _refreshBilling(invoiceId);
    return r;
  }

  /// Refund part or all of a settled payment.
  Future<Result<PaymentTransaction>> refundPayment({
    required PaymentTransaction payment,
    required double amount,
    required String reason,
    required IdempotencyKey key,
  }) async {
    final denied = _denyUnlessAdmin<PaymentTransaction>();
    if (denied != null) return denied;
    final r = await _ref
        .read(billingRepositoryProvider)
        .refund(
          transactionId: payment.id,
          amount: amount,
          reason: reason,
          idempotencyKey: key,
        );
    _refreshBilling(payment.invoiceId);
    return r;
  }

  /// Ask the provider about every payment whose outcome is unknown.
  Future<Result<int>> reconcilePayments() async {
    final denied = _denyUnlessAdmin<int>();
    if (denied != null) return denied;
    final r = await _ref.read(billingRepositoryProvider).reconcile();
    _refreshBilling();
    return r;
  }

  /// Admin cancels an open invoice.
  Future<Result<Invoice>> setInvoiceStatus({
    required String id,
    required InvoiceStatus status,
  }) async {
    final denied = _denyUnlessAdmin<Invoice>();
    if (denied != null) return denied;
    final r = await _ref
        .read(billingRepositoryProvider)
        .setStatus(id: id, status: status);
    if (r.isOk) {
      await _ref
          .read(auditRepositoryProvider)
          .record(
            action: 'invoice.status.${status.name}',
            entityType: 'invoice',
            entityId: id,
          );
    }
    _ref
      ..invalidate(allInvoicesProvider)
      ..invalidate(unpaidInvoiceCountProvider);
    return r;
  }

  /// Mark a feedback report resolved / re-open it.
  Future<Result<void>> setFeedbackStatus({
    required String id,
    required FeedbackStatus status,
  }) async {
    final denied = _denyUnlessAdmin<void>();
    if (denied != null) return denied;
    final adminId = _ref.read(currentUserProvider)?.id;
    final result = await _ref
        .read(feedbackRepositoryProvider)
        .setStatus(id: id, status: status, adminId: adminId);
    _ref
      ..invalidate(feedbackProvider)
      ..invalidate(openFeedbackCountProvider);
    return result;
  }

  Future<Result<void>> deleteDepartment(String id) async {
    final denied = _denyUnlessAdmin<void>();
    if (denied != null) return denied;
    final r = await _ref.read(departmentRepositoryProvider).delete(id);
    if (r.isOk) {
      await _ref
          .read(auditRepositoryProvider)
          .record(
            action: 'department.delete',
            entityType: 'department',
            entityId: id,
          );
    }
    _ref.invalidate(departmentsProvider);
    _ref.invalidate(systemStatsProvider);
    return r;
  }

  void _invalidateUsers() {
    for (final role in UserRole.values) {
      _ref.invalidate(usersByRoleProvider(role));
    }
    _ref.invalidate(systemStatsProvider);
  }
}

final adminActionsProvider = Provider<AdminActions>(AdminActions.new);

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};
