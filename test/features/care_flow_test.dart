// Batch B care services end to end: seeded sick notes reach the patient and
// build a PDF; a message thread round-trips patient <-> doctor; a home-visit
// request is created and triaged (P10-05, P10-07, P10-08).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/care/application/care_providers.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';
import 'package:myhealthcare/features/patient/application/patient_documents.dart';
import 'package:myhealthcare/features/staff_dashboard/application/staff_providers.dart';
import 'package:myhealthcare/services/pdf/reports.dart';
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
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
  addTearDown(db.close);
  addTearDown(container.dispose);
  return container;
}

Future<void> _login(ProviderContainer c, String email) async {
  final r = await c
      .read(sessionProvider.notifier)
      .login(email: email, password: Seeder.demoPassword);
  expect(r.isOk, isTrue, reason: 'login $email');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seeded sick-leave certificates reach the patient and build a PDF', () async {
    final c = await _container();
    await _login(c, 'patient3@myhealth.demo');

    final certs = await c.read(patientSickLeaveProvider.future);
    expect(certs, isNotEmpty);

    final identity = await c.read(pdfIdentityProvider.future);
    final bytes = await sickLeavePdf(
      patient: identity,
      certificate: certs.first,
      issuingClinician: 'Dr Test',
    );
    expect(bytes.length, greaterThan(800));
  });

  test('a patient message and a doctor reply share one thread', () async {
    final c = await _container();
    await _login(c, 'patient3@myhealth.demo');
    final patientId = c.read(currentUserProvider)!.id;

    // Message the first doctor the patient has seen.
    final doctors = await c.read(messageableDoctorsProvider.future);
    expect(doctors, isNotEmpty);
    final staffId = doctors.first.id;

    final sent = await c
        .read(messageActionsProvider)
        .send(
          patientId: patientId,
          staffId: staffId,
          fromStaff: false,
          body: 'Is my dose still right?',
        );
    expect(sent.isOk, isTrue);

    // The patient's message dropped a notification for the doctor.
    final staffInbox = await c
        .read(notificationRepositoryProvider)
        .forRecipient(staffId);
    expect(
      staffInbox.valueOrNull!.where(
        (n) => n.category == NotificationCategory.message,
      ),
      isNotEmpty,
      reason: 'a new message must notify the recipient (bell badge + cue)',
    );

    // The doctor signs in and sees the thread in their inbox.
    final staffEmail = _staffEmail(staffId);
    await _login(c, staffEmail);
    final inbox = await c.read(staffThreadsProvider.future);
    final mine = inbox.where((t) => t.patientId == patientId).toList();
    expect(mine, isNotEmpty);
    // The doctor's own name never double-prefixes ("Dr Dr …").
    for (final t in inbox) {
      expect(t.counterpartName, isNot(startsWith('Dr Dr')));
    }

    await c
        .read(messageActionsProvider)
        .send(
          patientId: patientId,
          staffId: staffId,
          fromStaff: true,
          body: 'Yes, keep the same dose.',
        );

    final thread = await c.read(staffThreadProvider(patientId).future);
    expect(thread, hasLength(greaterThanOrEqualTo(2)));

    // …and the reply notified the patient.
    final patientNotes = await c
        .read(notificationRepositoryProvider)
        .forRecipient(patientId);
    expect(
      patientNotes.valueOrNull!.where(
        (n) => n.category == NotificationCategory.message,
      ),
      isNotEmpty,
    );
  });

  test('a doctor name shows the "Dr" honorific exactly once', () async {
    final c = await _container();
    await _login(c, 'patient3@myhealth.demo');

    // The patient's own appointment labels.
    final directory = await c.read(doctorDirectoryProvider.future);
    for (final entry in directory.values) {
      expect(entry.name, startsWith('Dr '));
      expect(entry.name, isNot(startsWith('Dr Dr')));
    }
    // The stored name has no honorific baked in.
    final anyStaff = await c.read(staffDirectoryProvider.future);
    expect(anyStaff.first.fullName, isNot(startsWith('Dr ')));
  });

  test('a home-visit request is created and the clinic can schedule it', () async {
    final c = await _container();
    await _login(c, 'patient5@myhealth.demo');

    final created = await c
        .read(homeVisitActionsProvider)
        .request(
          address: 'Building 9, Road 9, Block 900',
          preferredDate: DateTime.now().add(const Duration(days: 3)),
          reason: 'Post-op wound check, cannot travel',
        );
    expect(created.isOk, isTrue);

    // Admin triages the queue.
    await _login(c, 'admin@myhealth.demo');
    final queue = await c.read(
      homeVisitQueueProvider(HomeVisitStatus.requested).future,
    );
    expect(queue, isNotEmpty);

    final decided = await c
        .read(homeVisitActionsProvider)
        .decide(
          id: created.valueOrNull!.id,
          status: HomeVisitStatus.scheduled,
          decisionNote: 'Nurse will call to confirm.',
        );
    expect(decided.valueOrNull!.status, HomeVisitStatus.scheduled);
  });
}

/// Seeded staff emails are `staff<n>@myhealth.demo` (no leading zero).
String _staffEmail(String staffId) {
  final n = int.parse(staffId.substring('staff_'.length));
  return 'staff$n@myhealth.demo';
}
