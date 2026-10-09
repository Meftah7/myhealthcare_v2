/// Rule-based staff task generator (P5-03).
///
/// Turns unacknowledged risk flags and overdue clinical work into `staff_tasks`
/// rows with a deterministic [StaffTask.ruleScore]. The AI layer (P5-10) later
/// blends an `aiPriorityScore` on top — but the board is useful with AI off.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/repositories.dart';

class TaskGenerator {
  TaskGenerator({required this.tasks, required this.risk});

  final TaskRepository tasks;
  final RiskRepository risk;

  static double _scoreFor(Severity s) => switch (s) {
    Severity.urgent => 0.9,
    Severity.warning => 0.6,
    Severity.info => 0.3,
  };

  /// Generates tasks for [staffId] from the given patients' current flags.
  /// Idempotent: a task's id is derived from `staffId + flag dedupeKey`, so
  /// re-running refreshes source fields without resetting workflow state.
  /// A new clinical episode must supply a new dedupeKey.
  Future<Result<int>> generateFor({
    required String staffId,
    required List<RiskFlag> flags,
  }) {
    return Result.guardAsync(() async {
      var written = 0;
      for (final f in flags.where((f) => !f.isAcknowledged)) {
        // Keep legacy IDs intact; source-specific work uses a collision-
        // resistant identity so distinct readings cannot share one task.
        final hash = f.dedupeKey.contains(':source:')
            ? sha256.convert(utf8.encode(f.dedupeKey)).toString()
            : _stableHash(f.dedupeKey);
        final id = 'task_${staffId}_$hash';
        final result = await tasks.upsert(
          StaffTask(
            id: id,
            staffId: staffId,
            patientId: f.patientId,
            title: _titleFor(f),
            kind: _kindFor(f.kind),
            status: TaskStatus.open,
            ruleScore: _scoreFor(f.severity),
            priority: switch (f.severity) {
              Severity.urgent => WorkPriority.urgent,
              Severity.warning => WorkPriority.priority,
              Severity.info => WorkPriority.routine,
            },
            createdAt: f.detectedAt,
            dueAt: f.severity == Severity.urgent
                ? f.detectedAt.add(const Duration(days: 1))
                : f.detectedAt.add(const Duration(days: 7)),
          ),
          sourceId: f.id,
        );
        if (result case Err(:final failure)) {
          if (written == 0) throw failure;
          throw PartialOperationFailure(
            completed: written,
            total: flags.where((f) => !f.isAcknowledged).length,
            failure: failure,
          );
        }
        written++;
      }
      return written;
    });
  }

  static String _titleFor(RiskFlag f) => switch (f.kind) {
    RiskFlagKind.abnormalVitals => 'Review abnormal vitals',
    RiskFlagKind.abnormalLab => 'Review critical lab result',
    RiskFlagKind.medicationGap => 'Address medication gap',
    RiskFlagKind.overdueFollowUp => 'Contact for overdue follow-up',
    RiskFlagKind.other => 'Clinical review',
  };

  static TaskKind _kindFor(RiskFlagKind k) => switch (k) {
    RiskFlagKind.abnormalLab => TaskKind.unreviewedAbnormalLab,
    RiskFlagKind.overdueFollowUp => TaskKind.followUpDue,
    RiskFlagKind.medicationGap => TaskKind.medicationReview,
    _ => TaskKind.other,
  };

  static String _stableHash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h.toRadixString(16);
  }
}
