/// The app's Drift database.
///
/// P0-09/10/11 are platform spikes: this starts with a single throwaway table
/// ([SpikeRows]) purely to prove Drift opens, migrates, reads and writes on
/// Windows, Android and Web. P1-01…P1-06 replace [SpikeRows] with the real
/// schema and a proper migration strategy.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Temporary — removed in P1-01.
class SpikeRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text().withLength(min: 1, max: 128)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [SpikeRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: _dbName, web: _webOptions));

  static const _dbName = 'myhealthcare';

  /// Web needs sqlite3 compiled to WASM plus a worker for OPFS-backed storage.
  /// Both files are served from web/ (P0-11). On native platforms this is
  /// ignored.
  static final _webOptions = DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
  );

  @override
  int get schemaVersion => 1;

  // --- Spike API (P0-09/10/11) -------------------------------------------

  Future<int> addSpikeRow(String label) =>
      into(spikeRows).insert(SpikeRowsCompanion.insert(label: label));

  Future<List<SpikeRow>> allSpikeRows() =>
      (select(spikeRows)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<int> spikeRowCount() async {
    final count = countAll();
    final row = await (selectOnly(spikeRows)..addColumns([count]))
        .getSingle();
    return row.read(count) ?? 0;
  }
}
