// Gate 2 — authoritative data: retried mutations never duplicate work, stale
// edits conflict instead of overwriting, side effects go through the outbox
// (atomically, retried independently), the audit log is append-only, the
// same state is visible from two sessions, reads page honestly, analytics
// carry no health text, and a populated v18 database migrates intact.

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/data/contracts.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/db/tables/sync.dart';
import 'package:myhealthcare/data/repositories/appointment_repository_impl.dart';
import 'package:myhealthcare/data/repositories/consultation_repository_impl.dart';
import 'package:myhealthcare/data/repositories/notification_repository_impl.dart';
import 'package:myhealthcare/data/repositories/system_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/data/sync/outbox.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/repositories.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/sessions.dart';
import '../support/test_database.dart';

Future<DateTime> _slot(AppDatabase db, String staffId) async {
  final repo = AppointmentRepositoryImpl(db);
  var day = DateTime.now().add(const Duration(days: 2));
  for (var i = 0; i < 21; i++, day = day.add(const Duration(days: 1))) {
    final slots = (await repo.openSlots(staffId, day)).valueOrNull ?? const [];
    if (slots.isNotEmpty) return slots.first.start;
  }
  throw StateError('no open slot for $staffId');
}

NewNotification _note(String to) => NewNotification(
  recipientId: to,
  category: NotificationCategory.system,
  title: 'Hello',
  body: 'World',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('retries never duplicate committed work', () {
    test('a booking retried with the same key books once', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      final start = await _slot(db, 'staff_01');
      final request = BookingRequest(
        patientId: 'patient_001',
        staffId: 'staff_01',
        start: start,
        end: start.add(const Duration(minutes: 20)),
        visitType: VisitType.followUp,
        idempotencyKey: IdempotencyKey.generate(),
        notify: [_note('patient_001')],
      );
      final repo = c.read(appointmentRepositoryProvider);
      final first = (await repo.book(request)).valueOrNull!;
      final retry = await repo.book(request);
      expect(retry.valueOrNull?.id, first.id);
      final rows = await (db.select(
        db.appointments,
      )..where((a) => a.slotStart.equals(start))).get();
      expect(rows, hasLength(1));
      // …and its side effect was recorded once.
      expect(await db.select(db.outboxEvents).get(), hasLength(1));
    });

    test('a wallet top-up and payment retried with the same key move money '
        'once', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      final invoice =
          (await c
                  .read(billingRepositoryProvider)
                  .issue(
                    const NewInvoice(patientId: 'patient_001', subtotal: 10),
                  ))
              .valueOrNull!;
      await signInAs(c, 'patient1@myhealth.demo');
      final billing = c.read(billingRepositoryProvider);
      const card = CardPayment(
        cardNumber: '4242424242424242',
        cardHolder: 'P',
        expiryMonth: 12,
        expiryYear: 2099,
        cvc: '123',
      );
      final start = (await billing.walletBalance('patient_001')).valueOrNull!;
      final topUp = IdempotencyKey.generate();
      for (var i = 0; i < 2; i++) {
        await billing.topUpWallet(
          patientId: 'patient_001',
          amount: 50,
          card: card,
          idempotencyKey: topUp,
        );
      }
      expect(
        (await billing.walletBalance('patient_001')).valueOrNull,
        closeTo(start + 50, 0.0001),
      );
      final pay = IdempotencyKey.generate();
      final first = await billing.payWithWallet(
        invoiceId: invoice.id,
        patientId: 'patient_001',
        idempotencyKey: pay,
      );
      final retry = await billing.payWithWallet(
        invoiceId: invoice.id,
        patientId: 'patient_001',
        idempotencyKey: pay,
      );
      expect(first.isOk, isTrue, reason: '$first');
      expect(retry.valueOrNull?.status, InvoiceStatus.paid);
      expect(
        (await billing.walletBalance('patient_001')).valueOrNull,
        closeTo(start + 50 - invoice.totalAmount, 0.0001),
      );
    });

    test('a key cannot be reused for a different action or account', () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient1@myhealth.demo');
      final key = IdempotencyKey.generate();
      final start = await _slot(db, 'staff_01');
      await c
          .read(appointmentRepositoryProvider)
          .book(
            BookingRequest(
              patientId: 'patient_001',
              staffId: 'staff_01',
              start: start,
              end: start.add(const Duration(minutes: 20)),
              visitType: VisitType.followUp,
              idempotencyKey: key,
            ),
          );
      final reused = await c
          .read(billingRepositoryProvider)
          .topUpWallet(
            patientId: 'patient_001',
            amount: 5,
            card: const CardPayment(
              cardNumber: '4242424242424242',
              cardHolder: 'P',
              expiryMonth: 12,
              expiryYear: 2099,
              cvc: '123',
            ),
            idempotencyKey: key,
          );
      expect(reused.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('optimistic concurrency', () {
    test('every update bumps the version, via the database itself', () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await Seeder(db).run();
      final row = await (db.select(db.appointments)..limit(1)).getSingle();
      expect(row.version, 1);
      await (db.update(db.appointments)..where((a) => a.id.equals(row.id)))
          .write(const AppointmentsCompanion(outcomeNote: Value('x')));
      final after = await (db.select(
        db.appointments,
      )..where((a) => a.id.equals(row.id))).getSingle();
      expect(after.version, 2);
    });

    test(
      'an edit based on a stale copy conflicts instead of overwriting',
      () async {
        final (c, db) = await seededContainer();
        await signInAs(c, 'patient1@myhealth.demo');
        final repo = c.read(patientRepositoryProvider);
        final mine = (await repo.byId('patient_001')).valueOrNull!;
        // Another device saves first.
        expect(
          await repo.updateProfile(mine.copyWith(emergencyContact: 'A')),
          isA<Ok<void>>(),
        );
        // This device still holds the old version.
        final stale = await repo.updateProfile(
          mine.copyWith(emergencyContact: 'B'),
        );
        expect(stale.failureOrNull, isA<ConflictFailure>());
        final saved = (await repo.byId('patient_001')).valueOrNull!;
        expect(saved.emergencyContact, 'A');
      },
    );

    test('a staff change on a stale appointment version conflicts', () async {
      final (c, db) = await seededContainer();
      final appt =
          await (db.select(db.appointments)
                ..where(
                  (a) =>
                      a.staffId.equals('staff_01') &
                      a.status.equalsValue(AppointmentStatus.booked),
                )
                ..limit(1))
              .getSingle();
      await signInAs(c, 'staff1@myhealth.demo');
      final r = await c
          .read(appointmentRepositoryProvider)
          .updateStatus(
            id: appt.id,
            staffId: 'staff_01',
            status: AppointmentStatus.confirmed,
            expectedVersion: appt.version + 1,
          );
      expect(r.failureOrNull, isA<ConflictFailure>());
    });

    test('two clinicians claiming one walk-in: exactly one wins', () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await Seeder(db).run();
      final walkIns = WalkInTicketRepositoryImpl(db);
      final dept = await (db.select(db.departments)..limit(1)).getSingle();
      final ticket = (await walkIns.create(
        NewWalkInTicket(
          patientId: 'patient_001',
          departmentId: dept.id,
          createdByStaffId: 'staff_01',
        ),
      )).valueOrNull!;
      // Each clinician opened their own visit for the ticket.
      final visits = await (db.select(db.appointments)..limit(2)).get();
      final results = await Future.wait([
        walkIns.claim(
          id: ticket.id,
          doctorId: 'staff_01',
          resultAppointmentId: visits[0].id,
        ),
        walkIns.claim(
          id: ticket.id,
          doctorId: 'staff_02',
          resultAppointmentId: visits[1].id,
        ),
      ]);
      expect(results.where((r) => r.isOk), hasLength(1));
      expect(
        results.where((r) => r.failureOrNull is ConflictFailure),
        hasLength(1),
      );
    });
  });

  group('outbox', () {
    test(
      'a side effect is delivered once, however often the dispatcher runs',
      () async {
        final db = newTestDatabase();
        addTearDown(db.close);
        await Seeder(db).run();
        final before = (await db.select(db.notifications).get()).length;
        await NotificationRepositoryImpl(db).send(_note('patient_001'));
        // Recorded, not yet delivered.
        expect((await db.select(db.notifications).get()).length, before);
        final dispatcher = OutboxDispatcher(db);
        expect(await dispatcher.drain(), 1);
        expect(await dispatcher.drain(), 0);
        expect((await db.select(db.notifications).get()).length, before + 1);
      },
    );

    test(
      'a failed delivery never undoes the change and is retried later',
      () async {
        final db = newTestDatabase();
        addTearDown(db.close);
        await Seeder(db).run();
        var now = DateTime.now();
        await NotificationRepositoryImpl(db).send(_note('patient_001'));
        final failing = OutboxDispatcher(
          db,
          now: () => now,
          handlers: {
            OutboxTypes.deliverNotification: (_, _) async =>
                throw StateError('provider down'),
          },
        );
        expect(await failing.drain(), 0);
        final event = (await db.select(db.outboxEvents).get()).single;
        expect(event.status, OutboxStatus.pending);
        expect(event.attempts, 1);
        expect(event.lastError, 'StateError'); // type only, no payload

        // Not due again yet…
        final working = OutboxDispatcher(db, now: () => now);
        expect(await working.drain(), 0);
        // …then delivered once the backoff has passed.
        now = now.add(OutboxDispatcher.backoff(1));
        expect(await working.drain(), 1);
      },
    );

    test(
      'an interrupted write leaves neither the change nor its side effect',
      () async {
        final db = newTestDatabase();
        addTearDown(db.close);
        await Seeder(db).run();
        final events = (await db.select(db.outboxEvents).get()).length;
        await expectLater(
          db.transaction(() async {
            await Outbox(db).enqueueNotification(_note('patient_001'));
            throw StateError('crash mid-write');
          }),
          throwsStateError,
        );
        expect((await db.select(db.outboxEvents).get()).length, events);
      },
    );
  });

  group('audit', () {
    test('the audit log is append-only', () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await Seeder(db).run();
      await AuditRepositoryImpl(db).record(action: 'x', entityType: 'test');
      await expectLater(
        db.customStatement("UPDATE audit_log SET action = 'y'"),
        throwsA(anything),
      );
      await expectLater(
        db.customStatement('DELETE FROM audit_log'),
        throwsA(anything),
      );
    });

    test(
      'AI analytics never keep what was typed or whose chart it was',
      () async {
        final db = newTestDatabase();
        addTearDown(db.close);
        await AiUsageRepositoryImpl(db).log(
          feature: AiFeature.clinicalScribe,
          usedLiveModel: false,
          summary: 'Pt reports chest pain, HIV positive',
        );
        final row = (await db.select(db.aiUsageLog).get()).single;
        expect(row.summary, isNot(contains('chest')));
        expect(row.summary, isNot(contains('HIV')));
      },
    );
  });

  group('two sessions, one truth', () {
    test('what one session writes, another authorized session sees', () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await Seeder(db).run();
      Future<ProviderContainer> device(Map<String, Object> prefs) async {
        SharedPreferences.setMockInitialValues(prefs);
        final c = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
            appDatabaseProvider.overrideWithValue(db),
          ],
        );
        addTearDown(c.dispose);
        return c;
      }

      final phone = await device({});
      final desk = await device({});
      await signInAs(phone, 'patient1@myhealth.demo');
      await signInAs(desk, 'patient1@myhealth.demo');

      await phone
          .read(patientRepositoryProvider)
          .updateProfile(
            (await phone.read(patientRepositoryProvider).byId('patient_001'))
                .valueOrNull!
                .copyWith(emergencyContact: '+973 1111 2222'),
          );
      final seen =
          (await desk.read(patientRepositoryProvider).byId('patient_001'))
              .valueOrNull!;
      expect(seen.emergencyContact, '+973 1111 2222');

      // A live feed on one session updates when the other writes.
      final updates = <int>[];
      final sub = desk
          .read(notificationRepositoryProvider)
          .watchForRecipient('patient_001')
          .listen((list) => updates.add(list.length));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await NotificationRepositoryImpl(db).send(_note('patient_001'));
      await OutboxDispatcher(db).drain();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(updates.last, updates.first + 1);
      expect(desk.read(sessionProvider).isAuthenticated, isTrue);
    });
  });

  test(
    'reads page honestly: pages are disjoint and say when more exist',
    () async {
      final (c, _) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      final repo = c.read(patientRepositoryProvider);
      final first = (await repo.directoryPage(
        page: const PageRequest(size: 10),
      )).valueOrNull!;
      expect(first.items, hasLength(10));
      expect(first.hasMore, isTrue);
      final second = (await repo.directoryPage(
        page: const PageRequest(size: 10).next,
      )).valueOrNull!;
      expect(
        first.items
            .map((p) => p.id)
            .toSet()
            .intersection(second.items.map((p) => p.id).toSet()),
        isEmpty,
      );
    },
  );

  test(
    'a populated v18 database migrates with rows and relationships intact',
    () async {
      final dir = await Directory.systemTemp.createTemp('mhc_mig');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/db.sqlite');

      // Build a populated database, then turn it back into its v18 shape.
      final seeded = AppDatabase(NativeDatabase(file));
      await Seeder(seeded).run();
      Future<int> count(AppDatabase db, String table) async =>
          (await db
                  .customSelect('SELECT COUNT(*) AS n FROM $table')
                  .getSingle())
              .read<int>('n');
      const tables = ['users', 'appointments', 'invoices', 'medical_records'];
      final before = {for (final t in tables) t: await count(seeded, t)};
      for (final stmt in [
        'DROP TABLE outbox_events',
        'DROP TABLE idempotency_records',
        'DROP INDEX idx_notifications_source_event',
        for (final t in [
          'appointments',
          'walk_in_tickets',
          'referral_requests',
          'home_visit_requests',
          'invoices',
          'patient_profiles',
          'staff_tasks',
        ]) ...[
          'DROP TRIGGER trg_${t}_version',
          'ALTER TABLE $t DROP COLUMN version',
        ],
        'DROP TRIGGER trg_audit_log_no_update',
        'DROP TRIGGER trg_audit_log_no_delete',
        'ALTER TABLE notifications DROP COLUMN source_event_id',
        'PRAGMA user_version = 18',
      ]) {
        await seeded.customStatement(stmt);
      }
      await seeded.close();

      final migrated = AppDatabase(NativeDatabase(file));
      addTearDown(migrated.close);
      for (final t in tables) {
        expect(await count(migrated, t), before[t], reason: t);
      }
      final orphans = await migrated
          .customSelect('PRAGMA foreign_key_check')
          .get();
      expect(orphans, isEmpty);
      final appt = await (migrated.select(
        migrated.appointments,
      )..limit(1)).getSingle();
      expect(appt.version, 1);
      // The new rules are live on the upgraded database.
      await AuditRepositoryImpl(
        migrated,
      ).record(action: 'post-migration', entityType: 'test');
      await expectLater(
        migrated.customStatement('DELETE FROM audit_log'),
        throwsA(anything),
      );
    },
  );
}
