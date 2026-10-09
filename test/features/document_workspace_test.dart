import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/domain/repositories/document_service.dart';
import 'package:myhealthcare/domain/repositories/export_repository.dart';
import 'package:myhealthcare/features/care/presentation/document_workspace_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/sessions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final locale in ['en', 'ar']) {
    for (final type in [
      ExportDocument.fitnessCertificate,
      ExportDocument.releasedLabReport,
    ]) {
      testWidgets(
        '$locale ${type.name} form fits a phone and shows its own fields',
        (tester) async {
          tester.view.physicalSize = const Size(320, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final workspace = DocumentWorkspace(
            patientName: 'Patient',
            visits: [DocumentVisit('visit', DateTime(2026, 10, 8, 9))],
            templates: [
              DocumentTemplateChoice(
                'template',
                'en',
                DisclosureProfile.clinic,
                false,
                documentType: type,
              ),
            ],
            requests: const [],
            issued: const [],
            sources: [
              DocumentSourceChoice(
                'source',
                'visit',
                type,
                'Reviewed clinic source',
              ),
            ],
          );
          final (c, _) = await seededContainer(
            overrides: [
              documentWorkspaceProvider(
                'patient_003',
              ).overrideWith((ref) => workspace),
            ],
          );
          await signInAs(c, 'staff1@myhealth.demo');
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: c,
              child: MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.2)),
                  child: child!,
                ),
                home: DocumentWorkspaceScreen(
                  patientId: 'patient_003',
                  appointmentId: type == ExportDocument.fitnessCertificate
                      ? 'unrelated'
                      : 'visit',
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<DropdownButtonFormField<String>>(
                  find.byKey(const ValueKey('documentVisit')),
                )
                .initialValue,
            type == ExportDocument.fitnessCertificate ? isNull : 'visit',
          );
          final template = find.byKey(const ValueKey('documentTemplate'));
          await tester.scrollUntilVisible(
            template,
            150,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(template);
          await tester.pumpAndSettle();
          await tester.tap(find.textContaining('English ·').last);
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('leaveStart')), findsNothing);
          if (type == ExportDocument.fitnessCertificate) {
            final activity = find.text(
              locale == 'ar' ? 'النشاط الذي تم تقييمه' : 'Activity assessed',
            );
            await tester.scrollUntilVisible(
              activity,
              150,
              scrollable: find.byType(Scrollable).first,
            );
            expect(activity, findsOneWidget);
          } else {
            final release = find.text(
              locale == 'ar'
                  ? 'الطبيب: اعتماد هذه النتيجة للنشر'
                  : 'Doctor: release this exact result',
            );
            await tester.scrollUntilVisible(
              release,
              150,
              scrollable: find.byType(Scrollable).first,
            );
            expect(release, findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
  for (final locale in ['en', 'ar']) {
    testWidgets(
      '$locale workspace fits a small phone and preserves inputs after denial',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final workspace = DocumentWorkspace(
          patientName: 'A patient with a long recorded name',
          visits: [DocumentVisit('visit', DateTime(2026, 10, 8, 9))],
          templates: const [
            DocumentTemplateChoice(
              'template',
              'en',
              DisclosureProfile.employer,
              true,
            ),
          ],
          requests: const [],
          issued: const [],
        );
        final (c, _) = await seededContainer(
          overrides: [
            documentWorkspaceProvider(
              'patient_003',
            ).overrideWith((ref) => workspace),
          ],
        );
        await signInAs(c, 'staff1@myhealth.demo');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.2)),
                child: child!,
              ),
              home: const DocumentWorkspaceScreen(patientId: 'patient_003'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final visit = find.byKey(const ValueKey('documentVisit'));
        final template = find.byKey(const ValueKey('documentTemplate'));
        await tester.scrollUntilVisible(
          visit,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(visit);
        await tester.pumpAndSettle();
        await tester.tap(find.text('2026-10-08 09:00').last);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          template,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(template);
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('English ·').last);
        await tester.pumpAndSettle();
        final start = find.byKey(const ValueKey('leaveStart'));
        final end = find.byKey(const ValueKey('leaveEnd'));
        await tester.scrollUntilVisible(
          start,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(start, '2026-10-08');
        await tester.scrollUntilVisible(
          end,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(end, '2026-10-10');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final save = find.text(locale == 'ar' ? 'حفظ المسودة' : 'Save draft');
        await tester.scrollUntilVisible(
          save,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        // The real service rejects this ungranted staff account. Input remains.
        await tester.scrollUntilVisible(
          start,
          -150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(start).controller!.text, '2026-10-08');
        expect(tester.widget<TextField>(end).controller!.text, '2026-10-10');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
