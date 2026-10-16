import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shared_mode.dart';
import '../../core/di.dart';
import '../../core/failures.dart';
import '../../core/utils/ids.dart';
import '../../data/db/app_database.dart';
import '../../data/remote/shared_client.dart';
import '../../domain/enums.dart';
import '../../domain/identity/identity.dart';
import '../../domain/identity/permissions.dart';
import '../../services/auth/access_policy.dart';
import '../auth/application/session.dart';
import '../workspace/workspace_repository.dart';

final workforceRepositoryProvider = Provider(
  (ref) => WorkforceRepository(
    db: ref.watch(sharedModeProvider) ? null : ref.watch(appDatabaseProvider),
    client: ref.watch(sharedModeProvider)
        ? ref.watch(sharedClientProvider)
        : null,
    access: ref.watch(accessPolicyProvider),
  ),
);
final workforceDataProvider = FutureProvider.family<WorkspaceData, String>((
  ref,
  resource,
) {
  ref.watch(currentUserProvider);
  ref.watch(workspaceChangesProvider);
  return ref.watch(workforceRepositoryProvider).read(resource);
});

/// Local and shared work use one contract. Shared failures never read scratch data.
class WorkforceRepository {
  WorkforceRepository({
    required this.db,
    required this.client,
    required this.access,
  });
  final AppDatabase? db;
  final SharedClient? client;
  final AccessPolicy access;

  Future<List<WorkspaceData>> _query(
    String sql, [
    List<Object> args = const [],
  ]) async => [
    for (final r
        in await db!
            .customSelect(
              sql,
              variables: [
                for (final a in args)
                  a is int ? Variable<int>(a) : Variable<String>(a as String),
              ],
            )
            .get())
      r.data,
  ];
  Future<int> _count(String sql, [List<Object> args = const []]) async =>
      ((await _query(sql, args)).single.values.first as num).toInt();

  Future<(String, StaffRole)> _staff() async {
    final actor = await access.require(
      Permission.manageTasks,
      entityType: 'staff_workspace',
    );
    if (actor == null || !actor.isStaff)
      throw const AuthFailure('Staff access required.');
    final profile = await (db!.select(
      db!.staffProfiles,
    )..where((p) => p.userId.equals(actor.accountId))).getSingleOrNull();
    final role = StaffRole.parse(profile?.jobTitle);
    if (role == null)
      throw const AuthFailure(
        'A valid staff profile is required. Ask an administrator to repair the account.',
      );
    return (actor.accountId, role);
  }

