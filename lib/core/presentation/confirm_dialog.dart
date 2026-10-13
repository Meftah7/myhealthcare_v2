/// Confirmation dialog (P2-18). `SectionHeader` now lives in app_card.dart.
library;

import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';

/// Shows a yes/no dialog; returns true only if the user confirms.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final t = AppLocalizations.of(context)!;
      final theme = Theme.of(context);
      // Preserve the existing patient destructive action; staff/admin resolve
      // their semantic foreground/background pair from the active theme.
      final destructiveScheme = Radii.cardOf(context) == Radii.card
          ? theme.colorScheme
          : AppColors.patientLight;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel ?? t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: destructiveScheme.error,
                    foregroundColor: destructiveScheme.onError,
                  )
                : null,
            child: Text(confirmLabel ?? t.confirm),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
