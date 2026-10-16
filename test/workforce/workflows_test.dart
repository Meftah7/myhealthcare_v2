import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/demo_workforce.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/pharmacy_repository.dart';
import 'package:myhealthcare/features/workforce/workforce_repository.dart';
import '../support/sessions.dart';

void main() {
  test(
    'all configured staff and admins sign in through the normal session service',
    () async {
      final (c, db) = await seededContainer();
      for (final account in demoWorkforceAccounts) {
        await signInAs(c, account['email'] as String);
      }
      final before = await db.select(db.users).get();
      await DemoWorkforce(db, demoEnabled: true).repair();
      expect((await db.select(db.users).get()).length, before.length);
      expect(before.where((u) => u.role == UserRole.staff).length, 44);
      expect(before.where((u) => u.role == UserRole.admin).length, 2);
    },
  );
  test(
    'role homes use live data and nursing participation does not sign or complete the encounter',
    () async {
      final (c, db) = await seededContainer();
      for (final role in [
        'staff1',
        'nurse',
        'reception',
        'pharmacy',
        'dentist',
      ]) {
        await signInAs(c, '$role@myhealth.demo');
        final data = await c.read(workforceRepositoryProvider).read('home');
        expect(data['stats'], isA<Map<String, dynamic>>());
      }
      await signInAs(c, 'nurse@myhealth.demo');
      final repo = c.read(workforceRepositoryProvider);
      final intake = Map<String, dynamic>.from(
        ((await repo.read('intakes'))['rows'] as List).first as Map,
      );
      await repo.saveIntake(
        intake: intake,
        note: 'Synthetic nursing observation',
        requestKey: 'nursing-once',
        temperature: 36.8,
        pulse: 72,
        oxygen: 98,
      );
      await repo.saveIntake(
        intake: intake,
        note: 'Synthetic nursing observation',
        requestKey: 'nursing-once',
        temperature: 36.8,
        pulse: 72,
        oxygen: 98,
      );
      final visit =
          await (db.select(db.appointments)
                ..where((a) => a.id.equals(intake['appointment_id'] as String)))
              .getSingle();
      expect(visit.status, isNot(AppointmentStatus.completed));
      expect(
        (await (db.select(
          db.signedNotes,
        )..where((s) => s.appointmentId.equals(visit.id))).get()),
        isEmpty,
      );
      expect(
        (await (db.select(db.encounterParticipants)..where(
              (p) =>
                  p.appointmentId.equals(visit.id) &
                  p.staffId.equals('staff_nurse'),
            ))
            .get()),
        hasLength(1),
      );
    },
  );
  test('a hold cannot bypass an unresolved pharmacy clarification', () async {
    final (c, _) = await seededContainer();
    await signInAs(c, 'pharmacy@myhealth.demo');
    final repo = c.read(pharmacyRepositoryProvider);
    final order = (await repo.queue()).valueOrNull!.first;
    Future<bool> record(DispenseOutcome outcome, String key) => repo
        .record(
          DispenseInput(
            medicationId: order.medicationId,
            outcome: outcome,
            patientVerified: true,
            idempotencyKey: key,
            quantity: '1 tablet',
            note: 'Synthetic review',
          ),
        )
        .then((r) => r.isOk);
    expect(
      await record(DispenseOutcome.clarificationRequested, 'question'),
      true,
    );
    expect(await record(DispenseOutcome.held, 'hold'), true);
    expect((await repo.queue()).valueOrNull!.first.clarificationPending, true);
    expect(await record(DispenseOutcome.dispensed, 'supply'), false);
  });
  test(
    'team messages are persisted and deny nonmembers after a role switch',
    () async {
      final (c, _) = await seededContainer();
      await signInAs(c, 'reception@myhealth.demo');
      final repo = c.read(workforceRepositoryProvider);
      final id = await repo.startConversation('staff_pharmacy');
      await repo.send(id, 'Synthetic team question', 'message-once');
      await repo.send(id, 'Synthetic team question', 'message-once');
      await signInAs(c, 'pharmacy@myhealth.demo');
      expect((await repo.read('thread', {'id': id}))['rows'], hasLength(1));
      await signInAs(c, 'nurse@myhealth.demo');
      await expectLater(repo.read('thread', {'id': id}), throwsA(anything));
    },
  );
}
