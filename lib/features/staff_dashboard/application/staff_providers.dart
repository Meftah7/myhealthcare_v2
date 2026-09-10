/// Staff-scoped providers: today's schedule, the patient panel, open risk
/// flags, the task list, and the rules pipeline that fills them (P5-01…P5-11).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/app_sounds.dart';
import '../../../core/di.dart';
import '../../../core/result.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import '../../../services/rules/risk_detection_service.dart';
import '../../../services/rules/task_generator.dart';
import '../../auth/application/session.dart';

String _staffId(Ref ref) {
  final u = ref.watch(currentUserProvider);
  if (u == null || !u.isStaff) throw StateError('no staff member in session');
  return u.id;
}

final riskDetectionServiceProvider = Provider<RiskDetectionService>(
  (ref) => RiskDetectionService(
    records: ref.watch(recordRepositoryProvider),
    vitals: ref.watch(vitalsRepositoryProvider),
    medications: ref.watch(medicationRepositoryProvider),
    appointments: ref.watch(appointmentRepositoryProvider),
    risk: ref.watch(riskRepositoryProvider),
  ),
);

final taskGeneratorProvider = Provider<TaskGenerator>(
  (ref) => TaskGenerator(
    tasks: ref.watch(taskRepositoryProvider),
    risk: ref.watch(riskRepositoryProvider),
  ),
);

/// The signed-in staff member's own profile record (P8-07).
final staffProfileProvider = FutureProvider<Staff>((ref) async {
  final id = _staffId(ref);
  return _unwrap(await ref.watch(userRepositoryProvider).staffById(id));
});

/// Human-readable name of a department by id, or `null` if unset / unknown.
final departmentNameProvider = FutureProvider.family<String?, String?>((
  ref,
  departmentId,
) async {
  if (departmentId == null) return null;
  final all = _unwrap(await ref.watch(departmentRepositoryProvider).all());
  for (final d in all) {
    if (d.id == departmentId) return d.name;
  }
  return null;
});

/// Today's appointments for the signed-in staff member (P5-05, P5-12).
final staffTodayProvider = FutureProvider<List<Appointment>>((ref) async {
  final id = _staffId(ref);
  return _unwrap(
    await ref
        .watch(appointmentRepositoryProvider)
        .forStaffOnDay(id, DateTime.now()),
  );
});

/// Today's queue — the actionable slice of [staffTodayProvider]: still-open
/// visits (booked / confirmed), soonest first. Mirrors the FirstSemMyHealth
/// doctor "Today's Patients" list.
final staffQueueProvider = FutureProvider<List<Appointment>>((ref) async {
  final today = await ref.watch(staffTodayProvider.future);
  final open =
      today
          .where(
            (a) =>
                a.status == AppointmentStatus.booked ||
                a.status == AppointmentStatus.confirmed,
          )
          .toList()
        ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
  return open;
});

/// Every staff member, for the staff directory + transfer picker.
final staffDirectoryProvider = FutureProvider<List<Staff>>((ref) async {
  return _unwrap(await ref.watch(userRepositoryProvider).allStaff());
});

/// Patient id → full name, for screens that list records/appointments across
/// many patients (staff activity, transfer picker).
final patientNameLookupProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final patients = await ref.watch(staffPanelProvider.future);
  return {for (final p in patients) p.id: p.fullName};
});

/// Records the signed-in staff member authored (staff "Activity" view).
final staffRecordsAuthoredProvider = FutureProvider<List<MedicalRecord>>((
  ref,
) async {
  final id = _staffId(ref);
  return _unwrap(await ref.watch(recordRepositoryProvider).authoredBy(id));
});

/// Medications the signed-in staff member prescribed (staff "Activity" view).
final staffPrescriptionsIssuedProvider = FutureProvider<List<Medication>>((
  ref,
) async {
  final id = _staffId(ref);
  return _unwrap(
    await ref.watch(medicationRepositoryProvider).prescribedBy(id),
  );
});

/// The whole patient panel (small single-clinic demo) (P5-06).
final staffPanelProvider = FutureProvider<List<Patient>>((ref) async {
  return _unwrap(await ref.watch(patientRepositoryProvider).all(limit: 500));
});

/// Free-text patient search backing the staff patient list (P5-06).
final patientSearchQueryProvider = StateProvider<String>((ref) => '');

final patientSearchResultsProvider = FutureProvider<List<Patient>>((ref) async {
  final q = ref.watch(patientSearchQueryProvider).trim();
  final repo = ref.watch(patientRepositoryProvider);
  if (q.isEmpty) return _unwrap(await repo.all(limit: 200));
  return _unwrap(await repo.search(q, limit: 50));
});

