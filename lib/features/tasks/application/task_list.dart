import '../../../domain/entities/staff_task.dart';
import '../../../domain/enums.dart';

enum StaffWorkView { mine, covering, team, completed }

enum TaskTimeGroup { urgent, overdue, today, upcoming, completed }

TaskTimeGroup taskTimeGroup(StaffTask task, DateTime now) {
  if (!task.isOpen) return TaskTimeGroup.completed;
  if (task.priority == WorkPriority.urgent) return TaskTimeGroup.urgent;
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
    return group != 0 ? group : compareStaffTasks(a, b, aiWeight: aiWeight);
  });
  return result;
}
