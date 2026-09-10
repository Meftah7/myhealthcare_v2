/// A doctor's request, mid-consultation, for the admin to refer the patient
/// out. The doctor supplies only the reason; the admin decides where.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'referral_request.freezed.dart';

@freezed
abstract class ReferralRequest with _$ReferralRequest {
  const factory ReferralRequest({
    required String id,
    required String patientId,
    required String requestedByStaffId,
    required String reason,
    required ReferralRequestStatus status,
    required DateTime createdAt,
    String? appointmentId,
    String? decidedByAdminId,
    String? decisionNote,
    DateTime? decidedAt,
  }) = _ReferralRequest;

  const ReferralRequest._();

  bool get isPending => status == ReferralRequestStatus.pending;
}