/// Patient lookup for the quick-action pickers (note / prescribe / lab /
/// transfer). Keyed on the raw query so each picker dialog owns its own state.
final patientPickerResultsProvider =
    FutureProvider.family<List<Patient>, String>((ref, query) async {
      final repo = ref.watch(patientRepositoryProvider);
      final q = query.trim();
      if (q.isEmpty) return _unwrap(await repo.all(limit: 30));
      return _unwrap(await repo.search(q, limit: 30));
    });

final unacknowledgedFlagsProvider = FutureProvider<List<RiskFlag>>((ref) async {
  return _unwrap(await ref.watch(riskRepositoryProvider).unacknowledged());
});

/// Open walk-in tickets for the signed-in doctor's department — patients sent
/// here by a department referral, waiting to be seen.
final departmentWalkInsProvider = FutureProvider<List<WalkInTicket>>((
  ref,
) async {
  final profile = await ref.watch(staffProfileProvider.future);
  final deptId = profile.departmentId;
  if (deptId == null) return const [];
  return _unwrap(
    await ref
        .watch(walkInTicketRepositoryProvider)
        .forDepartment(deptId, openOnly: true),
  );
});

final staffTasksProvider = FutureProvider<List<StaffTask>>((ref) async {
  final id = _staffId(ref);
  final tasks = _unwrap(
    await ref.watch(taskRepositoryProvider).forStaff(id, openOnly: true),
  );
  final weight = await ref.watch(aiTaskWeightProvider.future);
  tasks.sort(
    (a, b) =>
        b.effectivePriority(weight).compareTo(a.effectivePriority(weight)),
  );
  return tasks;
});

/// The AI-vs-rule blend weight from app settings (0 = rules only) (P5-10).
final aiTaskWeightProvider = FutureProvider<double>((ref) async {
  final r = await ref.watch(settingsRepositoryProvider).get();
  return r.valueOrNull?.aiTaskWeight ?? 0.5;
});

class StaffOps {
  StaffOps(this._ref);
  final Ref _ref;

  /// P5-01/02/03: scan every panel patient for risks, then (re)generate this
  /// staff member's task list from the still-open flags. Returns the flag count.
  Future<int> refreshPanel() async {
    final staffId = _ref.read(currentUserProvider)!.id;
    final patients = await _ref.read(staffPanelProvider.future);
    final detector = _ref.read(riskDetectionServiceProvider);

    for (final p in patients) {
      await detector.runAndPersist(p);
    }
    final flags = _unwrap(
      await _ref.read(riskRepositoryProvider).unacknowledged(),
    );
    await _ref
        .read(taskGeneratorProvider)
        .generateFor(staffId: staffId, flags: flags);

    _ref
      ..invalidate(unacknowledgedFlagsProvider)
      ..invalidate(staffTasksProvider);
    return flags.length;
  }

  /// P5-10: score open tasks with the (deterministic mock) AI ranker and store
  /// the raw AI score + rationale. [StaffTask.effectivePriority] blends it with
  /// the rule score at read time, so this is safe to re-run.
  Future<void> prioritiseWithAi() async {
    final staffId = _ref.read(currentUserProvider)!.id;
    final tasks = _unwrap(
      await _ref.read(taskRepositoryProvider).forStaff(staffId, openOnly: true),
    );
    final repo = _ref.read(taskRepositoryProvider);
    for (final (task, score, rationale) in _rankTasks(tasks)) {
      await repo.applyAiPriority(
        id: task.id,
        score: score,
        rationale: rationale,
      );
    }
    _ref.invalidate(staffTasksProvider);
  }

