/// A full-screen checkmark that confirms a booked appointment. Unlike a dialog,
/// this lives *above* the router (mounted from `MaterialApp.router`'s `builder`),
/// so it stays on screen while the app navigates from the booking flow to Home
/// underneath it, then fades itself out.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../features/booking/application/appointment_confirmation.dart';

class AppointmentConfirmationOverlay extends ConsumerStatefulWidget {
  const AppointmentConfirmationOverlay({super.key});

  @override
  ConsumerState<AppointmentConfirmationOverlay> createState() =>
      _AppointmentConfirmationOverlayState();
}

class _AppointmentConfirmationOverlayState
    extends ConsumerState<AppointmentConfirmationOverlay>
    with SingleTickerProviderStateMixin {
  static const _hold = Duration(milliseconds: 900);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.slow,
    reverseDuration: Motion.medium,
  );

  int? _shownNonce;
  String _message = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _play(AppointmentConfirmation confirmation) async {
    setState(() => _message = confirmation.message);
    final reduce = Motion.reduced(context);
    if (reduce) {
      _controller.value = 1;
    } else {
      await _controller.forward(from: 0);
    }
    await Future<void>.delayed(_hold);
    if (!mounted) return;
    if (reduce) {
      _controller.value = 0;
    } else {
      await _controller.reverse();
    }
    if (!mounted) return;
    ref.read(appointmentConfirmationProvider.notifier).clear();
    _shownNonce = null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appointmentConfirmationProvider, (_, next) {
      if (next != null && next.nonce != _shownNonce) {
        _shownNonce = next.nonce;
        unawaited(_play(next));
      }
    });

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          if (t == 0) return const SizedBox.shrink();
          final theme = Theme.of(context);
          final reduce = Motion.reduced(context);
          final scale = reduce
              ? 1.0
              : Curves.easeOutBack.transform(t.clamp(0.0, 1.0));

          return Opacity(
            opacity: t,
            child: Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: Material(
                color: theme.colorScheme.surface,
                borderRadius: Radii.card,
                child: Padding(
                  padding: const EdgeInsets.all(Space.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: theme.clinicalStatus.riskLow.container,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 36,
                            color: theme.clinicalStatus.riskLow.onContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      Text(_message, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
