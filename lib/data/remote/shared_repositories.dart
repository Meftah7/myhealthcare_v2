/// Shared-server implementations of the app's repository interfaces.
///
/// The full app runs on these when built with `SHARED_API_ORIGIN`. Every
/// method either calls the server (which re-authorizes it) or, through
/// [SharedUnavailable], fails with [SharedModeUnavailableFailure]. Nothing
/// falls back to the local database.
library;

import 'dart:async';

import '../../core/data/contracts.dart';
import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums.dart';
import '../../domain/identity/permissions.dart';
import '../../domain/identity/principal.dart';
import '../../domain/repositories/dental_chart_repository.dart';
import '../../domain/repositories/document_policy_repository.dart';
import '../../domain/repositories/document_service.dart';
import '../../domain/repositories/document_verification_repository.dart';
import '../../domain/repositories/pharmacy_repository.dart';
import '../../domain/repositories/record_activity_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/repositories/scoped_grant_repository.dart';
import '../../services/auth/auth_context.dart';
import 'shared_client.dart';

/// Any member without a server adapter fails visibly; it never touches
/// local data. Futures resolve to an [Err]; streams emit the failure.
abstract class SharedUnavailable {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    const failure = SharedModeUnavailableFailure();
    final name = invocation.memberName.toString();
    if (name.contains('"watch')) return Stream<Never>.error(failure);
    return Future<Result<Never>>.value(const Err(failure));
  }
}

/// Repositories with no shared adapter yet: every call fails visibly.
class UnavailableRecordActivityRepository extends SharedUnavailable
    implements RecordActivityRepository {}

class UnavailableScopedGrantRepository extends SharedUnavailable
    implements ScopedGrantRepository {}

class UnavailableDocumentPolicyRepository extends SharedUnavailable
    implements DocumentPolicyRepository {}

class UnavailableDocumentService extends SharedUnavailable
    implements DocumentService {}

class UnavailableFamilyLinkRepository extends SharedUnavailable
    implements FamilyLinkRepository {}

class UnavailableSickLeaveRepository extends SharedUnavailable
    implements SickLeaveRepository {}

class UnavailableHomeVisitRepository extends SharedUnavailable
    implements HomeVisitRepository {}

class UnavailableWalkInTicketRepository extends SharedUnavailable
    implements WalkInTicketRepository {}

class UnavailableDocumentVerificationRepository extends SharedUnavailable
    implements DocumentVerificationRepository {}

class UnavailableExportRepository extends SharedUnavailable
    implements ExportRepository {}

class UnavailableResultReviewRepository extends SharedUnavailable
    implements ResultReviewRepository {}

class UnavailableReferralRequestRepository extends SharedUnavailable
    implements ReferralRequestRepository {}

class RemoteReferralRequestRepository extends SharedUnavailable
    implements ReferralRequestRepository {
  RemoteReferralRequestRepository(this.client);
  final SharedClient client;
  ReferralRequest _request(Map<String, dynamic> r) => ReferralRequest(
    id: r['id'] as String,
    patientId: r['patient'] as String,
    requestedByStaffId: r['requested_by'] as String,
    reason: r['reason'] as String,
    status: ReferralRequestStatus.values.byName(r['status'] as String),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (r['created'] as num).toInt(),
      isUtc: true,
    ),
    appointmentId: r['appointment'] as String?,
    version: r['version'] as int,
  );
  @override
  Future<Result<ReferralRequest>> create(
    NewReferralRequest request, {
    IdempotencyKey? idempotencyKey,
  }) => _guard(() async {
    if (request.requestedByStaffId != client.user?['id'])
      throw const AuthFailure('Requesting clinician must be signed in.');
    return _request(
      Map<String, dynamic>.from(
        await client.request(
              '/api/workspace/referrals',
              method: 'POST',
              body: {
                'patientId': request.patientId,
                'appointmentId': request.appointmentId,
                'reason': request.reason,
                'idempotencyKey':
                    (idempotencyKey ?? IdempotencyKey.generate()).value,
              },
            )
            as Map,
      ),
    );
  });
  @override
  Future<Result<List<ReferralRequest>>> pending() => _guard(
    () async => [
      for (final r in await _list(client, '/api/workspace/referrals'))
        if (r['status'] == 'pending') _request(r),
    ],
  );
  @override
  Future<Result<List<ReferralRequest>>> forPatient(String patientId) => _guard(
    () async => [
      for (final r in await _list(client, '/api/workspace/referrals', {
        'patientId': patientId,
      }))
        _request(r),
    ],
  );
  @override
  Future<Result<ReferralRequest?>> pendingForAppointment(
    String appointmentId,
  ) => _guard(
    () async => ([
      for (final r in await _list(client, '/api/workspace/referrals', {
        'appointmentId': appointmentId,
      }))
        if (r['status'] == 'pending') _request(r),
    ]).firstOrNull,
  );
}

