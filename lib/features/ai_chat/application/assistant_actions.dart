/// The only places the patient assistant can send someone: a short allowlist
/// of action ids. The report AI may suggest an id (services/report_ai
/// `ACTION_IDS`); the app owns everything else — the route or action, the
/// button label, the permission check — and navigates only when the patient
/// taps. The AI never supplies a route or URL, and no action books a visit,
/// submits a form or changes patient data.
library;

import '../../../app/router.dart';
import '../../../domain/entities/entities.dart';

enum AssistantAction {
  /// The Appointments tab (choose a clinician, see available times).
  openAppointments('open_appointments'),

  /// Health Records (saved reports).
  openRecords('open_records'),

  /// The existing PDF import sheet, then the report summary.
  uploadReport('upload_report');

  const AssistantAction(this.id);

  /// The id the report AI may suggest.
  final String id;

  /// The action for an id from the report AI; unknown ids are ignored.
  static AssistantAction? fromId(Object? id) {
    for (final action in values) {
      if (action.id == id) return action;
    }
    return null;
  }

  /// The button label, in the language of the reply it belongs to.
  String label({required bool arabic}) => switch (this) {
    openAppointments => arabic ? 'فتح المواعيد' : 'Open Appointments',
    openRecords => arabic ? 'فتح السجلات' : 'Open Records',
    uploadReport => arabic ? 'رفع تقرير' : 'Upload report',
  };

  /// The screen it opens; null for an in-place action (upload).
  String? get route => switch (this) {
    openAppointments => AppRoutes.patientAppointments,
    openRecords => AppRoutes.patientTimeline,
    uploadReport => null,
  };
}

/// Whether [user] may be offered (and may run) [action]: an active patient,
/// and a destination the router would let them open. Checked when the
/// button is shown and again when it is tapped.
bool canOfferAssistantAction(User? user, AssistantAction action) {
  if (user == null || !user.isPatient || !user.isActive) return false;
  final route = action.route;
  return route == null || canAccessLocation(route, user.role);
}
