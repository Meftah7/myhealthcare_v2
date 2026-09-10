/// Walk-in queue token — a patient sent to a department's desk without a
/// scheduled slot (created when the admin actions a department referral).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'walk_in_ticket.freezed.dart';

@freezed
abstract class WalkInTicket with _$WalkInTicket {
  const factory WalkInTicket({
    required String id,
    required String patientId,
    required String departmentId,
    required String ticketTag,
    required WalkInStatus status,
    required String createdByStaffId,
    required DateTime createdAt,
    String? reason,
    String? sourceAppointmentId,
    String? claimedByStaffId,
    String? resultAppointmentId,
    DateTime? resolvedAt,
  }) = _WalkInTicket;

  const WalkInTicket._();

  /// Still waiting to be seen.
  bool get isOpen =>
      status == WalkInStatus.waiting || status == WalkInStatus.called;
}
