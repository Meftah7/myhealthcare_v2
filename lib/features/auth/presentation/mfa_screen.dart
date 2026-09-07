/// The verification-code step shown after sign-in / registration when
/// [kRequireMfaAtSignIn] is on. Ported from `MFA.html` — same 6-digit field,
/// same demo code, a resend affordance, and it clears the session's MFA
/// challenge on success so the router lands the user on their dashboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_card.dart';
import '../application/session.dart';

class MfaScreen extends ConsumerStatefulWidget {
  const MfaScreen({super.key});

  @override
  ConsumerState<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends ConsumerState<MfaScreen> {
  // Pre-filled with the demo code (matches `MFA.html`'s value="111111") so a
  // tap on Verify always clears it while the app is in demo / testing mode.
  final _code = TextEditingController(text: kDemoMfaCode);
  String? _error;
  bool _resent = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    if (_code.text.trim() == kDemoMfaCode) {
      ref.read(sessionProvider.notifier).passMfa();
      // The router redirect takes the user to their dashboard.
      return;
    }
    setState(() => _error = 'That code is not right. Try again.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = ref.watch(currentUserProvider)?.fullName.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify it’s you'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: Space.md),
                Text(
                  name == null
                      ? 'Enter your 6-digit code'
                      : 'Almost there, $name',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  'We sent a 6-digit verification code to your device.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.lg),
                TextField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 8,
                    fontFeatures: kTabularFigures,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                  ),
                  onChanged: (v) {
                    if (_error != null) setState(() => _error = null);
                    if (v.length == 6) _verify();
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: Space.sm),
                  InlineBanner.error(_error!),
                ],
                const SizedBox(height: Space.md),
                FilledButton(
                  onPressed: _verify,
                  child: const Text('Verify'),
                ),
                const SizedBox(height: Space.xs),
                TextButton(
                  onPressed: () => setState(() => _resent = true),
                  child: Text(_resent ? 'Code re-sent' : 'Resend code'),
                ),
                const SizedBox(height: Space.md),
                Container(
                  padding: const EdgeInsets.all(Space.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: Radii.cardSmall,
                  ),
                  child: Text(
                    'Demo build — the verification code is $kDemoMfaCode.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
