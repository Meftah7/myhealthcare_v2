import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../../core/result.dart';
import '../../domain/repositories/document_service.dart';
import '../../domain/repositories/export_repository.dart';
import 'shared_client.dart';

class RemoteDocumentService implements DocumentService {
  RemoteDocumentService(this.client);
  final SharedClient client;
  DateTime _date(dynamic value) =>
      DateTime.fromMillisecondsSinceEpoch((value as num).toInt(), isUtc: true);
  DocumentRequest _request(Map<String, dynamic> r) => DocumentRequest(
    id: r['id'] as String,
    patientId: r['patient'] as String,
    templateId: r['template'] as String,
    status: DocumentRequestStatus.values.byName(r['status'] as String),
    version: (r['version'] as num).toInt(),
  );
  IssuedDocument _document(Map<String, dynamic> d) {
    return IssuedDocument(
      id: d['id'] as String,
      patientId: d['patient'] as String,
      verificationCode: d['reference'] as String? ?? '',
      validity: DocumentValidity.values.byName(
        d['validity'] as String? ?? 'valid',
      ),
      renderStatus: DocumentRenderStatus.values.byName(
        d['render'] as String? ?? 'pending',
      ),
      requestId: d['request'] as String? ?? '',
      documentType: ExportDocument.values.byName(
        d['type'] as String? ?? 'sickLeaveCertificate',
      ),
      language: d['language'] as String? ?? 'en',
      issuedAt: d['issued'] == null ? null : _date(d['issued']),
    );
  }

  @override
  Future<Result<DocumentWorkspace>> workspace(String patientId) =>
      Result.guardAsync(() async {
        final data =
            await client.request(
                  '/api/document-workspace',
                  query: {'patientId': patientId},
                )
                as Map<String, dynamic>;
        return DocumentWorkspace(
          patientName: data['patientName'] as String,
          visits: [
            for (final v in data['visits'] as List)
              DocumentVisit(v['id'] as String, _date(v['at'])),
          ],
          templates: [
            for (final t in data['templates'] as List)
              DocumentTemplateChoice(
                t['id'] as String,
                t['language'] as String,
                DisclosureProfile.values.byName(t['disclosure'] as String),
                t['approved'] == 1,
                documentType: ExportDocument.values.byName(t['type'] as String),
              ),
          ],
          requests: [
            for (final r in data['requests'] as List)
              DocumentReviewItem(
                _request(r as Map<String, dynamic>),
                r['visit'] as String,
                Map<String, Object?>.from(r['content'] as Map<String, dynamic>),
              ),
          ],
          issued: [
            for (final d in data['issued'] as List)
              _document(d as Map<String, dynamic>),
          ],
        );
      });
  @override
  Stream<List<IssuedDocument>> watchForPatient(String patientId) async* {
    do {
      final result = await workspace(patientId);
      switch (result) {
        case Ok(:final value):
          yield value.issued;
        case Err(:final failure):
          throw failure;
      }
      await Future<void>.delayed(const Duration(seconds: 30));
    } while (client.user != null);
  }

