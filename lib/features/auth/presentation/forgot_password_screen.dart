/// Forgot password: verified, single-use recovery.
///
/// 1. The requester enters an email or national ID. A 6-digit code goes to
///    the email already on the account — the screen says the same thing
///    whether or not the identifier matched, so it can't be used to discover
///    accounts.
/// 2. They enter the code and a new password. The code works once, expires
///    after 10 minutes, and is burnt after 5 wrong guesses.
///
/// Where no delivery channel exists (a production build with no email
/// provider configured) step 1 instead queues a request for an administrator
/// to verify the person, and no password can be set from this screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth/recovery_delivery.dart';
import 'auth_app_bar_actions.dart';

enum _Step { identify, verify, queued, done }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifier = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  _Step _step = _Step.identify;
  RecoveryChallenge? _challenge;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final t = AppLocalizations.of(context)!;
    final id = _identifier.text.trim();
    if (id.isEmpty) {
      setState(() => _error = t.enterEmailOrNationalId);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(authRepositoryProvider).startRecovery(id);
    if (!mounted) return;
    switch (result) {
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = describeFailure(
            AppLocalizations.of(context)!,
            failure,
          ).message;
        });
      case Ok(:final value):
        setState(() {
          _busy = false;
          _challenge = value;
          _code.clear();
          _step = value.selfService ? _Step.verify : _Step.queued;
        });
    }
  }

  Future<void> _reset() async {
    final t = AppLocalizations.of(context)!;
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = t.recoveryCodeRequired);
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = t.passwordsDoNotMatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .completeRecovery(
          challengeId: _challenge!.challengeId,
          code: code,
          newPassword: _password.text,
        );
    if (!mounted) return;
    switch (result) {
      case Err(:final failure):
        // Keep what they typed; only the code is likely wrong.
        setState(() {
          _busy = false;
          _error = describeFailure(
            AppLocalizations.of(context)!,
            failure,
          ).message;
        });
      case Ok():
        _password.clear();
        _confirm.clear();
        setState(() {
          _busy = false;
          _step = _Step.done;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.resetPasswordTitle),
        actions: authAppBarActions,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: switch (_step) {
              _Step.identify => _identifyForm(t),
              _Step.verify => _verifyForm(t),
              _Step.queued => _Outcome(
                icon: Icons.mark_email_read_outlined,
                title: t.passwordResetRequestedTitle,
                body: t.passwordResetRequestedBody,
                onDone: () => context.go(AppRoutes.login),
              ),
              _Step.done => _Outcome(
                icon: Icons.verified_user_outlined,
                title: t.recoveryDoneTitle,
                body: t.recoveryDoneBody,
                onDone: () => context.go(AppRoutes.login),
              ),
            },
          ),
        ),
      ),
    );
  }

  Widget _identifyForm(AppLocalizations t) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.forgotPasswordQuestion, style: theme.textTheme.headlineSmall),
        const SizedBox(height: Space.xxs),
        Text(
          t.forgotPasswordBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Space.lg),
        TextField(
          controller: _identifier,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _requestCode(),
          decoration: InputDecoration(
            labelText: t.emailOrNationalIdLabel,
            prefixIcon: const Icon(Icons.person_search_outlined),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: Space.md),
          InlineBanner.error(_error!),
        ],
        const SizedBox(height: Space.lg),
        FilledButton(
          onPressed: _busy ? null : _requestCode,
          child: _busy ? const _Spinner() : Text(t.continueButton),
        ),
        const SizedBox(height: Space.xs),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: Text(t.backToSignIn),
        ),
      ],
    );
  }

  Widget _verifyForm(AppLocalizations t) {
    final theme = Theme.of(context);
    final outbox = ref.watch(recoveryDeliveryProvider);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.recoveryCodeSentTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Space.xxs),
          Text(
            t.recoveryCodeSentBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (outbox is DemoRecoveryOutbox) ...[
            const SizedBox(height: Space.md),
            _DemoInbox(outbox: outbox),
          ],
          const SizedBox(height: Space.lg),
          TextField(
            key: const ValueKey('recovery-code'),
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: InputDecoration(
              labelText: t.recoveryCodeLabel,
              prefixIcon: const Icon(Icons.pin_outlined),
              counterText: '',
            ),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            key: const ValueKey('recovery-password'),
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: t.newPasswordLabel,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: Space.sm),
          TextField(
            key: const ValueKey('recovery-confirm'),
            controller: _confirm,
            obscureText: true,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _reset(),
            decoration: InputDecoration(
              labelText: t.recoveryConfirmPasswordLabel,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: Space.md),
            InlineBanner.error(_error!),
          ],
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: _busy ? null : _reset,
            child: _busy ? const _Spinner() : Text(t.recoveryResetButton),
          ),
          const SizedBox(height: Space.xs),
          TextButton(
            onPressed: _busy ? null : _requestCode,
            child: Text(t.recoveryResendButton),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: Text(t.backToSignIn),
          ),
        ],
      ),
    );
  }
}

/// The simulated inbox a demo build shows in place of real email. Labelled
/// as simulated so nobody mistakes it for how production recovery works.
class _DemoInbox extends StatelessWidget {
  const _DemoInbox({required this.outbox});

  final DemoRecoveryOutbox outbox;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: outbox,
      builder: (context, _) {
        final latest = outbox.messages.firstOrNull;
        return Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: Text(
                      t.recoveryDemoInboxTitle,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xxs),
              Text(
                t.recoveryDemoInboxBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (latest != null) ...[
                const SizedBox(height: Space.xs),
                SelectableText(
                  t.recoveryDemoCodeFor(latest.sentTo, latest.code),
                  key: const ValueKey('demo-recovery-code'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.icon,
    required this.title,
    required this.body,
    required this.onDone,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 40, color: theme.colorScheme.primary),
        const SizedBox(height: Space.md),
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: Space.xs),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Space.lg),
        FilledButton(onPressed: onDone, child: Text(t.backToSignIn)),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
