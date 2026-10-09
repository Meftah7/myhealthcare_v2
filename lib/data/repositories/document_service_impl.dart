import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/documents/document_rules.dart';
import '../../domain/enums.dart';
import '../../domain/identity/identity.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/identity/principal.dart';
import '../../domain/repositories/document_service.dart';
import '../../domain/repositories/document_verification_repository.dart';
import '../../domain/repositories/export_repository.dart';
import '../../services/auth/access_policy.dart';
import '../../services/pdf/issued_sick_leave_pdf.dart';
import '../db/app_database.dart';
import 'document_sources.dart';

/// Sick-leave issuance is committed before rendering. A rendering failure can
/// therefore be retried without issuing another certificate or reference.
class DocumentServiceImpl implements DocumentService {
  DocumentServiceImpl(
    this._db,
    this._access,
    this._verification,
    this._renderer,
  );
  final AppDatabase _db;
  final AccessPolicy _access;
  final DocumentVerificationRepository _verification;
  final IssuedSickLeaveRenderer _renderer;
  static const _uuid = Uuid();
  static final _random = Random.secure();

  Future<String> _externalBase() async {
    final row = await (_db.select(
      _db.clinicConfigurations,
    )..where((c) => c.id.equals('integrations'))).getSingleOrNull();
    final config = row == null
        ? <String, dynamic>{}
        : jsonDecode(row.valueJson) as Map<String, dynamic>;
    final origin =
        config['verificationOrigin'] as String? ??
        const String.fromEnvironment('DOCUMENT_VERIFICATION_ORIGIN');
    if (origin.isEmpty) return '';
    final uri = Uri.tryParse(origin);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' &&
                {'localhost', '127.0.0.1'}.contains(uri.host)))) {
      throw const ValidationFailure(
        'Configure an HTTPS verification origin, without credentials or a path.',
      );
    }
    return origin.replaceAll(RegExp(r'/$'), '');
  }

  Future<String> _clinicName() async {
    final row = await (_db.select(
      _db.clinicConfigurations,
    )..where((c) => c.id.equals('clinic'))).getSingleOrNull();
    return row == null
        ? 'MyHealth Care'
        : (jsonDecode(row.valueJson) as Map<String, dynamic>)['name'] as String;
  }

  @override
  Future<Result<Uint8List>> exportVerificationManifest() =>
      Result.guardAsync(() async {
        await _actor();
        await _access.require(Permission.manageSettings);
        await _access.requireScoped(Permission.manageDocumentTemplates);
        await _access.requireRecentAuthentication();
        return _db.transaction(() async {
          final versions = await _db.select(_db.issuedDocumentVersions).get();
          final entries = <Map<String, Object?>>[];
          for (final v in versions) {
            final template = jsonDecode(v.templateSnapshotJson) as Map;
            final token = template['externalToken'];
            if (token is! String) continue;
            final issued = await _issued(v.id);
            if (issued.renderStatus != DocumentRenderStatus.ready) continue;
            final artifact = await (_db.select(
              _db.documentArtifacts,
            )..where((a) => a.issuedVersionId.equals(v.id))).getSingle();
            if (artifact.bytes == null ||
                crypto.sha256.convert(artifact.bytes!).toString() !=
                    artifact.sha256) {
              throw const ValidationFailure(
                'An artifact failed its fingerprint check.',
              );
            }
            entries.add({
              'token': token,
              'documentType': v.documentType,
              'issuedAt': v.issuedAt.toUtc().toIso8601String(),
              'validity': issued.validity.name,
              'sha256': artifact.sha256,
            });
          }
          await _access.audit(
            'document.verification.export',
            entityType: 'document_registry',
            detail: 'Minimal registry entries: ${entries.length}',
          );
          return Uint8List.fromList(
            utf8.encode(
              jsonEncode({
                'schema': 1,
                'exportedAt': DateTime.now().toUtc().toIso8601String(),
                'entries': entries,
              }),
            ),
          );
        });
      });

  T _value<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };

  Future<Principal> _actor() async =>
      await _access.principal() ?? (throw const SessionExpiredFailure());

  Future<DocumentRequestRow> _request(String id) async =>
      await (_db.select(
        _db.documentRequests,
      )..where((r) => r.id.equals(id))).getSingleOrNull() ??
      (throw const ValidationFailure('Document request not found.'));

  Future<IssuedDocumentVersionRow> _version(String id) async =>
      await (_db.select(
        _db.issuedDocumentVersions,
      )..where((r) => r.id.equals(id))).getSingleOrNull() ??
      (throw const ValidationFailure('Issued document not found.'));

  DocumentRequest _model(DocumentRequestRow r) => DocumentRequest(
    id: r.id,
    patientId: r.patientId,
    templateId: r.templateId,
    status: DocumentRequestStatus.values.byName(r.status),
    version: r.version,
  );

  Future<DocumentTemplateRow> _template(
    String id, {
    bool approved = false,
  }) async {
    final t = await (_db.select(
      _db.documentTemplates,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (t == null ||
        !DocumentRules.supported.any((type) => type.name == t.documentType) ||
        t.clinicalSignatureRequired !=
            DocumentRules.clinical(
              ExportDocument.values.byName(t.documentType),
            ) ||
        !['en', 'ar'].contains(t.language) ||
        !DisclosureProfile.values.any((d) => d.name == t.disclosureProfile) ||
        t.retiredAt != null ||
        (approved && t.approvedAt == null)) {
      throw const ValidationFailure(
        'A current, clinic-approved matching document policy is required for issuance.',
      );
    }
    return t;
  }

  Map<String, Object?> _content(
    Map<String, Object?> input,
    DocumentTemplateRow t,
  ) {
    final type = ExportDocument.values.byName(t.documentType);
    DocumentRules.validatePolicy(
      type,
      DisclosureProfile.values.byName(t.disclosureProfile),
      t.clinicalSignatureRequired,
      t.wording,
    );
    if (type != ExportDocument.sickLeaveCertificate) {
      final fields = DocumentRules.sourced(type)
          ? {'sourceId'}
          : type == ExportDocument.fitnessCertificate
          ? {'activity', 'assessment', 'restrictions'}
          : <String>{};
      if (input.keys.toSet().difference(fields).isNotEmpty ||
          !input.keys.toSet().containsAll(fields) ||
          input.values.any(
            (v) => v is! String || v.trim().isEmpty || v.length > 2000,
          )) {
        throw const ValidationFailure(
          'Complete the required source or assessment fields; unrelated data is not allowed.',
        );
      }
      return {
        for (final key in fields.toList()..sort())
          key: (input[key] as String).trim(),
      };
    }
    final external = t.disclosureProfile != DisclosureProfile.clinic.name;
    final allowed = {'leaveStart', 'leaveEnd', if (!external) 'diagnosis'};
    if (!allowed.containsAll(input.keys) ||
        input.values.any((v) => v is! String)) {
      throw const ValidationFailure(
        'Only leave dates and clinic-copy diagnosis are allowed.',
      );
    }
    final start = DateTime.tryParse(input['leaveStart'] as String? ?? '');
    final end = DateTime.tryParse(input['leaveEnd'] as String? ?? '');
    bool dateOnly(String key, DateTime? date) =>
        date != null &&
        (input[key] == date.toIso8601String() ||
            input[key] == date.toIso8601String().split('T').first) &&
        date.hour == 0 &&
        date.minute == 0 &&
        date.second == 0 &&
        date.millisecond == 0 &&
        date.microsecond == 0;
    if (start == null ||
        end == null ||
        end.isBefore(start) ||
        !dateOnly('leaveStart', start) ||
        !dateOnly('leaveEnd', end) ||
        (input['diagnosis'] as String? ?? '').length > 300) {
      throw const ValidationFailure(
        'Enter valid leave dates in order and a diagnosis of at most 300 characters.',
      );
    }
    return {
      'leaveStart': start.toIso8601String(),
      'leaveEnd': end.toIso8601String(),
      if (!external && input.containsKey('diagnosis'))
        'diagnosis': (input['diagnosis'] as String).trim(),
    };
  }

  Future<void> _subject(String patientId, String? appointmentId) async {
    final patient = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(patientId))).getSingleOrNull();
    final visit = await (_db.select(
      _db.appointments,
    )..where((a) => a.id.equals(appointmentId ?? ''))).getSingleOrNull();
    if (patient == null ||
        patient.role != UserRole.patient ||
        visit == null ||
        visit.patientId != patientId) {
      throw const ValidationFailure(
        'Select the patient and a visit belonging to that patient.',
      );
    }
  }

  Future<void> _prepareAuthority(DocumentRequestRow r) async {
    await _actor();
    await _access.requireScoped(
      Permission.prepareDocument,
      patientId: r.patientId,
      appointmentId: r.appointmentId,
    );
    final t = await (_db.select(
      _db.documentTemplates,
    )..where((t) => t.id.equals(r.templateId))).getSingle();
    if (t.clinicalSignatureRequired &&
        t.disclosureProfile == 'clinic' &&
        !await _access.canRead(r.patientId)) {
      await _sign(r);
    }
  }

  Future<void> _sign(DocumentRequestRow r) async {
    await _actor();
    await _subject(r.patientId, r.appointmentId);
    final t = await (_db.select(
      _db.documentTemplates,
    )..where((t) => t.id.equals(r.templateId))).getSingle();
    if (t.documentType == ExportDocument.financeStatement.name) {
      await _access.require(Permission.manageBilling);
    }
    if (t.clinicalSignatureRequired) {
      await _access.requireClinicalDocumentSigner(
        patientId: r.patientId,
        appointmentId: r.appointmentId!,
      );
    } else {
      await _access.requireScoped(
        Permission.issueAdministrativeDocument,
        patientId: r.patientId,
        appointmentId: r.appointmentId,
      );
    }
    if (t.documentType == ExportDocument.financeStatement.name) {
      await _access.require(Permission.manageBilling);
    }
  }

  void _expected(DocumentRequestRow r, int expected) {
    if (r.version != expected) {
      throw ConflictFailure(
        'Request changed. Reload before continuing.',
        currentVersion: r.version,
      );
    }
  }

  Future<void> _audit(String action, DocumentRequestRow r) => _access.audit(
    action,
    entityType: 'document_request',
    entityId: r.id,
    subjectPatientId: r.patientId,
  );

  Map<String, Object?> _requestInput(
    DocumentRequestRow r,
    DocumentTemplateRow t,
  ) => _content(
    Map<String, Object?>.from(jsonDecode(r.contentJson) as Map)
      ..remove('_approvalFingerprint'),
    t,
  );

  @override
  Future<Result<void>> releaseSource(
    String recordId, {
    required bool released,
    required String reason,
  }) => Result.guardAsync(() async {
    await _actor();
    if (reason.trim().isEmpty || reason.length > 1000) {
      throw const ValidationFailure('Enter a release or withholding reason.');
    }
    final sources = DocumentSources(_db);
    final source = await sources.record(recordId);
    if (!{'labResult', 'imaging'}.contains(source['recordType']) ||
        source['appointmentId'] == null) {
      throw const ValidationFailure(
        'Select a visit-linked clinic laboratory or imaging result.',
      );
    }
    final patient = source['patientId']! as String;
    final visit = source['appointmentId']! as String;
    if (released && source['recordType'] == 'labResult') {
      final values = source['values']! as List;
      if (values.isEmpty ||
          values.any((v) => (v as Map)['verified'] == 'unverified')) {
        throw const ValidationFailure(
          'Verify the laboratory values before releasing the report.',
        );
      }
    }
    await _access.requireClinicalDocumentSigner(
      patientId: patient,
      appointmentId: visit,
    );
    await _access.requireRecentAuthentication();
    if (!released) {
      await _access.requireScoped(
        Permission.revokeDocument,
        patientId: patient,
        appointmentId: visit,
      );
    }
    await _db.transaction(() async {
      final current = await sources.record(recordId);
      if (DocumentSources.fingerprint(current) !=
          DocumentSources.fingerprint(source)) {
        throw const ConflictFailure('Result changed. Review it again.');
      }
      await _access.audit(
        released ? 'document.source.release' : 'document.source.withhold',
        entityType: 'document_source_release',
        entityId: recordId,
        subjectPatientId: patient,
        detail: jsonEncode({
          'reason': reason.trim(),
          'fingerprint': DocumentSources.fingerprint(source),
        }),
      );
      if (!released) {
        final versions =
            await (_db.select(_db.issuedDocumentVersions)..where(
                  (v) =>
                      v.patientId.equals(patient) &
                      v.documentType.isIn([
                        'releasedLabReport',
                        'releasedImagingReport',
                      ]),
                ))
                .get();
        for (final version in versions) {
          if ((jsonDecode(version.contentJson) as Map)['sourceId'] ==
              recordId) {
            _value(
              await _verification.revokeIssuedVersion(
                version.id,
                reason: reason.trim(),
              ),
            );
          }
        }
      }
    });
  });

  @override
  Stream<List<IssuedDocument>> watchForPatient(String patientId) =>
      authorizedStream(
        () async {
          await _actor();
          await _access.readPatient(patientId);
        },
        () => _db
            .customSelect(
              'SELECT v.id FROM issued_document_versions v '
              'JOIN document_artifacts a ON a.issued_version_id = v.id '
              'JOIN document_verifications d ON d.issued_version_id = v.id '
              'JOIN document_delivery_events e ON e.issued_version_id = v.id '
              'WHERE v.patient_id = ? ORDER BY v.issued_at DESC',
              variables: [Variable.withString(patientId)],
              readsFrom: {
                _db.issuedDocumentVersions,
                _db.documentArtifacts,
                _db.documentVerifications,
                _db.documentDeliveryEvents,
              },
            )
            .watch()
            .asyncMap((rows) async {
              await _actor();
              await _access.readPatient(patientId);
              final documents = <IssuedDocument>[];
              for (final row in rows) {
                final version = await _version(row.read<String>('id'));
                final scope = version.documentType == 'financeStatement'
                    ? PatientDataScope.financial
                    : PatientDataScope.clinical;
                if (await _access.canRead(patientId, scope: scope)) {
                  documents.add(await _issued(version.id));
                }
              }
              await _access.readPatient(patientId);
              return documents;
            }),
      );

  @override
  Future<Result<DocumentWorkspace>> workspace(
    String patientId,
  ) => Result.guardAsync(() async {
    final actor = await _actor();
    if (actor.isPatient) throw const AccessDeniedFailure();
    await _access.readPatient(
      patientId,
      scope: PatientDataScope.administrative,
    );
    final clinical = await _access.canRead(patientId);
    final financial = actor.isAdmin && actor.can(Permission.manageBilling);
    final visits =
        await (_db.select(_db.appointments)
              ..where((a) => a.patientId.equals(patientId))
              ..orderBy([(a) => OrderingTerm.desc(a.slotStart)]))
            .get();
    // Evaluate actual visit scope, including department grants. A workspace
    // never broadens a grant to other visits or exposes clinic-copy content.
    final preparation = <String>{};
    final reprint = <String>{};
    for (final visit in visits) {
      try {
        await _access.requireScoped(
          Permission.prepareDocument,
          patientId: patientId,
          appointmentId: visit.id,
        );
        preparation.add(visit.id);
      } on AccessDeniedFailure {
        /* Not a preparation visit. */
      }
      try {
        await _access.requireScoped(
          Permission.reprintApprovedDocument,
          patientId: patientId,
          appointmentId: visit.id,
        );
        reprint.add(visit.id);
      } on AccessDeniedFailure {
        /* Not a reprint visit. */
      }
    }
    if (!clinical && preparation.isEmpty && reprint.isEmpty) {
      throw const AccessDeniedFailure(
        'A patient-scoped document grant is required.',
      );
    }
    final templates =
        await (_db.select(_db.documentTemplates)..where(
              (t) => t.documentType.isIn(
                DocumentRules.supported.map((t) => t.name),
              ),
            ))
            .get();
    final visibleTemplates = templates
        .where(
          (t) =>
              (t.documentType != 'financeStatement' || financial) &&
              (!t.clinicalSignatureRequired ||
                  clinical ||
                  t.disclosureProfile != 'clinic'),
        )
        .toList();
    final allowedTemplateIds = visibleTemplates.map((t) => t.id).toSet();
    final requests =
        await (_db.select(_db.documentRequests)
              ..where((r) => r.patientId.equals(patientId))
              ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
            .get();
    final visibleRequests = requests
        .where(
          (r) =>
              allowedTemplateIds.contains(r.templateId) &&
              (clinical || preparation.contains(r.appointmentId)),
        )
        .toList();
    final versions =
        await (_db.select(_db.issuedDocumentVersions)
              ..where((v) => v.patientId.equals(patientId))
              ..orderBy([(v) => OrderingTerm.desc(v.issuedAt)]))
            .get();
    final requestVisits = {for (final r in requests) r.id: r.appointmentId};
    final issued = <IssuedDocument>[];
    for (final v in versions) {
      if ((v.documentType != 'financeStatement' || financial) &&
          (clinical ||
              ((!DocumentRules.clinical(
                        ExportDocument.values.byName(v.documentType),
                      ) ||
                      v.disclosureProfile != 'clinic') &&
                  reprint.contains(requestVisits[v.requestId])))) {
        issued.add(await _issued(v.id));
      }
    }
    final patient = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(patientId))).getSingle();
    await _actor();
    final sourceChoices = <DocumentSourceChoice>[];
    if (clinical) {
      final records =
          await (_db.select(_db.medicalRecords)..where(
                (r) =>
                    r.patientId.equals(patientId) &
                    r.uploadedByPatient.equals(false) &
                    r.authorStaffId.isNotNull(),
              ))
              .get();
      for (final record in records) {
        final type = switch (record.recordType) {
          RecordType.referral => ExportDocument.referralLetter,
          RecordType.prescription => ExportDocument.prescriptionCopy,
          RecordType.labResult => ExportDocument.releasedLabReport,
          RecordType.imaging => ExportDocument.releasedImagingReport,
          _ => null,
        };
        if (type != null && record.appointmentId != null) {
          final source = await DocumentSources(_db).record(record.id);
          sourceChoices.add(
            DocumentSourceChoice(
              record.id,
              record.appointmentId!,
              type,
              record.title,
              released: await DocumentSources(_db).released(source),
            ),
          );
        }
      }
    }
    if (financial) {
      final invoices =
          await (_db.select(_db.invoices)..where(
                (i) =>
                    i.patientId.equals(patientId) & i.appointmentId.isNotNull(),
              ))
              .get();
      for (final invoice in invoices) {
        sourceChoices.add(
          DocumentSourceChoice(
            invoice.id,
            invoice.appointmentId!,
            ExportDocument.financeStatement,
            'Invoice: ${invoice.id}',
          ),
        );
      }
    }
    return DocumentWorkspace(
      patientName: patient.fullName,
      visits: [
        for (final v in visits)
          if (clinical || preparation.contains(v.id) || reprint.contains(v.id))
            DocumentVisit(v.id, v.slotStart),
      ],
      templates: [
        for (final t in visibleTemplates.where((t) => t.retiredAt == null))
          DocumentTemplateChoice(
            t.id,
            t.language,
            DisclosureProfile.values.byName(t.disclosureProfile),
            t.approvedAt != null,
            documentType: ExportDocument.values.byName(t.documentType),
          ),
      ],
      requests: [
        for (final r in visibleRequests)
          DocumentReviewItem(
            _model(r),
            r.appointmentId!,
            Map<String, Object?>.from(jsonDecode(r.contentJson) as Map),
          ),
      ],
      issued: issued,
      sources: sourceChoices,
    );
  });

  @override
  Future<Result<Uint8List>> preview(String requestId) =>
      Result.guardAsync(() async {
        final r = await _request(requestId);
        await _prepareAuthority(r);
        final t = await _template(r.templateId);
        final patient = await (_db.select(
          _db.users,
        )..where((u) => u.id.equals(r.patientId))).getSingle();
        final visit = await (_db.select(
          _db.appointments,
        )..where((v) => v.id.equals(r.appointmentId!))).getSingle();
        final normalized = _requestInput(r, t);
        final content = {
          ...normalized,
          ...await DocumentSources(_db).resolve(
            r.patientId,
            r.appointmentId!,
            ExportDocument.values.byName(t.documentType),
            normalized,
            language: t.language,
          ),
        };
        final fields = {
          'clinicName': await _clinicName(),
          'patientName': patient.fullName,
          'visitDate': visit.slotStart.toIso8601String().split('T').first,
          ...content,
          if (content['leaveStart'] != null)
            'leaveStart': (content['leaveStart'] as String).split('T').first,
          if (content['leaveEnd'] != null)
            'leaveEnd': (content['leaveEnd'] as String).split('T').first,
          'diagnosis': content['diagnosis'] ?? '',
          'issuerName': 'DRAFT',
          'license': 'DRAFT',
          'verificationCode': 'DRAFT',
        };
        final wording = t.wording.replaceAllMapped(
          RegExp(r'\{([^{}]+)\}'),
          (m) => fields[m[1]]?.toString() ?? 'DRAFT',
        );
        final bytes = await _renderer.render(
          wording: wording,
          clinicName: await _clinicName(),
          language: t.language,
          title: DocumentRules.title(
            ExportDocument.values.byName(t.documentType),
            arabic: t.language == 'ar',
          ),
          reference: 'DRAFT',
          issuedAt: r.createdAt,
          draft: true,
        );
        await _prepareAuthority(r);
        return bytes;
      });

  @override
  Future<Result<DocumentRequest>> prepare(PrepareDocument input) =>
      Result.guardAsync(() async {
        if (!DocumentRules.supported.contains(input.documentType)) {
          throw const ValidationFailure(
            'This document type is not supported by the issuance workflow.',
          );
        }
        final actor = await _actor();
        await _access.requireScoped(
          Permission.prepareDocument,
          patientId: input.patientId,
          appointmentId: input.appointmentId,
        );
        await _subject(input.patientId, input.appointmentId);
        final template = await _template(input.templateId);
        if (template.clinicalSignatureRequired &&
            template.disclosureProfile == 'clinic' &&
            !await _access.canRead(input.patientId)) {
          await _access.requireClinicalDocumentSigner(
            patientId: input.patientId,
            appointmentId: input.appointmentId,
          );
        }
        if (template.documentType != input.documentType.name) {
          throw const ValidationFailure(
            'Selected policy and document type must match.',
          );
        }
        if (input.documentType == ExportDocument.financeStatement) {
          await _access.require(Permission.manageBilling);
        }
        final normalized = _content(input.content, template);
        await DocumentSources(_db).resolve(
          input.patientId,
          input.appointmentId,
          input.documentType,
          normalized,
          language: template.language,
        );
        final content = jsonEncode(normalized);
        if (input.idempotencyKey.trim().isEmpty) {
          throw const ValidationFailure('A retry key is required.');
        }
        return _db.transaction(() async {
          final existing =
              await (_db.select(_db.documentRequests)..where(
                    (r) => r.idempotencyKey.equals(input.idempotencyKey),
                  ))
                  .getSingleOrNull();
          if (existing != null) {
            if (existing.patientId != input.patientId ||
                existing.appointmentId != input.appointmentId ||
                existing.templateId != input.templateId ||
                existing.requestedBy != actor.accountId ||
                jsonEncode(_requestInput(existing, template)) != content) {
              throw const ConflictFailure(
                'Retry key belongs to a different request.',
              );
            }
            return _model(existing);
          }
          final id = _uuid.v4();
          final now = DateTime.now();
          await _db
              .into(_db.documentRequests)
              .insert(
                DocumentRequestsCompanion.insert(
                  id: id,
                  patientId: input.patientId,
                  appointmentId: Value(input.appointmentId),
                  templateId: input.templateId,
                  requestedBy: actor.accountId,
                  contentJson: content,
                  idempotencyKey: input.idempotencyKey,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
          final r = await _request(id);
          await _audit('document.prepare', r);
          return _model(r);
        });
      });

  @override
  Future<Result<DocumentRequest>> prepareReplacement(
    String issuedVersionId, {
    required int expectedVersion,
    required Map<String, Object?> content,
    required String reason,
    String? templateId,
  }) => Result.guardAsync(() async {
    if (reason.trim().isEmpty || reason.trim().length > 300) {
      throw const ValidationFailure(
        'Enter a replacement reason of at most 300 characters.',
      );
    }
    return _db.transaction(() async {
      final previous = await _version(issuedVersionId);
      final r = await _request(previous.requestId);
      await _prepareAuthority(r);
      _expected(r, expectedVersion);
      final latest =
          await (_db.select(_db.issuedDocumentVersions)
                ..where((v) => v.requestId.equals(r.id))
                ..orderBy([(v) => OrderingTerm.desc(v.version)])
                ..limit(1))
              .getSingle();
      if (r.status != 'issued' || latest.id != previous.id) {
        throw const ConflictFailure(
          'Reload the latest issued version before preparing a correction.',
        );
      }
      final t = await _template(templateId ?? r.templateId);
      if (t.disclosureProfile != previous.disclosureProfile ||
          t.documentType != previous.documentType) {
        throw const ValidationFailure(
          'A replacement must retain the original disclosure audience.',
        );
      }
      final validated = _content(content, t);
      await (_db.update(
        _db.documentRequests,
      )..where((r) => r.id.equals(previous.requestId))).write(
        DocumentRequestsCompanion(
          status: const Value('draft'),
          templateId: Value(t.id),
          contentJson: Value(jsonEncode(validated)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _access.audit(
        'document.replacement.prepare',
        entityType: 'document_request',
        entityId: r.id,
        subjectPatientId: r.patientId,
        detail: jsonEncode({
          'supersedesId': previous.id,
          'reason': reason.trim(),
        }),
      );
      return _model(await _request(r.id));
    });
  });

  @override
  Future<Result<DocumentRequest>> submit(
    String requestId, {
    required int expectedVersion,
  }) => Result.guardAsync(() async {
    final r = await _request(requestId);
    await _prepareAuthority(r);
    return _db.transaction(() async {
      final current = await _request(requestId);
      _expected(current, expectedVersion);
      if (current.status != 'draft') {
        throw const ConflictFailure('Only drafts can be submitted.');
      }
      await (_db.update(
        _db.documentRequests,
      )..where((t) => t.id.equals(requestId))).write(
        DocumentRequestsCompanion(
          status: const Value('submitted'),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _audit('document.submit', current);
      return _model(await _request(requestId));
    });
  });

  @override
  Future<Result<DocumentRequest>> approve(
    String requestId, {
    required int expectedVersion,
  }) => Result.guardAsync(() async {
    await _sign(await _request(requestId));
    return _db.transaction(() async {
      final r = await _request(requestId);
      await _sign(r);
      _expected(r, expectedVersion);
      if (r.status != 'submitted') {
        throw const ConflictFailure(
          'Submit this draft for clinical review first.',
        );
      }
      final t = await _template(r.templateId, approved: true);
      final normalized = _requestInput(r, t);
      final resolved = await DocumentSources(_db).resolve(
        r.patientId,
        r.appointmentId!,
        ExportDocument.values.byName(t.documentType),
        normalized,
        language: t.language,
      );
      await (_db.update(
        _db.documentRequests,
      )..where((t) => t.id.equals(requestId))).write(
        DocumentRequestsCompanion(
          status: const Value('approved'),
          contentJson: Value(
            jsonEncode({
              ...normalized,
              '_approvalFingerprint': DocumentSources.fingerprint(resolved),
            }),
          ),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _audit('document.approve', r);
      return _model(await _request(requestId));
    });
  });

  @override
  Future<Result<IssuedDocument>> issue(
    String requestId, {
    required int expectedVersion,
    required String idempotencyKey,
  }) => Result.guardAsync(() async {
    await _sign(await _request(requestId));
    if (idempotencyKey.trim().isEmpty) {
      throw const ValidationFailure('A retry key is required.');
    }
    return _db.transaction(() async {
      final r = await _request(requestId);
      await _sign(r);
      final actor = await _actor();
      final existing =
          await (_db.select(_db.issuedDocumentVersions)
                ..where((v) => v.idempotencyKey.equals(idempotencyKey)))
              .getSingleOrNull();
      if (existing != null) {
        if (existing.requestId != r.id ||
            existing.issuerAccountId != actor.accountId) {
          throw const ConflictFailure('Retry key belongs to another issuance.');
        }
        return _issued(existing.id);
      }
      _expected(r, expectedVersion);
      if (r.status != 'approved') {
        throw const ConflictFailure('Only an approved request can be issued.');
      }
      final t = await _template(r.templateId, approved: true);
      final normalized = _requestInput(r, t);
      final resolved = await DocumentSources(_db).resolve(
        r.patientId,
        r.appointmentId!,
        ExportDocument.values.byName(t.documentType),
        normalized,
        language: t.language,
      );
      if ((jsonDecode(r.contentJson) as Map)['_approvalFingerprint'] !=
          DocumentSources.fingerprint(resolved)) {
        throw const ConflictFailure(
          'Source changed after approval. Prepare a new reviewed request.',
        );
      }
      final content = {...normalized, ...resolved};
      final patient = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(r.patientId))).getSingle();
      final issuer = await (_db.select(
        _db.users,
      )..where((u) => u.id.equals(actor.accountId))).getSingle();
      final now = DateTime.now();
      final issuerSnapshot = <String, Object?>{
        'accountId': issuer.id,
        'name': issuer.fullName,
      };
      if (t.clinicalSignatureRequired) {
        final profile = await (_db.select(
          _db.staffProfiles,
        )..where((s) => s.userId.equals(actor.accountId))).getSingle();
        final credentials =
            await (_db.select(_db.staffCredentials)..where(
                  (c) =>
                      c.staffId.equals(actor.accountId) &
                      c.kind.equalsValue(CredentialKind.medicalLicense) &
                      c.revokedAt.isNull() &
                      c.verifiedAt.isSmallerOrEqualValue(now) &
                      (c.validUntil.isNull() |
                          c.validUntil.isBiggerThanValue(now)),
                ))
                .get();
        final credential = credentials.firstWhere(
          (c) => c.identifier.trim().isNotEmpty,
          orElse: () => throw const AccessDeniedFailure(
            'A current verified medical licence is required.',
          ),
        );
        issuerSnapshot.addAll({
          'jobTitle': profile.jobTitle,
          'specialty': profile.specialty,
          'license': credential.identifier,
          'credentialId': credential.id,
          'credentialIssuer': credential.issuer,
          'verifiedAt': credential.verifiedAt!.toIso8601String(),
          'validUntil': credential.validUntil?.toIso8601String(),
        });
      }
      final visit = await (_db.select(
        _db.appointments,
      )..where((v) => v.id.equals(r.appointmentId!))).getSingle();
      final previous =
          await (_db.select(_db.issuedDocumentVersions)
                ..where((v) => v.requestId.equals(r.id))
                ..orderBy([(v) => OrderingTerm.desc(v.version)])
                ..limit(1))
              .getSingleOrNull();
      final id = _uuid.v4();
      await _db
          .into(_db.issuedDocumentVersions)
          .insert(
            IssuedDocumentVersionsCompanion.insert(
              id: id,
              requestId: r.id,
              patientId: r.patientId,
              templateId: t.id,
              version: (previous?.version ?? 0) + 1,
              supersedesId: Value(previous?.id),
              documentType: t.documentType,
              language: t.language,
              disclosureProfile: t.disclosureProfile,
              patientSnapshotJson: jsonEncode({
                'id': patient.id,
                'name': patient.fullName,
              }),
              issuerSnapshotJson: jsonEncode(issuerSnapshot),
              contentJson: jsonEncode({
                ...content,
                'visitDate': visit.slotStart.toIso8601String(),
              }),
              templateSnapshotJson: jsonEncode({
                'wording': t.wording,
                'version': t.version,
                'approvedBy': t.approvedBy,
                'approvedAt': t.approvedAt!.toIso8601String(),
                'clinicName': await _clinicName(),
                'externalToken': base64UrlEncode(
                  List<int>.generate(32, (_) => _random.nextInt(256)),
                ).replaceAll('=', ''),
                'externalBase': await _externalBase(),
              }),
              issuerAccountId: actor.accountId,
              idempotencyKey: idempotencyKey,
              issuedAt: now,
            ),
          );
      // Registration errors must escape, rolling back every issuance write.
      _value(await _verification.bindIssuedVersion(id));
      if (t.documentType == ExportDocument.sickLeaveCertificate.name) {
        await _db
            .into(_db.sickLeaveCertificates)
            .insert(
              SickLeaveCertificatesCompanion.insert(
                id: id,
                patientId: r.patientId,
                issuedByStaffId: actor.accountId,
                appointmentId: Value(r.appointmentId),
                diagnosis: content['diagnosis'] as String? ?? 'Sick leave',
                fromDate: DateTime.parse(content['leaveStart']! as String),
                toDate: DateTime.parse(content['leaveEnd']! as String),
                issuedAt: Value(now),
              ),
            );
      }
      await _db
          .into(_db.documentArtifacts)
          .insert(DocumentArtifactsCompanion.insert(issuedVersionId: id));
      await _db
          .into(_db.documentDeliveryEvents)
          .insert(
            DocumentDeliveryEventsCompanion.insert(
              id: _uuid.v4(),
              issuedVersionId: id,
              recipientAccountId: patient.id,
              channel: 'inApp',
              createdAt: now,
            ),
          );
      await (_db.update(
        _db.documentRequests,
      )..where((t) => t.id.equals(r.id))).write(
        DocumentRequestsCompanion(
          status: const Value('issued'),
          updatedAt: Value(now),
        ),
      );
      await _access.audit(
        'document.issue',
        entityType: 'issued_document',
        entityId: id,
        subjectPatientId: r.patientId,
        detail: previous == null
            ? null
            : jsonEncode({'supersedesId': previous.id}),
      );
      return _issued(id);
    });
  });

  Future<IssuedDocument> _issued(String id) async {
    final v = await _version(id);
    final code = await (_db.select(
      _db.documentVerifications,
    )..where((t) => t.issuedVersionId.equals(id))).getSingle();
    final artifact = await (_db.select(
      _db.documentArtifacts,
    )..where((t) => t.issuedVersionId.equals(id))).getSingle();
    final delivery =
        await (_db.select(_db.documentDeliveryEvents)..where(
              (t) => t.issuedVersionId.equals(id) & t.channel.equals('inApp'),
            ))
            .getSingle();
    return IssuedDocument(
      id: id,
      patientId: v.patientId,
      verificationCode: code.code,
      validity: DocumentValidity.values.byName(code.validity),
      renderStatus: DocumentRenderStatus.values.byName(artifact.status),
      deliveryStatus: delivery.status,
      deliveryAttempts: delivery.attempt,
      requestId: v.requestId,
      supersedesId: v.supersedesId,
      documentType: ExportDocument.values.byName(v.documentType),
      language: v.language,
      issuedAt: v.issuedAt,
    );
  }

  Future<void> _read(IssuedDocumentVersionRow v) async {
    final actor = await _actor();
    if (v.documentType == 'financeStatement') {
      await _access.readPatient(v.patientId, scope: PatientDataScope.financial);
      if (actor.isPatient) return;
      await _access.require(Permission.manageBilling);
      final request = await _request(v.requestId);
      if (actor.accountId == v.issuerAccountId) {
        await _sign(request);
        return;
      }
      await _access.requireScoped(
        Permission.reprintApprovedDocument,
        patientId: v.patientId,
        appointmentId: request.appointmentId,
      );
      return;
    }
    if (await _access.canRead(v.patientId)) return;
    if (!actor.isPatient && actor.accountId == v.issuerAccountId) {
      await _sign(await _request(v.requestId));
      return;
    }
    // A reprint grant exposes the minimal external copy, never a clinic copy.
    if (actor.isPatient ||
        (v.disclosureProfile == 'clinic' &&
            DocumentRules.clinical(
              ExportDocument.values.byName(v.documentType),
            ))) {
      throw const AccessDeniedFailure();
    }
    final r = await _request(v.requestId);
    await _access.requireScoped(
      Permission.reprintApprovedDocument,
      patientId: v.patientId,
      appointmentId: r.appointmentId,
    );
  }

  String? _verificationUrl(IssuedDocumentVersionRow version) {
    final snapshot = jsonDecode(version.templateSnapshotJson) as Map;
    final origin = snapshot['externalBase'];
    final token = snapshot['externalToken'];
    return origin is String && origin.isNotEmpty && token is String
        ? '$origin/v/$token'
        : null;
  }

  String _wording(IssuedDocumentVersionRow v, String code) {
    final patient = jsonDecode(v.patientSnapshotJson) as Map;
    final issuer = jsonDecode(v.issuerSnapshotJson) as Map;
    final content = Map<String, Object?>.from(jsonDecode(v.contentJson) as Map);
    final template = jsonDecode(v.templateSnapshotJson) as Map;
    final fields = <String, Object?>{
      'clinicName': template['clinicName'],
      'patientName': patient['name'],
      'issuerName': issuer['name'],
      'license': issuer['license'] ?? '',
      ...content,
      'verificationCode': code,
      'diagnosis': content['diagnosis'] ?? '',
      for (final key in ['visitDate', 'leaveStart', 'leaveEnd'])
        if (content[key] != null)
          key: (content[key] as String).split('T').first,
    };
    return (template['wording'] as String).replaceAllMapped(
      RegExp(r'\{([^{}]+)\}'),
      (m) =>
          fields[m[1]]?.toString() ??
          (throw const ValidationFailure(
            'Template contains an unsupported field.',
          )),
    );
  }

  @override
  Future<Result<IssuedDocument>> render(
    String issuedVersionId,
  ) => Result.guardAsync(() async {
    final v = await _version(issuedVersionId);
    await _read(v);
    final initial = await _issued(v.id);
    if (initial.validity != DocumentValidity.valid) {
      throw const ConflictFailure('This version is no longer valid.');
    }
    if (initial.renderStatus != DocumentRenderStatus.ready) {
      Uint8List bytes;
      try {
        bytes = await _renderer.render(
          wording: _wording(v, initial.verificationCode),
          clinicName:
              (jsonDecode(v.templateSnapshotJson)
                      as Map<String, dynamic>)['clinicName']
                  as String? ??
              'MyHealth Care',
          language: v.language,
          reference: initial.verificationCode,
          title: DocumentRules.title(
            ExportDocument.values.byName(v.documentType),
            arabic: v.language == 'ar',
          ),
          verificationUrl: _verificationUrl(v),
          issuedAt: v.issuedAt,
        );
        if (bytes.isEmpty) {
          throw const ValidationFailure('Renderer returned an empty document.');
        }
      } catch (_) {
        await _read(v);
        await (_db.update(_db.documentArtifacts)..where(
              (a) =>
                  a.issuedVersionId.equals(v.id) &
                  a.status.equals('ready').not(),
            ))
            .write(
              const DocumentArtifactsCompanion(
                status: Value('failed'),
                failure: Value('PDF generation failed. Retry rendering.'),
              ),
            );
        throw const ValidationFailure(
          'PDF generation failed. The certificate was issued once; retry rendering.',
        );
      }
      await _db.transaction(() async {
        await _read(v);
        if ((await _issued(v.id)).validity != DocumentValidity.valid) {
          throw const ConflictFailure('This version is no longer valid.');
        }
        final changed =
            await (_db.update(_db.documentArtifacts)..where(
                  (a) =>
                      a.issuedVersionId.equals(v.id) &
                      a.status.equals('ready').not(),
                ))
                .write(
                  DocumentArtifactsCompanion(
                    status: const Value('ready'),
                    bytes: Value(bytes),
                    sha256: Value(crypto.sha256.convert(bytes).toString()),
                    failure: const Value(null),
                    renderedAt: Value(DateTime.now()),
                  ),
                );
        if (changed > 0) {
          await _access.audit(
            'document.render',
            entityType: 'issued_document',
            entityId: v.id,
            subjectPatientId: v.patientId,
          );
        }
      });
    }
    _value(await deliver(v.id));
    return _issued(v.id);
  });

  /// In-app delivery retries never issue, render or download another copy.
  @override
  Future<Result<void>> deliver(String id) => Result.guardAsync(() async {
    final v = await _version(id);
    await _read(v);
    final eventId = await _db.transaction(() async {
      final issued = await _issued(id);
      if (issued.validity != DocumentValidity.valid ||
          issued.renderStatus != DocumentRenderStatus.ready) {
        throw const ConflictFailure('Delivery requires a ready, valid PDF.');
      }
      final event =
          await (_db.select(_db.documentDeliveryEvents)..where(
                (e) => e.issuedVersionId.equals(id) & e.channel.equals('inApp'),
              ))
              .getSingle();
      if (event.status == 'sent') return null;
      await (_db.update(
        _db.documentDeliveryEvents,
      )..where((e) => e.id.equals(event.id))).write(
        DocumentDeliveryEventsCompanion(
          attempt: Value(event.attempt + 1),
          attemptedAt: Value(DateTime.now()),
        ),
      );
      return event.id;
    });
    if (eventId == null) return;
    try {
      await _db.transaction(() async {
        await _read(v);
        final issued = await _issued(id);
        if (issued.validity != DocumentValidity.valid) {
          throw const ConflictFailure('This version is no longer valid.');
        }
        final event = await (_db.select(
          _db.documentDeliveryEvents,
        )..where((e) => e.id.equals(eventId))).getSingle();
        if (event.status == 'sent') return;
        await _db
            .into(_db.notifications)
            .insert(
              NotificationsCompanion.insert(
                id: _uuid.v4(),
                recipientId: event.recipientAccountId,
                category: NotificationCategory.system,
                title: v.language == 'ar'
                    ? 'وثيقة صادرة جاهزة'
                    : 'Issued document ready',
                body: v.language == 'ar'
                    ? 'النسخة الصادرة متاحة في الوثائق.'
                    : 'Your issued copy is available in Documents.',
                deepLink: Value(
                  '/patient/timeline/documents?patientId=${Uri.encodeQueryComponent(v.patientId)}',
                ),
                sourceEventId: Value(event.id),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        await (_db.update(
          _db.documentDeliveryEvents,
        )..where((e) => e.id.equals(event.id))).write(
          const DocumentDeliveryEventsCompanion(
            status: Value('sent'),
            failure: Value(null),
          ),
        );
        await _access.audit(
          'document.deliver',
          entityType: 'issued_document',
          entityId: id,
          subjectPatientId: v.patientId,
        );
      });
    } catch (_) {
      await (_db.update(
            _db.documentDeliveryEvents,
          )..where((e) => e.id.equals(eventId) & e.status.equals('sent').not()))
          .write(
            const DocumentDeliveryEventsCompanion(
              status: Value('failed'),
              failure: Value(
                'In-app delivery failed. Retry notification delivery.',
              ),
            ),
          );
      throw const ValidationFailure(
        'PDF is ready. Notification delivery failed; retry delivery.',
      );
    }
  });

  @override
  Future<Result<Uint8List>> download(String issuedVersionId) =>
      Result.guardAsync(() async {
        await _read(await _version(issuedVersionId));
        return _db.transaction(() async {
          final v = await _version(issuedVersionId);
          await _read(v);
          final issued = await _issued(v.id);
          if (issued.validity != DocumentValidity.valid ||
              issued.renderStatus != DocumentRenderStatus.ready) {
            throw const ConflictFailure(
              'A valid, ready official copy is required.',
            );
          }
          final a = await (_db.select(
            _db.documentArtifacts,
          )..where((a) => a.issuedVersionId.equals(v.id))).getSingle();
          final bytes = a.bytes;
          if (bytes == null ||
              crypto.sha256.convert(bytes).toString() != a.sha256) {
            throw const ValidationFailure(
              'Stored copy failed its integrity check.',
            );
          }
          await _read(v);
          await _access.audit(
            'document.download',
            entityType: 'issued_document',
            entityId: v.id,
            subjectPatientId: v.patientId,
          );
          return Uint8List.fromList(bytes);
        });
      });

  @override
  Future<Result<void>> revoke(
    String issuedVersionId, {
    required String reason,
  }) => Result.guardAsync(() async {
    await _actor();
    _value(
      await _verification.revokeIssuedVersion(issuedVersionId, reason: reason),
    );
  });
}
