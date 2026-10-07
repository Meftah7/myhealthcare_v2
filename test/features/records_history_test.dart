import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/data/contracts.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';
import 'package:myhealthcare/features/records/application/records_providers.dart';
import 'package:myhealthcare/features/timeline/presentation/timeline_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/sessions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'history reads every authorized page beyond the displayed timeline',
    () async {
      final (container, db) = await seededContainer();
      await signInAs(container, 'patient3@myhealth.demo');
      final patientId = container.read(currentUserProvider)!.id;
      await db.batch((batch) {
        batch.insertAll(db.medicalRecords, [
          for (var i = 0; i < 260; i++)
            MedicalRecordsCompanion.insert(
              id: 'old-record-$i',
              patientId: patientId,
              recordType: RecordType.labResult,
              title: 'Old result $i',
              occurredAt: DateTime(1990).add(Duration(days: i)),
              sourceFacility: const Value('Outside lab'),
            ),
        ]);
      });
      final visible = await container.read(patientTimelinePageProvider.future);
      expect(visible.items.length, PageLimits.defaultSize);
      expect(visible.hasMore, isTrue);
      final history = await container.read(patientRecordHistoryProvider.future);
      expect(
        history.where((r) => r.id.startsWith('old-record-')),
        hasLength(260),
      );
      expect(history.every((r) => r.patientId == patientId), isTrue);
      expect(history.map((r) => r.id).toSet(), hasLength(history.length));
    },
  );

  for (final locale in ['en', 'ar']) {
    testWidgets('history search and upload at phone width ($locale)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final record = MedicalRecord(
        id: 'old',
        patientId: 'patient',
        recordType: RecordType.labResult,
        title: 'Older result',
        occurredAt: DateTime(1990),
        createdAt: DateTime(2026),
        extractedText: 'Unique extracted finding',
        sourceFacility: 'Outside lab',
        uploadedByPatient: true,
        reviewStatus: ImportReviewStatus.pendingReview,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(null),
            recordReadIdsProvider.overrideWith((ref) async => {}),
            doctorDirectoryProvider.overrideWith((ref) async => {}),
            recordsCanManageProvider.overrideWith((ref) async => true),
            patientRecordHistoryProvider.overrideWith((ref) async => [record]),
            patientVitalsProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TimelineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.upload_file_outlined), findsOneWidget);
      expect(find.text('Older result'), findsOneWidget);
      await tester.enterText(find.byType(SearchBar), 'unique extracted');
      await tester.pumpAndSettle();
      expect(find.text('Older result'), findsOneWidget);
      await tester.enterText(find.byType(SearchBar), 'no match');
      await tester.pumpAndSettle();
      expect(find.text('Older result'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
