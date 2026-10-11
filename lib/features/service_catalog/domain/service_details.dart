/// Copy and actions for the service detail pages opened from the Services
/// catalogue. A detail only offers a real action when the feature behind it
/// works in this build; planned services explain Future work instead.
library;

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';
import 'patient_catalog.dart';

class ServiceDetail {
  const ServiceDetail({
    required this.item,
    required this.heading,
    required this.body,
    this.actionLabel,
    this.actionRoute,
  }) : assert((actionLabel == null) == (actionRoute == null));

  final CatalogItem item;
  final String Function(AppLocalizations t) heading;
  final String Function(AppLocalizations t) body;

  /// A working destination, or null for a Future work explanation.
  final String Function(AppLocalizations t)? actionLabel;
  final String? actionRoute;

  bool get hasWorkingAction => actionRoute != null;
}

abstract final class ServiceDetails {
  static final _all = [
    ServiceDetail(
      item: PatientCatalog.completeCheckup,
      heading: (t) => t.svcCheckupTitle,
      body: (t) => t.svcCheckupBody,
    ),
    ServiceDetail(
      item: PatientCatalog.eReferral,
      heading: (t) => t.svcEReferralTitle,
      body: (t) => t.svcEReferralBody,
    ),
    ServiceDetail(
      item: PatientCatalog.bloodDonation,
      heading: (t) => t.svcBloodDonationTitle,
      body: (t) => t.svcBloodDonationBody,
    ),
    // Outside the proposal (keeps its Future work badge) but backed by the
    // working Vitals & Trends screen.
    ServiceDetail(
      item: PatientCatalog.healthTrackers,
      heading: (t) => t.svcTrackersTitle,
      body: (t) => t.svcTrackersBody,
      actionLabel: (t) => t.svcViewVitals,
      actionRoute: AppRoutes.patientVitals,
    ),
    ServiceDetail(
      item: PatientCatalog.wearables,
      heading: (t) => t.svcWatchesTitle,
      body: (t) => t.svcWatchesBody,
    ),
    ServiceDetail(
      item: PatientCatalog.waterTracking,
      heading: (t) => t.svcWaterTitle,
      body: (t) => t.svcWaterBody,
    ),
  ];

  static final Map<String, ServiceDetail> byId = {
    for (final d in _all) d.item.id: d,
  };
}
