/// Forgot password: queue a request for an authenticated admin to verify the
/// person and issue a new password. There is no email/SMS delivery in this
/// app, so a self-service "click a link, set a new password" flow can't
/// actually prove the requester owns the account — it would let anyone who
/// knows (or guesses) an email or national ID take the account over. This
/// screen always shows the same confirmation, whether or not the identifier
/// matches an account, so it can't be used to test which emails/national IDs
/// exist either.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_app_bar_actions.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifier = TextEditingController();
  bool _busy = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
    // This always succeeds from the caller's point of view — see the class
    // doc. There is deliberately nothing to switch on here.
    await ref.read(authRepositoryProvider).requestPasswordReset(id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
            child: _submitted
                ? _Confirmation(onDone: () => context.go(AppRoutes.login))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t.forgotPasswordQuestion,
                        style: theme.textTheme.headlineSmall,
                      ),
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
                        onSubmitted: (_) => _submit(),
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
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(t.continueButton),
                      ),
                      const SizedBox(height: Space.xs),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: Text(t.backToSignIn),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 40,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: Space.md),
        Text(
          t.passwordResetRequestedTitle,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: Space.xs),
        Text(
          t.passwordResetRequestedBody,
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
