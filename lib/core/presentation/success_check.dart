/// A momentary checkmark success animation (redesign v2 patient dashboard:
/// confirms a booked appointment).
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// Shows a scale-in checkmark over a dimmed barrier for [duration], then
/// dismisses itself automatically.
Future<void> showSuccessCheck(
  BuildContext context, {
  String message = 'Booked',
  Duration duration = const Duration(milliseconds: 1100),
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black26,
    transitionDuration: Motion.medium,
    pageBuilder: (context, _, _) =>
        _SuccessCheckDialog(message: message, holdFor: duration),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Motion.standard),
      child: child,
    ),
  );
}

class _SuccessCheckDialog extends StatefulWidget {
  const _SuccessCheckDialog({required this.message, required this.holdFor});

  final String message;
  final Duration holdFor;

  @override
  State<_SuccessCheckDialog> createState() => _SuccessCheckDialogState();
}

class _SuccessCheckDialogState extends State<_SuccessCheckDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.slow,
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.holdFor, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduce = Motion.reduced(context);
    final scale = reduce
        ? const AlwaysStoppedAnimation<double>(1)
        : CurvedAnimation(parent: _controller, curve: Motion.emphasized);

    return Center(
      child: Material(
        color: scheme.surface,
        borderRadius: Radii.card,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
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
              Text(widget.message, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
