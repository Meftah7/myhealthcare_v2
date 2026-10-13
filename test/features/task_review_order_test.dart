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

  group('handover state', () {
    String j(Map<String, Object?> m) =>
        '{${m.entries.map((e) => '"${e.key}":"${e.value}"').join(',')}}';
    final offer = (
      'task.offer',
      j({
        'bundle': 'b1',
        'expires': now.add(const Duration(hours: 4)).toIso8601String(),
      }),
      now.subtract(const Duration(hours: 1)),
    );

    test('an offer alone is pending, not a transfer', () {
      expect(handoverState([offer], now), HandoverState.pending);
      expect(handoverState(const [], now), HandoverState.none);
    });

    test('accepted, declined and expired', () {
      final accepted = ('task.offer.accepted', j({'bundle': 'b1'}), now);
      final declined = ('task.offer.declined', j({'bundle': 'b1'}), now);
      expect(handoverState([offer, accepted], now), HandoverState.accepted);
      expect(handoverState([offer, declined], now), HandoverState.declined);
      final later = now.add(const Duration(hours: 5));
      expect(handoverState([offer], later), HandoverState.expired);
      expect(handoverState([offer, accepted], later), HandoverState.expired);
    });
  });
}