  Future<WorkspaceData> read(
    String resource, [
    WorkspaceData parameters = const {},
  ]) async {
    if (client != null)
      return Map<String, dynamic>.from(
        await client!.request(
              '/api/workforce/$resource',
              query: parameters.map((k, v) => MapEntry(k, '$v')),
            )
            as Map,
      );
    final (id, role) = await _staff();
    if (resource == 'activity')
      return {
        'rows': await _query(
          'SELECT action,entity_id AS entity,at FROM audit_log WHERE actor_user_id=? ORDER BY at DESC,id DESC LIMIT 100',
          [id],
        ),
      };
    if (resource == 'directory')
      return {
        'rows': await _query(
          '''SELECT u.id,u.full_name AS name,sp.job_title AS role,d.name AS department,
      COALESCE((SELECT MIN(start_minutes) FROM staff_shifts WHERE staff_id=u.id),(SELECT MIN(start_minutes) FROM schedule_templates WHERE staff_id=u.id)) AS start_minutes,
      COALESCE((SELECT MAX(end_minutes) FROM staff_shifts WHERE staff_id=u.id),(SELECT MAX(end_minutes) FROM schedule_templates WHERE staff_id=u.id)) AS end_minutes
      FROM users u JOIN staff_profiles sp ON sp.user_id=u.id LEFT JOIN departments d ON d.id=sp.department_id
      WHERE u.role='staff' AND u.is_active=1 ORDER BY u.full_name,u.id''',
        ),
      };
    if (resource == 'shifts')
      return {
        'rows': await _query(
          'SELECT * FROM staff_shifts WHERE staff_id=? ORDER BY weekday,start_minutes',
          [id],
        ),
      };
    if (resource == 'conversations')
      return {
        'rows': await _query(
          '''SELECT c.id,u.id AS peer_id,u.full_name AS peer_name,sp.job_title AS peer_role,
      (SELECT body FROM staff_messages WHERE conversation_id=c.id ORDER BY sent_at DESC,id DESC LIMIT 1) AS latest_message,
      (SELECT MAX(sent_at) FROM staff_messages WHERE conversation_id=c.id) AS latest_at,
      (SELECT COUNT(*) FROM staff_messages m WHERE m.conversation_id=c.id AND m.sender_id!=? AND m.sent_at>COALESCE(mine.last_read_at,0)) AS unread
      FROM staff_conversations c JOIN staff_conversation_members mine ON mine.conversation_id=c.id AND mine.user_id=?
      JOIN staff_conversation_members peer ON peer.conversation_id=c.id AND peer.user_id!=?
      JOIN users u ON u.id=peer.user_id JOIN staff_profiles sp ON sp.user_id=u.id ORDER BY latest_at DESC,c.id''',
          [id, id, id],
        ),
      };
    if (resource == 'thread') {
      final conversation = parameters['id'] as String;
      await _member(conversation, id);
      return {
        'rows': await _query(
          'SELECT m.*,u.full_name AS sender_name FROM staff_messages m JOIN users u ON u.id=m.sender_id WHERE m.conversation_id=? ORDER BY m.sent_at,m.id',
          [conversation],
        ),
      };
    }
    if (resource == 'intakes') {
      if (![
        StaffRole.nurse,
        StaffRole.doctor,
        StaffRole.dentist,
      ].contains(role))
        throw const AccessDeniedFailure('Nursing care access required.');
      final where = role == StaffRole.nurse ? 'ni.nurse_id=?' : 'a.staff_id=?';
      final visible = await access.clinicallyVisiblePatientIds() ?? <String>{};
      if (visible.isEmpty) return {'rows': <WorkspaceData>[]};
      final patientScope = List.filled(visible.length, '?').join(',');
      return {
        'rows': await _query(
          '''SELECT ni.*,a.patient_id,a.slot_start,a.slot_end,a.status AS appointment_status,a.department_id,
        u.full_name AS patient_name,u.national_id,d.name AS department,v.temp_c,v.heart_rate,v.spo2,
        EXISTS(SELECT 1 FROM risk_flags rf WHERE rf.patient_id=a.patient_id AND rf.severity='urgent' AND rf.acknowledged_at IS NULL) AS urgent
        FROM nursing_intakes ni JOIN appointments a ON a.id=ni.appointment_id JOIN users u ON u.id=a.patient_id
        LEFT JOIN departments d ON d.id=a.department_id LEFT JOIN vitals v ON v.id=ni.vitals_id
        WHERE $where AND a.patient_id IN ($patientScope) AND a.status NOT IN ('cancelled','noShow') ORDER BY a.slot_start,ni.id''',
          [id, ...visible],
        ),
      };
    }
    if (resource == 'clarifications') {
      if (role != StaffRole.pharmacist && !role.takesAppointments)
        throw const AccessDeniedFailure('Medication review access required.');
      return {
        'rows': await _query(
          '''SELECT c.*,m.name AS medication_name,m.dose,m.patient_id,u.full_name AS patient_name
        FROM medication_clarifications c JOIN medications m ON m.id=c.medication_id JOIN users u ON u.id=m.patient_id
        WHERE c.resolved_at IS NULL ${role == StaffRole.pharmacist ? '' : 'AND m.prescriber_id=?'} ORDER BY c.requested_at''',
          role == StaffRole.pharmacist ? [] : [id],
        ),
      };
    }
    if (resource == 'dispensing-history') {
      if (role != StaffRole.pharmacist)
        throw const AccessDeniedFailure('Pharmacy access required.');
      return {
        'rows': await _query(
          '''SELECT x.*,m.name AS medication_name,p.full_name AS patient_name,u.full_name AS pharmacist_name
        FROM medication_dispenses x JOIN medications m ON m.id=x.medication_id JOIN users p ON p.id=m.patient_id
        JOIN users u ON u.id=x.pharmacist_id ORDER BY x.recorded_at DESC,x.id LIMIT 100''',
        ),
      };
    }
    if (resource != 'home')
      throw const ValidationFailure('Unknown workforce resource.');
    final today = clinicStart(clinicDay()),
        start = today.millisecondsSinceEpoch ~/ 1000,
        end = today.add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000;
    final me = (await _query(
      'SELECT u.full_name AS name,d.name AS department FROM users u JOIN staff_profiles sp ON sp.user_id=u.id LEFT JOIN departments d ON d.id=sp.department_id WHERE u.id=?',
      [id],
    )).single;
    final data = <String, dynamic>{...me, 'role': role.name};
    final stats = <String, int>{};
    if (role == StaffRole.nurse) {
      final intake = await read('intakes');
      data['queue'] = intake['rows'];
      final scoped = (intake['rows'] as List).cast<WorkspaceData>();
      stats['assignedToday'] = scoped
          .where(
            (n) =>
                (n['slot_start'] as num) >= start &&
                (n['slot_start'] as num) < end,
          )
          .map((n) => n['patient_id'])
          .toSet()
          .length;
      stats['completedToday'] = scoped
          .where(
            (n) =>
                n['status'] == 'completed' &&
                (n['recorded_at'] as num) >= start &&
                (n['recorded_at'] as num) < end,
          )
          .length;
      stats['observationsDue'] = scoped
          .where((n) => n['status'] == 'pending')
          .length;
      stats['handover'] = await _count(
        "SELECT COUNT(*) FROM staff_tasks WHERE staff_id=? AND status IN ('open','inProgress','waiting','blocked')",
        [id],
      );
    } else if (role == StaffRole.pharmacist) {
      stats['pendingOrders'] = await _count(
        "SELECT COUNT(*) FROM medications m JOIN signed_notes s ON s.appointment_id=m.appointment_id WHERE m.is_active=1 AND NOT EXISTS(SELECT 1 FROM medication_dispenses x WHERE x.medication_id=m.id AND x.outcome='dispensed')",
      );
      stats['dispensedToday'] = await _count(
        "SELECT COUNT(DISTINCT medication_id) FROM medication_dispenses WHERE outcome='dispensed' AND recorded_at>=? AND recorded_at<?",
        [start, end],
      );
      stats['clarifications'] = await _count(
        'SELECT COUNT(*) FROM medication_clarifications WHERE resolved_at IS NULL',
      );
      stats['stockAlerts'] = await _count(
        'SELECT COUNT(*) FROM pharmacy_stock_batches WHERE quantity<=5 OR expiry<=?',
        [end + 30 * 86400],
      );
      data['queue'] = await _query(
        "SELECT m.id,m.name AS medication_name,m.patient_id,u.full_name AS patient_name,m.dose,m.frequency FROM medications m JOIN signed_notes s ON s.appointment_id=m.appointment_id JOIN users u ON u.id=m.patient_id WHERE m.is_active=1 AND NOT EXISTS(SELECT 1 FROM medication_dispenses x WHERE x.medication_id=m.id AND x.outcome='dispensed') ORDER BY m.issued_at,m.id LIMIT 100",
      );
    } else {
      final all = role == StaffRole.receptionist;
      final scope = all ? '1' : 'a.staff_id=?';
      final args = <Object>[if (!all) id, start, end];
      stats['appointmentsToday'] = await _count(
        'SELECT COUNT(*) FROM appointments a WHERE $scope AND a.slot_start>=? AND a.slot_start<?',
        args,
      );
      if (all) {
        stats['checkedIn'] = await _count(
          'SELECT COUNT(*) FROM appointments a WHERE a.checked_in_at IS NOT NULL AND a.slot_start>=? AND a.slot_start<?',
          [start, end],
        );
        stats['waiting'] = await _count(
          "SELECT COUNT(*) FROM appointments a WHERE a.status IN ('booked','confirmed') AND a.checked_in_at IS NULL AND a.slot_start>=? AND a.slot_start<?",
          [start, end],
        );
        stats['pendingCopies'] = await _count(
          'SELECT COUNT(*) FROM issued_document_versions v WHERE NOT EXISTS(SELECT 1 FROM document_copy_confirmations c WHERE c.issued_version_id=v.id)',
        );
      } else {
        stats['completedToday'] = await _count(
          "SELECT COUNT(*) FROM appointments a WHERE a.staff_id=? AND a.status='completed' AND COALESCE(a.completed_at,(SELECT signed_at FROM signed_notes WHERE appointment_id=a.id))>=? AND COALESCE(a.completed_at,(SELECT signed_at FROM signed_notes WHERE appointment_id=a.id))<?",
          [id, start, end],
        );
        stats['followUp'] = await _count(
          "SELECT COUNT(*) FROM staff_tasks WHERE staff_id=? AND kind='followUpDue' AND status NOT IN ('done','dismissed')",
          [id],
        );
        stats['unsignedNotes'] = await _count(
          'SELECT COUNT(*) FROM encounter_drafts e WHERE e.author_staff_id=? AND NOT EXISTS(SELECT 1 FROM signed_notes s WHERE s.appointment_id=e.appointment_id)',
          [id],
        );
      }
      data['queue'] = await _query(
        '''SELECT a.id,a.patient_id,a.staff_id,a.slot_start,a.slot_end,a.status,a.visit_type,a.reason_text,a.room_number,u.full_name AS patient_name
        FROM appointments a JOIN users u ON u.id=a.patient_id WHERE $scope AND a.status IN ('booked','confirmed','inProgress') AND a.slot_end>=? ORDER BY CASE WHEN a.status='inProgress' THEN 0 ELSE 1 END,a.slot_start,a.id LIMIT 100''',
        [if (!all) id, start],
      );
    }
    data['stats'] = stats;
    return data;
  }

