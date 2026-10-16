// Newly supported patient routes remain available in shared mode; unrelated
// administration pages that still require local storage remain blocked.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/shared_mode.dart';

import '../support/sessions.dart';

void main() {
  testWidgets(
    'supported document routes no longer show the shared-mode explanation',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (c, _) = await seededContainer(
        overrides: [sharedModeProvider.overrideWithValue(true)],
        prefs: {'ui.hasSeenOnboarding': true},
      );
      await signInAs(c, 'patient1@myhealth.demo');
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
      );
      c.read(routerProvider).go('/patient/timeline/documents');
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(
        c.read(routerProvider).state.uri.path,
        '/patient/timeline/documents',
      );
      expect(find.byType(SharedModeUnavailableScreen), findsNothing);
      expect(sharedModeBlocks('/admin/profile/audit'), isTrue);
      // Supported screens still open normally.
      c.read(routerProvider).go(AppRoutes.patientAppointments);
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(
        c.read(routerProvider).state.uri.path,
        AppRoutes.patientAppointments,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
