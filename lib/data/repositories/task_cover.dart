import 'dart:convert';
import 'package:drift/drift.dart';
import '../db/app_database.dart';

/// Legacy cover has no timed grant. Accepted handovers do, and that explicit
/// expiry governs responsibility even when another care relationship exists.
Future<bool> activeTaskCover(AppDatabase db, String task, String actor) async {
  final assignments =
      (await (db.select(
            db.careTeamAssignments,
          )..where((c) => c.staffId.equals(actor))).get())
          .where((a) => a.id.startsWith('task-cover-$task-'))
          .toList();
  final now = DateTime.now();
  if (assignments.isEmpty) {
    final accepted =
        await (db.select(db.taskHistory)..where(
              (h) =>
                  h.taskId.equals(task) &
                  h.actorAccountId.equals(actor) &
                  h.action.equals('task.offer.accepted'),
            ))
            .get();
    if (accepted.isEmpty) return true;
    accepted.sort(
      (a, b) =>
          ((jsonDecode(b.afterJson)
                          as Map<String, dynamic>)['assignmentVersion']
                      as int? ??
                  0)
              .compareTo(
                (jsonDecode(a.afterJson)
                            as Map<String, dynamic>)['assignmentVersion']
                        as int? ??
                    0,
              ),
    );
    final bundle =
        (jsonDecode(accepted.first.afterJson)
            as Map<String, dynamic>)['bundle'];
    final offers =
        await (db.select(db.taskHistory)..where(
              (h) => h.taskId.equals(task) & h.action.equals('task.offer'),
            ))
            .get();
    final offer = offers
        .where(
          (h) =>
              (jsonDecode(h.afterJson) as Map<String, dynamic>)['bundle'] ==
              bundle,
        )
        .firstOrNull;
    if (offer == null) return false;
    return DateTime.parse(
      (jsonDecode(offer.afterJson) as Map<String, dynamic>)['expires']
          as String,
    ).isAfter(now);
  }
  return assignments.any(
    (a) =>
        !a.assignedAt.isAfter(now) &&
        (a.endedAt == null || a.endedAt!.isAfter(now)),
  );
}
