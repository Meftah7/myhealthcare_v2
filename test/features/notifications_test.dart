// Notifications: a patient reads their feed, marks messages read, and cannot
// touch anyone else's.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/data/repositories/notification_repository_impl.dart';
import 'package:myhealthcare/data/seed/seeder.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/notification_repository.dart';
import 'package:myhealthcare/features/auth/application/session.dart';
import 'package:myhealthcare/features/notifications/application/notification_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('patient sees a seeded feed and marking read updates the count',
      () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    final login = await container
        .read(sessionProvider.notifier)
        .login(email: 'patient3@myhealth.demo', password: Seeder.demoPassword);
    expect(login.isOk, isTrue);

    // Keep the stream provider alive for the whole test so its value tracks
    // writes (a StreamProvider's `.future` only ever yields the first event).
    final sub = container.listen(patientNotificationsProvider, (_, _) {});
    addTearDown(sub.close);

    Future<List<T>> settledList<T>(
      ProviderListenable<AsyncValue<List<T>>> p,
    ) async {
      for (var i = 0; i < 50; i++) {
        final v = container.read(p);
        if (v is AsyncData<List<T>>) return v.value;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      throw StateError('provider never resolved');
    }

    Future<int> settledUnread(int expected) async {
      for (var i = 0; i < 50; i++) {
        if (container.read(unreadNotificationCountProvider) == expected) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return container.read(unreadNotificationCountProvider);
    }

    final feed = await settledList(patientNotificationsProvider);
    expect(feed, isNotEmpty);
    // Newest first.
    for (var i = 1; i < feed.length; i++) {
      expect(feed[i - 1].createdAt.isBefore(feed[i].createdAt), isFalse);
    }

    // Seed leaves the two most recent unread.
    final unreadBefore = feed.where((n) => !n.isRead).length;
    expect(unreadBefore, greaterThan(0));
    expect(container.read(unreadNotificationCountProvider), unreadBefore);

    final target = feed.firstWhere((n) => !n.isRead);
    final marked = await container
        .read(notificationControllerProvider)
        .markRead(target.id);
    expect(marked.isOk, isTrue);

    // The live stream updates the count without a manual refresh.
    expect(await settledUnread(unreadBefore - 1), unreadBefore - 1);

    // Mark-all clears the rest.
    await container.read(notificationControllerProvider).markAllRead();
    expect(await settledUnread(0), 0);
  });

  test('markRead is scoped to the recipient', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    final repo = NotificationRepositoryImpl(db);
    final users = await db.select(db.users).get();
    final patients =
        users.where((u) => u.role == UserRole.patient).map((u) => u.id).toList();
    expect(patients.length, greaterThan(1));

    final victimFeed = (await repo.forRecipient(patients.first)).valueOrNull!;
    final victimUnread = victimFeed.firstWhere((n) => !n.isRead);

    // Another patient tries to mark it read.
    final result = await repo.markRead(
      id: victimUnread.id,
      recipientId: patients[1],
    );
    expect(result.isOk, isTrue); // no error...

    // ...but the notification is untouched.
    final after = (await repo.forRecipient(patients.first)).valueOrNull!;
    expect(after.firstWhere((n) => n.id == victimUnread.id).isRead, isFalse);
  });

  test('send fans a message to one recipient', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    await Seeder(db).run();

    final repo = NotificationRepositoryImpl(db);
    final patient =
        (await db.select(db.users).get()).firstWhere((u) => u.role == UserRole.patient);

    final before = (await repo.forRecipient(patient.id)).valueOrNull!.length;
    final sent = await repo.send(
      NewNotification(
        recipientId: patient.id,
        category: NotificationCategory.message,
        title: 'From reception',
        body: 'Please arrive 10 minutes early for your next visit.',
        deepLink: '/patient/appointments',
      ),
    );
    expect(sent.isOk, isTrue);
    expect(sent.valueOrNull!.isRead, isFalse);

    final after = (await repo.forRecipient(patient.id)).valueOrNull!;
    expect(after.length, before + 1);
    expect(after.first.title, 'From reception'); // newest first
  });
}
