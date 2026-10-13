// myhealth branding: the shared logo component, its assets, the lowercase
// name, and the PDF mark applied only to versions issued with it.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/presentation/app_scaffold.dart';
import 'package:myhealthcare/services/pdf/brand_pdf.dart';

import '../services/document_service_test.dart'
    show TestRenderer, approved, setup, value;
import '../support/sessions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled logos are square, transparent outside the mark', () async {
    for (final asset in [AppLogo.asset, BrandPdf.asset]) {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      expect(image.width, image.height, reason: asset);
      final pixels = (await image.toByteData())!;
      // Top-left corner pixel is outside the rounded square: transparent.
      expect(pixels.getUint8(3), 0, reason: asset);
      // Centre pixel is inside the mark: opaque.
      final centre = ((image.height ~/ 2) * image.width + image.width ~/ 2) * 4;
      expect(pixels.getUint8(centre + 3), 255, reason: asset);
    }
  });

  testWidgets('AppLogo shows the approved asset and announces myhealth once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(children: [AppLogo(height: 48), AppBrandLockup()]),
        ),
      ),
    );
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images, hasLength(2));
    for (final image in images) {
      expect((image.image as AssetImage).assetName, AppLogo.asset);
      expect(image.fit, BoxFit.contain);
    }
    expect(kBrandName, 'myhealth');
    expect(find.text('myhealth'), findsOneWidget);
    // The standalone logo is labelled; the lockup's logo is decorative, so
    // the brand is announced by its wordmark only.
    expect(find.bySemanticsLabel('myhealth'), findsNWidgets(2));
    semantics.dispose();
  });

  group('issued documents', () {
    test('new issuances freeze the mark and render with the logo', () async {
      final renderer = TestRenderer();
      final (c, db) = await seededContainer(
        overrides: [
          issuedSickLeaveRendererProvider.overrideWithValue(renderer),
        ],
      );
      final visit = await setup(db);
      await signInAs(c, 'staff1@myhealth.demo');
      final service = c.read(documentServiceProvider);
      final request = await approved(service, visit);
      final issued = value(
        await service.issue(
          request.id,
          expectedVersion: request.version,
          idempotencyKey: 'brand-new',
        ),
      );
      final row = await (db.select(
        db.issuedDocumentVersions,
      )..where((d) => d.id.equals(issued.id))).getSingle();
      expect(
        (jsonDecode(row.templateSnapshotJson) as Map)['brandMark'],
        BrandPdf.snapshotMark,
      );
      value(await service.render(issued.id));
      expect(renderer.brandLogo, isTrue);
    });

    test('an already rendered issued copy is never regenerated', () async {
      final renderer = TestRenderer();
      final (c, db) = await seededContainer(
        overrides: [
          issuedSickLeaveRendererProvider.overrideWithValue(renderer),
        ],
      );
      final visit = await setup(db);
      await signInAs(c, 'staff1@myhealth.demo');
      final service = c.read(documentServiceProvider);
      final request = await approved(service, visit);
      final issued = value(
        await service.issue(
          request.id,
          expectedVersion: request.version,
          idempotencyKey: 'brand-ready',
        ),
      );
      value(await service.render(issued.id));
      final before = value(await service.download(issued.id));
      final calls = renderer.calls;
      value(await service.render(issued.id));
      expect(renderer.calls, calls);
      expect(value(await service.download(issued.id)), before);
    });
  });
}
