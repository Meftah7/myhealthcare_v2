import 'dart:convert';
import '../../../domain/entities/staff_task.dart';
import '../../../domain/enums.dart';

enum StaffWorkView { mine, covering, team, completed }

enum TaskTimeGroup { urgent, overdue, today, upcoming, completed }

TaskTimeGroup taskTimeGroup(StaffTask task, DateTime now) {
  if (!task.isOpen) return TaskTimeGroup.completed;
  if (task.priority == WorkPriority.urgent) return TaskTimeGroup.urgent;
  // Waiting/blocked work whose review time has passed needs the owner now,
  // whatever its original deadline.
  final review = task.nextReviewAt;
  if (review != null && review.isBefore(now)) return TaskTimeGroup.overdue;
  final due = task.dueAt;
  if (due == null) return TaskTimeGroup.upcoming;
  if (due.isBefore(now)) return TaskTimeGroup.overdue;
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  return due.isBefore(tomorrow) ? TaskTimeGroup.today : TaskTimeGroup.upcoming;
}

List<StaffTask> visibleStaffWork(
  List<StaffTask> tasks, {
  required String staffId,
  required StaffWorkView view,
  required DateTime now,
  required double aiWeight,
  String query = '',
  TaskKind? kind,
  Map<String, String> names = const {},
}) {
  final needle = query.trim().toLowerCase();
  final result = tasks.where((t) {
    // Filtering never broadens the service's ownership or clinical scope.
    if (view != StaffWorkView.team &&
        t.staffId != staffId &&
        t.coverageStaffId != staffId) {
      return false;
    }
    final matchesView = switch (view) {
      StaffWorkView.team => t.isOpen,
      StaffWorkView.mine => t.isOpen && t.staffId == staffId,
      StaffWorkView.covering =>
        t.isOpen && t.staffId != staffId && t.coverageStaffId == staffId,
      StaffWorkView.completed => !t.isOpen,
    };
    return matchesView &&
        (kind == null || t.kind == kind) &&
        (needle.isEmpty ||
            '${t.title} ${t.patientId ?? ''} ${t.staffId} ${t.id} ${names[t.patientId] ?? ''} ${names[t.staffId] ?? ''}'
                .toLowerCase()
                .contains(needle));
  }).toList();
  result.sort((a, b) {
    final group = taskTimeGroup(
      a,
      now,
    ).index.compareTo(taskTimeGroup(b, now).index);
    if (group != 0) return group;
    // Waiting/blocked work is ordered by its next review time, soonest first.
    final ra = a.nextReviewAt, rb = b.nextReviewAt;
    if (ra != null && rb != null) return ra.compareTo(rb);
    return compareStaffTasks(a, b, aiWeight: aiWeight);
  });
  return result;
}

/// The latest handover offer on a task. An offer never transfers
/// responsibility by itself: only an acceptance does, and only until the
/// offer's expiry.
enum HandoverState { none, pending, accepted, declined, expired }

/// Derives [HandoverState] from task history entries
/// `(action, afterJson, at)`.
HandoverState handoverState(
  Iterable<(String, String, DateTime)> history,
  DateTime now,
) {
  Map<String, dynamic> data(String json) =>
      jsonDecode(json) as Map<String, dynamic>;
  final offers = [
    for (final h in history)
      if (h.$1 == 'task.offer') h,
  ]..sort((a, b) => a.$3.compareTo(b.$3));
  if (offers.isEmpty) return HandoverState.none;
  final latest = data(offers.last.$2);
  final bundle = latest['bundle'];
  final expires = DateTime.tryParse('${latest['expires']}');
  final expired = expires != null && !expires.isAfter(now);
  for (final h in history) {
    if (data(h.$2)['bundle'] != bundle) continue;
    if (h.$1 == 'task.offer.accepted') {
      return expired ? HandoverState.expired : HandoverState.accepted;
    }
    if (h.$1 == 'task.offer.declined') return HandoverState.declined;
  }
  return expired ? HandoverState.expired : HandoverState.pending;
}