class UnavailableNotificationRepository extends SharedUnavailable
    implements NotificationRepository {}

class UnavailableRecordRepository extends SharedUnavailable
    implements RecordRepository {}

class UnavailableVitalsRepository extends SharedUnavailable
    implements VitalsRepository {}

class UnavailableRiskRepository extends SharedUnavailable
    implements RiskRepository {}

class UnavailableAiSummaryRepository extends SharedUnavailable
    implements AiSummaryRepository {}

class UnavailableAuditRepository extends SharedUnavailable
    implements AuditRepository {}

class UnavailableSettingsRepository extends SharedUnavailable
    implements SettingsRepository {}

class UnavailableFeedbackRepository extends SharedUnavailable
    implements FeedbackRepository {}

/// The same feedback store backs submission and administrator handling.
class RemoteFeedbackRepository implements FeedbackRepository {
  RemoteFeedbackRepository(this.client);
  final SharedClient client;
  @override
  Future<Result<void>> submit({
    required FeedbackCategory category,
    required String message,
    String? reporterId,
  }) => _guard(() async {
    if (reporterId != null && reporterId != client.user?['id'])
      throw const AuthFailure('Reporter must be the signed-in account.');
    await client.request(
      '/api/workspace/feedback-submit',
      method: 'POST',
      body: {'category': category.name, 'message': message},
    );
  });
  @override
  Future<Result<List<UserFeedback>>> all({
    FeedbackStatus? status,
  }) => _guard(() async {
    final data =
        await client.request('/api/workspace/feedback') as Map<String, dynamic>;
    return [
      for (final raw in data['rows'] as List)
        if (status == null || (raw as Map)['status'] == status.name)
          UserFeedback(
            id: (raw as Map)['id'] as String,
            category: FeedbackCategory.values.byName(raw['category'] as String),
            message: raw['message'] as String,
            status: FeedbackStatus.values.byName(raw['status'] as String),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (raw['created_at'] as num).toInt() * 1000,
              isUtc: true,
            ),
            reporterId: raw['reporter'] as String?,
            reporterName: raw['reporter_name'] as String?,
            handledByAdminId: raw['handler'] as String?,
            handledAt: raw['handled_at'] == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    (raw['handled_at'] as num).toInt() * 1000,
                    isUtc: true,
                  ),
          ),
    ];
  });
  @override
  Future<Result<void>> setStatus({
    required String id,
    required FeedbackStatus status,
    String? adminId,
  }) => _guard(() async {
    if (adminId != null && adminId != client.user?['id'])
      throw const AuthFailure('Handler must be the signed-in account.');
    final data =
        await client.request('/api/workspace/feedback') as Map<String, dynamic>;
    final item = (data['rows'] as List)
        .cast<Map<String, dynamic>>()
        .where((f) => f['id'] == id)
        .firstOrNull;
    if (item == null) throw const NotFoundFailure('Feedback unavailable.');
    await client.request(
      '/api/workspace/feedback',
      method: 'POST',
      body: {'id': id, 'status': status.name, 'version': item['version']},
    );
  });
}

class UnavailableAiUsageRepository extends SharedUnavailable
    implements AiUsageRepository {}

class UnavailableCareTeamRepository extends SharedUnavailable
    implements CareTeamRepository {}

class UnavailableStaffCredentialRepository extends SharedUnavailable
    implements StaffCredentialRepository {}

Future<Result<T>> _guard<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } on Failure catch (f) {
    return Err(f);
  } catch (e, s) {
    return Err(UnexpectedFailure.from(e, s));
  }
}

DateTime _at(Object? iso) => DateTime.parse('$iso').toLocal();
DateTime? _atOrNull(Object? iso) => iso == null ? null : _at(iso);
final _epoch = DateTime.utc(2000);

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.where((v) => v.name == name).firstOrNull ?? fallback;

User userFromJson(Map<String, dynamic> j) => User(
  id: j['id'] as String,
  role: _enum(UserRole.values, j['role'], UserRole.patient),
  fullName: j['fullName'] as String,
  email: (j['email'] as String?) ?? '',
  isActive: (j['isActive'] as bool?) ?? true,
  createdAt: _epoch,
);

