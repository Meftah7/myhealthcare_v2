/// Admin providers: user directory, departments, audit log, system stats
/// (P5-14, P5-15, P5-17).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
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

final auditLogProvider = FutureProvider<List<AuditEntry>>((ref) async {
  return _unwrap(
    await ref
        .watch(auditRepositoryProvider)
        .query(const AuditQuery(limit: 200)),
  );
});

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
  return _unwrap(
    await ref
        .watch(aiUsageRepositoryProvider)
        .recent(feature: feature, limit: 200),
  );
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

  Future<Result<Staff>> createStaff({
    required String fullName,
    required String email,
    required String temporaryPassword,
    String? specialty,
    String? departmentId,
    String? jobTitle,
  }) async {
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

  Future<void> setActive({required String id, required bool active}) async {
    await _ref.read(userRepositoryProvider).setActive(id: id, active: active);
    _invalidateUsers();
  }

  Future<Result<void>> resetPassword({
    required String id,
    required String newPassword,
  }) async {
    final r = await _ref
        .read(userRepositoryProvider)
        .resetPassword(id: id, newPassword: newPassword);
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
    final adminId = _ref.read(currentUserProvider)?.id;
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
          ),
        );
    if (r case Ok(:final value)) {
      await _ref
          .read(auditRepositoryProvider)
          .record(
            action: 'appointment.book.admin',
            entityType: 'appointment',
            entityId: value.id,
            actorUserId: adminId,
          );
      await _ref
          .read(notificationRepositoryProvider)
          .send(
            NewNotification(
              recipientId: patientId,
              category: NotificationCategory.appointment,
              title: 'Appointment booked for you',
              body:
                  'The clinic booked you a visit on '
                  '${fmtDateTime(value.slotStart)}'
                  '${value.ticketTag == null ? '' : ' · ticket ${value.ticketTag}'}.',
            ),
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
    final adminId = _ref.read(currentUserProvider)?.id;
    final trimmedReason = reason.trim();
    final r = await _ref
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
          ),
        );
    if (r case Ok(:final value)) {
      await _ref
          .read(auditRepositoryProvider)
          .record(
            action: external ? 'patient.refer.external' : 'patient.refer.dept',
            entityType: 'medical_record',
            entityId: value.id,
            actorUserId: adminId,
            detail: destination,
          );

      String notice;
      if (external) {
        notice =
            'To $destination. Reason: $trimmedReason. A referral letter is in '
            'your Records.';
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
                      ))
                  .valueOrNull;
        notice = ticket == null
            ? 'To the $destination department. Reason: $trimmedReason.'
            : 'To the $destination department — walk-in ticket ${ticket.ticketTag}. '
                  'Please proceed to the $destination desk.';
      }

      await _ref
          .read(notificationRepositoryProvider)
          .send(
            NewNotification(
              recipientId: patientId,
              category: NotificationCategory.appointment,
              title: 'You have been referred',
              body: notice,
            ),
          );
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
    final adminId = _ref.read(currentUserProvider)?.id ?? '';
    final r = await referPatient(
      patientId: request.patientId,
      destination: destination,
      external: external,
      reason: request.reason,
      departmentId: departmentId,
      sourceAppointmentId: request.appointmentId,
    );
    if (r.isOk) {
      await _ref
          .read(referralRequestRepositoryProvider)
          .decide(
            id: request.id,
            status: ReferralRequestStatus.actioned,
            adminId: adminId,
            note: decisionNote,
          );
      _ref.invalidate(pendingReferralRequestsProvider);
    }
    return r;
  }

  Future<Result<ReferralRequest>> rejectReferralRequest({
    required String id,
    String? note,
  }) async {
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

  /// Admin changes an invoice's status (mark paid / cancel).
  Future<Result<Invoice>> setInvoiceStatus({
    required String id,
    required InvoiceStatus status,
  }) async {
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
  Future<void> setFeedbackStatus({
    required String id,
    required FeedbackStatus status,
  }) async {
    final adminId = _ref.read(currentUserProvider)?.id;
    await _ref
        .read(feedbackRepositoryProvider)
        .setStatus(id: id, status: status, adminId: adminId);
    _ref
      ..invalidate(feedbackProvider)
      ..invalidate(openFeedbackCountProvider);
  }

  Future<Result<void>> deleteDepartment(String id) async {
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
