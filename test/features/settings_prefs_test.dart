// Preferences: a failed save rolls back and is reported, scoped resets
// restore defaults, notification channels are per-user, and the high-contrast
// toggle persists.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/settings/ui_prefs.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every read is empty and every write reports failure.
class _FailingPrefs extends Fake implements SharedPreferences {
  @override
  String? getString(String key) => null;
  @override
  bool? getBool(String key) => null;
  @override
  Future<bool> setString(String key, String value) async => false;
  @override
  Future<bool> setBool(String key, bool value) async => false;
}

User _user(String id) => User(
  id: id,
  role: UserRole.patient,
  fullName: id,
  email: '$id@example.com',
  isActive: true,
  createdAt: DateTime(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a failed save rolls the value back and reports it', () async {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(_FailingPrefs())],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
    await container.read(themeModeProvider.notifier).set(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(container.read(settingsSaveFailureProvider), 1);
  });

  test('scoped resets restore the defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await container
        .read(motionPreferenceProvider.notifier)
        .set(MotionPreference.full);
    await container.read(highContrastProvider.notifier).set(enabled: true);
    await container.read(notificationPrefsProvider.notifier).setSms(true);
    await container.read(notificationPrefsProvider.notifier).setPush(false);

    await container.read(themeModeProvider.notifier).reset();
    await container.read(motionPreferenceProvider.notifier).reset();
    await container.read(highContrastProvider.notifier).reset();
    await container.read(notificationPrefsProvider.notifier).reset();

    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(container.read(motionPreferenceProvider), MotionPreference.system);
    expect(container.read(highContrastProvider), isFalse);
    final n = container.read(notificationPrefsProvider);
    expect((n.sms, n.email, n.push), (false, true, true));
  });

  test('notification channels are kept per user on the same device', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    ProviderContainer signedInAs(String id) {
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWithValue(_user(id)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    final alice = signedInAs('alice');
    await alice.read(notificationPrefsProvider.notifier).setSms(true);

    // Bob, on the same device, still has the defaults.
    final bob = signedInAs('bob');
    expect(bob.read(notificationPrefsProvider).sms, isFalse);

    // And Alice's choice survives a fresh read.
    expect(signedInAs('alice').read(notificationPrefsProvider).sms, isTrue);
  });

  test('enabledChannels always keeps in-app delivery', () {
    const off = NotificationPrefs(email: false, push: false);
    expect(off.enabledChannels, {ReminderChannel.inApp});
  });
}
