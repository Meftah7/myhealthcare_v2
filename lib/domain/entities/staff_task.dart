/// A staff work item, rule-scored and optionally AI-prioritised (P1-10).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'staff_task.freezed.dart';

@freezed
abstract class StaffTask with _$StaffTask {
  const factory StaffTask({
    required String id,
    required String staffId,
    required String title,
    required TaskKind kind,
    required TaskStatus status,
    required double ruleScore,
    required DateTime createdAt,
    String? patientId,
    DateTime? dueAt,
    double? aiPriorityScore,
    String? aiRationale,
    @Default(WorkPriority.routine) WorkPriority priority,

    /// A clinician covering the task (escalation, or off-duty cover). The
    /// owner ([staffId]) stays accountable.
    String? coverageStaffId,
    DateTime? escalatedAt,
    @Default(1) int version,
  }) = _StaffTask;

  const StaffTask._();

  bool get isOpen =>
      status != TaskStatus.done && status != TaskStatus.dismissed;

  bool get isEscalated => escalatedAt != null;

  bool get isOverdue {
    final due = dueAt;
    return isOpen && due != null && due.isBefore(DateTime.now());
  }

  /// Blend of the deterministic rule score and the AI score (P5-10). Falls back
  /// to the rule score alone when AI is off.
  double effectivePriority(double aiWeight) {
    double bounded(double score) => score.isFinite ? score.clamp(0.0, 1.0) : 0;
    final rule = bounded(ruleScore);
    final ai = aiPriorityScore;
    if (ai == null) return rule;
    final weight = bounded(aiWeight);
    return rule * (1 - weight) + bounded(ai) * weight;
  }
}

/// Explicit urgency and deadlines precede supporting AI/rule scores.
int compareStaffTasks(StaffTask a, StaffTask b, {required double aiWeight}) {
  final priority = b.priority.index.compareTo(a.priority.index);
  if (priority != 0) return priority;
  final aDue = a.dueAt;
  final bDue = b.dueAt;
  if (aDue != bDue) {
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    final deadline = aDue.compareTo(bDue);
    if (deadline != 0) return deadline;
  }
  final score = b
      .effectivePriority(aiWeight)
      .compareTo(a.effectivePriority(aiWeight));
  return score != 0 ? score : a.id.compareTo(b.id);
}