  Future<void> _member(String conversation, String id) async {
    if (await _count(
          'SELECT COUNT(*) FROM staff_conversation_members WHERE conversation_id=? AND user_id=?',
          [conversation, id],
        ) !=
        1)
      throw const AccessDeniedFailure('Conversation membership required.');
  }

  Future<String> startConversation(String peerId) async {
    if (client != null)
      return (await client!.request(
                '/api/workforce/conversations',
                method: 'POST',
                body: {'peerId': peerId},
              )
              as Map)['id']
          as String;
    final (id, _) = await _staff();
    if (id == peerId)
      throw const ValidationFailure('Choose another staff member.');
    final peer = await (db!.select(
      db!.users,
    )..where((u) => u.id.equals(peerId))).getSingleOrNull();
    final profile = await (db!.select(
      db!.staffProfiles,
    )..where((p) => p.userId.equals(peerId))).getSingleOrNull();
    if (peer == null ||
        !peer.isActive ||
        !peer.hasLogin ||
        peer.role != UserRole.staff ||
        StaffRole.parse(profile?.jobTitle) == null)
      throw const AccessDeniedFailure('An active staff recipient is required.');
    return db!.transaction(() async {
      final pair = ([id, peerId]..sort()).join('|');
      final existing = await (db!.select(
        db!.staffConversations,
      )..where((c) => c.pairKey.equals(pair))).getSingleOrNull();
      if (existing != null) return existing.id;
      final key = newId('conversation');
      await db!
          .into(db!.staffConversations)
          .insert(
            StaffConversationsCompanion.insert(
              id: key,
              pairKey: pair,
              createdBy: id,
              createdAt: DateTime.now(),
            ),
          );
      for (final member in [id, peerId])
        await db!
            .into(db!.staffConversationMembers)
            .insert(
              StaffConversationMembersCompanion.insert(
                conversationId: key,
                userId: member,
              ),
            );
      await access.audit(
        'staff.conversation.created',
        entityType: 'conversation',
        entityId: key,
      );
      return key;
    });
  }

