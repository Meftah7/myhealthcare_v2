/// Staff-scoped providers: today's schedule, the patient panel, open risk
/// flags, the task list, and the rules pipeline that fills them (P5-01…P5-11).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final unacknowledgedFlagsProvider = FutureProvider<List<RiskFlag>>((ref) async {
  return _unwrap(await ref.watch(riskRepositoryProvider).unacknowledged());
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
}

final staffOpsProvider = Provider<StaffOps>(StaffOps.new);

// --- schedule week grid (P5-12) -----------------------------------------

/// Monday of the week the grid is showing, offset in weeks from this one.
final scheduleWeekOffsetProvider = StateProvider<int>((ref) => 0);

DateTime _mondayOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

final scheduleWeekStartProvider = Provider<DateTime>((ref) {
  final offset = ref.watch(scheduleWeekOffsetProvider);
  return _mondayOf(DateTime.now()).add(Duration(days: 7 * offset));
});

final staffWeekProvider = FutureProvider<List<Appointment>>((ref) async {
  final id = _staffId(ref);
  final start = ref.watch(scheduleWeekStartProvider);
  return _unwrap(
    await ref
        .watch(appointmentRepositoryProvider)
        .forStaffInRange(id, start, start.add(const Duration(days: 7))),
  );
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
