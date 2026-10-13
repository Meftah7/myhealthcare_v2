// People & Access: a staff profile is split into identity, role, credentials,
// scoped permissions and temporary cover; access forms use pickers, never
// raw ID fields.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/features/admin/presentation/admin_people_profile.dart';
import 'package:myhealthcare/features/admin/presentation/admin_pickers.dart';
import 'package:myhealthcare/features/admin/presentation/audit_log_screen.dart';
import 'package:myhealthcare/features/admin/presentation/document_access_screen.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

import '../support/sessions.dart';

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer c,
  Widget home,
) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('a staff profile shows the five access sections', (tester) async {
    final (c, _) = await seededContainer();
    await signInAs(c, 'admin@myhealth.demo');
    await _pump(tester, c, const AdminPeopleProfileScreen('staff_01'));
    expect(tester.takeException(), isNull);
    for (final heading in [
      'Identity',
      'Role & assignment',
      'Clinical credentials',
      'Scoped permissions',
      'Temporary cover',
    ]) {
      expect(find.text(heading), findsOneWidget, reason: heading);
    }
    expect(find.text('Doctor'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('document access uses a patient picker, not an ID field', (
    tester,
  ) async {
    final (c, _) = await seededContainer();
    await signInAs(c, 'admin@myhealth.demo');
    await _pump(tester, c, const DocumentAccessScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Patient ID'), findsNothing);
    expect(find.byType(PatientPickerField), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  test('audit entries link only to records an admin may open', () {
    expect(auditLink('account', 'staff_01'), '/admin/users/staff_01');
    expect(auditLink('referral_request', 'r1'), isNotNull);
    expect(auditLink('schedule', 'staff_01'), '/admin/clinic/schedules');
    for (final clinical in ['record', 'encounter', 'care_message', 'vitals']) {
      expect(auditLink(clinical, 'x'), isNull, reason: clinical);
    }
  });
}
