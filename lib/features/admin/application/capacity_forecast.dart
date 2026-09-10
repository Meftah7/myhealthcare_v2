/// Capacity forecast (Tier B) — a 7-day, per-weekday view of the clinic's
/// busiest hours and where demand is likely to outrun capacity.
///
/// Ported from the FirstSemMyHealth `Ai/predictive_schedule.php`: the same
/// weekday × hour aggregation and overflow flag, computed deterministically
/// from appointment history. AI-enhanced narration is layered on when a key is
/// configured, with the statistical result as the always-available fallback.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums.dart';
import 'admin_providers.dart';
import 'settings_providers.dart';

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

  /// 1 = Monday … 7 = Sunday (Dart's `DateTime.weekday`).
  final int weekday;
  final String peakWindow;
  final int peakCount;
  final DemandLevel level;
  final bool overflowRisk;
  final String note;

  String get dayName => DateFormat('EEEE').format(DateTime(2024, 1, weekday));
}

class CapacityForecast {
  const CapacityForecast({required this.days, required this.aiNarrated});

  final List<DayForecast> days;

  /// True when a live model wrote the notes (drives the disclaimer banner).
  final bool aiNarrated;
}

/// Deterministic forecast from appointment history — the always-available base.
CapacityForecast forecastFromHistory(
  List<Appointment> history, {
  int overflowPerHour = 4,
}) {
  // weekday (1-7) → hour (0-23) → count
  final grid = <int, Map<int, int>>{};
  for (final a in history) {
    if (a.status == AppointmentStatus.cancelled) continue;
    final wd = a.slotStart.weekday;
    final hr = a.slotStart.hour;
    (grid[wd] ??= {})[hr] = ((grid[wd] ?? const {})[hr] ?? 0) + 1;
  }

  // All bucket counts, for a relative Low / Moderate / High scale.
  final allCounts = [for (final byHour in grid.values) ...byHour.values]
    ..sort();
  int percentile(double p) {
    if (allCounts.isEmpty) return 0;
    final idx = ((allCounts.length - 1) * p).round();
    return allCounts[idx];
  }

  final p50 = percentile(0.5);
  final p80 = percentile(0.8);

  final days = <DayForecast>[];
  for (var wd = 1; wd <= 7; wd++) {
    final byHour = grid[wd] ?? const <int, int>{};
    if (byHour.isEmpty) {
      days.add(
        DayForecast(
          weekday: wd,
          peakWindow: '—',
          peakCount: 0,
          level: DemandLevel.low,
          overflowRisk: false,
          note: 'No history for this day yet.',
        ),
      );
      continue;
    }
    final peakHour = byHour.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final level = peakHour.value >= p80 && p80 > 0
        ? DemandLevel.high
        : peakHour.value >= p50
        ? DemandLevel.moderate
        : DemandLevel.low;
    final overflow =
        peakHour.value >= overflowPerHour && level == DemandLevel.high;
    days.add(
      DayForecast(
        weekday: wd,
        peakWindow: '${_hh(peakHour.key)}–${_hh((peakHour.key + 1) % 24)}',
        peakCount: peakHour.value,
        level: level,
        overflowRisk: overflow,
        note: overflow
            ? 'Peak demand has run at or above capacity here — consider an '
                  'extra clinician on this shift.'
            : level == DemandLevel.high
            ? 'Consistently one of the busier windows; watch the waitlist.'
            : 'Coverage looks adequate.',
      ),
    );
  }
  return CapacityForecast(days: days, aiNarrated: false);
}

String _hh(int h) => '${h.toString().padLeft(2, '0')}:00';

/// The forecast for the admin dashboard — statistical, then AI-narrated when a
/// key is set (the numbers never change; only the notes get richer).
final capacityForecastProvider = FutureProvider<CapacityForecast>((ref) async {
  final history = await ref.watch(allAppointmentsProvider.future);
  final base = forecastFromHistory(history);

  final settings = await ref.watch(appSettingsProvider.future);
  final key = await ref.watch(aiKeyStoreProvider).read();
  if (!settings.usesRealAi || key == null || key.isEmpty || base.days.isEmpty) {
    return base;
  }

  try {
    final notes = await _narrate(base, apiKey: key, model: settings.modelId);
    if (notes.isEmpty) return base;
    return CapacityForecast(
      aiNarrated: true,
      days: [
        for (final d in base.days)
          DayForecast(
            weekday: d.weekday,
            peakWindow: d.peakWindow,
            peakCount: d.peakCount,
            level: d.level,
            overflowRisk: d.overflowRisk,
            note: notes[d.weekday] ?? d.note,
          ),
      ],
    );
  } catch (_) {
    return base;
  }
});

Future<Map<int, String>> _narrate(
  CapacityForecast base, {
  required String apiKey,
  required String model,
}) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  final rows = [
    for (final d in base.days)
      {
        'weekday': d.weekday,
        'day': d.dayName,
        'peak_window': d.peakWindow,
        'peak_count': d.peakCount,
        'level': d.level.name,
        'overflow_risk': d.overflowRisk,
      },
  ];

  final res = await dio.post<Map<String, dynamic>>(
    '/models/$model:generateContent',
    queryParameters: {'key': apiKey},
    data: {
      'systemInstruction': {
        'parts': [
          {
            'text':
                'You are a clinic operations analyst. For each weekday you are '
                'given the busiest hour and how it compares to the clinic norm. '
                'Return ONLY a JSON object mapping the weekday number (1-7) to a '
                'one-sentence staffing note. Be concrete and calm; do not invent '
                'numbers.',
          },
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': jsonEncode(rows)},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.3,
        'responseMimeType': 'application/json',
      },
    },
  );

  final candidates = res.data?['candidates'];
  final first = (candidates is List && candidates.isNotEmpty)
      ? candidates.first
      : null;
  final content = first is Map ? first['content'] : null;
  final parts = content is Map ? content['parts'] : null;
  final part = (parts is List && parts.isNotEmpty) ? parts.first : null;
  final raw = part is Map ? part['text'] : null;
  if (raw is! String) return const {};

  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) return const {};
  final decoded = jsonDecode(raw.substring(start, end + 1));
  if (decoded is! Map) return const {};
  return {
    for (final e in decoded.entries)
      if (int.tryParse(e.key.toString()) != null && e.value is String)
        int.parse(e.key.toString()): e.value as String,
  };
}
