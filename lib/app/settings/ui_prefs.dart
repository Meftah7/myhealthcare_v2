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
