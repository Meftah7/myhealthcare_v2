/// Sign-in screen (P2-02, redesign v2).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../data/seed/seeder.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) {
      if (_email.text.trim().isEmpty) {
        _emailFocus.requestFocus();
      } else if (_password.text.isEmpty) {
        _passwordFocus.requestFocus();
      }
      return;
    }
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
      setState(
        () => _error = describeFailure(
          AppLocalizations.of(context)!,
          failure,
        ).message,
      );
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
    final canResume = ref.watch(
      sessionProvider.select((s) => s.resumeLocation != null),
    );

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      canResume
                          ? '${t.sessionEndedNotice} ${t.sessionResumeHint}'
                          : t.sessionEndedNotice,
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
            focusNode: _emailFocus,
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
            focusNode: _passwordFocus,
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
          OutlinedButton(
            onPressed: _busy ? null : () => context.push(AppRoutes.register),
            child: Text(t.createPatientAccount),
          ),
          // Demo credentials belong to the explicit demo runtime only.
          if (ref.watch(appModeProvider).isDemo) ...[
            const SizedBox(height: Space.lg),
            _DemoQuickActions(
              enabled: !_busy,
              onSelect: (email) {
                _email.text = email;
                _password.text = Seeder.demoPassword;
                unawaited(_submit());
              },
            ),
          ],
        ],
      ),
    );

    return AuthScaffold(
      title: t.signInTitle,
      subtitle: t.signInSubtitle,
      child: AutofillGroup(child: form),
    );
  }
}

class _DemoQuickActions extends StatelessWidget {
  const _DemoQuickActions({required this.enabled, required this.onSelect});

  final bool enabled;
  final void Function(String email) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = AppLocalizations.of(context)!;
    final accounts = [
      (t.demoPatient, Icons.person_outline, 'patient1@myhealth.demo'),
      (t.demoStaff, Icons.medical_services_outlined, 'staff1@myhealth.demo'),
      (t.demoAdmin, Icons.admin_panel_settings_outlined, 'admin@myhealth.demo'),
    ];
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: Radii.cardSmall,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Text(t.demoAccounts, style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            t.demoQuickSignInHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final tiles = [
                for (final (label, icon, email) in accounts)
                  _DemoAccountTile(
                    label: label,
                    icon: icon,
                    onTap: enabled ? () => onSelect(email) : null,
                  ),
              ];
              // Three across needs ~96dp per tile at the current text size;
              // otherwise (narrow phone, large text) stack them full width.
              final scale = MediaQuery.textScalerOf(context).scale(1);
              if (constraints.maxWidth / 3 < 96 * scale) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, tile) in tiles.indexed) ...[
                      if (i > 0) const SizedBox(height: Space.xs),
                      tile,
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (final (i, tile) in tiles.indexed) ...[
                    if (i > 0) const SizedBox(width: Space.xs),
                    Expanded(child: tile),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: Space.sm),
          Text(
            t.demoPasswordNote(Seeder.demoPassword),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoAccountTile extends StatelessWidget {
  const _DemoAccountTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.cardSmall,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Space.sm,
              horizontal: Space.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(height: Space.xxs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
