import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/services/pdf/issued_sick_leave_pdf.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final language in ['en', 'ar']) {
    test('long mixed-direction $language document preserves all pages', () async {
      final paragraphs = List.generate(
        90,
        (i) =>
            'ROW$i ${language == 'ar' ? 'المريض أحمد محمد الطبيب سارة' : 'Patient Alexandra Montgomery clinician Samuel'} '
            'Reference AB-123 / أحمد — follow-up 2026-10-09.',
      );
      final bytes = await const IssuedSickLeavePdf().render(
        wording: paragraphs.join('\n'),
        language: language,
        reference: 'ACCEPTANCE-123',
        issuedAt: DateTime.utc(2026, 10, 9),
        clinicName: 'MyHealth أحمد Alexandra Montgomery Clinical Care Centre',
      );
      final document = sf.PdfDocument(inputBytes: bytes);
      final output = Platform.environment['PDF_ACCEPTANCE_OUTPUT'];
      if (output != null) {
        await Directory(output).create(recursive: true);
        await File('$output/mixed-$language.pdf').writeAsBytes(bytes);
        final printSample = await const IssuedSickLeavePdf().render(
          wording: language == 'ar'
              ? 'نسخة اختبار ببيانات وهمية للاختبار فقط.\nالمريض: أحمد محمد عبدالرحمن. الطبيب: سارة محمد.\nتاريخ الحضور: 2026-10-09. المرجع: AB-123.\nمدة الإجازة من 2026-10-09 إلى 2026-10-10.'
              : 'SYNTHETIC PRINT TEST ONLY.\nPatient: Alexandra Montgomery. Clinician: Samuel Morgan.\nAttendance: 2026-10-09. Reference: AB-123.\nLeave from 2026-10-09 to 2026-10-10.',
          language: language,
          title: language == 'ar'
              ? 'إجازة مرضية — نسخة اختبار'
              : 'Sick leave — print test',
          clinicName: 'MyHealth Care — عيادة الاختبار',
          reference: 'TEST-PRINT-2026',
          issuedAt: DateTime.utc(2026, 10, 9),
          draft: true,
        );
        await File(
          '$output/print-draft-$language.pdf',
        ).writeAsBytes(printSample);
      }
      try {
        expect(document.pages.count, greaterThan(2));
        final extractor = sf.PdfTextExtractor(document);
        final text = extractor.extractText();
        for (var i = 0; i < paragraphs.length; i++) {
          expect(text, contains('ROW$i'), reason: 'paragraph $i was lost');
        }
        for (var page = 0; page < document.pages.count; page++) {
          final pageText = extractor.extractText(
            startPageIndex: page,
            endPageIndex: page,
          );
          expect(pageText, contains('ACCEPTANCE-123'));
          expect(pageText, contains('2026-10-09'));
          expect(document.pages[page].size.width, closeTo(595.28, 1));
          expect(document.pages[page].size.height, closeTo(841.89, 1));
        }
        expect(
          RegExp(r'[\u0600-\u06FF\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(text),
          isTrue,
        );
        expect(text, isNot(contains('DRAFT')));
      } finally {
        document.dispose();
      }
    });
  }

  test(
    'one long clinical paragraph spans pages without losing its ending',
    () async {
      final bytes = await const IssuedSickLeavePdf().render(
        wording:
            '${List.filled(500, 'Clinical assessment and follow-up documented.').join(' ')} END_OF_NOTE',
        language: 'en',
        reference: 'LONG-NOTE-123',
        issuedAt: DateTime.utc(2026, 10, 9),
      );
      final document = sf.PdfDocument(inputBytes: bytes);
      try {
        expect(document.pages.count, greaterThan(1));
        final text = sf.PdfTextExtractor(document).extractText();
        expect(text, contains('END_OF_NOTE'));
        expect(
          RegExp(
            'Clinical assessment',
          ).allMatches(text.replaceAll(RegExp(r'\s+'), ' ')),
          hasLength(500),
        );
      } finally {
        document.dispose();
      }
    },
  );
}
