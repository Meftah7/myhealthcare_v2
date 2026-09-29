/// Care-services entities (P10 Batch B): sick-leave certificate, care message,
/// home-visit request.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'care.freezed.dart';

@freezed
abstract class SickLeaveCertificate with _$SickLeaveCertificate {
  const factory SickLeaveCertificate({
    required String id,
    required String patientId,
    required String issuedByStaffId,
    required String diagnosis,
    required DateTime fromDate,
    required DateTime toDate,
    required DateTime issuedAt,
    String? appointmentId,
    String? notes,
  }) = _SickLeaveCertificate;

  const SickLeaveCertificate._();

  /// Inclusive day count — a note from Mon to Mon is one day, Mon to Tue two.
  int get days => toDate.difference(fromDate).inDays + 1;

  bool get isActive {
    final now = DateTime.now();
    return !now.isBefore(fromDate) &&
        !now.isAfter(toDate.add(const Duration(days: 1)));
  }
}

@freezed
abstract class CareMessage with _$CareMessage {
  const factory CareMessage({
    required String id,
    required String patientId,
    required String staffId,
    required bool fromStaff,
    required String body,
    required DateTime sentAt,
    DateTime? readAt,

    /// Who must answer a patient's message (the thread's clinician), and who
    /// covers it while they are off duty. Null on staff replies.
    String? queueOwnerStaffId,
    String? coverageStaffId,

    /// When a reply is due ([CareMessageQueue.responseWindow] after it was
    /// sent). Null on staff replies.
    DateTime? responseDueAt,
  }) = _CareMessage;

  const CareMessage._();

  bool get isRead => readAt != null;

  bool isOverdueAt(DateTime now) {
    final due = responseDueAt;
    return !fromStaff && due != null && due.isBefore(now);
  }
}

/// The clinic's messaging promise (Phase 4). Shown to patients as-is, so it
/// must stay honest: a reply within one working day, never an emergency
/// channel.
abstract final class CareMessageQueue {
  static const responseWindow = Duration(hours: 24);
}

/// A patient <-> doctor thread: the latest message plus unread counts. Built
/// in the repository from [CareMessage] rows, never stored.
@freezed
abstract class CareThread with _$CareThread {
  const factory CareThread({
    required String patientId,
    required String staffId,
    required String counterpartName,
    required CareMessage lastMessage,
    required int unreadForPatient,
    required int unreadForStaff,
  }) = _CareThread;
}

@freezed
abstract class HomeVisitRequest with _$HomeVisitRequest {
  const factory HomeVisitRequest({
    required String id,
    required String patientId,
    required String addressText,
    required DateTime preferredDate,
    required String reasonText,
    required HomeVisitStatus status,
    required DateTime createdAt,
    String? departmentId,
    String? assignedStaffId,
    String? decisionNote,
    DateTime? decidedAt,
    @Default(1) int version,
  }) = _HomeVisitRequest;

  const HomeVisitRequest._();

  /// Still needs a decision or is on the books.
  bool get isOpen =>
      status == HomeVisitStatus.requested ||
      status == HomeVisitStatus.scheduled;
}
