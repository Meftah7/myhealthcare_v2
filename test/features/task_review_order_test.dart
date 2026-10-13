// Next review time is first-class on the board: a passed review surfaces as
// overdue and waiting work is ordered by review time.
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/tasks/application/task_list.dart';

StaffTask _task(String id, {DateTime? due, DateTime? review}) => StaffTask(
  id: id,
  staffId: 's',
  title: id,
  kind: TaskKind.followUpDue,
  status: review == null ? TaskStatus.open : TaskStatus.waiting,
  ruleScore: 0,
  createdAt: DateTime(2026),
  dueAt: due,
  nextReviewAt: review,
);

void main() {
  final now = DateTime(2026, 10, 13, 12);

  test('a passed review is overdue even before the deadline', () {
    final t = _task(
      'a',
      due: now.add(const Duration(days: 3)),
      review: now.subtract(const Duration(hours: 1)),
    );
    expect(taskTimeGroup(t, now), TaskTimeGroup.overdue);
    expect(t.dueAt, isNot(t.nextReviewAt));
  });

  test('waiting work is ordered by next review time', () {
    final later = _task('later', review: now.add(const Duration(days: 2)));
    final sooner = _task('sooner', review: now.add(const Duration(days: 1)));
    final list = visibleStaffWork(
      [later, sooner],
      staffId: 's',
      view: StaffWorkView.mine,
      now: now,
      aiWeight: 0.5,
    );
    expect(list.map((t) => t.id), ['sooner', 'later']);
  });
}
