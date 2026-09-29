/// Historical appointment demand compared with configured staff schedules.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import 'admin_providers.dart';

bool get _ar => Intl.getCurrentLocale().startsWith('ar');

enum DemandLevel { low, moderate, high }

class DayForecast {
  const DayForecast({
    required this.weekday,
    required this.peakWindow,
    required this.peakCount,
    required this.level,
    required this.overflowRisk,
    required this.note,
  });
  final int weekday;
  final String peakWindow;
  final int peakCount;
  final DemandLevel level;
  final bool overflowRisk;
  final String note;
  String get dayName => DateFormat('EEEE').format(DateTime(2024, 1, weekday));
}

class ForecastMetadata {
  const ForecastMetadata({
    required this.source,
    required this.windowStart,
    required this.windowEnd,
    required this.exclusions,
    required this.timezone,
    required this.refreshedAt,
  });
  final String source;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final String exclusions;
  final String timezone;
  final DateTime refreshedAt;

  bool isStaleAt(DateTime now) =>
      now.difference(refreshedAt) > const Duration(minutes: 15);
}

class DemandSourceRow {
  const DemandSourceRow({
    required this.appointmentId,
    required this.staffId,
    required this.slotStart,
    required this.status,
  });

  final String appointmentId;
  final String staffId;
  final DateTime slotStart;
  final AppointmentStatus status;
}

class CapacityForecast {
  const CapacityForecast({
    required this.days,
    required this.metadata,
    required this.sourceRows,
    this.aiNarrated = false,
  });
  final List<DayForecast> days;
  final ForecastMetadata metadata;
  final List<DemandSourceRow> sourceRows;
  final bool aiNarrated;
}

CapacityForecast forecastFromHistory(
  List<Appointment> history, {
  Map<int, int> staffedSlotsPerHour = const {},
  DateTime? refreshedAt,
}) {
  final included = history
      .where((a) => a.status != AppointmentStatus.cancelled)
      .toList();
  final grid = <int, Map<int, int>>{};
  for (final appointment in included) {
    final weekday = appointment.slotStart.weekday;
    final hour = appointment.slotStart.hour;
    (grid[weekday] ??= {}).update(hour, (v) => v + 1, ifAbsent: () => 1);
  }
  final counts = [for (final hours in grid.values) ...hours.values]..sort();
  int percentile(double value) =>
      counts.isEmpty ? 0 : counts[((counts.length - 1) * value).round()];
  final p50 = percentile(0.5);
  final p80 = percentile(0.8);
  final days = <DayForecast>[];
  for (var weekday = 1; weekday <= 7; weekday++) {
    final hours = grid[weekday] ?? const <int, int>{};
    if (hours.isEmpty) {
      days.add(
        DayForecast(
          weekday: weekday,
          peakWindow: '—',
          peakCount: 0,
          level: DemandLevel.low,
          overflowRisk: false,
          note: _ar
              ? 'لا يوجد سجل مواعيد لهذا اليوم بعد.'
              : 'No appointment history for this day yet.',
        ),
      );
      continue;
    }
    final peak = hours.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final level = peak.value >= p80 && p80 > 0
        ? DemandLevel.high
        : peak.value >= p50
        ? DemandLevel.moderate
        : DemandLevel.low;
    final capacity = staffedSlotsPerHour[weekday];
    final aboveCapacity =
        capacity != null && capacity > 0 && peak.value > capacity;
    days.add(
      DayForecast(
        weekday: weekday,
        peakWindow: '${_hh(peak.key)}–${_hh((peak.key + 1) % 24)}',
        peakCount: peak.value,
        level: level,
        overflowRisk: aboveCapacity,
        note: aboveCapacity
            ? (_ar
                  ? 'تجاوز الطلب التاريخي سعة المواعيد المجدولة في هذه الساعة.'
                  : 'Historical demand exceeded scheduled appointment capacity in this hour.')
            : level == DemandLevel.high
            ? (_ar
                  ? 'هذه من أكثر الفترات ازدحاماً في السجل.'
                  : 'This is one of the busier windows in the historical record.')
            : (_ar
                  ? 'لا يُستنتج مستوى التغطية من الطلب وحده.'
                  : 'No staffing conclusion is made from demand alone.'),
      ),
    );
  }
  final dates = included.map((a) => a.slotStart).toList()..sort();
  return CapacityForecast(
    days: days,
    metadata: ForecastMetadata(
      source: 'Appointment history and active staff schedule templates',
      windowStart: dates.isEmpty ? null : dates.first,
      windowEnd: dates.isEmpty ? null : dates.last,
      exclusions: 'Cancelled appointments',
      timezone: 'Clinic local time',
      refreshedAt: refreshedAt ?? DateTime.now(),
    ),
    sourceRows: [
      for (final appointment
          in included..sort((a, b) => b.slotStart.compareTo(a.slotStart)))
        DemandSourceRow(
          appointmentId: appointment.id,
          staffId: appointment.staffId,
          slotStart: appointment.slotStart,
          status: appointment.status,
        ),
    ],
  );
}

String _hh(int hour) => '${hour.toString().padLeft(2, '0')}:00';

Map<int, int> scheduledHourlyCapacity(List<ScheduleTemplate> templates) {
  final result = <int, int>{};
  for (var weekday = 1; weekday <= 7; weekday++) {
    final slotsByHour = <int, int>{};
    for (final template in templates.where((t) => t.weekday == weekday)) {
      for (
        var minute = template.startMinutes;
        minute < template.endMinutes;
        minute += template.slotMinutes
      ) {
        slotsByHour.update(minute ~/ 60, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    if (slotsByHour.isNotEmpty) {
      result[weekday] = slotsByHour.values.reduce((a, b) => a > b ? a : b);
    }
  }
  return result;
}

final capacityForecastProvider = FutureProvider<CapacityForecast>((ref) async {
  final history = await ref.watch(allAppointmentsProvider.future);
  final staff = await ref.watch(usersByRoleProvider(UserRole.staff).future);
  final templates = <ScheduleTemplate>[];
  for (final member in staff.where((u) => u.isActive)) {
    templates.addAll(
      await ref.watch(staffScheduleTemplatesProvider(member.id).future),
    );
  }
  return forecastFromHistory(
    history,
    staffedSlotsPerHour: scheduledHourlyCapacity(templates),
  );
});