Staff _staff(Map<String, dynamic> j) => Staff(
  user: userFromJson({...j, 'role': 'staff'}),
  specialty: j['specialty'] as String?,
  departmentId: j['departmentId'] as String?,
  jobTitle: StaffRole.parse(j['job'] as String?)?.jobTitle,
  presence: PresenceStatus.onDuty,
);

Appointment _appointment(Map<String, dynamic> j) {
  final status = switch (j['status']) {
    'checkedIn' => AppointmentStatus.confirmed,
    final String s => _enum(
      AppointmentStatus.values,
      s,
      AppointmentStatus.booked,
    ),
    _ => AppointmentStatus.booked,
  };
  return Appointment(
    id: j['id'] as String,
    patientId: j['patientId'] as String,
    staffId: j['staffId'] as String,
    slotStart: _at(j['start']),
    slotEnd: _at(j['end']),
    visitType: _enum(VisitType.values, j['visitType'], VisitType.followUp),
    status: status,
    bookedAt: _atOrNull(j['bookedAt']) ?? _at(j['start']),
    remindersSent: 0,
    reasonText: j['reason'] as String?,
    checkedInAt: _atOrNull(j['checkedInAt']),
    version: (j['version'] as num?)?.toInt() ?? 1,
  );
}

Future<List<Map<String, dynamic>>> _list(
  SharedClient client,
  String path, [
  Map<String, dynamic>? query,
]) async => ((await client.request(path, query: query)) as List)
    .cast<Map<String, dynamic>>();

Future<Map<String, dynamic>> _post(
  SharedClient client,
  String path,
  Map<String, dynamic> body,
) async =>
    (await client.request(path, method: 'POST', body: body))
        as Map<String, dynamic>;

// ---------------------------------------------------------------------------
// Accounts
// ---------------------------------------------------------------------------

class RemoteAuthRepository extends SharedUnavailable implements AuthRepository {
  RemoteAuthRepository(this.client, this.context);

  final SharedClient client;
  final AuthContext context;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) => _guard(() async {
    final reply = await client.login(email, password);
    final json = (reply['user'] ?? reply) as Map<String, dynamic>;
    final user = userFromJson(json);
    context.establish(
      Principal(
        accountId: user.id,
        role: user.role,
        // The same role table the server applies; the server re-checks.
        permissions: RolePermissions.forRole(
          user.role,
          staffRole: StaffRole.parse(json['job'] as String?),
        ),
        sessionId: 'shared',
        authenticatedAt: DateTime.now(),
      ),
    );
    return user;
  });

  @override
  Future<void> signOut({String reason = 'signed_out'}) async {
    context.clear();
    try {
      await client.logout();
    } on Failure {
      // The server session expires on its own; the device is signed out.
    }
  }

  @override
  Future<Result<void>> reauthenticate(String password) => _guard(() async {
    await client.request(
      '/api/reauthenticate',
      method: 'POST',
      body: {'password': password},
    );
    context.markReauthenticated();
  });
}

class RemoteUserRepository extends SharedUnavailable implements UserRepository {
  RemoteUserRepository(this.client);

  final SharedClient client;

  @override
  Future<Result<User>> byId(String id) => _guard(() async {
    final me = client.user;
    if (me != null && me['id'] == id) return userFromJson(me);
    for (final s in await _list(client, '/api/staff')) {
      if (s['id'] == id) return userFromJson({...s, 'role': 'staff'});
    }
    return userFromJson(
      (await client.request('/api/patients/$id')) as Map<String, dynamic>,
    );
  });

  @override
  Future<Result<Staff>> staffById(String id) => _guard(() async {
    final me = client.user;
    final rows = await _list(client, '/api/staff');
    final row = rows.where((s) => s['id'] == id).firstOrNull;
    if (row != null) return _staff(row);
    if (me != null && me['id'] == id) return _staff(me);
    throw const NotFoundFailure('Staff member unavailable.');
  });

  @override
  Future<Result<List<Staff>>> allStaff() => _guard(
    () async => [for (final s in await _list(client, '/api/staff')) _staff(s)],
  );

  @override
  Future<Result<List<User>>> byRole(UserRole role) => _guard(() async {
    final rows = role == UserRole.staff
        ? await _list(client, '/api/staff')
        : role == UserRole.patient
        ? await _list(client, '/api/patients', {'query': ''})
        : const <Map<String, dynamic>>[];
    return [
      for (final r in rows) userFromJson({...r, 'role': role.name}),
    ];
  });