  Future<void> send(String conversation, String body, String requestKey) async {
    if (client != null) {
      await client!.request(
        '/api/workforce/messages',
        method: 'POST',
        body: {
          'conversationId': conversation,
          'body': body,
          'idempotencyKey': requestKey,
        },
      );
      return;
    }
    final (id, _) = await _staff();
    await _member(conversation, id);
    final message = body.trim();
    if (message.isEmpty || message.length > 4000 || requestKey.isEmpty)
      throw const ValidationFailure('Enter a message of 1–4000 characters.');
    await db!.transaction(() async {
      final prior = await (db!.select(
        db!.staffMessages,
      )..where((m) => m.requestKey.equals(requestKey))).getSingleOrNull();
      if (prior != null) {
        if (prior.senderId != id ||
            prior.conversationId != conversation ||
            prior.body != message)
          throw const ConflictFailure('Retry key belongs to another message.');
        return;
      }
      if (await _count(
            'SELECT COUNT(*) FROM staff_conversation_members m JOIN users u ON u.id=m.user_id WHERE m.conversation_id=? AND u.is_active=1 AND u.has_login=1',
            [conversation],
          ) !=
          2)
        throw const AccessDeniedFailure(
          'Both participants must be active to send.',
        );
      await db!
          .into(db!.staffMessages)
          .insert(
            StaffMessagesCompanion.insert(
              id: newId('message'),
              conversationId: conversation,
              senderId: id,
              body: message,
              requestKey: requestKey,
              sentAt: DateTime.now(),
            ),
          );
      await access.audit(
        'staff.message.sent',
        entityType: 'conversation',
        entityId: conversation,
      );
    });
  }

