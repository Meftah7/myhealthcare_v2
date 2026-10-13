// Receptionist (front desk) scope: books and checks in on a patient's
// behalf, confirms issued copies administratively, and never signs,
// issues or reads the clinical chart.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myhealthcare/core/data/contracts.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/identity/permissions.dart';
import 'package:myhealthcare/domain/repositories/repositories.dart';

import '../support/sessions.dart';
import 'document_service_test.dart'
    show TestRenderer, approved, grant, setup, value;

typedef ProviderContainerDb = (ProviderContainer, AppDatabase);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<DateTime> freeSlot(ProviderContainerDb ctx) async {
    final (c, _) = ctx;
    final day = DateTime.now().add(const Duration(days: 7));
    for (var i = 0; i < 14; i++) {
      final slots =
          (await c
                  .read(appointmentRepositoryProvider)
                  .openSlots('staff_01', day.add(Duration(days: i))))
              .valueOrNull;
      if (slots != null && slots.isNotEmpty) return slots.first.start;
    }
    throw StateError('no open slot');
  }

  test('reception books on behalf; a retry books once', () async {
    final ctx = await seededContainer();
    final (c, db) = ctx;
    await signInAs(c, 'reception@myhealth.demo');
    final start = await freeSlot(ctx);
    final request = BookingRequest(
      patientId: 'patient_002',
      staffId: 'staff_01',
      start: start,
      end: start.add(const Duration(minutes: 20)),
      visitType: VisitType.followUp,
      idempotencyKey: IdempotencyKey.generate(),
    );
    final repo = c.read(appointmentRepositoryProvider);
    final first = value(await repo.book(request));
    final retry = value(await repo.book(request));
    expect(retry.id, first.id);
    expect(first.patientId, 'patient_002');
    final row = await (db.select(
      db.appointments,
    )..where((a) => a.id.equals(first.id))).getSingle();
    expect(row.bookedByAccountId, 'staff_reception');
  });

  test('reception check-in is idempotent and needs the permission', () async {
    final (c, db) = await seededContainer();
    final booked =
        await (db.select(db.appointments)
              ..where((a) => a.status.equalsValue(AppointmentStatus.booked))
              ..limit(1))
            .getSingle();
    final repo = c.read(appointmentRepositoryProvider);

    await signInAs(c, 'pharmacy@myhealth.demo');
    expect(
      (await repo.deskCheckIn(booked.id, at: DateTime.now())).failureOrNull,
      isA<AccessDeniedFailure>(),
    );

    await signInAs(c, 'reception@myhealth.demo');
    final at = DateTime.now();
    expect((await repo.deskCheckIn(booked.id, at: at)).isOk, isTrue);
    final after = await (db.select(
      db.appointments,
    )..where((a) => a.id.equals(booked.id))).getSingle();
    expect(after.checkedInAt, isNotNull);
    expect(after.status, AppointmentStatus.confirmed);
    // A repeated tap changes nothing.
    expect(
      (await repo.deskCheckIn(booked.id, at: DateTime.now())).isOk,
      isTrue,
    );
    final again = await (db.select(
      db.appointments,
    )..where((a) => a.id.equals(booked.id))).getSingle();
    expect(again.version, after.version);
  });

  group('issued copy confirmation', () {
    Future<(ProviderContainerDb, String)> issued() async {
      final ctx = await seededContainer(
        overrides: [
          issuedSickLeaveRendererProvider.overrideWithValue(TestRenderer()),
        ],
      );
      final (c, db) = ctx;
      final visit = await setup(db);
      await signInAs(c, 'staff1@myhealth.demo');
      final service = c.read(documentServiceProvider);
      final request = await approved(service, visit);
      final doc = value(
        await service.issue(
          request.id,
          expectedVersion: request.version,
          idempotencyKey: 'desk-issue',
        ),
      );
      value(await service.render(doc.id));
      return (ctx, doc.id);
    }

    test('records who confirmed, once per key, without signing', () async {
      final ((c, db), id) = await issued();
      await signInAs(c, 'reception@myhealth.demo');
      final service = c.read(documentServiceProvider);
      final missingId = await service.confirmIssuedCopy(
        id,
        recipientIdentityChecked: false,
        reason: 'Collected at desk',
        idempotencyKey: 'k1',
      );
      expect(missingId.failureOrNull, isA<ValidationFailure>());

      value(
        await service.confirmIssuedCopy(
          id,
          recipientIdentityChecked: true,
          reason: 'Collected at desk',
          idempotencyKey: 'k1',
        ),
      );
      value(
        await service.confirmIssuedCopy(
          id,
          recipientIdentityChecked: true,
          reason: 'Collected at desk',
          idempotencyKey: 'k1',
        ),
      );
      final rows = await db.select(db.documentCopyConfirmations).get();
      expect(rows, hasLength(1));
      expect(rows.single.confirmedBy, 'staff_reception');
      // Confirmation never creates another issued version.
      expect(await db.select(db.issuedDocumentVersions).get(), hasLength(1));
    });

    test('desk looks a copy up by its printed reference', () async {
      final ((c, db), id) = await issued();
      final code = (await (db.select(
        db.documentVerifications,
      )..where((v) => v.issuedVersionId.equals(id))).getSingle()).code;
      await signInAs(c, 'reception@myhealth.demo');
      final service = c.read(documentServiceProvider);
      final found = value(await service.findForDesk(' ${code.toLowerCase()} '));
      expect(found.id, id);
      expect(
        (await service.findForDesk('NOPE-0000')).failureOrNull,
        isA<NotFoundFailure>(),
      );
      await signInAs(c, 'staff1@myhealth.demo');
      expect(
        (await c.read(documentServiceProvider).findForDesk(code)).failureOrNull,
        isA<AccessDeniedFailure>(),
      );
    });

    test('a revoked copy cannot be confirmed', () async {
      final ((c, db), id) = await issued();
      await grant(db, 'staff_01', Permission.revokeDocument);
      final service = c.read(documentServiceProvider);
      value(await service.revoke(id, reason: 'Issued in error'));
      await signInAs(c, 'reception@myhealth.demo');
      final r = await service.confirmIssuedCopy(
        id,
        recipientIdentityChecked: true,
        reason: 'Reprint',
        idempotencyKey: 'k2',
      );
      expect(r.failureOrNull, isA<ConflictFailure>());
      expect(await db.select(db.documentCopyConfirmations).get(), isEmpty);
    });

    test('clinicians without the desk grant cannot confirm', () async {
      final ((c, _), id) = await issued();
      final r = await c
          .read(documentServiceProvider)
          .confirmIssuedCopy(
            id,
            recipientIdentityChecked: true,
            reason: 'x',
            idempotencyKey: 'k3',
          );
      expect(r.failureOrNull, isA<AccessDeniedFailure>());
    });
  });
}