  @override
  Stream<User?> watchById(String id) => Stream<User?>.multi((c) {
    final me = client.user;
    // The signed-in account: the server re-checks it on every request; a
    // revoked session surfaces as SessionExpiredFailure there.
    c.add(me != null && me['id'] == id ? userFromJson(me) : null);
  });

  @override
  Future<Result<void>> setPresence({
    required String id,
    required PresenceStatus status,
  }) async => const Err(
    SharedModeUnavailableFailure(
      'Availability status is a local preference and is not shared yet.',
    ),
  );
}

class RemotePatientRepository extends SharedUnavailable
    implements PatientRepository {
  RemotePatientRepository(this.client);

  final SharedClient client;

  @override
  Future<Result<Patient>> byId(String id) => _guard(() async {
    final me = client.user;
    final json = me != null && me['id'] == id
        ? me
        : (await client.request('/api/patients/$id')) as Map<String, dynamic>;
    return Patient(user: userFromJson({...json, 'role': 'patient'}));
  });

  @override
  Future<Result<List<Patient>>> search(String query, {int limit = 50}) =>
      _guard(
        () async => [
          for (final p in (await _list(client, '/api/patients', {
            'query': query,
          })).take(limit))
            Patient(user: userFromJson({...p, 'role': 'patient'})),
        ],
      );

  @override
  Future<Result<List<Patient>>> clinicallyVisible({
    String query = '',
    int limit = 30,
  }) => search(query, limit: limit);
}

class RemoteDepartmentRepository extends SharedUnavailable
    implements DepartmentRepository {
  RemoteDepartmentRepository(this.client);

  final SharedClient client;

  @override
  Future<Result<List<Department>>> all() => _guard(
    () async => [
      for (final d in await _list(client, '/api/departments'))
        Department(
          id: d['id'] as String,
          name: d['name'] as String,
          description: d['description'] as String?,
        ),
    ],
  );

  @override
  Future<Result<Department>> byId(String id) => _guard(() async {
    final all = (await this.all()).valueOrNull ?? const <Department>[];
    return all.firstWhere(
      (d) => d.id == id,
      orElse: () => throw const NotFoundFailure('Department unavailable.'),
    );
  });
}

// ---------------------------------------------------------------------------
// Appointments and consultations
// ---------------------------------------------------------------------------

