/// Root widget: `MaterialApp.router` with the DESIGN.md theme, go_router, and
/// the device UI preferences (theme mode + locale + text size) (tasks P0-05,
/// P0-06, P0-07, P8-07).
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/presentation/appointment_confirmation_overlay.dart';
import '../features/auth/presentation/session_activity_monitor.dart';
import '../features/auth/presentation/splash_overlay.dart';
import '../features/notifications/presentation/notification_sound_cue.dart';
import 'router.dart';
import 'settings/ui_prefs.dart';
import 'theme/theme.dart';

class MyHealthCareApp extends ConsumerWidget {
  const MyHealthCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MyHealth Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => _AppFrame(
        textScale: ref.watch(textScaleProvider).factor,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Wraps the routed content in the app-wide text-scale override plus the
/// session-idle monitor and the two full-screen overlays (booking confirmation
/// + the opening splash).
///
/// Split out so the overlays and the [child] subtree are not rebuilt when the
/// only thing that changed is a MediaQuery inset (a keyboard opening, say).
class _AppFrame extends StatelessWidget {
  const _AppFrame({required this.textScale, required this.child});

  final double textScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // `textScalerOf` subscribes to just that aspect of MediaQuery; the rest of
    // the data is read once here and passes straight through.
    final base = MediaQuery.textScalerOf(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: _ScaledTextScaler(base, textScale),
      ),
      child: NotificationSoundCue(
        child: SessionActivityMonitor(
          child: Stack(
            children: [
              child,
              const AppointmentConfirmationOverlay(),
              const SplashOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The device's own [TextScaler] multiplied by the in-app text-size preference
/// ([TextScaleLevel.factor]). At the default level the factor is 1.0, so the
/// platform setting passes through unchanged.
class _ScaledTextScaler extends TextScaler {
  const _ScaledTextScaler(this._base, this._factor);

  final TextScaler _base;
  final double _factor;

  @override
  double scale(double fontSize) => _base.scale(fontSize) * _factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => _base.textScaleFactor * _factor;

  @override
  bool operator ==(Object other) =>
      other is _ScaledTextScaler &&
      other._base == _base &&
      other._factor == _factor;

  @override
  int get hashCode => Object.hash(_base, _factor);
}
