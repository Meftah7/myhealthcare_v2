/// Per-device UI preferences: theme mode and language (P8-07).
///
/// These are *device* preferences, not clinical data — they live in
/// [SharedPreferences], never in the Drift `app_settings` row (which is shared
/// demo data and wiped on re-seed).
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/di.dart';

/// Locales the app is built to support. English is the source language;
/// Arabic is wired end to end (RTL + Material localisation) — full UI string
/// translation is tracked as future work (P8-07).
const supportedLocales = <Locale>[Locale('en'), Locale('ar')];

// --- theme mode ------------------------------------------------------------

const _themeModeKey = 'ui.themeMode';

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_themeModeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_themeModeKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

// --- locale --------------------------------------------------------------

const _localeKey = 'ui.locale';

/// The selected [Locale], or `null` to follow the device setting.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_localeKey);
    final locale = (raw == null || raw.isEmpty) ? null : Locale(raw);
    _syncIntlDefaultLocale(locale);
    return locale;
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    _syncIntlDefaultLocale(locale);
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }

  /// Keeps `Intl.defaultLocale` — which plain (non-widget) helpers like
  /// `core/utils/format.dart` read via `Intl.getCurrentLocale()` — matched to
  /// the app's language preference, including the "system" case (`null`),
  /// since those helpers have no `BuildContext` to resolve it from.
  void _syncIntlDefaultLocale(Locale? locale) {
    final languageCode =
        locale?.languageCode ??
        (PlatformDispatcher.instance.locale.languageCode == 'ar'
            ? 'ar'
            : 'en');
    intl.Intl.defaultLocale = languageCode;
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

// --- text size ----------------------------------------------------------

const _textScaleKey = 'ui.textScale';

/// The five in-app text sizes. [TextScaleLevel.medium] is the default and
/// leaves the platform's own text size untouched (multiplier 1.0); the other
/// four scale it down or up. Applied app-wide in `app.dart`.
enum TextScaleLevel {
  xSmall(0.85, 'Smaller'),
  small(0.92, 'Small'),
  medium(1, 'Default'),
  large(1.15, 'Large'),
  xLarge(1.3, 'Larger');

  const TextScaleLevel(this.factor, this.label);

  /// Multiplier applied on top of the device's own text-scale setting.
  final double factor;

  /// Short human label for the picker.
  final String label;
}

/// A per-device text-size preference, like [themeModeProvider]. Stored in
/// [SharedPreferences] by [TextScaleLevel.name].
class TextScaleController extends Notifier<TextScaleLevel> {
  @override
  TextScaleLevel build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_textScaleKey);
    return TextScaleLevel.values.firstWhere(
      (l) => l.name == raw,
      orElse: () => TextScaleLevel.medium,
    );
  }

  Future<void> set(TextScaleLevel level) async {
    state = level;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_textScaleKey, level.name);
  }
}

final textScaleProvider =
    NotifierProvider<TextScaleController, TextScaleLevel>(
      TextScaleController.new,
    );

// --- sound cues ---------------------------------------------------------

const _soundsKey = 'ui.sounds';

/// Whether the app plays its short cue sounds (a message arriving, a staff
/// member changing their working status). A device preference like the theme,
/// so it lives in [SharedPreferences].
class SoundsEnabledController extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(_soundsKey) ?? true;

  Future<void> set({required bool enabled}) async {
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(_soundsKey, enabled);
  }
}

final soundsEnabledProvider =
    NotifierProvider<SoundsEnabledController, bool>(
      SoundsEnabledController.new,
    );

// --- admin working status ---------------------------------------------

const _adminStatusKey = 'ui.adminStatus';

/// An administrator's self-set working status. Unlike a clinician's presence
/// (which colleagues and the directory see), an admin's is a personal signal
/// only — so it lives on the device in [SharedPreferences], never in the DB.
enum AdminStatus {
  available('Available'),
  meeting('In a meeting'),
  away('Away'),
  off('Off');

  const AdminStatus(this.label);

  final String label;
}

class AdminStatusController extends Notifier<AdminStatus> {
  @override
  AdminStatus build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_adminStatusKey);
    return AdminStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => AdminStatus.available,
    );
  }

  Future<void> set(AdminStatus status) async {
    state = status;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_adminStatusKey, status.name);
  }
}

final adminStatusProvider =
    NotifierProvider<AdminStatusController, AdminStatus>(
      AdminStatusController.new,
    );

// --- notification preferences (redesign v2 patient dashboard) -------------