  Future<void> markRead(String conversation) async {
    if (client != null) {
      await client!.request(
        '/api/workforce/read',
        method: 'POST',
        body: {'conversationId': conversation},
      );
      return;
    }
    final (id, _) = await _staff();
    await _member(conversation, id);
    await (db!.update(db!.staffConversationMembers)..where(
          (m) => m.conversationId.equals(conversation) & m.userId.equals(id),
        ))
        .write(
          StaffConversationMembersCompanion(lastReadAt: Value(DateTime.now())),
        );
  }

  Future<void> saveIntake({
    required WorkspaceData intake,
    required String note,
    required String requestKey,
    double? temperature,
    int? pulse,
    int? oxygen,
  }) async {
    if (client != null) {
      await client!.request(
        '/api/workforce/intakes',
        method: 'POST',
        body: {
          'id': intake['id'],
          'version': intake['version'],
          'note': note,
          'temperature': temperature,
          'pulse': pulse,
          'oxygen': oxygen,
          'idempotencyKey': requestKey,
        },
      );
      return;
    }
    final (id, role) = await _staff();
    if (role != StaffRole.nurse)
      throw const AccessDeniedFailure('Nurse access required.');
    if (note.trim().isEmpty &&
        temperature == null &&
        pulse == null &&
        oxygen == null)
      throw const ValidationFailure('Record an observation or nursing note.');
    if (note.length > 5000 ||
        temperature?.isFinite == false ||
        pulse != null && pulse <= 0 ||
        oxygen != null && (oxygen < 0 || oxygen > 100))
      throw const ValidationFailure(
        'Check the measurement format and units. Oxygen saturation must be 0–100%.',
      );
    await db!.transaction(() async {
      final current =
          await (db!.select(db!.nursingIntakes)..where(
                (n) =>
                    n.id.equals(intake['id'] as String) & n.nurseId.equals(id),
              ))
              .getSingleOrNull();
      if (current == null)
        throw const AccessDeniedFailure('This intake is not assigned to you.');
      final appointment = await (db!.select(
        db!.appointments,
      )..where((a) => a.id.equals(current.appointmentId))).getSingle();
      await access.clinicalWrite(
        staffId: id,
        patientId: appointment.patientId,
        permission: Permission.writeClinicalRecord,
        entityType: 'nursing_intake',
      );
      if ([
        AppointmentStatus.cancelled,
        AppointmentStatus.noShow,
      ].contains(appointment.status))
        throw const ConflictFailure('This visit is no longer active.');
      if (current.lastRequestKey == requestKey) {
        final prior = await (db!.select(
          db!.vitals,
        )..where((v) => v.id.equals(current.vitalsId!))).getSingle();
        if (current.observationNote != note.trim() ||
            prior.tempC != temperature ||
            prior.heartRate != pulse ||
            prior.spo2 != oxygen)
          throw const ConflictFailure(
            'Retry key belongs to another observation.',
          );
        return;
      }
      if (current.version != intake['version'])
        throw const ConflictFailure(
          'Intake changed. Reload before saving; your input is retained.',
        );
      final at = DateTime.now(), vitalId = newId('vitals');
      await db!
          .into(db!.vitals)
          .insert(
            VitalsCompanion.insert(
              id: vitalId,
              patientId: appointment.patientId,
              appointmentId: Value(appointment.id),
              recordedAt: at,
              recordedByStaffId: Value(id),
              tempC: Value(temperature),
              heartRate: Value(pulse),
              spo2: Value(oxygen),
            ),
          );
      await (db!.update(db!.nursingIntakes)..where(
            (n) => n.id.equals(current.id) & n.version.equals(current.version),
          ))
          .write(
            NursingIntakesCompanion(
              status: const Value('completed'),
              observationNote: Value(note.trim()),
              vitalsId: Value(vitalId),
              recordedAt: Value(at),
              recordedBy: Value(id),
              lastRequestKey: Value(requestKey),
              version: Value(current.version + 1),
            ),
          );
      await db!
          .into(db!.encounterParticipants)
          .insert(
            EncounterParticipantsCompanion.insert(
              appointmentId: appointment.id,
              staffId: id,
              participatedAt: at,
              recordedBy: id,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await access.audit(
        'nursing.intake.saved',
        entityType: 'nursing_intake',
        entityId: current.id,
        subjectPatientId: appointment.patientId,
      );
    });
  }

  Future<void> assignIntake(String appointmentId, String nurseId) async {
    if (client != null) {
      await client!.request(
        '/api/workforce/intake-assignments',
        method: 'POST',
        body: {'appointmentId': appointmentId, 'nurseId': nurseId},
      );
      return;
    }
    final actor = await access.principal();
    if (actor == null) throw const AuthFailure('Sign in first.');
    final appointment = await (db!.select(
      db!.appointments,
    )..where((a) => a.id.equals(appointmentId))).getSingle();
    final profile = await (db!.select(
      db!.staffProfiles,
    )..where((s) => s.userId.equals(nurseId))).getSingleOrNull();
    final nurse = await (db!.select(
      db!.users,
    )..where((u) => u.id.equals(nurseId))).getSingleOrNull();
    if (profile == null ||
        StaffRole.parse(profile.jobTitle) != StaffRole.nurse ||
        nurse?.isActive != true)
      throw const ValidationFailure('Choose an active nurse.');
    if (!actor.can(Permission.manageUsers) &&
        !actor.can(Permission.bookForPatients)) {
      final (_, role) = await _staff();
      if (!role.takesAppointments || appointment.staffId != actor.accountId)
        throw const AccessDeniedFailure(
          'Only the responsible clinician or authorized desk can assign intake.',
        );
    }
    if ([
      AppointmentStatus.completed,
      AppointmentStatus.cancelled,
      AppointmentStatus.noShow,
    ].contains(appointment.status))
      throw const ConflictFailure('Assign intake to an active visit.');
    await db!.transaction(() async {
      final key = 'intake_${appointment.id}_$nurseId', at = DateTime.now();
      await db!
          .into(db!.nursingIntakes)
          .insert(
            NursingIntakesCompanion.insert(
              id: key,
              appointmentId: appointment.id,
              nurseId: nurseId,
              assignedAt: at,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await db!
          .into(db!.careTeamAssignments)
          .insert(
            CareTeamAssignmentsCompanion.insert(
              id: 'care_$key',
              patientId: appointment.patientId,
              staffId: nurseId,
              role: CareTeamRole.nurse,
              assignedAt: at,
              assignedBy: Value(actor.accountId),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await access.audit(
        'nursing.intake.assigned',
        entityType: 'nursing_intake',
        entityId: key,
        subjectPatientId: appointment.patientId,
      );
    });
  }

  Future<void> resolveClarification(
    WorkspaceData item,
    String resolution,
    String requestKey,
  ) async {
    if (client != null) {
      await client!.request(
        '/api/workforce/clarifications',
        method: 'POST',
        body: {
          'id': item['id'],
          'version': item['version'],
          'resolution': resolution,
          'idempotencyKey': requestKey,
        },
      );
      return;
    }
    final (id, role) = await _staff();
    if (!role.takesAppointments ||
        resolution.trim().isEmpty ||
        resolution.length > 4000)
      throw const ValidationFailure(
        'The prescriber must record a clarification response.',
      );
    await db!.transaction(() async {
      final row = (await _query(
        'SELECT c.*,m.patient_id,m.prescriber_id FROM medication_clarifications c JOIN medications m ON m.id=c.medication_id WHERE c.id=?',
        [item['id'] as String],
      )).single;
      if (row['prescriber_id'] != id)
        throw const AccessDeniedFailure(
          'Only the responsible prescriber can resolve this clarification.',
        );
      await access.clinicalWrite(
        staffId: id,
        patientId: row['patient_id'] as String,
        permission: Permission.prescribe,
        entityType: 'medication_clarification',
      );
      if (row['resolved_at'] != null) {
        if (row['resolved_by'] == id && row['resolution'] == resolution.trim())
          return;
        throw const ConflictFailure('Clarification already resolved.');
      }
      final changed =
          await (db!.update(db!.medicationClarifications)..where(
                (c) =>
                    c.id.equals(item['id'] as String) &
                    c.version.equals(item['version'] as int),
              ))
              .write(
                MedicationClarificationsCompanion(
                  resolvedBy: Value(id),
                  resolvedAt: Value(DateTime.now()),
                  resolution: Value(resolution.trim()),
                  version: Value((item['version'] as int) + 1),
                ),
              );
      if (changed != 1)
        throw const ConflictFailure('Clarification changed. Reload and retry.');
      await access.audit(
        'pharmacy.clarification.resolved',
        entityType: 'medication_clarification',
        entityId: item['id'] as String,
        detail: jsonEncode({'requestKey': requestKey}),
      );
    });
  }
}
