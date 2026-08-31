/// Sign-in screen (P2-02).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/result.dart';
import '../application/session.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(sessionProvider.notifier)
        .login(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Err(:final failure)) {
      setState(() => _error = failure.message);
    }
    // On success the router redirect takes over.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.add_circle,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    'MyHealth Care',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    'Sign in to your health record',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Space.xl),
                  TextFormField(
                    controller: _email,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: Space.md),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your password' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: Space.md),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.lg),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: Space.xs),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => context.push(AppRoutes.register),
                    child: const Text('Create a patient account'),
                  ),
                  const SizedBox(height: Space.lg),
                  _DemoHint(
                    onFill: (email) {
                      _email.text = email;
                      _password.text = 'password';
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Seeded-data helper so a demo doesn't need memorised credentials.
class _DemoHint extends StatelessWidget {
  const _DemoHint({required this.onFill});

  final void Function(String email) onFill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: Radii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demo accounts (password: password)',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            children: [
              for (final (label, email) in const [
                ('Patient', 'patient1@myhealth.demo'),
                ('Staff', 'staff1@myhealth.demo'),
                ('Admin', 'admin@myhealth.demo'),
              ])
                ActionChip(label: Text(label), onPressed: () => onFill(email)),
            ],
          ),
        ],
      ),
    );
  }
}
