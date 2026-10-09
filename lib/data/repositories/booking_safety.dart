import 'package:drift/drift.dart';

import '../../core/failures.dart';
import '../../domain/enums.dart';
import '../db/app_database.dart';

const activeBookingStates = [
  AppointmentStatus.booked,
  AppointmentStatus.confirmed,
  AppointmentStatus.inProgress,
];

Future<void> requireSafeDeactivation(AppDatabase db, String id) async {
  final user = await (db.select(
    db.users,
  )..where((u) => u.id.equals(id))).getSingleOrNull();
  if (user == null) throw const NotFoundFailure('Account unavailable.');
  if (user.role == UserRole.admin && user.isActive) {
    final admins =
        await (db.select(db.users)..where(
              (u) =>
                  u.role.equalsValue(UserRole.admin) & u.isActive.equals(true),
            ))
            .get();
    if (admins.length <= 1) {
      throw const ValidationFailure(
        'The last active administrator must remain active.',
      );
    }
  }
  if (user.role != UserRole.staff) return;
  final bookings =
      await (db.select(db.appointments)..where(
            (a) =>
                a.staffId.equals(id) & a.status.isInValues(activeBookingStates),
          ))
          .get();
  final tasks =
      await (db.select(db.staffTasks)..where(
            (t) =>
                (t.staffId.equals(id) | t.coverageStaffId.equals(id)) &
                t.status.isNotInValues([TaskStatus.done, TaskStatus.dismissed]),
          ))
          .get();
  final reviews =
      await (db.select(db.resultReviews)..where(
            (r) =>
                (r.ownerStaffId.equals(id) | r.coverageStaffId.equals(id)) &
                r.status.equalsValue(ResultReviewStatus.resolved).not(),
          ))
          .get();
  final referrals =
      await (db.select(db.referralRequests)..where(
            (r) =>
                (r.ownerStaffId.equals(id) | r.coverageStaffId.equals(id)) &
                r.status.isNotInValues([
                  ReferralRequestStatus.actioned,
                  ReferralRequestStatus.rejected,
                  ReferralRequestStatus.closed,
                ]),
          ))
          .get();
  final homes =
      await (db.select(db.homeVisitRequests)..where(
            (r) =>
                r.assignedStaffId.equals(id) &
                r.status.equalsValue(HomeVisitStatus.scheduled),
          ))
          .get();
  final messages = await db.select(db.careMessages).get();
  final replies = messages
      .where(
        (m) =>
            !m.fromStaff &&
            (m.queueOwnerStaffId == id ||
                m.queueOwnerStaffId == null && m.staffId == id ||
                m.coverageStaffId == id) &&
            !messages.any(
              (r) =>
                  r.fromStaff &&
                  r.patientId == m.patientId &&
                  r.staffId == m.staffId &&
                  r.sentAt.isAfter(m.sentAt),
            ),
      )
      .toList();
  if (bookings.isNotEmpty ||
      tasks.isNotEmpty ||
      reviews.isNotEmpty ||
      referrals.isNotEmpty ||
      homes.isNotEmpty ||
      replies.isNotEmpty) {
    throw ValidationFailure(
      'Assign replacement responsibility before deactivation: ${bookings.length} bookings, ${tasks.length} tasks, ${reviews.length} reviews, ${referrals.length} referrals, ${homes.length} home visits, ${replies.length} unanswered messages.',
    );
  }
}
