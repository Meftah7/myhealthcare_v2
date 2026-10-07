import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/data/contracts.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/repositories/record_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/clinical/lab_history.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/export_repository.dart';
import 'package:myhealthcare/domain/repositories/record_repository.dart';
import 'package:myhealthcare/features/patient/application/patient_documents.dart';
import 'package:myhealthcare/features/records/application/records_providers.dart';
import 'package:myhealthcare/features/records/presentation/record_detail_screen.dart';
import 'package:myhealthcare/features/timeline/presentation/health_records_screen.dart';
import 'package:myhealthcare/features/timeline/presentation/import_record_sheet.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import 'package:pdf/widgets.dart' as pw;

import '../support/sessions.dart';

final _pdf = Uint8List.fromList('%PDF-1.4\noriginal bytes'.codeUnits);
NewRecord _upload(
  String patientId, {
  bool override = false,
  IdempotencyKey? key,
}) => NewRecord(
  patientId: patientId,
  recordType: RecordType.labResult,
  title: 'Outside report',
  occurredAt: DateTime(2020),
  sourceFacility: 'Outside lab',
  uploadedByPatient: true,
  sourceFile: NewSourceFile(
    fileName: 'original.pdf',
    mimeType: 'application/pdf',
    bytes: _pdf,
  ),
  allowDuplicate: override,
  idempotencyKey: key,
);

Future<void> _link(
  AppDatabase db, {
  required FamilyLinkPermission permission,
}) async {
  await db
      .into(db.familyLinks)
      .insert(
        FamilyLinksCompanion.insert(
          id: 'records-proxy',
          ownerPatientId: 'patient_003',
          viewerPatientId: 'patient_004',
          permission: permission,
          status: const Value(FamilyLinkStatus.accepted),
          createdAt: Value(DateTime.now()),
        ),
      );
}

