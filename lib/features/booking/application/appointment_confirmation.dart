/// App-level "appointment confirmed" signal. Set on a successful booking so the
/// checkmark animation (`AppointmentConfirmationOverlay`) can play *over* the
/// navigation from the booking screen to Home.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppointmentConfirmation {
  const AppointmentConfirmation({required this.message, required this.nonce});

  final String message;

  /// Bumped on every [AppointmentConfirmationController.show] so booking twice
  /// in a row re-triggers the animation even with the same message.
  final int nonce;
}

class AppointmentConfirmationController
    extends Notifier<AppointmentConfirmation?> {
  @override
  AppointmentConfirmation? build() => null;

  void show(String message) {
    state = AppointmentConfirmation(
      message: message,
      nonce: (state?.nonce ?? 0) + 1,
    );
  }

  void clear() => state = null;
}

final appointmentConfirmationProvider =
    NotifierProvider<AppointmentConfirmationController, AppointmentConfirmation?>(
      AppointmentConfirmationController.new,
    );
