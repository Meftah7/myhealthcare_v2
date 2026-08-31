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
  }) = _StaffTask;

  const StaffTask._();

  bool get isOpen =>
      status == TaskStatus.open || status == TaskStatus.inProgress;

  bool get isOverdue {
    final due = dueAt;
    return isOpen && due != null && due.isBefore(DateTime.now());
  }

  /// Blend of the deterministic rule score and the AI score (P5-10). Falls back
  /// to the rule score alone when AI is off.
  double effectivePriority(double aiWeight) {
    final ai = aiPriorityScore;
    if (ai == null) return ruleScore;
    return ruleScore * (1 - aiWeight) + ai * aiWeight;
  }
}