class RemoteAppointmentRepository extends SharedUnavailable
    implements AppointmentRepository {
  RemoteAppointmentRepository(this.client);

  final SharedClient client;

  Future<List<Appointment>> _mine() async => [
    for (final a in await _list(client, '/api/appointments')) _appointment(a),
  ];

  @override
  Future<Result<Appointment>> byId(String id) => _guard(
    () async => _appointment(
      (await client.request('/api/appointments/$id')) as Map<String, dynamic>,
    ),
  );

  @override
  Future<Result<List<Appointment>>> forPatient(
    String patientId, {
    bool upcomingOnly = false,
  }) => _guard(() async {
    final me = client.user;
    final rows = me != null && me['id'] == patientId
        ? await _list(client, '/api/appointments')
        : await _list(client, '/api/appointments', {'patientId': patientId});
    final now = DateTime.now();
    return [
      for (final r in rows)
        if (!upcomingOnly || _at(r['end']).isAfter(now)) _appointment(r),
    ];
  });

  @override
  Future<Result<List<Appointment>>> forStaffOnDay(
    String staffId,
    DateTime day,
  ) => forStaffInRange(
    staffId,
    DateTime(day.year, day.month, day.day),
    DateTime(day.year, day.month, day.day + 1),
  );

  @override
  Future<Result<List<Appointment>>> forStaffInRange(
    String staffId,
    DateTime from,
    DateTime to,
  ) => _guard(() async {
    final all = client.user?['id'] == staffId
        ? await _mine()
        : [
            for (final a in await _list(client, '/api/appointments', {
              'from': from.toUtc().toIso8601String(),
              'to': to.toUtc().toIso8601String(),
            }))
              _appointment(a),
          ];
    return [
      for (final a in all)
        if (a.staffId == staffId &&
            !a.slotStart.isBefore(from) &&
            a.slotStart.isBefore(to))
          a,
    ]..sort((a, b) => a.slotStart.compareTo(b.slotStart));
  });

  @override
  Stream<List<Appointment>> watchForStaffOnDay(String staffId, DateTime day) =>
      _poll(() => forStaffOnDay(staffId, day));

  @override
  Future<Result<List<Appointment>>> inRange(DateTime from, DateTime to) =>
      _guard(
        () async => [
          for (final a in await _list(client, '/api/appointments', {
            'from': from.toUtc().toIso8601String(),
            'to': to.toUtc().toIso8601String(),
          }))
            _appointment(a),
        ],
      );

  @override
  Future<Result<List<OpenSlot>>> openSlots(
    String staffId,
    DateTime day,
  ) => _guard(() async {
    final d =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return [
      for (final s in await _list(client, '/api/slots', {
        'staffId': staffId,
        'day': d,
      }))
        OpenSlot(staffId: staffId, start: _at(s['start']), end: _at(s['end'])),
    ];
  });

  @override
  Future<Result<Appointment>> book(BookingRequest r) => _guard(() async {
    return _appointment(
      await _post(client, '/api/appointments', {
        'patientId': r.patientId,
        'staffId': r.staffId,
        'start': r.start.toUtc().toIso8601String(),
        'end': r.end.toUtc().toIso8601String(),
        'reason': r.reasonText,
        'visitType': r.visitType.name,
        'idempotencyKey': (r.idempotencyKey ?? IdempotencyKey.generate()).value,
      }),
    );
  });

  @override
  Future<Result<void>> cancel(
    String id, {
    required String patientId,
    int? expectedVersion,
  }) => _guard(() async {
    final version =
        expectedVersion ?? (await byId(id)).valueOrNull?.version ?? 1;
    await _post(client, '/api/appointments/$id/cancel', {
      'expectedVersion': version,
      'reason': 'Cancelled in the app',
    });
  });

  @override
  Future<Result<void>> deskCheckIn(
    String id, {
    required DateTime at,
    int? expectedVersion,
  }) => _guard(() async {
    final version =
        expectedVersion ?? (await byId(id)).valueOrNull?.version ?? 1;
    await _post(client, '/api/appointments/$id/check-in', {
      'expectedVersion': version,
      'reason': null,
    });
  });

  /// "Patient arrived" starts the visit on the server.
  @override
  Future<Result<void>> markArrived(
    String id, {
    required String staffId,
    required DateTime at,
    int? expectedVersion,
  }) => _guard(() async {
    final version =
        expectedVersion ?? (await byId(id)).valueOrNull?.version ?? 1;
    await _post(client, '/api/encounters/$id/start', {
      'expectedVersion': version,
    });
  });
}

class RemoteEncounterDraftRepository extends SharedUnavailable
    implements EncounterDraftRepository {
  RemoteEncounterDraftRepository(this.client);

  final SharedClient client;

  EncounterDraftData _draft(
    String appointmentId,
    String patientId,
    Map<String, dynamic> d,
  ) => EncounterDraftData(
    appointmentId: appointmentId,
    patientId: patientId,
    authorStaffId: (d['authorId'] as String?) ?? '',
    note: (d['note'] as String?) ?? '',
    medications: [
      for (final m
          in (d['meds'] as List? ?? const []).cast<Map<String, dynamic>>())
        DraftMedicationData(
          name: m['name'] as String,
          dose: m['dose'] as String?,
          frequency: m['frequency'] as String?,
        ),
    ],
    version: (d['version'] as num?)?.toInt() ?? 1,
    updatedAt: _atOrNull(d['updatedAt']),
  );

  @override
  Future<Result<EncounterDraftData?>> forAppointment(String appointmentId) =>
      _guard(() async {
        final e =
            (await client.request('/api/encounters/$appointmentId'))
                as Map<String, dynamic>;
        final d = e['draft'] as Map<String, dynamic>?;
        return d == null ? null : _draft(appointmentId, '', d);
      });

  @override
  Future<Result<EncounterDraftData>> save(
    EncounterDraftData draft, {
    int? expectedVersion,
  }) => _guard(() async {
    final reply = await _post(
      client,
      '/api/encounters/${draft.appointmentId}/draft',
      {
        'note': draft.note,
        'meds': [
          for (final m in draft.medications)
            {'name': m.name, 'dose': m.dose, 'frequency': m.frequency},
        ],
        'expectedVersion': expectedVersion,
      },
    );
    return _draft(draft.appointmentId, draft.patientId, reply);
  });
}