  @override
  Future<Result<DocumentRequest>> prepare(PrepareDocument input) =>
      Result.guardAsync(
        () async => _request(
          await client.request(
                '/api/requests',
                method: 'POST',
                body: {
                  'patientId': input.patientId,
                  'visitId': input.appointmentId,
                  'templateId': input.templateId,
                  'content': input.content,
                  'idempotencyKey': input.idempotencyKey,
                },
              )
              as Map<String, dynamic>,
        ),
      );
  Future<Result<DocumentRequest>> _transition(
    String id,
    String action,
    int version,
  ) => Result.guardAsync(
    () async => _request(
      await client.request(
            '/api/requests/$id/$action',
            method: 'POST',
            body: {'expectedVersion': version},
          )
          as Map<String, dynamic>,
    ),
  );
  @override
  Future<Result<DocumentRequest>> submit(
    String requestId, {
    required int expectedVersion,
  }) => _transition(requestId, 'submit', expectedVersion);
  @override
  Future<Result<DocumentRequest>> approve(
    String requestId, {
    required int expectedVersion,
  }) => _transition(requestId, 'approve', expectedVersion);
  @override
  Future<Result<IssuedDocument>> issue(
    String requestId, {
    required int expectedVersion,
    required String idempotencyKey,
  }) => Result.guardAsync(
    () async => _document(
      await client.request(
            '/api/requests/$requestId/issue',
            method: 'POST',
            body: {
              'expectedVersion': expectedVersion,
              'idempotencyKey': idempotencyKey,
            },
          )
          as Map<String, dynamic>,
    ),
  );
  @override
  Future<Result<Uint8List>> preview(String requestId) => Result.guardAsync(
    () async =>
        await client.request('/api/requests/$requestId/preview', binary: true)
            as Uint8List,
  );
  @override
  Future<Result<Uint8List>> download(String issuedVersionId) =>
      Result.guardAsync(
        () async =>
            await client.request(
                  '/api/documents/$issuedVersionId/download',
                  binary: true,
                )
                as Uint8List,
      );
  @override
  Future<Result<IssuedDocument>> render(String issuedVersionId) =>
      Result.guardAsync(() async {
        await client.request(
          '/api/documents/$issuedVersionId/render',
          method: 'POST',
          body: {},
        );
        return _document(
          await client.request(
                '/api/document-metadata',
                query: {'id': issuedVersionId},
              )
              as Map<String, dynamic>,
        );
      });
  @override
  Future<Result<void>> deliver(String issuedVersionId) =>
      Result.guardAsync(() async {
        await client.request(
          '/api/document-delivery',
          method: 'POST',
          body: {'id': issuedVersionId},
        );
      });
  @override
  Future<Result<void>> revoke(
    String issuedVersionId, {
    required String reason,
  }) => Result.guardAsync(() async {
    final metadata =
        await client.request(
              '/api/document-metadata',
              query: {'id': issuedVersionId},
            )
            as Map<String, dynamic>;
    await client.request(
      '/api/documents/$issuedVersionId/revoke',
      method: 'POST',
      body: {'reason': reason, 'expectedVersion': metadata['version']},
    );
  });
  @override
  Future<Result<IssuedDocument>> findForDesk(String reference) =>
      Result.guardAsync(
        () async => _document(
          await client.request(
                '/api/workforce/document-desk',
                query: {'reference': reference.trim()},
              )
              as Map<String, dynamic>,
        ),
      );
  @override
  Future<Result<DateTime>> confirmIssuedCopy(
    String issuedVersionId, {
    required bool recipientIdentityChecked,
    required String reason,
    required String idempotencyKey,
  }) => Result.guardAsync(() async {
    final result =
        await client.request(
              '/api/workforce/document-copy',
              method: 'POST',
              body: {
                'id': issuedVersionId,
                'recipientIdentityChecked': recipientIdentityChecked,
                'reason': reason,
                'idempotencyKey': idempotencyKey,
              },
            )
            as Map<String, dynamic>;
    return _date(result['at']);
  });
  @override
  Future<Result<DocumentRequest>> prepareReplacement(
    String issuedVersionId, {
    required int expectedVersion,
    required Map<String, Object?> content,
    required String reason,
    String? templateId,
  }) => Result.guardAsync(
    () async => _request(
      await client.request(
            '/api/document-replacement',
            method: 'POST',
            body: {
              'id': issuedVersionId,
              'expectedVersion': expectedVersion,
              'content': content,
              'reason': reason,
              'templateId': templateId,
              'idempotencyKey':
                  'replacement_${sha256.convert(utf8.encode(jsonEncode([issuedVersionId, expectedVersion, content, reason, templateId])))}',
            },
          )
          as Map<String, dynamic>,
    ),
  );
  @override
  Future<Result<void>> releaseSource(
    String recordId, {
    required bool released,
    required String reason,
  }) => Result.guardAsync(() async {
    await client.request(
      '/api/document-source-release',
      method: 'POST',
      body: {'id': recordId, 'released': released, 'reason': reason},
    );
  });
  @override
  Future<Result<Uint8List>> exportVerificationManifest() => Result.guardAsync(
    () async => Uint8List.fromList(
      utf8.encode(
        jsonEncode(await client.request('/api/document-verification-manifest')),
      ),
    ),
  );
}
