/// How a lab value is judged against its reference range (Phase 4).
///
/// These are *demonstration* rules for synthetic data. They are named and
/// versioned here — not scattered through the UI — so a qualified clinical
/// owner can replace them in one place before any care use. No value is ever
/// judged against a range that was not supplied: a missing range yields
/// [AbnormalFlag.unknown], never "normal".
library;

import '../enums.dart';

abstract final class LabRules {
  /// Recorded with each classification so a result shows which rules judged
  /// it.
  static const version = 'demo-lab-rules-v1';

  /// Without explicit critical limits, a value below `refLow × 0.75` or above
  /// `refHigh × 1.5` is treated as critical. A heuristic, not a clinical
  /// standard; explicit limits always win.
  static const criticalLowFactor = 0.75;
  static const criticalHighFactor = 1.5;

  static AbnormalFlag classify(
    double value, {
    double? refLow,
    double? refHigh,
    double? criticalLow,
    double? criticalHigh,
  }) {
    if (refLow == null && refHigh == null) return AbnormalFlag.unknown;
    if (refLow != null && value < refLow) {
      final limit = criticalLow ?? refLow * criticalLowFactor;
      return value < limit ? AbnormalFlag.critical : AbnormalFlag.low;
    }
    if (refHigh != null && value > refHigh) {
      final limit = criticalHigh ?? refHigh * criticalHighFactor;
      return value > limit ? AbnormalFlag.critical : AbnormalFlag.high;
    }
    return AbnormalFlag.normal;
  }

  /// How urgently a clinician must review a result with [flags].
  static WorkPriority priorityFor(Iterable<AbnormalFlag> flags) {
    if (flags.contains(AbnormalFlag.critical)) return WorkPriority.urgent;
    if (flags.any((f) => f == AbnormalFlag.low || f == AbnormalFlag.high)) {
      return WorkPriority.priority;
    }
    return WorkPriority.routine;
  }

  /// When a review at [priority] falls due.
  static Duration reviewWindow(WorkPriority priority) => switch (priority) {
    WorkPriority.urgent => const Duration(hours: 1),
    WorkPriority.priority => const Duration(hours: 24),
    WorkPriority.routine => const Duration(hours: 72),
  };

  /// Does a result with this flag need a clinician to look at it?
  static bool needsReview(AbnormalFlag flag) => flag != AbnormalFlag.normal;
}
