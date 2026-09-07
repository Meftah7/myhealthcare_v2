/// Forgot-password — step 1: identify the account by email or national ID,
/// then continue to the reset screen. Ported from `forgot_password.html`
/// (which is a client-only demo flow; this one at least verifies the account
/// exists before letting you set a new password).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/result.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifier = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final id = _identifier.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Enter your email or national ID.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .accountForIdentifier(id);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok(:final value):
        context.go('${AppRoutes.resetPassword}?user=${value.id}');
      case Err(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset your password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Forgot your password?',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  'Enter the email or national ID on your account and we’ll '
                  'take you to set a new password.',
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
                  onSubmitted: (_) => _continue(),
                  decoration: const InputDecoration(
                    labelText: 'Email or national ID',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: Space.md),
                  InlineBanner.error(_error!),
                ],
                const SizedBox(height: Space.lg),
                FilledButton(
                  onPressed: _busy ? null : _continue,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
                const SizedBox(height: Space.xs),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
