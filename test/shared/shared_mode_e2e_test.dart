// End to end: the full app's repositories in shared mode against the real
// Node shared server. A patient books through the app's booking contract,
// the doctor starts, drafts and signs the visit, the prescription reaches
// the pharmacist, and unsupported repositories fail visibly instead of
// returning local data.
@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/shared_mode.dart';
import 'package:myhealthcare/core/data/contracts.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/remote/shared_client.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/pharmacy_repository.dart';
import 'package:myhealthcare/domain/repositories/repositories.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

const _password = 'Synthetic-Test-Password-2026!';

void main() {
  // Storage needs the binding; the binding's fake HTTP is switched off so
  // the app talks to the real test server.
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  late Process server;
  late String origin;

  setUpAll(() async {
    server = await Process.start('node', [
      'services/shared_api/test_server.mjs',
      _password,
    ]);
    final line = await server.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first
        .timeout(const Duration(seconds: 20));
    origin =
        'http://127.0.0.1:${(jsonDecode(line) as Map<String, dynamic>)['port']}';
  });

  tearDownAll(() async {
    await server.stdin.close();
    await server.exitCode.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        server.kill();
        return 0;
      },
    );
  });

  Future<ProviderContainer> signedIn(String email) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = SharedClient(origin, endSessionOnForbidden: false);
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...sharedModeOverrides(client, openScratch: newTestDatabase),
      ],
    );
    addTearDown(c.dispose);
    final r = await c
        .read(sessionProvider.notifier)
        .login(email: email, password: _password);
    expect(r.isOk, isTrue, reason: '${r.failureOrNull}');
    return c;
  }

  test('book, consult, sign and dispense across roles', () async {
    // Patient books through the app's booking contract.
    final patient = await signedIn('patient@shared.demo');
    final me = patient.read(currentUserProvider)!;
    expect(me.role, UserRole.patient);
    final departments =
        (await patient.read(departmentRepositoryProvider).all()).valueOrNull!;
    expect(departments.single.name, 'Family Medicine');
    final doctor =
        (await patient.read(userRepositoryProvider).allStaff()).failureOrNull;
    expect(
      doctor,
      isA<AccessDeniedFailure>(),
      reason: 'staff list is staff-only',
    );
    final appointments = patient.read(appointmentRepositoryProvider);
    final staffRows =
        (await patient.read(sharedClientProvider).request('/api/clinicians'))
            as List;
    final doctorId = (staffRows.single as Map)['id'] as String;
    final day = DateTime.now().add(const Duration(days: 2));
    final slots = (await appointments.openSlots(doctorId, day)).valueOrNull!;
    expect(slots, isNotEmpty);
    final key = IdempotencyKey.generate();
    final request = BookingRequest(
      patientId: me.id,
      staffId: doctorId,
      start: slots.first.start,
      end: slots.first.end,
      visitType: VisitType.followUp,
      idempotencyKey: key,
    );
    final booked = (await appointments.book(request)).valueOrNull!;
    expect((await appointments.book(request)).valueOrNull!.id, booked.id);
    expect(
      (await appointments.forPatient(me.id)).valueOrNull!.single.id,
      booked.id,
    );
    // An unsupported repository fails visibly, never with local data.
    expect(
      (await patient.read(recordRepositoryProvider).timeline(me.id))
          .failureOrNull,
      isA<SharedModeUnavailableFailure>(),
    );

    // Doctor: start, draft (versioned) and sign once.
    final doc = await signedIn('doctor@shared.demo');
    final docAppts = doc.read(appointmentRepositoryProvider);
    expect(
      (await docAppts.forStaffInRange(
        doctorId,
        day.subtract(const Duration(days: 1)),
        day.add(const Duration(days: 1)),
      )).valueOrNull!.map((a) => a.id),
      contains(booked.id),
    );
    expect(
      (await docAppts.markArrived(
        booked.id,
        staffId: doctorId,
        at: DateTime.now(),
      )).isOk,
      isTrue,
    );
    final drafts = doc.read(encounterDraftRepositoryProvider);
    final saved = (await drafts.save(
      EncounterDraftData(
        appointmentId: booked.id,
        patientId: me.id,
        authorStaffId: doctorId,
        note: 'Cough for three days',
        medications: const [
          DraftMedicationData(name: 'Paracetamol', dose: '500 mg'),
        ],
      ),
    )).valueOrNull!;
    expect(saved.version, 1);
    expect(
      (await drafts.forAppointment(booked.id)).valueOrNull!.note,
      'Cough for three days',
    );
    final finalizeKey = IdempotencyKey.generate();
    final finalize = FinalizeEncounter(
      appointmentId: booked.id,
      staffId: doctorId,
      note: 'Viral URTI',
      medications: const [
        DraftMedicationData(name: 'Paracetamol', dose: '500 mg'),
      ],
    );
    final encounters = doc.read(encounterRepositoryProvider);
    expect(
      (await encounters.finalize(finalize, idempotencyKey: finalizeKey)).isOk,
      isTrue,
    );
    expect(
      (await encounters.finalize(finalize, idempotencyKey: finalizeKey)).isOk,
      isTrue,
    );
    expect(
      (await encounters.signedNoteFor(booked.id)).valueOrNull!.body,
      'Viral URTI',
    );

    // Pharmacist sees the signed prescription and dispenses it once.
    final pharmacy = await signedIn('pharmacy@shared.demo');
    final repo = pharmacy.read(pharmacyRepositoryProvider);
    final order = (await repo.queue()).valueOrNull!.single;
    expect(order.name, 'Paracetamol');
    final input = DispenseInput(
      medicationId: order.medicationId,
      outcome: DispenseOutcome.dispensed,
      patientVerified: true,
      quantity: '20 tablets',
      idempotencyKey: 'e2e-dispense',
    );
    expect((await repo.record(input)).isOk, isTrue);
    expect((await repo.record(input)).isOk, isTrue);
    expect(
      (await repo.record(
        DispenseInput(
          medicationId: order.medicationId,
          outcome: DispenseOutcome.dispensed,
          patientVerified: true,
          quantity: '1',
          idempotencyKey: 'e2e-again',
        ),
      )).failureOrNull,
      isA<ConflictFailure>(),
    );
  });

  test('blocked screens and admin home are decided by shared mode', () {
    expect(sharedModeBlocks('/admin/users'), isTrue);
    expect(sharedModeBlocks('/admin/dashboard'), isFalse);
    expect(sharedModeBlocks('/patient/timeline/documents'), isTrue);
    expect(sharedModeBlocks('/patient/appointments'), isFalse);
    expect(sharedModeBlocks('/staff/tasks/t1'), isTrue);
    expect(sharedModeBlocks('/staff/tasks'), isFalse);
  });
}
