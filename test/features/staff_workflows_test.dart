// Staff workflows through the real app on a phone: reception books for a
// patient (find → confirm → clinician → time → confirm), survives a taken
// slot without losing the patient, sees the booking in Schedule and opens
// reschedule with names (not record keys); an unread team message on Home
// opens the same thread as Chat does, with Chat selected and Back returning
// to the conversation list; pharmacy reviews from the queue.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/app.dart';
import 'package:myhealthcare/app/router.dart';
import 'package:myhealthcare/core/data/contracts.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/ui/patient/patient_bottom_navigation.dart';
import 'package:myhealthcare/core/utils/format.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/appointment_repository.dart';
import 'package:myhealthcare/features/staff_dashboard/presentation/role_workspaces.dart';
import 'package:myhealthcare/features/workforce/workforce_repository.dart';
import 'package:myhealthcare/features/workspace/workspace_repository.dart';

import '../support/sessions.dart';

/// Frames plus real time: the database answers on the real event loop.
Future<void> _settle(WidgetTester tester, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pump(WidgetTester tester, ProviderContainer c) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const MyHealthCareApp()),
  );
  await _settle(tester, 40);
}

String? _selected(WidgetTester tester) {
  for (final s in tester.widgetList<Semantics>(
    find.descendant(
      of: find.byType(PatientBottomNavigation),
      matching: find.byType(Semantics),
    ),
  )) {
    if (s.properties.selected == true) return s.properties.label;
  }
  return null;
}