class RemoteEncounterRepository extends SharedUnavailable
    implements EncounterRepository {
  RemoteEncounterRepository(this.client);

  final SharedClient client;

  @override
  Future<Result<SignedNote>> finalize(
    FinalizeEncounter request, {
    IdempotencyKey? idempotencyKey,
  }) => _guard(() async {
    final reply = await _post(
      client,
      '/api/encounters/${request.appointmentId}/finalize',
      {
        'note': request.note,
        'meds': [
          for (final m in request.medications)
            {'name': m.name, 'dose': m.dose, 'frequency': m.frequency},
        ],
        'outcome': request.outcomeNote,
        'idempotencyKey': (idempotencyKey ?? IdempotencyKey.generate()).value,
      },
    );
    return SignedNote(
      id: request.appointmentId,
      appointmentId: request.appointmentId,
      patientId: '',
      authorStaffId: reply['signerId'] as String,
      body: request.note,
      signedAt: _at(reply['signedAt']),
    );
  });

  @override
  Future<Result<SignedNote?>> signedNoteFor(String appointmentId) =>
      _guard(() async {
        final e =
            (await client.request('/api/encounters/$appointmentId'))
                as Map<String, dynamic>;
        final s = e['signed'] as Map<String, dynamic>?;
        return s == null
            ? null
            : SignedNote(
                id: appointmentId,
                appointmentId: appointmentId,
                patientId: '',
                authorStaffId: s['signerId'] as String,
                body: s['note'] as String,
                signedAt: _at(s['signedAt']),
              );
      });
}

// ---------------------------------------------------------------------------
// Messages, billing, tasks, medications
// ---------------------------------------------------------------------------

class RemoteCareMessageRepository extends SharedUnavailable
    implements CareMessageRepository {
  RemoteCareMessageRepository(this.client);

  final SharedClient client;

  String get _me => client.user?['id'] as String? ?? '';

  Future<List<CareThread>> _threads({required bool asPatient}) async => [
    for (final t in await _list(client, '/api/threads'))
      () {
        final patientId = asPatient ? _me : t['counterpartId'] as String;
        final staffId = asPatient ? t['counterpartId'] as String : _me;
        final unread = (t['unread'] as num).toInt();
        return CareThread(
          patientId: patientId,
          staffId: staffId,
          counterpartName: t['counterpartName'] as String,
          lastMessage: CareMessage(
            id: (t['lastId'] as String?) ?? '',
            patientId: patientId,
            staffId: staffId,
            fromStaff: t['lastSender'] == staffId,
            body: (t['lastBody'] as String?) ?? '',
            sentAt: _at(t['lastAt']),
          ),
          unreadForPatient: asPatient ? unread : 0,
          unreadForStaff: asPatient ? 0 : unread,
        );
      }(),
  ];

  @override
  Future<Result<List<CareThread>>> threadsForPatient(String patientId) =>
      _guard(() => _threads(asPatient: true));

  @override
  Future<Result<List<CareThread>>> threadsForStaff(String staffId) =>
      _guard(() => _threads(asPatient: false));

  @override
  Future<Result<List<CareMessage>>> thread({
    required String patientId,
    required String staffId,
  }) => _guard(
    () async => [
      for (final m in await _list(client, '/api/messages', {
        'patientId': patientId,
        'staffId': staffId,
      }))
        CareMessage(
          id: m['id'] as String,
          patientId: patientId,
          staffId: staffId,
          fromStaff: m['senderId'] == staffId,
          body: m['body'] as String,
          sentAt: _at(m['at']),
          readAt: _atOrNull(m['readAt']),
        ),
    ],
  );

  @override
  Future<Result<CareMessage>> send({
    required String patientId,
    required String staffId,
    required bool fromStaff,
    required String body,
    IdempotencyKey? idempotencyKey,
    List<NewNotification> notify = const [],
  }) => _guard(() async {
    final m = await _post(client, '/api/messages', {
      'patientId': patientId,
      'staffId': staffId,
      'body': body,
      'idempotencyKey': (idempotencyKey ?? IdempotencyKey.generate()).value,
    });
    return CareMessage(
      id: m['id'] as String,
      patientId: patientId,
      staffId: staffId,
      fromStaff: fromStaff,
      body: m['body'] as String,
      sentAt: _at(m['at']),
    );
  });

  @override
  Future<Result<void>> markRead({
    required String patientId,
    required String staffId,
    required bool readerIsStaff,
  }) => _guard(() async {
    await _post(client, '/api/messages/read', {
      'patientId': patientId,
      'staffId': staffId,
    });
  });

  @override
  Future<Result<List<CareMessage>>> awaitingReply({String? staffId}) => _guard(
    () async => [
      for (final t in await _threads(asPatient: false))
        if (t.unreadForStaff > 0) t.lastMessage,
    ],
  );
}

