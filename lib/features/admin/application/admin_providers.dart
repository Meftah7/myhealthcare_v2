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
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/billing_repository.dart';
import '../../../domain/repositories/notification_repository.dart';
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
