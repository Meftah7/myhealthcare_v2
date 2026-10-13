// Writes representative branded PDFs from fictional data for visual review:
//   flutter test tool/branding/sample_pdfs_test.dart
// Output: build/brand_samples/*.pdf (not committed).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/services/pdf/clinic_pdf.dart';
import 'package:myhealthcare/services/pdf/issued_sick_leave_pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final out = Directory('build/brand_samples')..createSync(recursive: true);
  const patient = PdfIdentity(
    name: 'Sample Patient (fictional)',
    patientId: 'TEST-0001',
  );

  test('clinical: sample sick-leave certificate', () async {
    final bytes = await const IssuedSickLeavePdf().render(
      wording:
          'This is a fictional sample certificate for branding review.\n'
          'Sample Patient (fictional) attended on 1 October 2026 and is '
          'advised rest from 1 to 3 October 2026.\n'
          'Issued by: Sample Clinician (fictional), licence TEST-LIC.',
      language: 'en',
      reference: 'SAMPLE-REF-0001',
      issuedAt: DateTime(2026, 10, 1, 9),
      verificationUrl: 'https://verify.example.test/SAMPLE-REF-0001',
      brandLogo: true,
    );
    File('${out.path}/sample_sick_leave.pdf').writeAsBytesSync(bytes);
    expect(bytes, isNotEmpty);
  });

  test('finance: sample invoice', () async {
    final bytes = await ClinicPdf.build(
      title: 'Invoice',
      subtitle: 'Fictional sample',
      patient: patient,
      provenance: DocumentProvenance(
        issuer: 'myhealth billing (sample)',
        source: 'Sample data',
        documentDate: DateTime(2026, 10, 1),
        status: 'Outstanding',
        reference: 'INV-SAMPLE-0001',
      ),
      body: [
        pw.TableHelper.fromTextArray(
          headers: ['Item', 'Qty', 'Amount (BHD)'],
          data: [
            ['Consultation (sample)', '1', '15.000'],
            ['Lab panel (sample)', '1', '8.500'],
            ['Total', '', '23.500'],
          ],
        ),
      ],
    );
    File('${out.path}/sample_invoice.pdf').writeAsBytesSync(bytes);
    expect(bytes, isNotEmpty);
  });

  test('multi-page: sample visit summary', () async {
    final bytes = await ClinicPdf.build(
      title: 'Visit summary',
      patient: patient,
      provenance: DocumentProvenance(
        issuer: 'Sample Clinician (fictional)',
        source: 'Sample data',
        documentDate: DateTime(2026, 10, 1),
        status: 'Final',
        reference: 'SUM-SAMPLE-0001',
      ),
      body: [
        for (var i = 1; i <= 90; i++)
          pw.Text('Sample line $i: fictional note text for layout review.'),
      ],
    );
    File('${out.path}/sample_visit_summary.pdf').writeAsBytesSync(bytes);
    expect(bytes, isNotEmpty);
  });
}
