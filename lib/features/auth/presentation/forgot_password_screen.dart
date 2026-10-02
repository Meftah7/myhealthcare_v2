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
import 'auth_scaffold.dart';

enum _Step { identify, verify, password, queued, done }

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
          _step = _Step.verify;
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
    switch (_step) {
      case _Step.identify:
        return AuthScaffold(
          title: t.forgotPasswordQuestion,
          subtitle: t.forgotPasswordBody,
          onBack: () => context.go(AppRoutes.login),
          child: _identifyForm(t),
        );
      case _Step.verify:
        return AuthScaffold(
          title: t.recoveryCodeSentTitle,
          subtitle: t.recoveryCodeSentBody,
          onBack: () => context.go(AppRoutes.login),
          child: _verifyForm(t),
        );
      case _Step.password:
        return AuthScaffold(
          title: t.newPasswordLabel,
          onBack: () => setState(() {
            _step = _Step.verify;
            _error = null;
          }),
          child: _verifyForm(t),
        );
      case _Step.queued:
      case _Step.done:
        break;
    }
    return AuthScaffold(
      title: _step == _Step.done
          ? t.recoveryDoneTitle
          : t.passwordResetRequestedTitle,
      child: switch (_step) {
        _Step.identify ||
        _Step.verify ||
        _Step.password => const SizedBox.shrink(),
        _Step.queued => _Outcome(
          icon: Icons.mark_email_read_outlined,
          body: t.passwordResetRequestedBody,
          onDone: () => context.go(AppRoutes.login),
        ),
        _Step.done => _Outcome(
          icon: Icons.verified_user_outlined,
          body: t.recoveryDoneBody,
          onDone: () => context.go(AppRoutes.login),
        ),
      },
    );
  }

  Widget _identifyForm(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
    final outbox = ref.watch(recoveryDeliveryProvider);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_step == _Step.verify && outbox is DemoRecoveryOutbox)
            _DemoInbox(outbox: outbox),
          const SizedBox(height: Space.lg),
          if (_step == _Step.verify)
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
          if (_step == _Step.password) ...[
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
          ],
          if (_error != null) ...[
            const SizedBox(height: Space.md),
            InlineBanner.error(_error!),
          ],
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: _busy
                ? null
                : _step == _Step.password
                ? _reset
                : () {
                    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
                      setState(() => _error = t.recoveryCodeRequired);
                      return;
                    }
                    setState(() {
                      _step = _Step.password;
                      _error = null;
                    });
                  },
            child: _busy
                ? const _Spinner()
                : Text(
                    _step == _Step.password
                        ? t.recoveryResetButton
                        : t.continueButton,
                  ),
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
    required this.body,
    required this.onDone,
  });

  final IconData icon;
  final String body;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: Space.md),
        const SizedBox(height: Space.xs),
        Text(
          body,
          textAlign: TextAlign.center,
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