const _notifySmsKey = 'ui.notify.sms';
const _notifyEmailKey = 'ui.notify.email';
const _notifyPushKey = 'ui.notify.push';

class NotificationPrefs {
  const NotificationPrefs({
    this.sms = false,
    this.email = true,
    this.push = true,
  });

  final bool sms;
  final bool email;
  final bool push;

  NotificationPrefs copyWith({bool? sms, bool? email, bool? push}) =>
      NotificationPrefs(
        sms: sms ?? this.sms,
        email: email ?? this.email,
        push: push ?? this.push,
      );
}

/// SMS / Email / Push toggles — a device preference like theme mode, not
/// clinical data, so it lives in [SharedPreferences] too.
class NotificationPrefsController extends Notifier<NotificationPrefs> {
  @override
  NotificationPrefs build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return NotificationPrefs(
      sms: prefs.getBool(_notifySmsKey) ?? false,
      email: prefs.getBool(_notifyEmailKey) ?? true,
      push: prefs.getBool(_notifyPushKey) ?? true,
    );
  }

  Future<void> setSms(bool value) => _set(sms: value);
  Future<void> setEmail(bool value) => _set(email: value);
  Future<void> setPush(bool value) => _set(push: value);

  Future<void> _set({bool? sms, bool? email, bool? push}) async {
    state = state.copyWith(sms: sms, email: email, push: push);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_notifySmsKey, state.sms);
    await prefs.setBool(_notifyEmailKey, state.email);
    await prefs.setBool(_notifyPushKey, state.push);
  }
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsController, NotificationPrefs>(
      NotificationPrefsController.new,
    );

// --- onboarding -----------------------------------------------------------

const _hasSeenOnboardingKey = 'ui.hasSeenOnboarding';

/// Whether the intro carousel has already been shown on this device. A
/// per-device preference like the theme mode, so it lives in
/// [SharedPreferences] rather than clinical data.
class HasSeenOnboardingController extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(_hasSeenOnboardingKey) ??
      false;

  Future<void> markSeen() async {
    state = true;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_hasSeenOnboardingKey, true);
  }
}

final hasSeenOnboardingProvider =
    NotifierProvider<HasSeenOnboardingController, bool>(
      HasSeenOnboardingController.new,
    );

// --- clinic schedule --------------------------------------------------

const _clinicOpenDaysKey = 'clinic.openDays';
const _clinicOpenHourKey = 'clinic.openHour';
const _clinicCloseHourKey = 'clinic.closeHour';

/// When the clinic is open — which [DateTime.weekday] values (1=Mon..7=Sun)
/// count as open, and the open/close hour. Admin-editable (Profile → Clinic
/// hours); shared by the booking wizard, the reschedule flow, and admin
/// scheduling. There's no backend in this demo app, so — like every other
/// setting in this file — "shared" just means the one local device's
/// [SharedPreferences], same as the rest of `ui_prefs.dart`.
class ClinicSchedule {
  const ClinicSchedule({
    this.openDays = const {1, 2, 3, 4, 5, 6, 7},
    this.openHour = 8,
    this.closeHour = 20,
  });

  final Set<int> openDays;
  final int openHour;
  final int closeHour;

  ClinicSchedule copyWith({Set<int>? openDays, int? openHour, int? closeHour}) =>
      ClinicSchedule(
        openDays: openDays ?? this.openDays,
        openHour: openHour ?? this.openHour,
        closeHour: closeHour ?? this.closeHour,
      );
}

class ClinicScheduleController extends Notifier<ClinicSchedule> {
  @override
  ClinicSchedule build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final days = prefs.getStringList(_clinicOpenDaysKey);
    return ClinicSchedule(
      openDays: days == null
          ? const {1, 2, 3, 4, 5, 6, 7}
          : days.map(int.parse).toSet(),
      openHour: prefs.getInt(_clinicOpenHourKey) ?? 8,
      closeHour: prefs.getInt(_clinicCloseHourKey) ?? 20,
    );
  }

  Future<void> set(ClinicSchedule schedule) async {
    state = schedule;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(
      _clinicOpenDaysKey,
      schedule.openDays.map((d) => d.toString()).toList(),
    );
    await prefs.setInt(_clinicOpenHourKey, schedule.openHour);
    await prefs.setInt(_clinicCloseHourKey, schedule.closeHour);
  }
}

final clinicScheduleProvider =
    NotifierProvider<ClinicScheduleController, ClinicSchedule>(
      ClinicScheduleController.new,
    );
