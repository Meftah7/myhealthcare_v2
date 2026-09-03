/// Reusable account menu for an authenticated screen's `AppBar.actions`
/// (P2-06, P8-07).
///
/// Shows "Profile" (when [profileRoute] is given) and "Sign out". Sign out
/// confirms first, then clears the session — the router redirect takes the
/// user back to /login.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../application/session.dart';

class SignOutAction extends ConsumerWidget {
  const SignOutAction({this.profileRoute, super.key});

  /// Route to push when "Profile" is selected. Omit to hide that entry.
  final String? profileRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    return PopupMenuButton<String>(
      tooltip: t.account,
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (v) async {
        if (v == 'profile') {
          final route = profileRoute;
          if (route != null) unawaited(context.push(route));
          return;
        }
        if (v != 'logout') return;
        final ok = await confirm(
          context,
          title: t.signOutConfirmTitle,
          message: t.signOutConfirmBody,
          confirmLabel: t.signOut,
        );
        if (ok) {
          unawaited(ref.read(sessionProvider.notifier).logout());
        }
      },
      itemBuilder: (context) => [
        if (profileRoute != null)
          PopupMenuItem(value: 'profile', child: Text(t.profile)),
        PopupMenuItem(value: 'logout', child: Text(t.signOut)),
      ],
    );
  }
}