class RemoteBillingRepository extends SharedUnavailable
    implements BillingRepository {
  RemoteBillingRepository(this.client);

  final SharedClient client;

  Invoice _invoice(Map<String, dynamic> i) {
    final total = (i['amountFils'] as num) / 1000;
    return Invoice(
      id: i['id'] as String,
      patientId: i['patientId'] as String,
      subtotal: total,
      taxRate: 0,
      taxAmount: 0,
      totalAmount: total,
      status: i['status'] == 'paid'
          ? InvoiceStatus.paid
          : InvoiceStatus.pending,
      issuedAt: _at(i['created']),
      notes: i['description'] as String?,
      version: (i['version'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  Future<Result<List<Invoice>>> forPatient(String patientId) =>
      _guard(() async {
        final me = client.user?['id'] == patientId;
        return [
          for (final i in await _list(
            client,
            '/api/invoices',
            me ? null : {'patientId': patientId},
          ))
            _invoice(i),
        ];
      });

  @override
  Future<Result<Invoice>> byId(String id) =>
      Future.value(const Err(SharedModeUnavailableFailure()));
}

class RemoteTaskRepository extends SharedUnavailable implements TaskRepository {
  RemoteTaskRepository(this.client);

  final SharedClient client;

  StaffTask _task(Map<String, dynamic> t) => StaffTask(
    id: t['id'] as String,
    staffId: t['owner'] as String,
    title: t['title'] as String,
    kind: switch (t['kind']) {
      'resultReview' => TaskKind.unreviewedAbnormalLab,
      'unsignedNote' => TaskKind.unsignedNote,
      'referralFollowUp' => TaskKind.referralAction,
      'followUpDue' => TaskKind.followUpDue,
      _ => TaskKind.other,
    },
    status: _enum(TaskStatus.values, t['status'], TaskStatus.open),
    ruleScore: 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (t['created'] as num).toInt(),
    ),
    patientId: t['patient'] as String?,
    dueAt: t['due'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch((t['due'] as num).toInt()),
    nextReviewAt: t['review_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch((t['review_at'] as num).toInt()),
    priority: switch (t['priority']) {
      'urgent' => WorkPriority.urgent,
      'high' => WorkPriority.priority,
      _ => WorkPriority.routine,
    },
    version: (t['version'] as num?)?.toInt() ?? 1,
  );

  @override
  Future<Result<List<StaffTask>>> forStaff(
    String staffId, {
    bool openOnly = false,
  }) => _guard(
    () async => [
      for (final t in await _list(client, '/api/tasks'))
        if (!openOnly || !{'done', 'dismissed'}.contains(t['status'])) _task(t),
    ],
  );

  @override
  Stream<List<StaffTask>> watchForStaff(
    String staffId, {
    bool openOnly = false,
  }) => _poll(() => forStaff(staffId, openOnly: openOnly));

  @override
  Future<Result<void>> setStatus({
    required String id,
    required String staffId,
    required TaskStatus status,
    int? expectedVersion,
    String? outcome,
    DateTime? reviewAt,
  }) => _guard(() async {
    await client.request(
      '/api/tasks/$id',
      method: 'PATCH',
      body: {
        'status': status.name,
        'expectedVersion': expectedVersion,
        'outcome': outcome ?? '',
        'reviewAt': reviewAt?.toUtc().toIso8601String(),
      },
    );
  });
}

class RemoteMedicationRepository extends SharedUnavailable
    implements MedicationRepository {
  RemoteMedicationRepository(this.client);

  final SharedClient client;

  @override
  Future<Result<List<Medication>>> forPatient(
    String patientId, {
    bool activeOnly = false,
  }) => _guard(
    () async => [
      for (final m in await _list(client, '/api/prescriptions', {
        'patientId': patientId,
      }))
        if (!activeOnly || m['isActive'] == true)
          Medication(
            id: m['id'] as String,
            patientId: patientId,
            name: m['name'] as String,
            startDate: _at(m['startDate']),
            isActive: m['isActive'] == true,
            prescriberId: m['prescriberId'] as String?,
            appointmentId: m['appointmentId'] as String?,
            dose: m['dose'] as String?,
            frequency: m['frequency'] as String?,
          ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Dental and pharmacy
// ---------------------------------------------------------------------------

class RemoteDentalChartRepository implements DentalChartRepository {
  RemoteDentalChartRepository(this.client);

  final SharedClient client;

  DentalEntry _entry(Map<String, dynamic> e) => DentalEntry(
    id: e['id'] as String,
    patientId: e['patientId'] as String,
    appointmentId: e['appointmentId'] as String,
    tooth: (e['tooth'] as num).toInt(),
    kind: _enum(DentalEntryKind.values, e['kind'], DentalEntryKind.observation),
    note: e['note'] as String,
    surface: e['surface'] as String?,
    fulfilsId: e['fulfilsId'] as String?,
    authorId: e['authorId'] as String,
    createdAt: _at(e['createdAt']),
  );

  @override
  Future<Result<List<DentalEntry>>> forPatient(String patientId) => _guard(
    () async => [
      for (final e in await _list(client, '/api/dental', {
        'patientId': patientId,
      }))
        _entry(e),
    ],
  );

  @override
  Future<Result<DentalEntry>> add(NewDentalEntry entry) => _guard(
    () async => _entry(
      await _post(client, '/api/dental', {
        'patientId': entry.patientId,
        'appointmentId': entry.appointmentId,
        'tooth': entry.tooth,
        'kind': entry.kind.name,
        'surface': entry.surface,
        'note': entry.note,
        'fulfilsId': entry.fulfilsId,
        'idempotencyKey': entry.idempotencyKey,
      }),
    ),
  );
}

class RemotePharmacyRepository implements PharmacyRepository {
  RemotePharmacyRepository(this.client);

  final SharedClient client;

  StockBatch _batch(Map<String, dynamic> s) => StockBatch(
    id: s['id'] as String,
    itemName: s['itemName'] as String,
    batch: s['batch'] as String,
    expiry: _at(s['expiry']),
    quantity: (s['quantity'] as num).toInt(),
    unit: s['unit'] as String,
    receivedAt: _at(s['receivedAt']),
    version: (s['version'] as num?)?.toInt() ?? 1,
  );

  @override
  Future<Result<List<PharmacyOrder>>> queue({int limit = 100}) => _guard(
    () async => [
      for (final o in (await _list(client, '/api/pharmacy/queue')).take(limit))
        PharmacyOrder(
          medicationId: o['medicationId'] as String,
          patientId: o['patientId'] as String,
          patientName: o['patientName'] as String,
          prescriberName: o['prescriberName'] as String,
          name: o['name'] as String,
          dose: o['dose'] as String?,
          frequency: o['frequency'] as String?,
          startDate: _at(o['startDate']),
          lastOutcome: o['lastOutcome'] == null
              ? null
              : _enum(
                  DispenseOutcome.values,
                  o['lastOutcome'],
                  DispenseOutcome.held,
                ),
          lastOutcomeAt: _atOrNull(o['lastOutcomeAt']),
        ),
    ],
  );

  @override
  Future<Result<DateTime>> record(DispenseInput input) => _guard(() async {
    final reply = await _post(client, '/api/pharmacy/dispense', {
      'prescriptionId': input.medicationId,
      'outcome': input.outcome.name,
      'patientVerified': input.patientVerified,
      'quantity': input.quantity,
      'batch': input.batch,
      'expiry': input.expiry?.toUtc().toIso8601String(),
      'note': input.note,
      'stockId': input.stockBatchId,
      'units': input.units,
      'idempotencyKey': input.idempotencyKey,
    });
    return _at(reply['recordedAt']);
  });

  @override
  Future<Result<List<StockBatch>>> stock() => _guard(
    () async => [
      for (final s in await _list(client, '/api/pharmacy/stock')) _batch(s),
    ],
  );

  @override
  Future<Result<StockBatch>> receive(ReceiveStockInput input) => _guard(
    () async => _batch(
      await _post(client, '/api/pharmacy/stock', {
        'itemName': input.itemName,
        'batch': input.batch,
        'expiry': input.expiry.toUtc().toIso8601String(),
        'quantity': input.quantity,
        'unit': input.unit,
        'idempotencyKey': input.idempotencyKey,
      }),
    ),
  );
}

/// Polls [load] every 20 s while listened to: the shared server has no push
/// channel yet. Errors surface as stream errors, never as empty lists.
Stream<List<T>> _poll<T>(Future<Result<List<T>>> Function() load) =>
    Stream<List<T>>.multi((c) {
      Timer? timer;
      Future<void> tick() async {
        switch (await load()) {
          case Ok(:final value):
            if (!c.isClosed) c.add(value);
          case Err(:final failure):
            if (!c.isClosed) c.addError(failure);
        }
      }

      unawaited(tick());
      timer = Timer.periodic(const Duration(seconds: 20), (_) => tick());
      c.onCancel = () => timer?.cancel();
    });
