import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/failures.dart';

/// Online-only transport. No tokens or patient data are persisted on the device.
/// Every repository reads from the server, whose authorization is authoritative.
class SharedClient {
  /// [endSessionOnForbidden]: the pilot workspace treats any 403 as revoked
  /// access and signs out; the full app keeps the session and reports
  /// "access denied" for that one action.
  SharedClient(String origin, {Dio? dio, this.endSessionOnForbidden = true})
    : _dio = dio ?? Dio() {
    final uri = Uri.parse(origin);
    final loopback = {'localhost', '127.0.0.1', '::1'}.contains(uri.host);
    if ((!loopback && uri.scheme != 'https') ||
        !{'https', 'http'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !{'', '/'}.contains(uri.path)) {
      throw ArgumentError(
        'Use an HTTPS origin, or HTTP on localhost for testing.',
      );
    }
    _dio.options = BaseOptions(
      baseUrl: uri.replace(path: '').toString(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      validateStatus: (status) => status != null,
    );
  }

  final bool endSessionOnForbidden;
  final Dio _dio;
  String? _token;
  Map<String, dynamic>? _user;
  int _generation = 0;
  final _sessions = StreamController<Map<String, dynamic>?>.broadcast();
  Map<String, dynamic>? get user =>
      _user == null ? null : Map.unmodifiable(_user!);
  Stream<Map<String, dynamic>?> get sessions => _sessions.stream;
  int get generation => _generation;

  Future<Map<String, dynamic>> login(String email, String password) async {
    clear();
    final result =
        await request(
              '/api/login',
              method: 'POST',
              body: {'email': email, 'password': password},
            )
            as Map<String, dynamic>;
    _token = result['token'] as String;
    _user = result['user'] as Map<String, dynamic>;
    _sessions.add(user);
    return user!;
  }

  void clear() {
    _generation++;
    _token = null;
    _user = null;
    _sessions.add(null);
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await request('/api/logout', method: 'POST', body: {});
      }
    } finally {
      clear();
    }
  }

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool binary = false,
  }) async {
    final generation = _generation;
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          responseType: binary ? ResponseType.bytes : ResponseType.json,
          headers: {if (_token != null) 'Authorization': 'Bearer $_token'},
        ),
      );
      // Account switches discard already-running replies, even successful ones.
      if (generation != _generation) throw const SessionExpiredFailure();
      final status = response.statusCode!;
      if (status == 401) {
        clear();
        throw const SessionExpiredFailure();
      }
      String? serverMessage() {
        final data = response.data;
        return data is Map && data['error'] is String
            ? data['error'] as String
            : null;
      }

      if (status == 403) {
        if (endSessionOnForbidden) {
          clear();
          throw const AccessDeniedFailure();
        }
        throw AccessDeniedFailure(
          serverMessage() ?? 'You do not have access to this.',
        );
      }
      if (status == 404) {
        throw NotFoundFailure(serverMessage() ?? 'Not found.');
      }
      if (status == 409) {
        throw ConflictFailure(
          serverMessage() ?? 'Changed on the server. Reload before saving.',
        );
      }
      if (status >= 500) {
        throw const NetworkFailure(
          'The server could not complete this operation. Retry after checking its status.',
        );
      }
      if (status >= 400) {
        final data = response.data;
        throw ValidationFailure(
          data is Map && data['error'] is String
              ? data['error'] as String
              : 'Request rejected.',
        );
      }
      return binary
          ? Uint8List.fromList((response.data as List).cast<int>())
          : response.data;
    } on DioException {
      throw const NetworkFailure(
        'Cannot reach the shared server. No local changes were saved.',
      );
    }
  }

  Stream<List<Map<String, dynamic>>> watch(
    String path, {
    Map<String, dynamic>? query,
  }) async* {
    final generation = _generation;
    while (generation == _generation && _user != null) {
      final data = await request(path, query: query) as List;
      yield data.cast<Map<String, dynamic>>();
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  Future<void> close() async {
    clear();
    _dio.close(force: true);
    await _sessions.close();
  }
}

/// Explicit adapters keep HTTP and version handling out of presentation code.
class SharedWorkspaceRepository {
  const SharedWorkspaceRepository(this.client);
  final SharedClient client;
  Future<List<Map<String, dynamic>>> _list(
    String path, [
    Map<String, dynamic>? query,
  ]) async => (await client.request(path, query: query) as List)
      .cast<Map<String, dynamic>>();
  Future<List<Map<String, dynamic>>> people() => _list('/api/people');
  Future<List<Map<String, dynamic>>> notifications() =>
      _list('/api/notifications');
  Future<List<Map<String, dynamic>>> tasks() => _list('/api/tasks');
  Future<List<Map<String, dynamic>>> documents(String patient) =>
      _list('/api/documents', {'patientId': patient});
  Future<List<Map<String, dynamic>>> originals(String patient) =>
      _list('/api/originals', {'patientId': patient});
  Future<List<Map<String, dynamic>>> visits(String patient) =>
      _list('/api/visits', {'patientId': patient});
  Future<List<Map<String, dynamic>>> templates() => _list('/api/templates');
  Future<List<Map<String, dynamic>>> requests(String patient) =>
      _list('/api/requests', {'patientId': patient});
  Future<Map<String, dynamic>> health() async =>
      await client.request('/api/health') as Map<String, dynamic>;

  // --- Appointments, messages and desk billing (shared server v2) ---------

  /// Own appointments (patient/clinician), a patient's (desk), or a time
  /// range for the front desk.
  Future<List<Map<String, dynamic>>> appointments({
    String? patientId,
    DateTime? from,
    DateTime? to,
  }) => _list('/api/appointments', {
    'patientId': ?patientId,
    'from': ?from?.toUtc().toIso8601String(),
    'to': ?to?.toUtc().toIso8601String(),
  });

  /// Books one visit; the same [idempotencyKey] never books twice. A taken
  /// slot is a 409 from the server, never a local success.
  Future<Map<String, dynamic>> book({
    required String patientId,
    required String staffId,
    required DateTime start,
    required DateTime end,
    required String idempotencyKey,
    String? reason,
  }) async =>
      await client.request(
            '/api/appointments',
            method: 'POST',
            body: {
              'patientId': patientId,
              'staffId': staffId,
              'start': start.toUtc().toIso8601String(),
              'end': end.toUtc().toIso8601String(),
              'reason': reason,
              'idempotencyKey': idempotencyKey,
            },
          )
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> appointmentAction(
    String id,
    String action, {
    required int expectedVersion,
    String? reason,
  }) async =>
      await client.request(
            '/api/appointments/$id/$action',
            method: 'POST',
            body: {'expectedVersion': expectedVersion, 'reason': reason},
          )
          as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> threads() => _list('/api/threads');

  Future<List<Map<String, dynamic>>> messages(String patient, String staff) =>
      _list('/api/messages', {'patientId': patient, 'staffId': staff});

  Future<Map<String, dynamic>> sendMessage({
    required String patientId,
    required String staffId,
    required String body,
    required String idempotencyKey,
  }) async =>
      await client.request(
            '/api/messages',
            method: 'POST',
            body: {
              'patientId': patientId,
              'staffId': staffId,
              'body': body,
              'idempotencyKey': idempotencyKey,
            },
          )
          as Map<String, dynamic>;

  Future<void> markRead(String patient, String staff) async {
    await client.request(
      '/api/messages/read',
      method: 'POST',
      body: {'patientId': patient, 'staffId': staff},
    );
  }

  Future<List<Map<String, dynamic>>> invoices([String? patientId]) =>
      _list('/api/invoices', {'patientId': ?patientId});

  /// Records a desk payment in integer fils. No card gateway is connected:
  /// the server stores a record only and says so (`recordedOnly`).
  Future<Map<String, dynamic>> recordDeskPayment(
    String invoiceId, {
    required int amountFils,
    required int expectedVersion,
    required String idempotencyKey,
  }) async =>
      await client.request(
            '/api/invoices/$invoiceId/payments',
            method: 'POST',
            body: {
              'amountFils': amountFils,
              'expectedVersion': expectedVersion,
              'idempotencyKey': idempotencyKey,
            },
          )
          as Map<String, dynamic>;
  Future<void> reauthenticate(String password) async {
    await client.request(
      '/api/reauthenticate',
      method: 'POST',
      body: {'password': password},
    );
  }

  Future<void> setTaskStatus(
    Map<String, dynamic> task,
    String status,
    String outcome, {
    DateTime? reviewAt,
  }) async {
    await client.request(
      '/api/tasks/${task['id']}',
      method: 'PATCH',
      body: {
        'status': status,
        'expectedVersion': task['version'],
        'outcome': outcome,
        if (reviewAt != null) 'reviewAt': reviewAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> input) async =>
      await client.request('/api/tasks', method: 'POST', body: input)
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> prepareDocument(
    Map<String, dynamic> input,
  ) async =>
      await client.request('/api/requests', method: 'POST', body: input)
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> documentAction(
    String request,
    String action,
    int version, {
    String? key,
  }) async =>
      await client.request(
            '/api/requests/$request/$action',
            method: 'POST',
            body: {
              'expectedVersion': version,
              if (key != null) 'idempotencyKey': key,
            },
          )
          as Map<String, dynamic>;
  Future<void> render(String document) async {
    await client.request(
      '/api/documents/$document/render',
      method: 'POST',
      body: {},
    );
  }

  Future<Uint8List> download(String document) async =>
      await client.request('/api/documents/$document/download', binary: true)
          as Uint8List;
}
