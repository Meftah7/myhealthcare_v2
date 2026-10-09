// Real Chrome/WASM acceptance without a WebDriver installation.
// Build this entry point for web, serve its output and inspect the JSON report.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/data/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final results = <String, Object>{};
  final name = 'acceptance-${DateTime.now().microsecondsSinceEpoch}';
  AppDatabase? db;
  try {
    db = AppDatabase.named(name);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    if (version.read<int>('user_version') != db.schemaVersion) {
      throw StateError('Wrong schema version');
    }
    results['schema'] = db.schemaVersion;
    await db
        .into(db.departments)
        .insert(
          DepartmentsCompanion.insert(
            id: 'acceptance',
            name: 'Browser persistence',
          ),
        );
    if ((await db.select(db.departments).get()).single.name !=
        'Browser persistence') {
      throw StateError('Round trip failed');
    }
    results['roundTrip'] = true;
    var refused = false;
    try {
      await db
          .into(db.patientProfiles)
          .insert(PatientProfilesCompanion.insert(userId: 'missing-user'));
    } catch (error) {
      refused = error.toString().toUpperCase().contains('FOREIGN KEY');
    }
    if (!refused) throw StateError('Foreign key was not enforced');
    results['foreignKeys'] = true;
    await db.close();
    db = AppDatabase.named(name);
    if ((await db.select(db.departments).get()).single.name !=
        'Browser persistence') {
      throw StateError('Reopen persistence failed');
    }
    results['reopenPersistence'] = true;
    results['passed'] = true;
  } catch (error, stack) {
    results['passed'] = false;
    results['error'] = error.toString();
    results['stack'] = stack.toString();
  } finally {
    await db?.close();
  }
  runApp(_Report(results));
}

class _Report extends StatefulWidget {
  const _Report(this.results);
  final Map<String, Object> results;
  @override
  State<_Report> createState() => _ReportState();
}

class _ReportState extends State<_Report> {
  final semantics = WidgetsBinding.instance.ensureSemantics();
  @override
  void dispose() {
    semantics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(jsonEncode(widget.results)),
        ),
      ),
    );
  }
}
