/// Per-device UI preferences: theme mode and language (P8-07).
///
/// These are *device* preferences, not clinical data — they live in
/// [SharedPreferences], never in the Drift `app_settings` row (which is shared
/// demo data and wiped on re-seed).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    if (raw == null || raw.isEmpty) return null;
    return Locale(raw);
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
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
