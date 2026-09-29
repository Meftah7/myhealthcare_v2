/// How a password-recovery code reaches the account holder.
///
/// Recovery is only as strong as this channel: the code proves the requester
/// controls the email/phone already on the account. This app has no email or
/// SMS provider yet, so:
///
/// * demo builds use [DemoRecoveryOutbox], a clearly labelled simulated inbox
///   shown on the recovery screen, standing in for the account's email;
/// * production builds use [UnavailableRecoveryDelivery] until a real
///   provider is wired in, and recovery falls back to a request an
///   administrator verifies in person.
library;

import 'package:flutter/foundation.dart';

import '../../domain/entities/user.dart';

/// One delivered code, as the recipient would see it.
@immutable
class RecoveryMessage {
  const RecoveryMessage({
    required this.recipientAccountId,
    required this.sentTo,
    required this.code,
    required this.expiresAt,
    required this.sentAt,
  });

  final String recipientAccountId;

  /// Masked address the code was sent to.
  final String sentTo;
  final String code;
  final DateTime expiresAt;
  final DateTime sentAt;
}

abstract interface class RecoveryDelivery {
  /// False when no channel exists — callers fall back to the administrator-
  /// verified request.
  bool get isAvailable;

  Future<void> send({
    required User account,
    required String sentTo,
    required String code,
    required DateTime expiresAt,
  });
}

class UnavailableRecoveryDelivery implements RecoveryDelivery {
  const UnavailableRecoveryDelivery();

  @override
  bool get isAvailable => false;

  @override
  Future<void> send({
    required User account,
    required String sentTo,
    required String code,
    required DateTime expiresAt,
  }) async {
    throw StateError('No recovery delivery channel is configured.');
  }
}

/// Simulated inbox for demo builds. Holds only the most recent few messages,
/// in memory, and is cleared whenever a code is used.
class DemoRecoveryOutbox extends ChangeNotifier implements RecoveryDelivery {
  static const _keep = 5;
  final List<RecoveryMessage> _messages = [];

  List<RecoveryMessage> get messages => List.unmodifiable(_messages);

  @override
  bool get isAvailable => true;

  @override
  Future<void> send({
    required User account,
    required String sentTo,
    required String code,
    required DateTime expiresAt,
  }) async {
    _messages.insert(
      0,
      RecoveryMessage(
        recipientAccountId: account.id,
        sentTo: sentTo,
        code: code,
        expiresAt: expiresAt,
        sentAt: DateTime.now(),
      ),
    );
    if (_messages.length > _keep) _messages.removeLast();
    notifyListeners();
  }

  /// Drop every message for [accountId] (after its code is used, or on
  /// sign-out on a shared device).
  void clearFor(String accountId) {
    _messages.removeWhere((m) => m.recipientAccountId == accountId);
    notifyListeners();
  }

  void clear() {
    if (_messages.isEmpty) return;
    _messages.clear();
    notifyListeners();
  }
}
