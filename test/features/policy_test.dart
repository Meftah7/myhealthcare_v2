// MyHealth Terms / Privacy: owner-replaceable content, honest draft state,
// signed-out access, both languages.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/features/policies/application/policy_content.dart';
import 'package:myhealthcare/features/policies/presentation/policy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

/// An asset bundle serving an approved config (test data only).
class _ApprovedBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final real = await rootBundle.loadString(key);
    if (key != 'assets/policies/policies.json') return real;
    final config = jsonDecode(real) as Map<String, dynamic>
      ..['status'] = 'approved';
    return jsonEncode(config);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('markdown subset: title, headings, bullets, paragraphs', () {
    final parsed = parsePolicyMarkdown(
      '# Title\n\nIntro line one\nline two\n\n## Section\n- a\n- b\n',
    );
    expect(parsed.title, 'Title');
    expect(parsed.blocks.map((b) => b.type), [
      PolicyBlockType.paragraph,
      PolicyBlockType.heading,
      PolicyBlockType.bullet,
      PolicyBlockType.bullet,
    ]);
    expect(parsed.blocks.first.text, 'Intro line one line two');
  });

  test('bundled documents load in both languages and are drafts', () async {
    for (final kind in PolicyKind.values) {
      for (final lang in ['en', 'ar']) {
        final doc = await loadPolicy(rootBundle, kind, lang);
        expect(doc.title, isNotEmpty, reason: '$kind $lang');
        expect(doc.blocks, isNotEmpty);
        expect(doc.approved, isFalse);
        expect(doc.unresolved, isNotEmpty);
      }
    }
    final en = await loadPolicy(rootBundle, PolicyKind.privacy, 'en');
    // No invented operator or compliance claims in the draft.
    final text = en.blocks.map((b) => b.text).join(' ');
    expect(text, contains('[operator legal name — to be supplied]'));
    expect(text.toLowerCase(), isNot(contains('compliant')));
    // An unknown language falls back to English.
    final fr = await loadPolicy(rootBundle, PolicyKind.terms, 'fr');
    expect(
      fr.title,
      (await loadPolicy(rootBundle, PolicyKind.terms, 'en')).title,
    );
  });

  test('an approved config is reported as approved', () async {
    final doc = await loadPolicy(_ApprovedBundle(), PolicyKind.terms, 'en');
    expect(doc.approved, isTrue);
  });

  testWidgets('signed out: the privacy policy opens with its draft banner', (
    tester,
  ) async {
    final db = newTestDatabase();
    await Seeder(db).run();
    SharedPreferences.setMockInitialValues({'ui.hasSeenOnboarding': true});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    c.read(routerProvider).go(AppRoutes.policyPrivacy);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(PolicyScreen), findsOneWidget);
    // Asset loading completes on the real event loop.
    for (
      var i = 0;
      i < 20 &&
          find.byKey(const ValueKey('policy-draft-banner')).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('policy-draft-banner')), findsOneWidget);
    expect(find.text('MyHealth Privacy Policy'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
