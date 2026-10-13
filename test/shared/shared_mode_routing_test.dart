// In shared mode, a screen that reads the device database is replaced by
// an explanation instead of showing empty local data.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/app/shared_mode.dart';

import '../support/sessions.dart';

void main() {
  testWidgets('blocked routes show the shared-mode explanation', (
    tester,
  ) async {
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
    expect(c.read(routerProvider).state.uri.path, sharedUnavailableRoute);
    expect(find.byType(SharedModeUnavailableScreen), findsOneWidget);
    expect(find.text('This screen is not available yet'), findsOneWidget);
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
  });
}
