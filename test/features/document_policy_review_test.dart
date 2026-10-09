import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/domain/identity/operational_roles.dart';
import 'package:myhealthcare/domain/identity/permissions.dart';
import 'package:myhealthcare/domain/repositories/document_policy_repository.dart';
import 'package:myhealthcare/features/admin/presentation/document_policies_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/sessions.dart';

T _value<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};
Future<void> _enable(ProviderContainer c) async {
  _value(
    await c
        .read(scopedGrantRepositoryProvider)
        .grant(
          accountId: 'admin_01',
          permission: Permission.manageDocumentTemplates,
          scope: GrantScope.clinic,
          scopeId: '',
          reason: 'Policy review',
        ),
  );
}

DocumentPolicyDraft _copy(
  DocumentPolicyDraft d, {
  String? wording,
  int? version,
}) => DocumentPolicyDraft(
  id: version == null ? d.id : '${d.id}-v$version',
  document: d.document,
  version: version ?? d.version,
  language: d.language,
  disclosure: d.disclosure,
  wording: wording ?? d.wording,
  clinicalSignatureRequired: d.clinicalSignatureRequired,
);
Widget _app(Widget child, {String locale = 'en', double scale = 1}) =>
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    );
Future<void> _expand(WidgetTester tester) async {
  final tile = find.byKey(
    const PageStorageKey('policy-sick-leave-v1-en-employer'),
  );
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  if (find.byType(TextField).evaluate().isEmpty) {
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }
}