  Future<void> acknowledgeFlag(String flagId) async {
    final staffId = _ref.read(currentUserProvider)!.id;
    await _ref
        .read(riskRepositoryProvider)
        .acknowledge(id: flagId, staffId: staffId);
    _ref
      ..invalidate(unacknowledgedFlagsProvider)
      ..invalidate(staffTasksProvider);
  }

  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    await _ref.read(taskRepositoryProvider).setStatus(taskId, status);
    _ref.invalidate(staffTasksProvider);
  }

  // --- presence + queue (FirstSemMyHealth doctor-dashboard parity) -------

  /// Set the signed-in staff member's live availability.
  Future<Result<void>> setPresence(PresenceStatus status) async {
    final id = _ref.read(currentUserProvider)!.id;
    final result = await _ref
        .read(userRepositoryProvider)
        .setPresence(id: id, status: status);
    if (result.isOk) {
      // Each working status has its own cue, so a hands-busy clinician hears
      // the change land without looking at the pill.
      unawaited(
        _ref.read(soundPlayerProvider).play(AppSound.forPresence(status)),
      );
      _ref
        ..invalidate(staffProfileProvider)
        ..invalidate(staffDirectoryProvider);
    }
    return result;
  }

  void _refreshQueue() {
    _ref
      ..invalidate(staffTodayProvider)
      ..invalidate(staffQueueProvider)
      ..invalidate(staffMonthProvider);
  }

  /// Accept a booked visit (→ confirmed).
  Future<void> acceptAppointment(String id) async {
    await _ref
        .read(appointmentRepositoryProvider)
        .updateStatus(id: id, status: AppointmentStatus.confirmed);
    _refreshQueue();
  }

  /// Start the visit — stamps check-in time.
  Future<void> startVisit(String id) async {
    await _ref
        .read(appointmentRepositoryProvider)
        .markCheckedIn(id, DateTime.now());
    _refreshQueue();
  }

  /// Complete the visit (→ completed).
  Future<void> completeAppointment(String id) async {
    await _ref
        .read(appointmentRepositoryProvider)
        .updateStatus(id: id, status: AppointmentStatus.completed);
    _refreshQueue();
  }

  /// Mark the visit cancelled / no-show.
  Future<void> cancelAppointment(String id, {bool noShow = false}) async {
    await _ref
        .read(appointmentRepositoryProvider)
        .updateStatus(
          id: id,
          status: noShow
              ? AppointmentStatus.noShow
              : AppointmentStatus.cancelled,
        );
    _refreshQueue();
  }

  /// Reassign a visit to another clinician.
  Future<Result<Appointment>> transferAppointment({
    required String id,
    required String toStaffId,
  }) async {
    final actorId = _ref.read(currentUserProvider)!.id;
    final result = await _ref
        .read(appointmentRepositoryProvider)
        .transfer(id: id, toStaffId: toStaffId);
    if (result.isOk) {
      await _ref
          .read(auditRepositoryProvider)
          .record(
            action: 'appointment.transfer',
            entityType: 'appointment',
            entityId: id,
            actorUserId: actorId,
          );
      _refreshQueue();
    }
    return result;
  }

  /// Start a walk-in visit: materialise an in-progress [Appointment] for the
  /// ticket, mark the ticket claimed, and return the new appointment id so the
  /// caller can open the consultation page.
  Future<Result<String>> startWalkIn(WalkInTicket ticket) async {
    final me = _ref.read(currentUserProvider)!.id;
    return Result.guardAsync(() async {
      final visit = _unwrap(
        await _ref
            .read(appointmentRepositoryProvider)
            .openWalkInVisit(
              patientId: ticket.patientId,
              staffId: me,
              departmentId: ticket.departmentId,
              ticketTag: ticket.ticketTag,
              reasonText: ticket.reason,
            ),
      );
      _unwrap(
        await _ref
            .read(walkInTicketRepositoryProvider)
            .claim(id: ticket.id, doctorId: me, resultAppointmentId: visit.id),
      );
      await _ref
          .read(auditRepositoryProvider)
          .record(
            action: 'walkin.start',
            entityType: 'appointment',
            entityId: visit.id,
            actorUserId: me,
            detail: ticket.id,
          );
      _ref.invalidate(departmentWalkInsProvider);
      _refreshQueue();
      return visit.id;
    });
  }
}

final staffOpsProvider = Provider<StaffOps>(StaffOps.new);

// --- schedule: year / month / day (P5-12, calendar rebuild) --------------

/// Which level of the calendar is on screen. Drills down year → month → day,
/// and back up via the button in the app bar's top-left.
enum ScheduleView { year, month, day }

final scheduleViewProvider = StateProvider<ScheduleView>(
  (ref) => ScheduleView.day,
);

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Monday on or before the 1st of [focused]'s month — the first cell of the
/// month grid, and the start of the window we query.
DateTime monthGridStart(DateTime focused) {
  final first = DateTime(focused.year, focused.month);
  return first.subtract(Duration(days: first.weekday - 1));
}

/// The day the calendar is focused on. The month and year views take their
/// period from it; the day view draws it.
final scheduleFocusedDayProvider = StateProvider<DateTime>(
  (ref) => dayOf(DateTime.now()),
);

/// The focused month, as its first day. Kept separate so moving between days
/// inside one month doesn't re-run the query.
final scheduleMonthProvider = Provider<DateTime>((ref) {
  final f = ref.watch(scheduleFocusedDayProvider);
  return DateTime(f.year, f.month);
});

