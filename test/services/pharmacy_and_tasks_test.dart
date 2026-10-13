// Pharmacist dispensing (separate from prescribing, never twice) and the
// first-class task next-review time.
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/pharmacy_repository.dart';

import '../support/sessions.dart';

void main() {
  group('pharmacy', () {
    test('only pharmacists see the queue', () async {
      final (c, _) = await seededContainer();
      await signInAs(c, 'reception@myhealth.demo');
      expect(
        (await c.read(pharmacyRepositoryProvider).queue()).failureOrNull,
        isA<AccessDeniedFailure>(),
      );
      await signInAs(c, 'pharmacy@myhealth.demo');
      final queue =
          (await c.read(pharmacyRepositoryProvider).queue()).valueOrNull!;
      expect(queue, isNotEmpty);
      expect(queue.every((o) => o.prescriberName.isNotEmpty), isTrue);
    });

    test(
      'dispenses once; retries and second dispenses do not duplicate',
      () async {
        final (c, db) = await seededContainer();
        await signInAs(c, 'pharmacy@myhealth.demo');
        final repo = c.read(pharmacyRepositoryProvider);
        final order = (await repo.queue()).valueOrNull!.first;
        DispenseInput input(String key, {bool verified = true}) =>
            DispenseInput(
              medicationId: order.medicationId,
              outcome: DispenseOutcome.dispensed,
              patientVerified: verified,
              quantity: '30 tablets',
              expiry: DateTime.now().add(const Duration(days: 200)),
              idempotencyKey: key,
            );

        expect(
          (await repo.record(input('a', verified: false))).failureOrNull,
          isA<ValidationFailure>(),
        );
        expect((await repo.record(input('a'))).isOk, isTrue);
        expect((await repo.record(input('a'))).isOk, isTrue); // retry
        expect(
          (await repo.record(input('b'))).failureOrNull,
          isA<ConflictFailure>(),
        );
        final rows = await db.select(db.medicationDispenses).get();
        expect(rows, hasLength(1));
        expect(rows.single.pharmacistId, 'staff_pharmacy');
        // The order itself is untouched.
        final med = await (db.select(
          db.medications,
        )..where((m) => m.id.equals(order.medicationId))).getSingle();
        expect(med.name, order.name);
      },
    );

    test('a hold needs a reason and an expired batch is refused', () async {
      final (c, _) = await seededContainer();
      await signInAs(c, 'pharmacy@myhealth.demo');
      final repo = c.read(pharmacyRepositoryProvider);
      final id = (await repo.queue()).valueOrNull!.first.medicationId;
      expect(
        (await repo.record(
          DispenseInput(
            medicationId: id,
            outcome: DispenseOutcome.held,
            patientVerified: true,
            idempotencyKey: 'h',
          ),
        )).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(
        (await repo.record(
          DispenseInput(
            medicationId: id,
            outcome: DispenseOutcome.dispensed,
            patientVerified: true,
            quantity: '1',
            expiry: DateTime.now().subtract(const Duration(days: 1)),
            idempotencyKey: 'e',
          ),
        )).failureOrNull,
        isA<ValidationFailure>(),
      );
    });
  });

  test('waiting work stores a first-class next review time', () async {
    final (c, _) = await seededContainer();
    const owner = 'staff_01';
    await signInAs(c, 'staff1@myhealth.demo');
    final repo = c.read(taskRepositoryProvider);
    final task = StaffTask(
      id: 'review-task',
      staffId: owner,
      title: 'Call back about results',
      kind: TaskKind.followUpDue,
      status: TaskStatus.open,
      ruleScore: 0,
      createdAt: DateTime.now(),
      dueAt: DateTime.now().add(const Duration(days: 1)),
    );
    expect((await repo.upsert(task)).isOk, isTrue);
    final review = DateTime.now().add(const Duration(hours: 4));
    expect(
      (await repo.setStatus(
        id: task.id,
        staffId: owner,
        status: TaskStatus.waiting,
        outcome: 'Awaiting lab callback',
        reviewAt: review,
      )).isOk,
      isTrue,
    );
    final waiting = (await repo.forStaff(
      'staff_01',
    )).valueOrNull!.firstWhere((t) => t.id == task.id);
    expect(waiting.nextReviewAt, isNotNull);
    expect(
      waiting.nextReviewAt!.difference(review).inSeconds.abs(),
      lessThan(2),
    );
    // The original due date is unchanged and distinct.
    expect(waiting.dueAt!.difference(task.dueAt!).inSeconds.abs(), lessThan(2));

    await repo.setStatus(
      id: task.id,
      staffId: owner,
      status: TaskStatus.inProgress,
    );
    final active = (await repo.forStaff(
      'staff_01',
    )).valueOrNull!.firstWhere((t) => t.id == task.id);
    expect(active.nextReviewAt, isNull);
  });
}