class _FailOnce implements DocumentPolicyRepository {
  _FailOnce(this.inner);
  final DocumentPolicyRepository inner;
  bool fail = true;
  @override
  Future<Result<List<DocumentPolicy>>> forReview() => inner.forReview();
  @override
  Future<Result<void>> approve(
    String id, {
    required DocumentPolicyDraft expectedDraft,
  }) => inner.approve(id, expectedDraft: expectedDraft);
  @override
  Future<Result<void>> saveDraft(
    DocumentPolicyDraft draft, {
    String? expectedWording,
    bool createOnly = false,
  }) async {
    if (fail) {
      fail = false;
      return const Err(DatabaseFailure('Injected write failure'));
    }
    return inner.saveDraft(
      draft,
      expectedWording: expectedWording,
      createOnly: createOnly,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'policy review authorization, stale approval, disclosure fields and replacement are enforced in the repository',
    () async {
      final (c, db) = await seededContainer();
      await signInAs(c, 'staff1@myhealth.demo');
      final repo = c.read(documentPolicyRepositoryProvider);
      expect(
        (await repo.forReview()).failureOrNull,
        isA<AccessDeniedFailure>(),
      );
      await signInAs(c, 'admin@myhealth.demo');
      final draft = _value(
        await repo.forReview(),
      ).firstWhere((p) => p.draft.id == 'sick-leave-v1-en-employer').draft;
      expect(
        (await repo.approve(draft.id, expectedDraft: draft)).failureOrNull,
        isA<AccessDeniedFailure>(),
      );
      await _enable(c);
      final auth = c.read(authContextProvider);
      auth.establish(
        auth.principal!.reauthenticated(
          DateTime.now().subtract(const Duration(minutes: 20)),
        ),
      );
      expect(
        (await repo.approve(draft.id, expectedDraft: draft)).failureOrNull,
        isA<ReauthRequiredFailure>(),
      );
      auth.markReauthenticated();
      final changed = _copy(draft, wording: '${draft.wording} Reviewed.');
      _value(await repo.saveDraft(changed, expectedWording: draft.wording));
      expect(
        (await repo.approve(draft.id, expectedDraft: draft)).failureOrNull,
        isA<ConflictFailure>(),
      );
      expect(
        (await repo.saveDraft(
          draft,
          expectedWording: draft.wording,
        )).failureOrNull,
        isA<ConflictFailure>(),
      );
      expect(
        (await repo.saveDraft(
          _copy(changed, wording: '${changed.wording} {diagnosis}'),
        )).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(
        (await repo.saveDraft(
          _copy(changed, wording: 'No required fields'),
        )).failureOrNull,
        isA<ValidationFailure>(),
      );
      _value(await repo.approve(changed.id, expectedDraft: changed));
      _value(await repo.approve(changed.id, expectedDraft: changed));
      expect(
        (await db.select(db.auditLog).get()).where(
          (a) => a.action == 'document.policy.approve',
        ),
        hasLength(1),
      );
      final next = _copy(changed, version: 2);
      _value(await repo.saveDraft(next, createOnly: true));
      expect(
        (await repo.saveDraft(next, createOnly: true)).failureOrNull,
        isA<ConflictFailure>(),
      );
      await db.customStatement(
        "CREATE TRIGGER fail_policy_approval BEFORE INSERT ON audit_log WHEN NEW.action='document.policy.approve' BEGIN SELECT RAISE(ABORT,'audit unavailable'); END",
      );
      expect((await repo.approve(next.id, expectedDraft: next)).isErr, isTrue);
      var policies = _value(await repo.forReview());
      expect(
        policies.firstWhere((p) => p.draft.id == changed.id).retiredAt,
        isNull,
      );
      expect(
        policies.firstWhere((p) => p.draft.id == next.id).approvedAt,
        isNull,
      );
      await db.customStatement('DROP TRIGGER fail_policy_approval');
      _value(await repo.approve(next.id, expectedDraft: next));
      policies = _value(await repo.forReview());
      expect(
        policies.firstWhere((p) => p.draft.id == changed.id).retiredAt,
        isNotNull,
      );
      expect(
        policies.firstWhere((p) => p.draft.id == next.id).approvedByName,
        isNotEmpty,
      );
      expect(
        (await repo.approve(changed.id, expectedDraft: changed)).isErr,
        isTrue,
      );
    },
  );

  testWidgets(
    'admin explicitly enables management, edits, approves and creates an unapproved next version',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (c, db) = await seededContainer();
      await signInAs(c, 'admin@myhealth.demo');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: _app(const DocumentPoliciesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(await db.select(db.scopedGrants).get(), isEmpty);
      await tester.tap(find.text('Enable policy management'));
      await tester.pumpAndSettle();
      expect(
        (await db.select(db.scopedGrants).get()).single.permission,
        Permission.manageDocumentTemplates.name,
      );
      await _expand(tester);
      final old = tester
          .widget<TextField>(find.byType(TextField))
          .controller!
          .text;
      await tester.enterText(find.byType(TextField), '$old Reviewed.');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save draft'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save draft'));
      await tester.pumpAndSettle();
      var policy = (await db.select(db.documentTemplates).get()).firstWhere(
        (p) => p.id == 'sick-leave-v1-en-employer',
      );
      expect(policy.approvedAt, isNull);
      expect(policy.wording, '$old Reviewed.');
      await _expand(tester);
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Approve this version'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve this version'));
      await tester.pumpAndSettle();
      policy = (await db.select(db.documentTemplates).get()).firstWhere(
        (p) => p.id == 'sick-leave-v1-en-employer',
      );
      expect(policy.approvedBy, 'admin_01');
      expect(policy.approvedAt, isNotNull);
      await _expand(tester);
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      await tester.ensureVisible(find.text('Create a new draft version'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create a new draft version'));
      await tester.pumpAndSettle();
      final next = (await db.select(db.documentTemplates).get()).singleWhere(
        (p) => p.version == 2,
      );
      expect(next.approvedAt, isNull);
      expect(next.wording, policy.wording);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed save retains entered wording for retry', (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (c, db) = await seededContainer();
    await signInAs(c, 'admin@myhealth.demo');
    await _enable(c);
    final fake = _FailOnce(c.read(documentPolicyRepositoryProvider));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: ProviderScope(
          overrides: [
            documentPolicyRepositoryProvider.overrideWithValue(fake),
            documentPoliciesProvider.overrideWith(
              (ref) async => _value(await fake.forReview()),
            ),
          ],
          child: _app(const DocumentPoliciesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _expand(tester);
    final input =
        '${tester.widget<TextField>(find.byType(TextField)).controller!.text} Retry wording.';
    await tester.enterText(find.byType(TextField), input);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save draft'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      input,
    );
    expect(
      (await db.select(db.documentTemplates).get())
          .firstWhere((p) => p.id == 'sick-leave-v1-en-employer')
          .wording,
      isNot(input),
    );
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();
    expect(
      (await db.select(db.documentTemplates).get())
          .firstWhere((p) => p.id == 'sick-leave-v1-en-employer')
          .wording,
      input,
    );
  });

  for (final locale in ['en', 'ar']) {
    testWidgets(
      'policy review fits a 320px phone with enlarged text ($locale)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final (c, db) = await seededContainer();
        await signInAs(c, 'admin@myhealth.demo');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: _app(
              const DocumentPoliciesScreen(),
              locale: locale,
              scale: 2,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final tile = find.byType(ExpansionTile).first;
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: tile, matching: find.byType(ListTile)).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(await db.select(db.scopedGrants).get(), isEmpty);
      },
    );
  }
}
