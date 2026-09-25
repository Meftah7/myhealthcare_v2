/// One recurring weekly working block for a staff member — the source
/// `openSlots` generates bookable appointment times from.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_template.freezed.dart';

@freezed
abstract class ScheduleTemplate with _$ScheduleTemplate {
  const factory ScheduleTemplate({
    required String id,
    required String staffId,

    /// 1 = Monday … 7 = Sunday (`DateTime.weekday`).
    required int weekday,

    /// Minutes from midnight, local clinic time.
    required int startMinutes,
    required int endMinutes,
    required int slotMinutes,
  }) = _ScheduleTemplate;
}

/// A block to save — no id yet, the repository generates one.
class NewScheduleTemplate {
  const NewScheduleTemplate({
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    this.slotMinutes = 20,
  });

  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final int slotMinutes;
}
