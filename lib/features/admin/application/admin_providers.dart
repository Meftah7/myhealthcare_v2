/// Admin providers: user directory, departments, audit log, system stats
/// (P5-14, P5-15, P5-17).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../domain/repositories/system_repository.dart';

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