String _path(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets(
    'Home unread team message opens the Chat thread',
    timeout: const Timeout(Duration(minutes: 2)),
    (tester) async {
      // Data setup runs in the real async zone, where the database lives.
      final (c, id) = (await tester.runAsync(() async {
        final (c, _) = await seededContainer(
          prefs: {'ui.hasSeenOnboarding': true},
        );
        await signInAs(c, 'staff1@myhealth.demo');
        final repo = c.read(workforceRepositoryProvider);
        final id = await repo.startConversation('staff_reception');
        await repo.send(id, 'Room 3 is ready for the next patient', 'k-1');
        await signInAs(c, 'reception@myhealth.demo');
        return (c, id);
      }))!;
      await _pump(tester, c);

      final row = find.byKey(
        ValueKey('home-unread-${AppRoutes.staffTeamThread(id)}'),
      );
      await tester.scrollUntilVisible(
        row,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1 unread'), findsWidgets);
      // Let the scroll settle before tapping (slow machines, parallel runs).
      await _settle(tester, 6);
      await tester.ensureVisible(row);
      await _settle(tester, 4);
      await tester.tap(row);
      for (
        var i = 0;
        i < 10 && _path(c) != AppRoutes.staffTeamThread(id);
        i++
      ) {
        await _settle(tester, 4);
      }
      await _settle(tester);
      expect(_path(c), AppRoutes.staffTeamThread(id));
      expect(_selected(tester), 'Chat');
      expect(find.text('Room 3 is ready for the next patient'), findsWidgets);

      // Back restores the conversation list, still under Chat.
      c.read(routerProvider).pop();
      await _settle(tester);
      expect(_path(c), AppRoutes.staffChat);
      expect(_selected(tester), 'Chat');

      // The Unread filter and search are on the list.
      expect(
        find.byKey(const ValueKey('staff-chat-filter-unread')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('staff-chat-search')), findsOneWidget);
      await _teardown(tester);
    },
  );

  testWidgets(
    'reception books for a patient, keeps them when a slot is taken, sees it in Schedule',
    timeout: const Timeout(Duration(minutes: 3)),
    (tester) async {
      final (c, day, slots, candidates) = (await tester.runAsync(() async {
        final (c, _) = await seededContainer(
          prefs: {'ui.hasSeenOnboarding': true},
        );
        await signInAs(c, 'reception@myhealth.demo');
        final appts = c.read(appointmentRepositoryProvider);
        // A day with at least two open times for Dr Wadha Smith.
        var day = DateTime.now().add(const Duration(days: 7));
        List<OpenSlot> slots = const [];
        for (var i = 0; i < 21 && slots.length < 2; i++) {
          day = DateTime.now().add(Duration(days: 7 + i));
          slots = (await appts.openSlots('staff_01', day)).valueOrNull ?? [];
        }
        final candidates =
            (await c.read(patientRepositoryProvider).search('Al')).valueOrNull!;
        return (c, day, slots, candidates);
      }))!;
      final appts = c.read(appointmentRepositoryProvider);
      expect(slots.length, greaterThanOrEqualTo(2));
      final patient = candidates.firstWhere((p) => p.user.nationalId != null);
      final other = candidates.firstWhere((p) => p.id != patient.id);

      await _pump(tester, c);
      c.read(routerProvider).go(AppRoutes.staffSchedule);
      await _settle(tester);
      expect(_selected(tester), 'Schedule');

      // 1. Find the patient by CPR.
      await tester.tap(find.byKey(const ValueKey('desk-schedule-book')));
      await _settle(tester);
      expect(find.text('Step 1 of 3 · Find the patient'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('desk-search')),
        patient.user.nationalId!,
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await _settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(ValueKey('desk-result-${patient.id}')),
          matching: find.text('Select'),
        ),
      );
      await _settle(tester);

      // 2. Confirm it is the right person.
      expect(find.text('Step 2 of 3 · Confirm the patient'), findsOneWidget);
      expect(find.textContaining(patient.user.nationalId!), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('desk-confirm-patient')));
      await _settle(tester);

      // 3. Clinic → clinician → day → time.
      expect(find.text('Book for ${patient.user.fullName}'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await _settle(tester);
      await tester.tap(find.text('Family Medicine').last);
      await _settle(tester);
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await _settle(tester);
      await tester.tap(find.text(clinicianName('Wadha Smith')).last);
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.event_outlined).last);
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await _settle(tester);
      await tester.enterText(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        ),
        '${day.month}/${day.day}/${day.year}',
      );
      await tester.tap(find.text('OK'));
      await _settle(tester, 24);
      final first = fmtTime(slots.first.start);
      final chip = find.widgetWithText(ChoiceChip, first);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await _settle(tester);

      // Someone else takes that time before confirmation.
      final taken = await tester.runAsync(
        () => appts.book(
          BookingRequest(
            patientId: other.id,
            staffId: 'staff_01',
            start: slots.first.start,
            end: slots.first.end,
            visitType: VisitType.followUp,
            idempotencyKey: IdempotencyKey.generate(),
          ),
        ),
      );
      expect(taken!.isOk, isTrue);
      final confirm = find.text('Confirm booking');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await _settle(tester, 24);
      expect(
        find.text(
          'That time was just taken. Choose one of the remaining times.',
        ),
        findsOneWidget,
      );
      // The patient stays selected; the taken time is no longer offered.
      expect(find.text('Book for ${patient.user.fullName}'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, first), findsNothing);
      final second = find.widgetWithText(ChoiceChip, fmtTime(slots[1].start));
      await tester.ensureVisible(second);
      await tester.tap(second);
      await _settle(tester);
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await _settle(tester, 24);
      expect(find.text('Booking confirmed'), findsOneWidget);

      // The confirmed booking shows in Schedule on its day.
      await tester.tap(find.byKey(const ValueKey('desk-booking-view')));
      await _settle(tester, 24);
      expect(_path(c), AppRoutes.staffSchedule);
      expect(c.read(workspaceDayProvider), clinicDay(slots[1].start));
      expect(find.text(patient.user.fullName), findsWidgets);
      // Names, never record keys, in the schedule.
      expect(find.textContaining(patient.id), findsNothing);

      // Details → Reschedule shows names too.
      final row = find.ancestor(
        of: find.text(patient.user.fullName).first,
        matching: find.byType(InkWell),
      );
      await tester.tap(row.first);
      await _settle(tester);
      expect(find.text('Reschedule'), findsOneWidget);
      expect(find.text(patient.user.nationalId!), findsOneWidget);
      await tester.tap(find.text('Reschedule'));
      await _settle(tester, 24);
      expect(find.text('Reschedule clinic appointment'), findsOneWidget);
      expect(find.textContaining(patient.user.fullName), findsWidgets);
      expect(find.textContaining(patient.id), findsNothing);
      await _teardown(tester);
    },
  );

  testWidgets('pharmacy reviews the next prescription from Home', (
    tester,
  ) async {
    final (c, queue) = (await tester.runAsync(() async {
      final (c, _) = await seededContainer(
        prefs: {'ui.hasSeenOnboarding': true},
      );
      await signInAs(c, 'pharmacy@myhealth.demo');
      return (c, await c.read(pharmacyQueueProvider.future));
    }))!;
    await _pump(tester, c);
    expect(find.byKey(const ValueKey('staff-work-card')), findsOneWidget);
    if (queue.any((o) => !o.isDispensed)) {
      await tester.tap(find.text('Review prescription'));
      await _settle(tester);
      expect(find.byType(DispenseSheet), findsOneWidget);
    } else {
      expect(find.textContaining('No prescriptions waiting'), findsOneWidget);
    }
    await _teardown(tester);
  });

  testWidgets('reception cannot open a chart from a direct link', (
    tester,
  ) async {
    final (c, p) = (await tester.runAsync(() async {
      final (c, _) = await seededContainer(
        prefs: {'ui.hasSeenOnboarding': true},
      );
      await signInAs(c, 'reception@myhealth.demo');
      final found = await c.read(patientRepositoryProvider).search('Al');
      return (c, found.valueOrNull!.first);
    }))!;
    await _pump(tester, c);
    c.read(routerProvider).go(AppRoutes.staffPatientChart(p.id));
    await _settle(tester, 24);
    expect(
      find.textContaining('does not include clinical chart access'),
      findsOneWidget,
    );
    expect(_selected(tester), 'Patients');
    await _teardown(tester);
  });
}
