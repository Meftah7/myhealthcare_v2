// Drift platform spike (P0-09 Windows, P0-10 Android, P0-11 Web).
//
// Runs the real app engine on a device and proves the app's Drift database
// opens, migrates to the current schemaVersion, enforces foreign keys, and
// round-trips a write + read using the platform's real SQLite (bundled DLL on
// Windows, .so on Android, WASM on web).
//
//   flutter test integration_test/drift_spike_test.dart -d windows
//   flutter test integration_test/drift_spike_test.dart -d <android>
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/drift_spike_test.dart \
//     -d web-server --browser-name=chrome --release

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Each run gets an isolated database file so a stale dev DB can't mask a bug.
  final dbName = 'spike-${DateTime.now().microsecondsSinceEpoch}';

  test('Drift opens and round-trips a row on this platform', () async {
    final db = AppDatabase.named(dbName);
    addTearDown(db.close);

    expect(db.schemaVersion, 1);

    const id = 'dept-1';
    await db
        .into(db.departments)
        .insert(DepartmentsCompanion.insert(id: id, name: 'Cardiology'));

    final rows = await db.select(db.departments).get();
    expect(
      rows.any((r) => r.id == id && r.name == 'Cardiology'),
      isTrue,
      reason: 'the row just inserted should read back',
    );
  });

  test('foreign keys are enforced', () async {
    final db = AppDatabase.named('$dbName-fk');
    addTearDown(db.close);

    // patient_profiles.userId references users.id — an orphan insert must fail.
    await expectLater(
      db
          .into(db.patientProfiles)
          .insert(PatientProfilesCompanion.insert(userId: 'no-such-user')),
      throwsA(
        predicate<Object>(
          (e) => e.toString().toUpperCase().contains('FOREIGN KEY'),
          'a FOREIGN KEY constraint error',
        ),
      ),
    );
  });

  test('Drift persists to disk — a fresh connection sees the write', () async {
    final name = '$dbName-persist';

    final first = AppDatabase.named(name);
    await first
        .into(first.departments)
        .insert(DepartmentsCompanion.insert(id: 'x', name: 'Radiology'));
    await first.close();

    // A brand-new connection to the same on-disk database.
    final second = AppDatabase.named(name);
    addTearDown(second.close);
    final rows = await second.select(second.departments).get();

    expect(
      rows.any((r) => r.id == 'x'),
      isTrue,
      reason: 'write from the first connection must survive on disk',
    );
  });
}
