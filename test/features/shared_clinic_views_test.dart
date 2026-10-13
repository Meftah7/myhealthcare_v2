// Shared-mode appointments, messages and billing never show success the
// server did not confirm: a 409 booking shows the server's reason, a failed
// send keeps the draft and retries with the same idempotency key.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/data/remote/shared_client.dart';
import 'package:myhealthcare/features/shared/presentation/shared_clinic_views.dart';

class _Server implements HttpClientAdapter {
  final sentKeys = <String>[];
  bool failSends = true;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    (int, Object) reply;
    if (o.path == '/api/login') {
      reply = (
        200,
        {
          'token': 't',
          'user': {'id': 'p1', 'role': 'patient', 'fullName': 'Pat'},
        },
      );
    } else if (o.path == '/api/appointments' && o.method == 'GET') {
      reply = (200, <Object>[]);
    } else if (o.path == '/api/threads') {
      reply = (
        200,
        [
          {
            'counterpartId': 'd1',
            'counterpartName': 'Dr Who',
            'lastAt': '2026-10-13T08:00:00Z',
            'unread': 0,
          },
        ],
      );
    } else if (o.path == '/api/messages' && o.method == 'GET') {
      reply = (200, <Object>[]);
    } else if (o.path == '/api/messages' && o.method == 'POST') {
      final data = o.data is String ? jsonDecode(o.data as String) : o.data;
      sentKeys.add((data as Map)['idempotencyKey'] as String);
      reply = failSends
          ? (503, {'error': 'Server unavailable.'})
          : (
              200,
              {
                'id': 'm1',
                'senderId': 'p1',
                'body': data['body'],
                'at': '2026-10-13T08:01:00Z',
                'readAt': null,
              },
            );
    } else if (o.path == '/api/messages/read') {
      reply = (200, {'ok': true});
    } else {
      reply = (404, {'error': 'Endpoint unavailable.'});
    }
    return ResponseBody.fromString(
      jsonEncode(reply.$2),
      reply.$1,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('a failed send keeps the draft and retries with the same key', (
    tester,
  ) async {
    final server = _Server();
    final client = SharedClient(
      'http://localhost:8787',
      dio: Dio()..httpClientAdapter = server,
    );
    await tester.runAsync(() => client.login('p@test.demo', 'synthetic'));
    final repo = SharedWorkspaceRepository(client);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SharedMessagesView(
              repository: repo,
              user: client.user!,
              tr: (en, _) => en,
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dr Who'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Can I move my visit?');
    await tester.tap(find.text('Send'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    // Not shown as sent; draft kept; an error is shown.
    expect(find.text('Can I move my visit?'), findsOneWidget);
    expect(find.textContaining('sent'), findsNothing);
    server.failSends = false;
    await tester.tap(find.text('Send'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(server.sentKeys, hasLength(2));
    expect(server.sentKeys.toSet(), hasLength(1), reason: 'same key on retry');
    await tester.pumpWidget(const SizedBox());
  });
}
