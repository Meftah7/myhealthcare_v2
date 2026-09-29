import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/capabilities/capability_registry.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/admin/application/capacity_forecast.dart';
import 'package:myhealthcare/features/nutrition/application/nutrition_providers.dart';

void main() {
  test('enabled Phase 8 capabilities have owners and safe fallbacks', () {
    final enabled = phase8Capabilities.where(
      (capability) => capability.mode != CapabilityMode.disabled,
    );
    expect(enabled, isNotEmpty);
    for (final capability in enabled) {
      expect(capability.mayShip, isTrue, reason: capability.id);
      expect(capability.fallback.trim(), isNotEmpty, reason: capability.id);
    }
  });

  test('unvalidated risk model is disabled', () {
    final risk = phase8Capabilities.singleWhere(
      (capability) => capability.id == 'no-show-risk',
    );
    expect(risk.mode, CapabilityMode.disabled);
    expect(risk.mayShip, isFalse);
  });

  test('nutrition preference keys isolate accounts and dependents', () {
    final account = nutritionPreferenceKey('nutrition.test', 'account-1');
    final dependent = nutritionPreferenceKey('nutrition.test', 'dependent-1');
    expect(account, isNot(dependent));
    expect(account, endsWith('.account-1'));
    expect(dependent, endsWith('.dependent-1'));
    expect(nutritionPreferenceKey('nutrition.test', null), isNull);
  });

  test('scheduled capacity comes from real template slot lengths', () {
    final capacity = scheduledHourlyCapacity([
      const ScheduleTemplate(
        id: 'one',
        staffId: 'doctor-a',
        weekday: DateTime.monday,
        startMinutes: 9 * 60,
        endMinutes: 10 * 60,
        slotMinutes: 20,
      ),
      const ScheduleTemplate(
        id: 'two',
        staffId: 'doctor-b',
        weekday: DateTime.monday,
        startMinutes: 9 * 60,
        endMinutes: 10 * 60,
        slotMinutes: 30,
      ),
    ]);
    expect(capacity[DateTime.monday], 5);
  });

  test('cancelled appointments are excluded and metadata is explicit', () {
    final monday = DateTime(2026, 9, 28, 9);
    Appointment appointment(String id, AppointmentStatus status) => Appointment(
      id: id,
      patientId: 'patient',
      staffId: 'staff',
      slotStart: monday,
      slotEnd: monday.add(const Duration(minutes: 20)),
      visitType: VisitType.followUp,
      status: status,
      bookedAt: monday.subtract(const Duration(days: 1)),
      remindersSent: 0,
    );

    final result = forecastFromHistory(
      [
        appointment('kept', AppointmentStatus.confirmed),
        appointment('cancelled', AppointmentStatus.cancelled),
      ],
      staffedSlotsPerHour: const {DateTime.monday: 1},
      refreshedAt: DateTime(2026, 9, 28, 12),
    );
    final day = result.days.singleWhere((d) => d.weekday == DateTime.monday);
    expect(day.peakCount, 1);
    expect(day.overflowRisk, isFalse);
    expect(result.metadata.exclusions, contains('Cancelled'));
    expect(result.metadata.timezone, 'Clinic local time');
    expect(result.metadata.isStaleAt(DateTime(2026, 9, 28, 12, 16)), isTrue);
  });
}
