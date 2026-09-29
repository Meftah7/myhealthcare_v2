// The staff consultation flow end to end: call → arrive → note + medication →
// complete, with the outputs landing in the patient's record; plus the
// doctor→admin referral request being actioned into a walk-in ticket / a
// downloadable referral letter, and a doctor starting a walk-in.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/appointment_repository.dart';
import 'package:myhealthcare/features/admin/application/admin_providers.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/consultation/application/consultation_providers.dart';
import 'package:myhealthcare/features/staff_dashboard/application/staff_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

Future<ProviderContainer> _container() async {
  final db = newTestDatabase();
  await Seeder(db).run();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWith((ref) {
        ref.onDispose(db.close);
        return db;
      }),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _login(ProviderContainer c, String email) => c
    .read(sessionProvider.notifier)
    .login(email: email, password: Seeder.demoPassword);

/// A fresh booked appointment for staff_01 + patient_001, a clear slot ahead.
/// Booked by the patient (clinicians don't book on a patient's behalf), then
/// whoever was signed in before is signed back in.
Future<String> _bookAppointment(ProviderContainer c) async {
  final previous = c.read(currentUserProvider)?.email;
  await _login(c, 'patient1@myhealth.demo');
  final now = DateTime.now();
  var start = DateTime(now.year, now.month, now.day + 2, 10);
  while (start.weekday == DateTime.friday ||
      start.weekday == DateTime.saturday) {
    start = start.add(const Duration(days: 1));
  }
  final r = await c
      .read(appointmentRepositoryProvider)
      .book(
        BookingRequest(
          patientId: 'patient_001',
          staffId: 'staff_01',
          start: start,
          end: start.add(const Duration(minutes: 20)),
          visitType: VisitType.followUp,
        ),
      );
  if (previous != null) await _login(c, previous);
  return r.valueOrNull!.id;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  test(
    'call → arrive → note + medication → complete lands in the record',
    () async {
      final c = await _container();
      await _login(c, 'staff1@myhealth.demo');

      final id = await _bookAppointment(c);
      final appt =
          (await c.read(appointmentRepositoryProvider).byId(id)).valueOrNull!;
      final ctrl = c.read(consultationControllerProvider(id));

      expect((await ctrl.callPatient()).isOk, isTrue);
      expect(
        (await c.read(consultationAppointmentProvider(id).future)).calledInAt,
        isNotNull,
      );

      expect((await ctrl.markArrived()).isOk, isTrue);
      expect(
        (await c.read(consultationAppointmentProvider(id).future)).status,
        AppointmentStatus.inProgress,
      );

      const draft = ConsultationDraft(
        note: 'Reviewed. BP stable on current therapy. Continue.',
        meds: [
          DraftMed(name: 'Amlodipine', dose: '5 mg', frequency: 'once daily'),
        ],
      );
      final done = await ctrl.complete(
        draft,
        outcomeNote: 'Routine review — stable.',
      );
      expect(done.isOk, isTrue, reason: done.toString());

      final finished = await c.read(appointmentRepositoryProvider).byId(id);
      expect(finished.valueOrNull!.status, AppointmentStatus.completed);
      expect(finished.valueOrNull!.outcomeNote, 'Routine review — stable.');

      final records = await c
          .read(recordRepositoryProvider)
          .timeline(appt.patientId, limit: 500);
      final note = records.valueOrNull!.firstWhere(
        (r) => r.recordType == RecordType.visitNote && r.appointmentId == id,
      );
      expect(note.body, contains('BP stable'));

      final meds = await c
          .read(medicationRepositoryProvider)
          .forPatient(appt.patientId);
      expect(
        meds.valueOrNull!.any(
          (m) => m.name == 'Amlodipine' && m.appointmentId == id,
        ),
        isTrue,
      );
    },
  );

  test(
    'doctor requests a referral → admin turns it into a walk-in ticket',
    () async {
      final c = await _container();
      await _login(c, 'staff1@myhealth.demo');

      final id = await _bookAppointment(c);
      final appt =
          (await c.read(appointmentRepositoryProvider).byId(id)).valueOrNull!;
      await c.read(consultationControllerProvider(id)).markArrived();

      final req = await c
          .read(consultationControllerProvider(id))
          .requestReferral('Needs cardiology assessment for new murmur.');
      expect(req.isOk, isTrue);
      expect(await c.read(consultationReferralProvider(id).future), isNotNull);

      // Admin actions it → Cardiology department.
      await c.read(sessionProvider.notifier).logout();
      await _login(c, 'admin@myhealth.demo');

      final pending = await c.read(pendingReferralRequestsProvider.future);
      final mine = pending.firstWhere((r) => r.patientId == appt.patientId);
      final depts = await c.read(departmentsProvider.future);
      final cardiology = depts.firstWhere((d) => d.name == 'Cardiology');

      final r = await c
          .read(adminActionsProvider)
          .actionReferralRequest(
            request: mine,
            destination: cardiology.name,
            external: false,
            departmentId: cardiology.id,
          );
      expect(r.isOk, isTrue, reason: r.toString());

      // The request is closed, and a walk-in ticket now exists in Cardiology.
      expect(
        (await c.read(
          pendingReferralRequestsProvider.future,
        )).where((x) => x.id == mine.id),
        isEmpty,
      );
      final walkIns = await c
          .read(walkInTicketRepositoryProvider)
          .forDepartment(cardiology.id, openOnly: true);
      expect(
        walkIns.valueOrNull!.any((t) => t.patientId == appt.patientId),
        isTrue,
      );
    },
  );

  test('forced close restores the persisted encounter draft', () async {
    final c = await _container();
    await _login(c, 'staff1@myhealth.demo');
    final id = await _bookAppointment(c);
    final controller = c.read(consultationControllerProvider(id));
    const draft = ConsultationDraft(
      note: 'Persistent assessment',
      meds: [DraftMed(name: 'Test medicine', dose: '5 mg')],
    );
    final saved = await controller.saveDraft(draft);
    expect(saved.isOk, isTrue);
    c.read(consultationDraftProvider(id).notifier).state =
        const ConsultationDraft();
    final restored = await controller.loadDraft();
    expect(restored.valueOrNull!.note, 'Persistent assessment');
    expect(restored.valueOrNull!.meds.single.name, 'Test medicine');
    expect(restored.valueOrNull!.version, isNotNull);
  });

  test('completion retry creates one signed note and prescription', () async {
    final c = await _container();
    await _login(c, 'staff1@myhealth.demo');
    final id = await _bookAppointment(c);
    final controller = c.read(consultationControllerProvider(id));
    await controller.markArrived();
    const draft = ConsultationDraft(
      note: 'Final clinical note',
      meds: [DraftMed(name: 'Idempotent medicine', dose: '10 mg')],
    );
    await controller.saveDraft(draft);
    final first = await controller.complete(draft);
    final retry = await controller.complete(draft);
    expect(first.isOk, isTrue);
    expect(retry.isOk, isTrue);
    final db = c.read(appDatabaseProvider);
    final signed = await (db.select(
      db.signedNotes,
    )..where((row) => row.appointmentId.equals(id))).get();
    final medications = await (db.select(
      db.medications,
    )..where((row) => row.appointmentId.equals(id))).get();
    expect(signed, hasLength(1));
    expect(
      medications.where((row) => row.name == 'Idempotent medicine'),
      hasLength(1),
    );
    expect(await db.select(db.encounterDrafts).get(), isEmpty);
  });

  test('admin refers to a hospital → a downloadable referral record', () async {
    final c = await _container();
    await _login(c, 'admin@myhealth.demo');

    const patientId = 'patient_002';
    final r = await c
        .read(adminActionsProvider)
        .referPatient(
          patientId: patientId,
          destination: 'Salmaniya Medical Complex',
          external: true,
          reason: 'Requires interventional cardiology not available on site.',
        );
    expect(r.isOk, isTrue, reason: r.toString());

    // sourceFacility + body carry what buildReferralLetter needs (the PDF
    // builder itself is covered in test/services/clinic_pdf_test.dart).
    final record = r.valueOrNull!;
    expect(record.recordType, RecordType.referral);
    expect(record.sourceFacility, 'Salmaniya Medical Complex');
    expect(record.body, contains('interventional cardiology'));

    // No walk-in ticket for an external referral.
    final walkIns = await c
        .read(walkInTicketRepositoryProvider)
        .forPatient(patientId);
    expect(walkIns.valueOrNull, isEmpty);
  });

  test('a doctor starts a seeded department walk-in', () async {
    final c = await _container();
    await _login(c, 'staff7@myhealth.demo'); // Cardiology

    final walkIns = await c.read(departmentWalkInsProvider.future);
    expect(walkIns, isNotEmpty, reason: 'seeded a waiting Cardiology walk-in');

    final result = await c.read(staffOpsProvider).startWalkIn(walkIns.first);
    expect(result.isOk, isTrue, reason: result.toString());

    final visit = await c
        .read(appointmentRepositoryProvider)
        .byId(result.valueOrNull!);
    expect(visit.valueOrNull!.status, AppointmentStatus.inProgress);
    expect(visit.valueOrNull!.visitType, VisitType.urgentCare);

    // The ticket is no longer in the open queue.
    final still = await c
        .read(walkInTicketRepositoryProvider)
        .forDepartment(walkIns.first.departmentId, openOnly: true);
    expect(still.valueOrNull!.any((t) => t.id == walkIns.first.id), isFalse);
  });
}
