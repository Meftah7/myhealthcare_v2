// Drift platform spike (P0-09 Windows, P0-10 Android, P0-11 Web).
//
// Runs the real app engine on a device and proves the app's Drift database
// opens, migrates to schemaVersion 1, and round-trips a write + read using the
// platform's real SQLite (bundled DLL on Windows, .so on Android, WASM on web).
//
//   flutter test integration_test/drift_spike_test.dart -d windows
//   flutter test integration_test/drift_spike_test.dart -d <android>
//   flutter test integration_test/drift_spike_test.dart -d chrome --web-renderer canvaskit

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myhealthcare/data/db/app_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('Drift opens and round-trips a row on this platform', () async {
    final db = AppDatabase();
    addTearDown(db.close);

    final before = await db.spikeRowCount();

    final id = await db.addSpikeRow('spike');
    expect(id, greaterThan(0));

    final after = await db.spikeRowCount();
    expect(after, before + 1);

    final rows = await db.allSpikeRows();
    expect(
      rows.any((r) => r.id == id && r.label == 'spike'),
      isTrue,
      reason: 'the row just inserted should read back',
    );
  });

  test('Drift persists to disk — a fresh connection sees the write', () async {
    final marker = 'persist-${DateTime.now().microsecondsSinceEpoch}';

    final first = AppDatabase();
    await first.addSpikeRow(marker);
    await first.close();

    // A brand-new connection to the same on-disk database file.
    final second = AppDatabase();
    addTearDown(second.close);
    final rows = await second.allSpikeRows();

    expect(
      rows.any((r) => r.label == marker),
      isTrue,
      reason: 'write from the first connection must survive on disk (not in-memory)',
    );
  });
}