final class _PickedPdf extends PlatformFile {
  _PickedPdf(this.bytes);
  final Uint8List bytes;
  @override
  String get name => 'outside.pdf';
  @override
  Future<Uint8List> readAsBytes() async => bytes;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Picker extends FilePickerPlatform {
  _Picker(this.bytes);
  final Uint8List bytes;
  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => _PickedPdf(bytes);
}

class _FailFirstSave implements RecordRepository {
  _FailFirstSave(this.delegate);
  final RecordRepository delegate;
  int calls = 0;
  @override
  Future<Result<MedicalRecord>> add(NewRecord record) async => ++calls == 1
      ? const Err(DatabaseFailure('Could not save. Retry.'))
      : delegate.add(record);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _localized(Widget home, {String locale = 'en'}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'subject selector switches history and preserves per-subject filters',
    (tester) async {
      final (c, db) = await seededContainer();
      await _link(db, permission: FamilyLinkPermission.viewOnly);
      await signInAs(c, 'patient4@myhealth.demo');
      final owner = recordValue(
        await c.read(patientRepositoryProvider).byId('patient_003'),
      );
      c.read(recordFiltersProvider('patient_004').notifier).state =
          const RecordsFilter(query: 'own filter');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: _localized(const HealthRecordsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(owner.fullName).last);
      await tester.pumpAndSettle();
      expect(c.read(recordsPatientIdProvider), 'patient_003');
      expect(
        (await c.read(
          recordsHistoryProvider.future,
        )).every((r) => r.patientId == 'patient_003'),
        isTrue,
      );
      expect(c.read(recordFiltersProvider('patient_003')).query, isEmpty);
      expect(
        find
            .widgetWithText(FilledButton, 'Upload document')
            .evaluate()
            .single
            .widget,
        isA<FilledButton>().having(
          (b) => b.onPressed,
          'view-only upload disabled',
          isNull,
        ),
      );
      c.read(selectedRecordsPatientProvider.notifier).state = null;
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SearchBar, 'own filter'), findsOneWidget);
    },
  );

  testWidgets(
    'upload failures and duplicate warning retain inputs until intentional override',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pdf = pw.Document()
        ..addPage(pw.Page(build: (_) => pw.Text('Outside result')));
      final bytes = await pdf.save();
      final originalPicker = FilePickerPlatform.instance;
      FilePickerPlatform.instance = _Picker(bytes);
      addTearDown(() => FilePickerPlatform.instance = originalPicker);
      final (c, _) = await seededContainer();
      await signInAs(c, 'patient3@myhealth.demo');
      final repo = c.read(recordRepositoryProvider);
      NewRecord upload() => NewRecord(
        patientId: 'patient_003',
        recordType: RecordType.labResult,
        title: 'First copy',
        occurredAt: DateTime(2020),
        sourceFacility: 'Outside lab',
        uploadedByPatient: true,
        sourceFile: NewSourceFile(
          fileName: 'outside.pdf',
          mimeType: 'application/pdf',
          bytes: bytes,
        ),
      );
      recordValue(await repo.add(upload()));
      final failing = _FailFirstSave(repo);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: ProviderScope(
            overrides: [recordRepositoryProvider.overrideWithValue(failing)],
            child: _localized(
              Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showImportRecordSheet(
                      context,
                      patientId: 'patient_003',
                    ),
                    child: const Text('Open upload'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open upload'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.upload_file_outlined));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).at(0),
        'Edited report title',
      );
      await tester.enterText(find.byType(TextField).at(1), 'Entered issuer');
      Future<void> save() async {
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Save to records'),
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Save to records'));
        await tester.pumpAndSettle();
      }

      await save();
      expect(find.text('Edited report title'), findsOneWidget);
      expect(find.text('Entered issuer'), findsOneWidget);
      await save();
      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('Edited report title'), findsOneWidget);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await save();
      expect(find.text('Open upload'), findsOneWidget);
      expect(failing.calls, 3);
      final history = recordValue(
        await repo.timeline('patient_003', limit: 200),
      );
      final saved = history.singleWhere(
        (r) => r.title == 'Edited report title',
      );
      expect(saved.sourceFacility, 'Entered issuer');
      expect(saved.reviewStatus, ImportReviewStatus.pendingReview);
      expect(recordValue(await repo.sourceFile(saved.id)).bytes, bytes);
    },
  );

  test(
    'duplicates are patient scoped, explicit overrides stay pending, retries reuse one record',
    () async {
      final (c, _) = await seededContainer();
      await signInAs(c, 'patient3@myhealth.demo');
      final repo = c.read(recordRepositoryProvider);
      final key = IdempotencyKey.generate();
      final first = recordValue(
        await repo.add(_upload('patient_003', key: key)),
      );
      expect(
        recordValue(await repo.add(_upload('patient_003', key: key))).id,
        first.id,
      );
      final duplicate = await repo.add(_upload('patient_003'));
      expect(duplicate.failureOrNull, isA<DuplicateUploadFailure>());
      final another = recordValue(
        await repo.add(_upload('patient_003', override: true)),
      );
      expect(another.id, isNot(first.id));
      expect(another.reviewStatus, ImportReviewStatus.pendingReview);
      expect(another.sourceDocument!.sha256, first.sourceDocument!.sha256);
      expect(recordValue(await repo.sourceFile(another.id)).bytes, _pdf);
      await signInAs(c, 'patient4@myhealth.demo');
      expect((await repo.add(_upload('patient_004'))).isOk, isTrue);
    },
  );

  test(
    'view-only proxy can read/export but cannot upload or request corrections; revocation denies every action',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'patient3@myhealth.demo');
      final record = recordValue(
        await c.read(recordRepositoryProvider).add(_upload('patient_003')),
      );
      await _link(db, permission: FamilyLinkPermission.viewOnly);
      await signInAs(c, 'patient4@myhealth.demo');
      c.read(selectedRecordsPatientProvider.notifier).state = 'patient_003';
      expect(
        (await c.read(
          recordsHistoryProvider.future,
        )).every((r) => r.patientId == 'patient_003'),
        isTrue,
      );
      expect(
        (await c.read(recordDetailProvider(record.id).future)).id,
        record.id,
      );
      expect(await c.read(recordsCanManageProvider.future), isFalse);
      expect(
        (await c.read(
          pdfIdentityForPatientProvider('patient_003').future,
        )).patientId,
        'patient_003',
      );
      expect(
        (await c
                .read(recordRepositoryProvider)
                .add(_upload('patient_003', override: true)))
            .failureOrNull,
        isA<AccessDeniedFailure>(),
      );
      expect(
        (await c
                .read(recordActivityRepositoryProvider)
                .requestCorrection(record.id, 'Fix date'))
            .failureOrNull,
        isA<AccessDeniedFailure>(),
      );
      expect(
        (await c
                .read(recordActivityRepositoryProvider)
                .setRead(record.id, read: true))
            .isOk,
        isTrue,
      );
      expect(
        (await c
                .read(exportRepositoryProvider)
                .authorizeExport(
                  patientId: 'patient_003',
                  document: ExportDocument.recordSummary,
                  entityId: record.id,
                ))
            .isOk,
        isTrue,
      );
      expect(
        (await c
                .read(exportRepositoryProvider)
                .authorizeExport(
                  patientId: 'patient_004',
                  document: ExportDocument.recordSummary,
                  entityId: record.id,
                ))
            .failureOrNull,
        isA<AccessDeniedFailure>(),
      );
      await (db.delete(
        db.familyLinks,
      )..where((r) => r.id.equals('records-proxy'))).go();
      expect(
        (await c.read(recordRepositoryProvider).byId(record.id)).failureOrNull,
        isA<AuthFailure>(),
      );
      expect(
        (await c.read(recordRepositoryProvider).sourceFile(record.id))
            .failureOrNull,
        isA<AuthFailure>(),
      );
      expect(
        (await c
                .read(recordActivityRepositoryProvider)
                .setRead(record.id, read: false))
            .failureOrNull,
        isA<AuthFailure>(),
      );
      expect(
        (await c
                .read(exportRepositoryProvider)
                .authorizeExport(
                  patientId: 'patient_003',
                  document: ExportDocument.originalFile,
                  entityId: record.id,
                ))
            .failureOrNull,
        isA<AuthFailure>(),
      );
    },
  );

  test(
    'manage proxy upload and correction retain subject/actor, with account-specific read state and untouched signed notes',
    () async {
      final (c, db) = await seededContainer();
      await _link(db, permission: FamilyLinkPermission.manage);
      await signInAs(c, 'patient4@myhealth.demo');
      final record = recordValue(
        await c.read(recordRepositoryProvider).add(_upload('patient_003')),
      );
      expect(record.patientId, 'patient_003');
      expect(record.createdByAccountId, 'patient_004');
      final activity = c.read(recordActivityRepositoryProvider);
      final signedBefore = await db.select(db.signedNotes).get();
      final request = recordValue(
        await activity.requestCorrection(record.id, 'Wrong collection date'),
      );
      expect(
        recordValue(
          await activity.requestCorrection(record.id, 'Wrong collection date'),
        ).id,
        request.id,
      );
      expect(
        (await activity.requestCorrection(record.id, '  ')).failureOrNull,
        isA<ValidationFailure>(),
      );
      final stored = await (db.select(
        db.recordCorrections,
      )..where((r) => r.id.equals(request.id))).getSingle();
      expect(stored.patientId, 'patient_003');
      expect(stored.requestedByAccountId, 'patient_004');
      expect(stored.status, 'pending');
      expect(
        (await db.select(db.signedNotes).get()).map((r) => r.toJson()),
        signedBefore.map((r) => r.toJson()),
      );
      expect(
        recordValue(await c.read(recordRepositoryProvider).byId(record.id)),
        record,
      );
      await activity.setRead(record.id, read: true);
      expect(
        recordValue(await activity.readIds('patient_003')),
        contains(record.id),
      );
      await signInAs(c, 'patient3@myhealth.demo');
      expect(
        recordValue(await activity.readIds('patient_003')),
        isNot(contains(record.id)),
      );
      expect(
        recordValue(await activity.corrections(record.id)).single.id,
        request.id,
      );
      await signInAs(c, 'patient4@myhealth.demo');
      await activity.setRead(record.id, read: false);
      expect(
        recordValue(await activity.readIds('patient_003')),
        isNot(contains(record.id)),
      );
      final audit = await (db.select(
        db.auditLog,
      )..where((r) => r.action.equals('record.correction.request'))).get();
      expect(audit, hasLength(1));
    },
  );

  test(
    'advanced filters cover date boundaries, author, facility, review, text and unread state',
    () {
      final record = MedicalRecord(
        id: 'r',
        patientId: 'p',
        recordType: RecordType.labResult,
        title: 'Report',
        occurredAt: DateTime(2020, 3, 1, 23, 59),
        createdAt: DateTime(2026),
        authorStaffId: 'doctor',
        sourceFacility: 'Lab',
        reviewStatus: ImportReviewStatus.pendingReview,
        extractedText: 'Ferritin',
        uploadedByPatient: true,
      );
      final f = RecordsFilter(
        from: DateTime(2020, 3),
        to: DateTime(2020, 3),
        facility: 'Lab',
        authorId: 'doctor',
        review: ImportReviewStatus.pendingReview,
        types: {RecordType.labResult},
        view: RecordsView.uploads,
        query: 'ferritin',
        unreadOnly: true,
      );
      expect(f.matches(record, {}), isTrue);
      expect(f.matches(record, {'r'}), isFalse);
      expect(f.copyWith(facility: 'Other').matches(record, {}), isFalse);
      expect(f.copyWith(authorId: 'Other').matches(record, {}), isFalse);
      expect(
        f.copyWith(from: DateTime(2020, 3, 2)).matches(record, {}),
        isFalse,
      );
      expect(
        f.copyWith(review: ImportReviewStatus.reviewed).matches(record, {}),
        isFalse,
      );
      expect(
        f
            .copyWith(query: 'Dr Example')
            .matches(record, {}, authorName: 'Dr Example'),
        isTrue,
      );
    },
  );

  test(
    'lab comparisons require the same patient, test, nonempty unit and earlier clinical date',
    () {
      LabValue lab(String id, String? unit, double value) => LabValue(
        id: id,
        recordId: id,
        analyte: 'Glucose',
        value: value,
        unit: unit,
        abnormalFlag: AbnormalFlag.unknown,
      );
      MedicalRecord record(
        String id,
        DateTime at,
        LabValue value, {
        String patient = 'p',
      }) => MedicalRecord(
        id: id,
        patientId: patient,
        recordType: RecordType.labResult,
        title: id,
        occurredAt: at,
        createdAt: at,
        labValues: [value],
      );
      final current = record('now', DateTime(2026), lab('now', 'mg/dL', 110));
      final prior = comparableLabHistory(current, [
        record(
          'wrong-unit',
          DateTime(2025, 12),
          lab('wrong-unit', 'mmol/L', 5.5),
        ),
        record(
          'wrong-patient',
          DateTime(2025, 11),
          lab('wrong-patient', 'mg/dL', 80),
          patient: 'other',
        ),
        record('future', DateTime(2027), lab('future', 'mg/dL', 140)),
        record('correct', DateTime(2025), lab('correct', 'mg/dL', 100)),
      ]);
      expect(prior[labHistoryKey(current.labValues.single)]!.value, 100);
      final noUnit = record(
        'no-unit',
        DateTime(2026),
        lab('no-unit', null, 110),
      );
      expect(
        comparableLabHistory(noUnit, [
          record('old-no-unit', DateTime(2025), lab('old-no-unit', null, 90)),
        ]),
        isEmpty,
      );
    },
  );

  test(
    'schema 28 upgrades preserve originals; read state and corrections survive reopen and backup',
    () async {
      final temp = await Directory.systemTemp.createTemp('records-migration-');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}/records.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      await Seeder(db).run();
      final original = recordValue(
        await RecordRepositoryImpl(db).add(_upload('patient_003')),
      );
      final signed = (await db.select(db.signedNotes).get()).length;
      await db.customStatement('DROP TABLE record_reads');
      await db.customStatement('DROP TABLE record_corrections');
      await db.customStatement('PRAGMA user_version = 28');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      expect(
        recordValue(
          await RecordRepositoryImpl(db).sourceFile(original.id),
        ).bytes,
        _pdf,
      );
      expect((await db.select(db.signedNotes).get()).length, signed);
      await db
          .into(db.recordReads)
          .insert(
            RecordReadsCompanion.insert(
              recordId: original.id,
              accountId: 'patient_003',
              readAt: DateTime.now(),
            ),
          );
      await db
          .into(db.recordCorrections)
          .insert(
            RecordCorrectionsCompanion.insert(
              id: 'correction',
              recordId: original.id,
              patientId: 'patient_003',
              requestedByAccountId: 'patient_003',
              reason: 'Wrong date',
              createdAt: DateTime.now(),
            ),
          );
      await db.close();
      final backup = await file.copy('${temp.path}/backup.sqlite');
      db = AppDatabase(NativeDatabase(backup));
      addTearDown(db.close);
      expect(
        (await db.select(db.recordReads).get()).single.recordId,
        original.id,
      );
      expect(
        (await db.select(db.recordCorrections).get()).single.reason,
        'Wrong date',
      );
      expect(
        recordValue(
          await RecordRepositoryImpl(db).sourceFile(original.id),
        ).bytes,
        _pdf,
      );
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    },
  );
}
