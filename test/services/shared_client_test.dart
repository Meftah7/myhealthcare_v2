import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/data/remote/shared_client.dart';

class _Adapter implements HttpClientAdapter {
  Future<ResponseBody> Function(RequestOptions) respond;
  _Adapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object value, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(value),
  status,
  headers: {
    'content-type': ['application/json'],
  },
);

void main() {
  test('shared origins reject secrets, paths and non-loopback HTTP', () {
    for (final origin in [
      'http://clinic.example',
      'https://user:secret@clinic.example',
      'https://clinic.example/api',
      'https://clinic.example?key=secret',
    ]) {
      expect(() => SharedClient(origin), throwsArgumentError);
    }
    final client = SharedClient('http://localhost:8787');
    addTearDown(client.close);
  });
  test(
    'account changes discard in-flight replies and authorization revocation clears memory',
    () async {
      final pending = Completer<ResponseBody>();
      final dio = Dio()
        ..httpClientAdapter = _Adapter((request) async {
          if (request.path == '/api/login')
            return _json({
              'token': 'test-token',
              'user': {'id': 'one', 'role': 'staff'},
            });
          if (request.path == '/pending') return pending.future;
          return _json({'error': 'Access revoked'}, 403);
        });
      final client = SharedClient('http://localhost:8787', dio: dio);
      addTearDown(client.close);
      await client.login('one@test.demo', 'password');
      final request = client.request('/pending');
      final expectation = expectLater(
        request,
        throwsA(isA<SessionExpiredFailure>()),
      );
      await Future<void>.delayed(Duration.zero);
      client.clear();
      pending.complete(_json({'private': 'old account'}));
      await expectation;
      await client.login('one@test.demo', 'password');
      await expectLater(
        client.request('/revoked'),
        throwsA(isA<AccessDeniedFailure>()),
      );
      expect(client.user, isNull);
    },
  );
  test(
    'server conflicts remain conflicts; transport failures never write locally',
    () async {
      final dio = Dio()
        ..httpClientAdapter = _Adapter((request) async {
          if (request.path == '/conflict')
            return _json({'error': 'stale version'}, 409);
          throw DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
          );
        });
      final client = SharedClient('http://localhost:8787', dio: dio);
      addTearDown(client.close);
      await expectLater(
        client.request('/conflict'),
        throwsA(isA<ConflictFailure>()),
      );
      await expectLater(
        client.request('/offline'),
        throwsA(isA<NetworkFailure>()),
      );
    },
  );
}
