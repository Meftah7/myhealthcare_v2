// Phase 6 gate: role workspaces put owned, overdue and failed work first, and
// a failed operational query is never presented as an all-clear.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/theme/theme.dart';
import 'package:myhealthcare/core/di.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';
import 'package:myhealthcare/data/db/app_database.dart';
import 'package:myhealthcare/data/db/tables/sync.dart';
import 'package:myhealthcare/data/sync/outbox.dart';
import 'package:myhealthcare/domain/entities/entities.dart';
import 'package:myhealthcare/domain/enums.dart';
import 'package:myhealthcare/domain/repositories/notification_repository.dart';
import 'package:myhealthcare/features/admin/application/attention_providers.dart';
import 'package:myhealthcare/features/admin/presentation/attention_list.dart';
import 'package:myhealthcare/features/billing/application/billing_providers.dart';
import 'package:myhealthcare/features/care/application/care_providers.dart';
import 'package:myhealthcare/features/patient/application/family_link_providers.dart';
import 'package:myhealthcare/features/patient_home/presentation/needs_attention_strip.dart';
import 'package:myhealthcare/l10n/app_localizations.dart';
import 'package:myhealthcare/l10n/app_localizations_en.dart';

import '../support/sessions.dart';

Widget _host(Widget child, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

List<Override> _attention(Map<AttentionKind, Object> values) => [
  for (final (kind, provider) in adminAttentionSources)
    provider.overrideWith((ref) async {
      final v = values[kind] ?? 0;
      if (v is Failure) throw v;
      return AttentionItem(
        kind: kind,
        count: v as int,
        route: '/admin/dashboard',
        parts: kind == AttentionKind.resultReviews
            ? {'unassigned': v, 'overdue': 0}
            : const {},
      );
    }),
];

void main() {
  final t = AppLocalizationsEn();

  group('admin "Needs attention"', () {
    testWidgets(
      'a queue that could not be checked says so; others still show',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const AdminAttentionList(),
            _attention({
              AttentionKind.resultReviews: 2,
              AttentionKind.unansweredMessages: const DatabaseFailure('x'),
            }),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(t.couldNotCheckQueue(t.attentionMessages)),
          findsOneWidget,
        );
        expect(find.text(t.attentionResultReviews), findsOneWidget);
        expect(
          find.textContaining(t.attentionPartUnassigned(2)),
          findsOneWidget,
        );
        expect(find.text(t.nothingNeedsAttention), findsNothing);
      },
    );

    testWidgets('only when every queue was read and empty: nothing needs you', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AdminAttentionList(), _attention({})),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.nothingNeedsAttention), findsOneWidget);
      expect(find.textContaining('Checked and clear'), findsOneWidget);
    });
  });

  group('patient "Needs your attention"', () {
    List<Override> base({bool messagesFail = false}) => [
      patientThreadsProvider.overrideWith((ref) async {
        if (messagesFail) throw const DatabaseFailure('x');
        return const <CareThread>[];
      }),
      patientInvoicesProvider.overrideWith((ref) async => const <Invoice>[]),
      patientPaymentsProvider.overrideWith(
        (ref) async => const <PaymentTransaction>[],
      ),
      incomingFamilyRequestsProvider.overrideWith(
        (ref) async => const <FamilyLinkView>[],
      ),
    ];

    testWidgets('hidden when everything was read and nothing waits', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const NeedsAttentionStrip(), base()));
      await tester.pumpAndSettle();
      expect(find.text('NEEDS YOUR ATTENTION'), findsNothing);
    });

    testWidgets('a failed read is shown, never hidden as "nothing to do"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const NeedsAttentionStrip(), base(messagesFail: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.couldNotCheckQueue(t.messagesTitle)), findsOneWidget);
    });
  });

  group('delivery health', () {
    test('failed side effects are counted and can be queued again', () async {
      final (c, db) = await seededContainer();
      final id = await Outbox(db).enqueueNotification(
        const NewNotification(
          recipientId: 'patient_001',
          category: NotificationCategory.system,
          title: 'x',
          body: 'y',
        ),
      );
      await (db.update(db.outboxEvents)..where((e) => e.id.equals(id))).write(
        const OutboxEventsCompanion(status: Value(OutboxStatus.failed)),
      );

      await signInAs(c, 'staff1@myhealth.demo');
      expect(
        (await c.read(notificationRepositoryProvider).deliveryHealth()).isErr,
        isTrue,
      );

      await signInAs(c, 'admin@myhealth.demo');
      final repo = c.read(notificationRepositoryProvider);
      final health = (await repo.deliveryHealth()).valueOrNull!;
      expect(health.failedSideEffects, greaterThanOrEqualTo(1));
      expect((await repo.retryFailedDeliveries()).valueOrNull, greaterThan(0));
      final row = await (db.select(
        db.outboxEvents,
      )..where((e) => e.id.equals(id))).getSingle();
      expect(row.status, OutboxStatus.pending);
    });
  });

  group('staff cover', () {
    test('the covering clinician sees the message, can read the thread, and '
        'nobody else can', () async {
      final (c, db) = await seededContainer();
      final thread = await (db.select(db.careMessages)..limit(1)).getSingle();
      final owner = await (db.select(
        db.staffProfiles,
      )..where((s) => s.userId.equals(thread.staffId))).getSingle();
      await (db.update(
        db.staffProfiles,
      )..where((s) => s.userId.equals(owner.userId))).write(
        const StaffProfilesCompanion(presence: Value(PresenceStatus.offShift)),
      );
      final cover =
          await (db.select(db.staffProfiles)
                ..where(
                  (s) =>
                      s.departmentId.equalsNullable(owner.departmentId) &
                      s.userId.equals(owner.userId).not(),
                )
                ..limit(1))
              .getSingle();
      await (db.update(
        db.staffProfiles,
      )..where((s) => s.userId.equals(cover.userId))).write(
        const StaffProfilesCompanion(presence: Value(PresenceStatus.onDuty)),
      );
      final patient = await (db.select(
        db.users,
      )..where((u) => u.id.equals(thread.patientId))).getSingle();
      await signInAs(c, patient.email);
      await c
          .read(careMessageRepositoryProvider)
          .send(
            patientId: thread.patientId,
            staffId: thread.staffId,
            fromStaff: false,
            body: 'Question while my doctor is away',
          );

      final coverUser = await (db.select(
        db.users,
      )..where((u) => u.id.equals(cover.userId))).getSingle();
      await signInAs(c, coverUser.email);
      final awaiting =
          (await c
                  .read(careMessageRepositoryProvider)
                  .awaitingReply(staffId: cover.userId))
              .valueOrNull!;
      expect(awaiting.any((m) => m.body.startsWith('Question while')), isTrue);
      expect(
        (await c
                .read(careMessageRepositoryProvider)
                .thread(patientId: thread.patientId, staffId: thread.staffId))
            .isOk,
        isTrue,
      );

      // A clinician who neither owns nor covers it is refused.
      final other =
          await (db.select(db.users)
                ..where(
                  (u) =>
                      u.role.equalsValue(UserRole.staff) &
                      u.id.isNotIn([thread.staffId, cover.userId]),
                )
                ..limit(1))
              .getSingle();
      await signInAs(c, other.email);
      final denied = await c
          .read(careMessageRepositoryProvider)
          .thread(patientId: thread.patientId, staffId: thread.staffId);
      expect(denied, isA<Err<dynamic>>());
    });
  });
}
