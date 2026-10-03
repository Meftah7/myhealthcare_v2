import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/app_theme.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/patient_home/presentation/upcoming_appointment_carousel.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';

Appointment _visit(int index) => Appointment(
  id: 'visit-$index',
  patientId: 'patient',
  staffId: 'doctor-$index',
  slotStart: DateTime(2030, 1, index + 1, 10),
  slotEnd: DateTime(2030, 1, index + 1, 11),
  visitType: VisitType.followUp,
  status: AppointmentStatus.confirmed,
  bookedAt: DateTime(2026),
  remindersSent: 0,
  ticketTag: 'K-$index',
  roomNumber: 'A-$index',
);

Future<void> _mount(
  WidgetTester tester, {
  int count = 3,
  double scale = 1,
  bool reduceMotion = false,
  String language = 'en',
}) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: UpcomingAppointmentCarousel(
              appointments: [for (var i = 1; i <= count; i++) _visit(i)],
              doctorNames: const {
                'doctor-1': 'Dr Anna Smith',
                'doctor-2': 'Dr Ahmed Ali',
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('slides every four seconds, wraps and disposes its timer', (
    tester,
  ) async {
    await _mount(tester);
    expect(find.text('1 of 3'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3999));
    expect(find.text('1 of 3'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('2 of 3'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Dr Ahmed Ali'), findsOneWidget);
    expect(find.text('Dr Anna Smith'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('3 of 3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('1 of 3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 8));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'swipe and arrows work without pause, and swiping resets the timer',
    (tester) async {
      await _mount(tester);
      await tester.pump(const Duration(seconds: 3));
      await tester.fling(
        find.byType(UpcomingAppointmentCarousel),
        const Offset(-200, 0),
        900,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('2 of 3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('2 of 3'), findsOneWidget);
      expect(find.byTooltip('Pause appointment slideshow'), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
      await tester.ensureVisible(find.byTooltip('Previous appointment'));
      await tester.tap(find.byTooltip('Previous appointment'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('1 of 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Next appointment'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('2 of 3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('3 of 3'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('one appointment stays still without carousel controls', (
    tester,
  ) async {
    await _mount(tester, count: 1);
    expect(find.byTooltip('Next appointment'), findsNothing);
    await tester.pump(const Duration(seconds: 12));
    expect(find.text('K-1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion keeps the card still with manual navigation', (
    tester,
  ) async {
    await _mount(tester, reduceMotion: true);
    await tester.pump(const Duration(seconds: 12));
    expect(find.text('1 of 3'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Next appointment'));
    await tester.tap(find.byTooltip('Next appointment'));
    await tester.pump();
    expect(find.text('2 of 3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final language in ['en', 'ar']) {
    testWidgets('320px card expands at 390% text in $language', (tester) async {
      await _mount(tester, scale: 3.9, language: language);
      expect(tester.takeException(), isNull);
      final t = await AppLocalizations.delegate.load(Locale(language));
      await tester.ensureVisible(find.byTooltip(t.nextAppointment));
      await tester.tap(find.byTooltip(t.nextAppointment));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(t.carouselPosition(2, 3)), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
