import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shared_mode.dart';
import '../../core/di.dart';
import '../../core/failures.dart';
import '../../core/utils/ids.dart';
import '../../data/db/app_database.dart';
import '../../data/remote/shared_client.dart';
import '../../data/repositories/appointment_repository_impl.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../services/auth/access_policy.dart';
import '../auth/application/session.dart';

typedef WorkspaceData = Map<String, dynamic>;

/// Bahrain has a fixed UTC+03:00 offset. Dates here are clinic wall dates,
/// converted to UTC only at query boundaries, independent of device timezone.
DateTime clinicDay([DateTime? instant]) {
  final wall = (instant ?? DateTime.now()).toUtc().add(
    const Duration(hours: 3),
  );
  return DateTime.utc(wall.year, wall.month, wall.day);
}

DateTime clinicStart(DateTime day) => DateTime.utc(
  day.year,
  day.month,
  day.day,
).subtract(const Duration(hours: 3));
String clinicDateLabel(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
int fils(num amount) => (amount * 1000).round();

final workspaceRepositoryProvider = Provider(
  (ref) => WorkspaceRepository(
    db: ref.watch(sharedModeProvider) ? null : ref.watch(appDatabaseProvider),
    client: ref.watch(sharedModeProvider)
        ? ref.watch(sharedClientProvider)
        : null,
    access: ref.watch(accessPolicyProvider),
    appointments: ref.watch(appointmentRepositoryProvider),
  ),
);
final workspaceDayProvider = StateProvider<DateTime>((ref) => clinicDay());
final workspacePeriodProvider = StateProvider<int>((ref) => 7);
final workspaceRevenuePeriodProvider = StateProvider<int>((ref) => 7);

/// Refresh aggregates when their source records change. Audit writes are
/// excluded so reading an authorized report cannot cause a refresh loop.
final workspaceChangesProvider = StreamProvider<int>((ref) {
  if (ref.watch(sharedModeProvider)) {
    return Stream<int>.periodic(const Duration(seconds: 30), (tick) => tick);
  }
  final db = ref.watch(appDatabaseProvider);
  const sources = {
    'users',
    'patient_profiles',
    'staff_profiles',
    'staff_credentials',
    'appointments',
    'encounter_participants',
    'signed_notes',
    'medications',
    'staff_tasks',
    'risk_flags',
    'referral_requests',
    'payment_transactions',
    'invoices',
    'feedbacks',
    'clinic_rooms',
    'schedule_templates',
    'availability_exceptions',
    'clinic_configurations',
    'care_team_assignments',
  };
  var revision = 0;
  return db
      .tableUpdates(
        TableUpdateQuery.onAllTables(
          db.allTables.where(
            (table) => sources.contains(table.actualTableName),
          ),
        ),
      )
      .map((_) => ++revision);
});
final workspaceOverviewProvider = FutureProvider<WorkspaceData>((ref) {
  ref.watch(workspaceChangesProvider);
  ref.watch(currentUserProvider);
  return ref.watch(workspaceRepositoryProvider).read('overview', {
    'day': clinicDateLabel(ref.watch(workspaceDayProvider)),
    'days': ref.watch(workspacePeriodProvider),
    'revenueDays': ref.watch(workspaceRevenuePeriodProvider),
  });
});
final historySummaryProvider = FutureProvider<WorkspaceData>((ref) {
  ref.watch(workspaceChangesProvider);
  ref.watch(currentUserProvider);
  return ref.watch(workspaceRepositoryProvider).read('history', {'limit': 1});
});

/// One authenticated contract for the new workspace reads in both modes.
/// Shared requests never touch the local scratch database.
class WorkspaceRepository {
  WorkspaceRepository({
    required this.db,
    required this.client,
    required this.access,
    required this.appointments,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final AppDatabase? db;
  final SharedClient? client;
  final AccessPolicy access;
  final AppointmentRepository appointments;
  final DateTime Function() now;

  Future<List<WorkspaceData>> query(
    String sql, [
    List<Object> args = const [],
  ]) async => [
    for (final row
        in await db!
            .customSelect(
              sql,
              variables: [
                for (final a in args)
                  if (a is int)
                    Variable<int>(a)
                  else
                    Variable<String>(a as String),
              ],
            )
            .get())
      row.data,
  ];
  Future<int> count(String sql, [List<Object> args = const []]) async =>
      ((await query(sql, args)).first.values.first as num).toInt();
  Future<WorkspaceData> read(
    String resource, [
    WorkspaceData parameters = const {},
  ]) async {
    if (client != null) {
      return Map<String, dynamic>.from(
        await client!.request(
              '/api/workspace/$resource',
              query: parameters.map((k, v) => MapEntry(k, '$v')),
            )
            as Map,
      );
    }
    if (resource == 'history') return _history(parameters);
    await access.require(
      Permission.viewOperationalReports,
      entityType: 'workspace',
    );
    return switch (resource) {
      'overview' => _overview(parameters),
      'rooms' => {
        'rows': await query(
          'SELECT r.*,d.name AS department FROM clinic_rooms r LEFT JOIN departments d ON d.id=r.department_id ORDER BY r.display_label,r.id',
        ),
      },
      'feedback' => {
        'rows': await query(
          'SELECT f.*,u.full_name AS reporter_name,u.role AS reporter_role,h.full_name AS handler_name FROM feedbacks f LEFT JOIN users u ON u.id=f.reporter_id LEFT JOIN users h ON h.id=f.handled_by_admin_id ORDER BY f.created_at DESC,f.id',
        ),
      },
      _ => throw const ValidationFailure('Unknown workspace resource.'),
    };
  }

  static const completion =
      'COALESCE(a.completed_at,(SELECT signed_at FROM signed_notes WHERE appointment_id=a.id))';
  Future<WorkspaceData> _history(WorkspaceData p) async {
    final actor = await access.require(
      Permission.readPatientChart,
      entityType: 'patient_history',
    );
    if (actor == null || !actor.isStaff) {
      throw const AuthFailure('Clinical staff access required.');
    }
    final id = actor.accountId;
    final profile = (await query(
      'SELECT job_title FROM staff_profiles WHERE user_id=?',
      [id],
    )).firstOrNull;
    final role = StaffRole.parse(profile?['job_title'] as String?);
    if (![
      StaffRole.doctor,
      StaffRole.dentist,
      StaffRole.nurse,
    ].contains(role)) {
      throw const AuthFailure('Clinical staff access required.');
    }
    final own = role == StaffRole.nurse ? '0' : 'a.staff_id=?';
    final args = <Object>[if (role != StaffRole.nurse) id, id];
    final scope =
        "a.status='completed' AND ($own OR EXISTS(SELECT 1 FROM encounter_participants ep WHERE ep.appointment_id=a.id AND ep.staff_id=?))";
    final base =
        '''SELECT u.id,u.full_name,u.national_id,u.gender,u.dob,pp.chronic_conditions,
      MAX(COALESCE($completion,a.slot_end)) AS last_visit,
      MAX(CASE WHEN $completion IS NULL THEN 1 ELSE 0 END) AS legacy_completion,
      EXISTS(SELECT 1 FROM risk_flags rf WHERE rf.patient_id=u.id AND rf.severity='urgent' AND rf.acknowledged_at IS NULL) AS critical,
      EXISTS(SELECT 1 FROM staff_tasks st WHERE st.patient_id=u.id AND st.kind='followUpDue' AND st.status NOT IN ('done','dismissed')) AS follow_up
      FROM appointments a JOIN users u ON u.id=a.patient_id LEFT JOIN patient_profiles pp ON pp.user_id=u.id
      WHERE $scope GROUP BY u.id''';
    final wall = clinicDay(now());
    final start = clinicStart(DateTime.utc(wall.year, wall.month));
    final end = clinicStart(DateTime.utc(wall.year, wall.month + 1));
    final stats = {
      'appointmentsToday': await count(
        'SELECT COUNT(*) FROM appointments WHERE staff_id=? AND slot_start>=? AND slot_start<?',
        [
          id,
          clinicStart(wall).millisecondsSinceEpoch ~/ 1000,
          clinicStart(
                wall.add(const Duration(days: 1)),
              ).millisecondsSinceEpoch ~/
              1000,
        ],
      ),
      'completedToday': await count(
        'SELECT COUNT(*) FROM appointments a WHERE $scope AND $completion>=? AND $completion<?',
        [
          ...args,
          clinicStart(wall).millisecondsSinceEpoch ~/ 1000,
          clinicStart(
                wall.add(const Duration(days: 1)),
              ).millisecondsSinceEpoch ~/
              1000,
        ],
      ),
      'total': await count('SELECT COUNT(*) FROM ($base)', args),
      'critical': await count(
        'SELECT COUNT(*) FROM ($base) WHERE critical=1',
        args,
      ),
      'followUp': await count(
        'SELECT COUNT(*) FROM ($base) WHERE follow_up=1',
        args,
      ),
      'month': await count(
        'SELECT COUNT(DISTINCT a.patient_id) FROM appointments a WHERE $scope AND $completion>=? AND $completion<?',
        [
          ...args,
          start.millisecondsSinceEpoch ~/ 1000,
          end.millisecondsSinceEpoch ~/ 1000,
        ],
      ),
    };
    final q = '%${(p['query'] ?? '').toString().trim().toLowerCase()}%';
    final filter = p['filter'];
    final where =
        "(lower(full_name) LIKE ? OR lower(id) LIKE ? OR COALESCE(national_id,'') LIKE ? OR lower(COALESCE(chronic_conditions,'')) LIKE ?)${filter == 'critical'
            ? ' AND critical=1'
            : filter == 'followUp'
            ? ' AND follow_up=1'
            : ''}";
    final limit = ((p['limit'] as int?) ?? 50).clamp(1, 200),
        offset = ((p['offset'] as int?) ?? 0).clamp(0, 1000000);
    final filteredArgs = [...args, q, q, q, q];
    return {
      'stats': stats,
      'total': await count(
        'SELECT COUNT(*) FROM ($base) WHERE $where',
        filteredArgs,
      ),
      'rows': await query(
        'SELECT * FROM ($base) WHERE $where ORDER BY full_name,id LIMIT ? OFFSET ?',
        [...filteredArgs, limit, offset],
      ),
      'nurse': role == StaffRole.nurse,
    };
  }

  Future<WorkspaceData> _overview(WorkspaceData p) async {
    final day = DateTime.parse(
      (p['day'] as String?) ?? clinicDateLabel(clinicDay(now())),
    );
    final days = ((p['days'] as int?) ?? 7).clamp(1, 31),
        revenueDays = ((p['revenueDays'] as int?) ?? 7).clamp(1, 31);
    final start = clinicStart(day), end = start.add(const Duration(days: 1));
    final from = start.subtract(Duration(days: days - 1));
    int sec(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
    final range = [sec(from), sec(end)];
    final appts = await query(
      '''SELECT a.*,p.full_name AS patient_name,s.full_name AS staff_name,d.name AS department,p.gender
      FROM appointments a JOIN users p ON p.id=a.patient_id JOIN users s ON s.id=a.staff_id LEFT JOIN departments d ON d.id=a.department_id
      WHERE a.slot_start>=? AND a.slot_start<? ORDER BY a.slot_start,a.id''',
      [sec(start), sec(end)],
    );
    final gender = await query(
      "SELECT u.gender,COUNT(*) AS n FROM appointments a JOIN users u ON u.id=a.patient_id WHERE a.slot_start>=? AND a.slot_start<? AND a.status NOT IN ('cancelled','noShow') GROUP BY u.gender",
      range,
    );
    final hours = await query(
      "SELECT CAST(strftime('%H',a.slot_start+10800,'unixepoch') AS INTEGER) AS hour,COUNT(*) AS n FROM appointments a WHERE a.slot_start>=? AND a.slot_start<? AND a.status NOT IN ('cancelled','noShow') GROUP BY hour ORDER BY hour",
      range,
    );
    final revenueFrom = start.subtract(Duration(days: revenueDays - 1));
    final ledger = await query(
      "SELECT t.* FROM payment_transactions t WHERE t.status='settled' AND (t.kind='invoiceCharge' OR (t.kind='refund' AND EXISTS(SELECT 1 FROM payment_transactions original WHERE original.id=t.refund_of_id AND original.kind='invoiceCharge'))) AND t.settled_at>=? AND t.settled_at<?",
      [sec(revenueFrom), sec(end)],
    );
    final revenue = <String, WorkspaceData>{};
    for (var i = 0; i < revenueDays; i++) {
      final d = day.subtract(Duration(days: revenueDays - i - 1));
      revenue[clinicDateLabel(d)] = {
        'day': clinicDateLabel(d),
        'payments': 0,
        'refunds': 0,
      };
    }
    for (final t in ledger) {
      final d = clinicDateLabel(
        clinicDay(
          DateTime.fromMillisecondsSinceEpoch(
            (t['settled_at'] as int) * 1000,
            isUtc: true,
          ),
        ),
      );
      final bucket = revenue[d];
      if (bucket != null) {
        final key = t['kind'] == 'refund' ? 'refunds' : 'payments';
        bucket[key] = (bucket[key] as int) + fils(t['amount'] as num);
      }
    }
    final doctors = <WorkspaceData>[];
    final staff =
        await (db!.select(db!.staffProfiles).join([
              innerJoin(
                db!.users,
                db!.users.id.equalsExp(db!.staffProfiles.userId),
              ),
            ])..where(
              db!.users.isActive.equals(true) &
                  db!.users.role.equalsValue(UserRole.staff),
            ))
            .get();
    for (final r in staff) {
      final s = r.readTable(db!.staffProfiles), u = r.readTable(db!.users);
      if (StaffRole.parse(s.jobTitle) != StaffRole.doctor) continue;
      final templates =
          await (db!.select(db!.scheduleTemplates)..where(
                (t) =>
                    t.staffId.equals(s.userId) & t.weekday.equals(day.weekday),
              ))
              .get();
      final exceptions =
          await (db!.select(db!.availabilityExceptions)..where(
                (e) =>
                    e.staffId.equals(s.userId) &
                    e.startsAt.isSmallerThanValue(end) &
                    e.endsAt.isBiggerThanValue(start),
              ))
              .get();
      final bookings =
          await (db!.select(db!.appointments)..where(
                (a) =>
                    a.staffId.equals(s.userId) &
                    a.slotStart.isSmallerThanValue(end) &
                    a.slotEnd.isBiggerThanValue(start) &
                    a.status.isNotInValues([AppointmentStatus.cancelled]),
              ))
              .get();
      final settings = await (db!.select(
        db!.appSettings,
      )..where((s) => s.id.equals(1))).getSingleOrNull();
      final raw = AppointmentRepositoryImpl.scheduleGridFor(
        s.userId,
        DateTime(day.year, day.month, day.day),
        templates,
        settings,
      );
      final available = <DateTime>[];
      for (final candidate in raw) {
        final slot = start.add(
          Duration(minutes: candidate.start.hour * 60 + candidate.start.minute),
        );
        final endMinutes =
            (candidate.end.day == candidate.start.day ? 0 : 1440) +
            candidate.end.hour * 60 +
            candidate.end.minute;
        final finish = start.add(Duration(minutes: endMinutes));
        if (slot.isAfter(now()) &&
            !exceptions.any(
              (e) => e.startsAt.isBefore(finish) && e.endsAt.isAfter(slot),
            ) &&
            !bookings.any(
              (a) => a.slotStart.isBefore(finish) && a.slotEnd.isAfter(slot),
            )) {
          available.add(slot);
        }
      }
      available.sort();
      if (available.isNotEmpty) {
        doctors.add({
          'id': u.id,
          'name': u.fullName,
          'specialty': s.specialty ?? '',
          'next': available.first.millisecondsSinceEpoch ~/ 1000,
        });
      }
    }
    return {
      'stats': {
        'patients': await count(
          "SELECT COUNT(*) FROM users WHERE role='patient'",
        ),
        'activePatients': await count(
          "SELECT COUNT(*) FROM users WHERE role='patient' AND is_active=1",
        ),
        'staff': await count("SELECT COUNT(*) FROM users WHERE role='staff'"),
        'activeStaff': await count(
          "SELECT COUNT(*) FROM users WHERE role='staff' AND is_active=1",
        ),
        'rooms': await count(
          'SELECT COUNT(*) FROM clinic_rooms WHERE enabled=1',
        ),
        'roomsConfigured': await count('SELECT COUNT(*) FROM clinic_rooms') > 0,
        'consultations': await count(
          "SELECT COUNT(*) FROM appointments a WHERE a.status='completed' AND $completion>=? AND $completion<?",
          range,
        ),
        'referrals': await count(
          'SELECT COUNT(*) FROM referral_requests WHERE created_at>=? AND created_at<?',
          range,
        ),
        'prescriptions': await count(
          'SELECT COUNT(*) FROM medications WHERE issued_at>=? AND issued_at<?',
          range,
        ),
      },
      'day': clinicDateLabel(day),
      'days': days,
      'appointments': appts,
      'gender': gender,
      'hours': hours,
      'doctors': doctors,
      'revenue': revenue.values.toList(),
      'payments': await query(
        '''SELECT t.*,u.full_name AS patient_name,i.notes AS description,COALESCE((SELECT SUM(r.amount) FROM payment_transactions r WHERE r.refund_of_id=t.id AND r.status='settled'),0) AS refunded FROM payment_transactions t JOIN users u ON u.id=t.patient_id LEFT JOIN invoices i ON i.id=t.invoice_id ORDER BY t.created_at DESC,t.id LIMIT 8''',
      ),
      'feedback': ((await read('feedback'))['rows'] as List<WorkspaceData>)
          .take(3)
          .toList(),
      'limitations': [
        'unknownCompletionDates',
        'unknownIssueDates',
        'receiptsNotProfit',
      ],
    };
  }

  Future<void> saveRoom({
    required String label,
    required bool enabled,
    String? id,
    String? departmentId,
    int version = 0,
  }) async {
    if (label.trim().isEmpty || label.length > 80) {
      throw const ValidationFailure('Enter a room label (1–80 characters).');
    }
    if (client != null) {
      await client!.request(
        '/api/workspace/rooms',
        method: 'POST',
        body: {
          'id': id,
          'label': label.trim(),
          'departmentId': departmentId,
          'enabled': enabled,
          'version': version,
        },
      );
      return;
    }
    await access.require(Permission.manageDepartments, entityType: 'room');
    await db!.transaction(() async {
      final roomId = id ?? newId('room');
      if (id == null) {
        await db!
            .into(db!.clinicRooms)
            .insert(
              ClinicRoomsCompanion.insert(
                id: roomId,
                displayLabel: label.trim(),
                departmentId: Value(departmentId),
                enabled: Value(enabled),
              ),
            );
      } else {
        final n =
            await (db!.update(
              db!.clinicRooms,
            )..where((r) => r.id.equals(id) & r.version.equals(version))).write(
              ClinicRoomsCompanion(
                displayLabel: Value(label.trim()),
                departmentId: Value(departmentId),
                enabled: Value(enabled),
                version: Value(version + 1),
              ),
            );
        if (n != 1) {
          throw const ConflictFailure('Room changed. Reload before saving.');
        }
      }
      await access.audit(
        'room.saved',
        entityType: 'room',
        entityId: roomId,
        detail: jsonEncode({
          'label': label.trim(),
          'enabled': enabled,
          'department': departmentId,
        }),
      );
    });
  }

  Future<void> recordParticipation(String appointmentId) async {
    if (client != null) {
      await client!.request(
        '/api/workspace/participation',
        method: 'POST',
        body: {'appointmentId': appointmentId},
      );
      return;
    }
    final actor = await access.require(
      Permission.readPatientChart,
      entityType: 'encounter_participation',
    );
    if (actor == null || !actor.isStaff) {
      throw const AuthFailure('Clinical staff access required.');
    }
    final a = await (db!.select(
      db!.appointments,
    )..where((a) => a.id.equals(appointmentId))).getSingle();
    await access.readPatient(
      a.patientId,
      entityType: 'encounter_participation',
      entityId: appointmentId,
    );
    if (![
      AppointmentStatus.inProgress,
      AppointmentStatus.completed,
    ].contains(a.status)) {
      throw const ValidationFailure(
        'Record participation during an active or completed visit.',
      );
    }
    await db!.transaction(() async {
      await db!
          .into(db!.encounterParticipants)
          .insert(
            EncounterParticipantsCompanion.insert(
              appointmentId: appointmentId,
              staffId: actor.accountId,
              participatedAt: now(),
              recordedBy: actor.accountId,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await access.audit(
        'encounter.participated',
        entityType: 'appointment',
        entityId: appointmentId,
        subjectPatientId: a.patientId,
      );
    });
  }

  Future<void> setFeedback(WorkspaceData feedback) async {
    final status = feedback['status'] == 'open' ? 'resolved' : 'open';
    if (client != null) {
      await client!.request(
        '/api/workspace/feedback',
        method: 'POST',
        body: {
          'id': feedback['id'],
          'status': status,
          'version': feedback['version'],
        },
      );
      return;
    }
    final actor = await access.require(
      Permission.viewOperationalReports,
      entityType: 'feedback',
    );
    await db!.transaction(() async {
      final updated =
          await (db!.update(db!.feedbacks)..where(
                (f) =>
                    f.id.equals(feedback['id'] as String) &
                    f.status.equalsValue(
                      FeedbackStatus.values.byName(
                        feedback['status'] as String,
                      ),
                    ),
              ))
              .write(
                FeedbacksCompanion(
                  status: Value(FeedbackStatus.values.byName(status)),
                  handledAt: Value(status == 'resolved' ? now() : null),
                  handledByAdminId: Value(
                    status == 'resolved' ? actor?.accountId : null,
                  ),
                ),
              );
      if (updated != 1) {
        throw const ConflictFailure('Feedback changed. Reload before saving.');
      }
      await access.audit(
        'feedback.$status',
        entityType: 'feedback',
        entityId: feedback['id'] as String,
      );
    });
  }
}
