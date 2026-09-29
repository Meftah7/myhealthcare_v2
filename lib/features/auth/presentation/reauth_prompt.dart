/// Step-up re-authentication for sensitive actions.
///
/// Repositories refuse account-changing actions with [ReauthRequiredFailure]
/// when the password hasn't been proven recently (`kReauthWindow`).
/// [runWithReauth] catches that, asks for the password, and retries once.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/failures.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session.dart';

Future<Result<T>> runWithReauth<T>(
  BuildContext context,
  WidgetRef ref,
  Future<Result<T>> Function() action,
) async {
  final first = await action();
  if (first case Err(failure: ReauthRequiredFailure())) {
    if (!context.mounted) return first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ReauthDialog(),
    );
    if (confirmed != true) return first;
    return action();
  }
  return first;
}

class _ReauthDialog extends ConsumerStatefulWidget {
  const _ReauthDialog();

  @override
  ConsumerState<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends ConsumerState<_ReauthDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(sessionProvider.notifier)
        .reauthenticate(_password.text);
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop(true);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = describeFailure(
            AppLocalizations.of(context)!,
            failure,
          ).message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.reauthTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.reauthBody),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _busy ? null : _confirm(),
            decoration: InputDecoration(
              labelText: t.password,
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _confirm,
          child: Text(t.confirm),
        ),
      ],
    );
  }
}