/// Every appointment inside the focused month's six-week grid window. One
/// query feeds both the month grid's per-day marks and the day timeline, so
/// drilling between them costs nothing.
final staffMonthProvider = FutureProvider<List<Appointment>>((ref) async {
  final id = _staffId(ref);
  final start = monthGridStart(ref.watch(scheduleMonthProvider));
  return _unwrap(
    await ref
        .watch(appointmentRepositoryProvider)
        .forStaffInRange(id, start, start.add(const Duration(days: 42))),
  );
});

/// The focused day's appointments, soonest first.
final staffFocusedDayProvider = Provider<List<Appointment>>((ref) {
  final day = ref.watch(scheduleFocusedDayProvider);
  final all =
      ref.watch(staffMonthProvider).valueOrNull ?? const <Appointment>[];
  return all.where((a) => isSameCalendarDay(a.slotStart, day)).toList()
    ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
});

// --- panel analytics (P5-13) -------------------------------------------

class PanelStats {
  const PanelStats({
    required this.total,
    required this.completed,
    required this.noShow,
    required this.cancelled,
    required this.upcoming,
    required this.windowDays,
  });

  final int total;
  final int completed;
  final int noShow;
  final int cancelled;
  final int upcoming;
  final int windowDays;

  /// No-shows as a share of appointments that were meant to happen.
  double get noShowRate {
    final attended = completed + noShow;
    return attended == 0 ? 0 : noShow / attended;
  }

  double get cancellationRate => total == 0 ? 0 : cancelled / total;

  /// Rough utilization: kept appointments per day over the window.
  double get keptPerDay => windowDays == 0 ? 0 : completed / windowDays;
}

final panelStatsProvider = FutureProvider<PanelStats>((ref) async {
  const windowDays = 90;
  final now = DateTime.now();
  final from = now.subtract(const Duration(days: windowDays));
  final appts = _unwrap(
    await ref
        .watch(appointmentRepositoryProvider)
        .inRange(from, now.add(const Duration(days: windowDays))),
  );
  var completed = 0, noShow = 0, cancelled = 0, past = 0, upcoming = 0;
  for (final a in appts) {
    switch (a.status) {
      case AppointmentStatus.completed:
        completed++;
        past++;
      case AppointmentStatus.noShow:
        noShow++;
        past++;
      case AppointmentStatus.cancelled:
        cancelled++;
      case AppointmentStatus.inProgress:
        // A live visit — counts as an appointment that happened.
        past++;
      case AppointmentStatus.booked || AppointmentStatus.confirmed:
        if (a.slotStart.isAfter(now)) upcoming++;
    }
  }
  return PanelStats(
    total: past + cancelled,
    completed: completed,
    noShow: noShow,
    cancelled: cancelled,
    upcoming: upcoming,
    windowDays: windowDays,
  );
});

/// Deterministic stand-in for `AiService.prioritizeTasks` — orders by task kind
/// urgency, overdue-ness and the rule score, and writes a one-line rationale.
/// Swapped for the Gemini path once a key is configured (P5-10).
Iterable<(StaffTask, double, String)> _rankTasks(List<StaffTask> tasks) sync* {
  double base(TaskKind k) => switch (k) {
    TaskKind.unreviewedAbnormalLab => 0.95,
    TaskKind.followUpDue => 0.70,
    TaskKind.medicationReview => 0.60,
    TaskKind.unsignedNote => 0.50,
    TaskKind.referralAction => 0.45,
    TaskKind.other => 0.40,
  };
  for (final t in tasks) {
    var score = base(t.kind);
    final reasons = <String>['${_label(t.kind)} work'];
    if (t.isOverdue) {
      score = (score + 0.10).clamp(0.0, 1.0);
      reasons.add('past its due date');
    }
    if (t.ruleScore >= 0.9) {
      score = (score + 0.05).clamp(0.0, 1.0);
      reasons.add('rule engine marked it urgent');
    }
    yield (t, score, 'Prioritised: ${reasons.join(', ')}.');
  }
}

String _label(TaskKind k) => switch (k) {
  TaskKind.unreviewedAbnormalLab => 'Abnormal-lab review',
  TaskKind.followUpDue => 'Follow-up',
  TaskKind.medicationReview => 'Medication review',
  TaskKind.unsignedNote => 'Unsigned-note',
  TaskKind.referralAction => 'Referral',
  TaskKind.other => 'Clinical',
};

T _unwrap<T>(Result<T> r) => switch (r) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};
