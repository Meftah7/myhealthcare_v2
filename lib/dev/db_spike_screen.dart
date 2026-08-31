/// Drift platform spike UI (P0-09/10/11).
///
/// Debug-only. Opens [AppDatabase], writes a row, reads them all back — proof
/// that Drift works on the current platform. Reachable at `/dev/db-spike`
/// (registered only in debug builds). Deleted when [SpikeRows] goes away in
/// Phase 1.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme/theme.dart';
import '../core/di.dart';
import '../data/db/app_database.dart';

class DbSpikeScreen extends ConsumerStatefulWidget {
  const DbSpikeScreen({super.key});

  @override
  ConsumerState<DbSpikeScreen> createState() => _DbSpikeScreenState();
}

class _DbSpikeScreenState extends ConsumerState<DbSpikeScreen> {
  late Future<List<SpikeRow>> _rows;
  String _status = '';

  AppDatabase get _db => ref.read(appDatabaseProvider);

  @override
  void initState() {
    super.initState();
    _rows = _db.allSpikeRows();
  }

  Future<void> _addRow() async {
    try {
      final platform = Theme.of(context).platform.name;
      final id = await _db.addSpikeRow('hello from $platform');
      final count = await _db.spikeRowCount();
      setState(() {
        _status = 'inserted row #$id · $count rows total';
        _rows = _db.allSpikeRows();
      });
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Drift spike')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRow,
        icon: const Icon(Icons.add),
        label: const Text('Insert row'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _status.isEmpty
                  ? 'Tap "Insert row" to write to SQLite.'
                  : _status,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _status.startsWith('ERROR')
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            Expanded(
              child: FutureBuilder<List<SpikeRow>>(
                future: _rows,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Text(
                      'read failed: ${snap.error}',
                      style: TextStyle(color: theme.colorScheme.error),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final rows = snap.data!;
                  if (rows.isEmpty) {
                    return const Center(child: Text('no rows yet'));
                  }
                  return ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      return ListTile(
                        leading: AppText.clinical('#${r.id}'),
                        title: Text(r.label),
                        subtitle: Text(r.createdAt.toIso8601String()),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
