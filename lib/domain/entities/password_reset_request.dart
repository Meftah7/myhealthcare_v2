/// A patient's request to reset a forgotten password (see
/// `PasswordResetRequests` for why this is a queued admin action rather than
/// a self-service email/SMS link).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_reset_request.freezed.dart';

@freezed
abstract class PasswordResetRequest with _$PasswordResetRequest {
  const factory PasswordResetRequest({
    required String id,
    required String userId,
    required String identifierEntered,
    required DateTime requestedAt,
    required bool resolved,
    String? resolvedByStaffId,
    DateTime? resolvedAt,
  }) = _PasswordResetRequest;
}
