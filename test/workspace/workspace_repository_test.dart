import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/identity/identity.dart';
import 'package:myhealthcare/features/workspace/workspace_repository.dart';
import '../support/sessions.dart';

void main() {
  test(
    'Bahrain day/month boundaries and integer fils are device independent',
    () {
      expect(
        clinicDay(DateTime.utc(2026, 9, 30, 21)),
        DateTime.utc(2026, 10, 1),
      );
      expect(
        clinicStart(DateTime.utc(2026, 10, 1)),
        DateTime.utc(2026, 9, 30, 21),
      );
      expect(fils(12.345), 12345);
      expect(fils(0.1) + fils(0.2), 300);
    },
  );
  test(
    'history scopes before search/pagination and counts unique completed patients',
    () async {
      final (c, db) = await seededContainer();
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await signInAs(c, 'staff1@myhealth.demo');
      final expected =
          (await (db.select(db.appointments)..where(
                    (a) =>
                        a.staffId.equals('staff_01') &
                        a.status.equalsValue(AppointmentStatus.completed),
                  ))
                  .get())
              .map((a) => a.patientId)
              .toSet();
      final repo = c.read(workspaceRepositoryProvider);
      final first = await repo.read('history', {'limit': 1});
      final stats = Map<String, dynamic>.from(first['stats'] as Map);
      expect(stats['total'], expected.length);
      expect(first['total'], expected.length);
      expect((first['rows'] as List).length, expected.isEmpty ? 0 : 1);
      final all = await repo.read('history', {'limit': 200});
      expect(
        (all['rows'] as List).map((r) => (r as Map)['id']).toSet(),
        expected,
      );
      final stranger =
          (await (db.select(db.users)..where(
                    (u) =>
                        u.role.equalsValue(UserRole.patient) &
                        u.id.isNotIn(expected),
                  ))
                  .get())
              .first;
      final search = await repo.read('history', {'query': stranger.id});
      expect(search['total'], 0);
      expect(search['rows'], isEmpty);
      // A real upcoming care relationship remains independent of completed history.
      final future =
          (await (db.select(db.appointments)..where(
                    (a) =>
                        a.staffId.equals('staff_01') &
                        a.status.equalsValue(AppointmentStatus.booked),
                  ))
                  .get())
              .firstOrNull;
      if (future != null)
        expect(
          (await c.read(patientRepositoryProvider).byId(future.patientId)).isOk,
          isTrue,
        );
    },
  );
  test(
    'nurse history requires explicit personal participation and forbids reception',
    () async {
      final (c, db) = await seededContainer();
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await signInAs(c, 'nurse@myhealth.demo');
      final repo = c.read(workspaceRepositoryProvider);
      expect((await repo.read('history'))['total'], 0);
      final visit =
          (await (db.select(db.appointments)..where(
                    (a) => a.status.equalsValue(AppointmentStatus.completed),
                  ))
                  .get())
              .first;
      // Trusted fixture grants current care, which alone still creates no history.
      await db
          .into(db.careTeamAssignments)
          .insert(
            CareTeamAssignmentsCompanion.insert(
              id: 'nurse-history-assignment',
              patientId: visit.patientId,
              staffId: 'staff_nurse',
              role: CareTeamRole.values.first,
              assignedAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
          );
      expect((await repo.read('history'))['total'], 0);
      await repo.recordParticipation(visit.id);
      await repo.recordParticipation(visit.id);
      expect((await repo.read('history'))['total'], 1);
      expect((await db.select(db.encounterParticipants).get()).length, 1);
      await signInAs(c, 'reception@myhealth.demo');
      await expectLater(repo.read('history'), throwsA(isA<AuthFailure>()));
      await expectLater(
        repo.recordParticipation(visit.id),
        throwsA(isA<AuthFailure>()),
      );
    },
  );
  test(
    'daily receipts use settlement day and exclude wallet topups and their refunds',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      final day = DateTime.utc(2040, 1, 2);
      final at = clinicStart(day).add(const Duration(minutes: 1));
      Future<void> payment(
        String id,
        PaymentKind kind,
        double amount, {
        String? original,
        PaymentStatus status = PaymentStatus.settled,
      }) async {
        await db
            .into(db.paymentTransactions)
            .insert(
              PaymentTransactionsCompanion.insert(
                id: id,
                patientId: 'patient_001',
                kind: kind,
                method: PaymentMethodKind.offline,
                amount: amount,
                provider: 'offline',
                requestReference: id,
                createdAt: at.subtract(const Duration(days: 1)),
                updatedAt: at,
                settledAt: Value(status == PaymentStatus.settled ? at : null),
                refundOfId: Value(original),
                status: Value(status),
              ),
            );
      }

      await payment('report-charge', PaymentKind.invoiceCharge, 0.3);
      await payment(
        'report-refund',
        PaymentKind.refund,
        0.1,
        original: 'report-charge',
      );
      await payment('report-topup', PaymentKind.walletTopUp, 10);
      await payment(
        'report-topup-refund',
        PaymentKind.refund,
        2,
        original: 'report-topup',
      );
      await payment(
        'report-failed',
        PaymentKind.invoiceCharge,
        9,
        status: PaymentStatus.failed,
      );
      final data = await c.read(workspaceRepositoryProvider).read('overview', {
        'day': '2040-01-02',
        'days': 1,
        'revenueDays': 1,
      });
      final revenue = (data['revenue'] as List).single as Map;
      expect(revenue['payments'], 300);
      expect(revenue['refunds'], 100);
    },
  );
  test(
    'room inventory is explicit, versioned, audited and authorized',
    () async {
      final (c, db) = await seededContainer();
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await signInAs(c, 'admin@myhealth.demo');
      final repo = c.read(workspaceRepositoryProvider);
      expect((await repo.read('rooms'))['rows'], isEmpty);
      final refreshed = Completer<void>();
      final subscription = c.listen(workspaceOverviewProvider, (_, next) {
        if ((next.asData?.value['stats'] as Map?)?['rooms'] == 1 &&
            !refreshed.isCompleted) {
          refreshed.complete();
        }
      });
      addTearDown(subscription.close);
      await c.read(workspaceOverviewProvider.future);
      await repo.saveRoom(label: 'A-02', enabled: true);
      await refreshed.future.timeout(const Duration(seconds: 5));
      final room = Map<String, dynamic>.from(
        ((await repo.read('rooms'))['rows'] as List).single as Map,
      );
      await repo.saveRoom(
        id: room['id'] as String,
        label: 'A-02',
        enabled: false,
        version: 1,
      );
      await expectLater(
        repo.saveRoom(
          id: room['id'] as String,
          label: 'Stale',
          enabled: true,
          version: 1,
        ),
        throwsA(isA<ConflictFailure>()),
      );
      expect((await db.select(db.clinicRooms).get()).single.enabled, isFalse);
      expect(
        (await (db.select(
          db.auditLog,
        )..where((a) => a.action.equals('room.saved'))).get()).length,
        2,
      );
      await signInAs(c, 'patient1@myhealth.demo');
      await expectLater(repo.read('rooms'), throwsA(isA<AuthFailure>()));
    },
  );
}
