/// Sign-in screen (P2-02, redesign v2).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session.dart';
import 'auth_app_bar_actions.dart';

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
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;
    final endedByInactivity = ref.watch(
      sessionProvider.select((s) => s.endedByInactivity),
    );

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BrandLockup(subtitle: t.signInSubtitle),
          const SizedBox(height: Space.xl),
          if (endedByInactivity) ...[
            Container(
              padding: const EdgeInsets.all(Space.sm),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: Radii.cardSmall,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_off_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: Text(
                      t.sessionEndedNotice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
          ],
          TextFormField(
            controller: _email,
            autofillHints: const [AutofillHints.username],
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: t.email,
              helperText: t.emailOrNationalIdHelper,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? t.emailOrNationalIdRequired
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
              labelText: t.password,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: _obscure ? t.showPassword : t.hidePassword,
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? t.passwordRequired : null,
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => context.push(AppRoutes.forgotPassword),
              child: Text(t.forgotPassword),
            ),
          ),
          AnimatedSize(
            duration: Motion.medium,
            curve: Motion.standard,
            alignment: Alignment.topCenter,
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Space.md),
                    child: InlineBanner.error(_error!),
                  ),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.signInTitle),
          ),
          const SizedBox(height: Space.xs),
          TextButton(
            onPressed: _busy ? null : () => context.push(AppRoutes.register),
            child: Text(t.createPatientAccount),
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
    );

    final wide = WindowSize.of(context).usesRail;

    return Scaffold(
      // No title, no back button — a minimal language pill + theme icon,
      // floating over the tinted page. Unlike every other top bar's paired
      // circular buttons, this pair is sign-in-specific: a language pill
      // (globe + the language you'd switch to) beside a bare theme icon.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: authAppBarActions,
      ),
      // On a wide window the form becomes a floating card on the tinted page;
      // on a phone it is the page, so the card chrome would just be noise.
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AppEntrance(
              rise: 12,
              child: wide
                  ? Container(
                      padding: const EdgeInsets.all(Space.xl),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: Radii.card,
                        border: Border.all(color: scheme.outlineVariant),
                        boxShadow: Shadows.e2,
                      ),
                      child: form,
                    )
                  : form,
            ),
          ),
        ),
      ),
    );
  }
}

/// The gradient-medallion mark + wordmark. One of the sanctioned brand-gradient
/// surfaces (DESIGN.md §1) — and the only saturated thing on this screen, so it
/// gets the coloured bloom rather than a neutral shadow.
class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.subtitle});
  final String subtitle;

  static const double _markSize = 80;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: _markSize,
          height: _markSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: AppColors.brandGradient,
            boxShadow: Shadows.glow(AppColors.brandViolet),
          ),
          // The mark sits on ~16% padding inside its medallion, which is what
          // keeps the heart optically centred in the rounded square.
          padding: const EdgeInsets.all(_markSize * 0.16),
          child: const AppLogo(),
        ),
        const SizedBox(height: Space.lg),
        Text(
          'MyHealth Care',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: Space.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _DemoHint extends StatelessWidget {
  const _DemoHint({required this.onFill});

  final void Function(String email) onFill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: Radii.cardSmall,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.demoAccounts, style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final (label, email) in [
                (t.demoPatient, 'patient1@myhealth.demo'),
                (t.demoStaff, 'staff1@myhealth.demo'),
                (t.demoAdmin, 'admin@myhealth.demo'),
              ])
                ActionChip(
                  label: Text(label),
                  onPressed: () => onFill(email),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            t.demoPasswordNote('password'),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
