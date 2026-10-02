/// Shared layout for the signed-out forms (Figma redesign, "auth" frames): a
/// pale-blue header panel carrying the brand mark, title and subtitle, with
/// the form on the page below it.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/presentation/app_scaffold.dart';
import 'auth_app_bar_actions.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Shows a back arrow in the header when non-null.
  final VoidCallback? onBack;

  static const double _maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Space.lg,
                        Space.lg,
                        Space.lg,
                        Space.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (onBack != null)
                                IconButton(
                                  onPressed: onBack,
                                  icon: const BackButtonIcon(),
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).backButtonTooltip,
                                ),
                              Expanded(
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  children: authAppBarActions,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Space.md),
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const AppLogo(),
                              ),
                              const SizedBox(width: Space.sm),
                              Expanded(
                                child: Text(
                                  'MyHealth Care',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Space.md),
                          Text(
                            title,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: Space.xxs),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    Space.lg,
                    Space.lg,
                    Space.xxl,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
