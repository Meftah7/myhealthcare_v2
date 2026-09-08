// The Allergies screen shows the list prominently, or a calm empty state
// (P10-06).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/patient/application/patient_data_providers.dart';
import 'package:myhealthcare/features/patient/presentation/allergies_screen.dart';

Patient _patient({List<String> allergies = const []}) => Patient(
  user: User(
    id: 'p1',
    role: UserRole.patient,
    fullName: 'Sara Ahmed',
    email: 'sara@example.com',
    isActive: true,
    createdAt: DateTime(2020),
  ),
  allergies: allergies,
);

Future<void> _pump(WidgetTester tester, Patient patient) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [patientProfileProvider.overrideWith((ref) async => patient)],
      child: MaterialApp(theme: AppTheme.light, home: const AllergiesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists each allergy with the alert heading', (tester) async {
    await _pump(tester, _patient(allergies: ['Penicillin', 'Peanuts']));

    expect(find.text('Known allergies'), findsOneWidget);
    expect(find.text('Penicillin'), findsOneWidget);
    expect(find.text('Peanuts'), findsOneWidget);
    expect(find.text('Update allergies'), findsOneWidget);
  });

  testWidgets('shows a calm empty state when none are recorded', (
    tester,
  ) async {
    await _pump(tester, _patient());

    expect(find.text('No allergies recorded'), findsOneWidget);
    expect(find.text('Add your allergies'), findsOneWidget);
  });
}
