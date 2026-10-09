import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/remote/shared_client.dart';
import 'package:myhealthcare/features/shared/presentation/shared_workspace_app.dart';

void main() {
  testWidgets(
    'revocation closes an active private preview and returns to login',
    (tester) async {
      final client = SharedClient(
        'http://localhost:8787',
        dio: Dio()..httpClientAdapter = _RevocationAdapter(),
      );
      await tester.runAsync(
        () => client.login('patient@test.demo', 'synthetic'),
      );
      await tester.pumpWidget(
        SharedWorkspaceApp(origin: 'http://localhost:8787', client: client),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.text('Shared workspace'));
      unawaited(
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Text('Private PDF bytes preview')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private PDF bytes preview'), findsOneWidget);
      await tester.runAsync(
        () => expectLater(client.request('/revoked'), throwsA(isA<Failure>())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private PDF bytes preview'), findsNothing);
      expect(find.text('Sign in to server'), findsOneWidget);
      expect(client.user, isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'shared login explains scope and switches English/Arabic without a local database',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const SharedWorkspaceApp(origin: 'http://localhost:8787'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sign in to server'), findsOneWidget);
      expect(
        find.textContaining('Other clinic modules remain in the local app'),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(find.text('الدخول إلى الخادم'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}

class _RevocationAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final login = options.path == '/api/login';
    return ResponseBody.fromString(
      jsonEncode(
        login
            ? {
                'token': 'synthetic-token',
                'user': {
                  'id': 'patient',
                  'role': 'patient',
                  'fullName': 'Synthetic Patient',
                },
              }
            : {'error': 'Access revoked'},
      ),
      login ? 200 : 403,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
