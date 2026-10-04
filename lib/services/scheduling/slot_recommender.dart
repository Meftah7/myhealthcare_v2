/// Suggests open slots that suit a patient, from how past visits went
/// (Phase 3).
///
/// Uses aggregate clinic history only — attendance and waiting time per
/// weekday × hour, never anyone else's individual visits — plus the
/// patient's own habits. It only ranks: every open slot stays bookable, and
/// the patient always chooses.
library;

import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/appointment_repository.dart';

/// Why a slot was suggested. The UI words these in the user's language.
enum SlotReason {
  /// Visits at this hour are usually attended.
  reliableHour,

  /// Patients at this hour are usually called in quickly.
  shortWait,

  /// The patient often books (and attends) around this time.
  yourUsualTime,

  /// A commonly booked time at the clinic.
  popularTime,

  /// The soonest open time — the fallback when there is little history.
  earliest,
}

class SlotRecommendation {
  const SlotRecommendation({
    required this.slot,
    required this.score,
    required this.reasons,
    this.avgWaitMinutes,
  });

  final OpenSlot slot;

  /// 0–1; higher suits the patient better. Only meaningful for ordering.
  final double score;

  /// Strongest first; never empty.
  final List<SlotReason> reasons;

  /// Typical wait at this hour, when history knows it.
  final int? avgWaitMinutes;
}

/// Ranks [slots] and returns the best [limit]. Falls back to the earliest
/// slots when there is too little history to say anything.
List<SlotRecommendation> recommendSlots({
  required List<OpenSlot> slots,
  required List<SlotDemandStat> staffStats,
  required List<SlotDemandStat> clinicStats,
  required List<Appointment> patientHistory,
  required DateTime now,
  int limit = 3,
}) {
  if (slots.isEmpty) return const [];
  final byTime = [...slots]..sort((a, b) => a.start.compareTo(b.start));

  Map<(int, int), SlotDemandStat> index(List<SlotDemandStat> stats) => {
    for (final s in stats) (s.weekday, s.hour): s,
  };
  final staff = index(staffStats);
  final clinic = index(clinicStats);
  final busiest = [
    ...staffStats,
    ...clinicStats,
  ].fold<int>(0, (m, s) => s.booked > m ? s.booked : m);

  // Hours this patient has actually turned up at.
  final attendedHours = [
    for (final a in patientHistory)
      if (a.status == AppointmentStatus.completed) a.slotStart.hour,
  ];

  final scored = <SlotRecommendation>[];
  for (final slot in byTime) {
    final cell =
        staff[(slot.start.weekday, slot.start.hour)] ??
        clinic[(slot.start.weekday, slot.start.hour)];

    // Each signal is 0–1 with a weight; missing signals drop out.
    final parts = <(SlotReason, double, double)>[];
    final attendance = cell?.attendanceRate;
    if (attendance != null) {
      parts.add((SlotReason.reliableHour, attendance, 0.35));
    }
    final wait = cell?.avgWaitMinutes;
    if (wait != null) {
      parts.add((SlotReason.shortWait, 1 - (wait.clamp(0, 60) / 60), 0.2));
    }
    if (attendedHours.length >= 2) {
      final near = attendedHours
          .where((h) => (h - slot.start.hour).abs() <= 1)
          .length;
      parts.add((SlotReason.yourUsualTime, near / attendedHours.length, 0.25));
    }
    if (cell != null && busiest > 0) {
      parts.add((SlotReason.popularTime, cell.booked / busiest, 0.1));
    }
    final leadDays = slot.start.difference(now).inHours / 24;
    parts.add((SlotReason.earliest, 1 - (leadDays.clamp(0, 14) / 14), 0.1));

    final weight = parts.fold<double>(0, (t, p) => t + p.$3);
    final score = parts.fold<double>(0, (t, p) => t + p.$2 * p.$3) / weight;

    // Name only the signals that are genuinely good for this slot.
    final good =
        parts
            .where(
              (p) => p.$1 != SlotReason.earliest && p.$2 >= _goodEnough[p.$1]!,
            )
            .toList()
          ..sort((a, b) => (b.$2 * b.$3).compareTo(a.$2 * a.$3));
    scored.add(
      SlotRecommendation(
        slot: slot,
        score: score,
        reasons: good.isEmpty
            ? const [SlotReason.earliest]
            : [for (final p in good.take(2)) p.$1],
        avgWaitMinutes: wait?.round(),
      ),
    );
  }

  // Nothing learned from history: plain earliest-first.
  final informed = scored.any((r) => r.reasons.first != SlotReason.earliest);
  if (!informed) return scored.take(limit).toList();

  scored.sort((a, b) {
    final c = b.score.compareTo(a.score);
    return c != 0 ? c : a.slot.start.compareTo(b.slot.start);
  });
  return scored.take(limit).toList();
}

/// The level at which a signal is worth telling the patient about.
const _goodEnough = <SlotReason, double>{
  SlotReason.reliableHour: 0.85,
  SlotReason.shortWait: 0.75, // ≤ 15 min
  SlotReason.yourUsualTime: 0.5,
  SlotReason.popularTime: 0.7,
};
