import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/repositories/document_verification_repository_impl.dart';
import 'package:myhealthcare/features/admin/presentation/verify_document_screen.dart';
import 'package:myhealthcare/features/care/application/care_providers.dart';
import 'package:myhealthcare/features/patient/application/patient_documents.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import 'package:myhealthcare/services/qr/qr_image_decoder.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../support/sessions.dart';

Uint8List _qrPicture(String payload) {
  final image = img.Image(width: 296, height: 296);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  for (final element in pw.Barcode.qrCode().make(
    payload,
    width: 256,
    height: 256,
  )) {
    if (element is pw.BarcodeBar && element.black) {
      img.fillRect(
        image,
        x1: 20 + element.left.round(),
        y1: 20 + element.top.round(),
        x2: 19 + (element.left + element.width).round(),
        y2: 19 + (element.top + element.height).round(),
        color: img.ColorRgb8(0, 0, 0),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets(
    'a demo patient certificate QR verifies for staff and admin, but not a patient',
    (tester) async {
      final (container, db) = await seededContainer();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
      await signInAs(container, 'patient3@myhealth.demo');
      final certificate = (await container.read(
        patientSickLeaveProvider.future,
      )).first;
      Uint8List? pdf;
      Widget app(Widget home) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Consumer(
              builder: (context, ref, _) => FilledButton(
                onPressed: () async {
                  pdf = await buildSickLeave(ref, certificate);
                },
                child: const Text('Export certificate'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Export certificate'));
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && pdf == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }
      });
      expect(pdf, isNotNull);
      final row = await (db.select(
        db.documentVerifications,
      )..where((v) => v.entityId.equals(certificate.id))).getSingle();
      final code = DocumentVerificationRepositoryImpl.format(row.code);
      final document = PdfDocument(inputBytes: pdf!);
      try {
        expect(PdfTextExtractor(document).extractText(), contains(code));
      } finally {
        document.dispose();
      }
      final payload = 'MHC-VERIFY:$code';
      final picture = _qrPicture(payload);
      final decoded = decodeQrFromImageSync(picture);
      expect(decoded, payload);
      expect(
        (await container
                .read(documentVerificationRepositoryProvider)
                .verify(code))
            .isErr,
        isTrue,
      );
      if (Platform.environment['QR_AUDIT_ARTIFACTS'] == '1') {
        File('.tmp/demo-sick-leave.pdf').writeAsBytesSync(pdf!);
        File('.tmp/demo-sick-leave-qr.png').writeAsBytesSync(picture);
        File('.tmp/demo-sick-leave-qr.txt').writeAsStringSync(payload);
      }
      for (final email in ['staff1@myhealth.demo', 'admin@myhealth.demo']) {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await tester.runAsync(() => signInAs(container, email));
        final lookup = await tester.runAsync(
          () => container
              .read(documentVerificationRepositoryProvider)
              .verify(code),
        );
        expect(lookup!.isOk, isTrue, reason: '$email: ${lookup.failureOrNull}');
        expect(lookup.valueOrNull, isNotNull);
        await tester.pumpWidget(
          app(VerifyDocumentScreen(key: ValueKey(email))),
        );
        await _settle(tester);
        await tester.enterText(find.byType(TextField), decoded!);
        await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
        await _settle(tester);
        expect(
          find.text('Legacy registry entry — no immutable issued version'),
          findsOneWidget,
          reason:
              '$email: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).join(" | ")}',
        );
        expect(find.text(code), findsOneWidget);
        expect(
          find.textContaining(certificate.diagnosis),
          email == 'admin@myhealth.demo' ? findsNothing : findsWidgets,
        );
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
