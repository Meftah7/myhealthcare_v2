/// One typed catalogue for every patient shortcut and service: Home quick
/// tools, the Services carousel, the Services catalogue, Home Quick Access
/// and the drawer all read from here, so labels, routes, scope and access
/// rules are defined once.
library;

import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';

/// Who may open an item. Every patient area currently requires sign-in;
/// guest browsing is future work.
enum CatalogAccess { signedIn }

/// Where an item stands against the senior-project proposal.
enum CatalogScope {
  /// In the proposal: records, booking, documents, report explanation.
  core,

  /// Works today but sits outside the proposal (messaging, nutrition,
  /// billing…). Shows a "Future work" label and stays fully functional.
  supplementary,

  /// Not built: shows a "Future work" label and opens an explanation only.
  planned,
}

/// Whether the integration behind an item exists in this build.
enum CatalogStatus { available, unavailable }

/// How an item is opened. Routes are dispatched centrally; widgets never
/// embed routing strings themselves.
enum CatalogActionKind {
  /// `context.go(route)`.
  route,

  /// Open the PDF import sheet, then the report explanation chat.
  explainReport,

  /// The existing feedback sheet.
  feedback,

  /// Emergency guidance sheet (never booking, never a pretend dispatch).
  emergency,

  /// Hospital-directory sheet, with the existing clinic path when unavailable.
  selectHospital,

  /// A planned extension: the Future work explanation sheet.
  futureWork,

  /// A service detail page (`context.push(route)`) that explains the
  /// service and offers its real action only when one works.
  serviceDetail,

  /// A core destination that does not exist yet ("Not available").
  unavailable,
}

/// Quick Access sub-groups (all of them sit below Services on Home).
enum QuickAccessGroup { records, care, wellbeing }

/// Services catalogue groups, in display order (promotions sit between
/// [core] and [tools]).
enum ServiceGroup { core, tools, futureExtensions, policies }

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.action,
    this.route,
    this.description,
    this.accent = PatientAccent.blue,
    this.access = CatalogAccess.signedIn,
    this.scope = CatalogScope.core,
    this.status = CatalogStatus.available,
  });

  /// Stable id (tests and widget keys).
  final String id;
  final String Function(AppLocalizations t) title;
  final String Function(AppLocalizations t)? description;
  final IconData icon;
  final PatientAccent accent;
  final CatalogActionKind action;

  /// Destination for [CatalogActionKind.route].
  final String? route;
  final CatalogAccess access;
  final CatalogScope scope;
  final CatalogStatus status;

  bool get isAvailable =>
      status == CatalogStatus.available && scope != CatalogScope.planned;

  /// Outside the proposal → carries the visible "Future work" label.
  bool get isFutureWork => scope != CatalogScope.core;
}

/// Every catalogue entry, keyed for reuse.
abstract final class PatientCatalog {
  // --- core: proposal features -------------------------------------------

  static final records = CatalogItem(
    id: 'records',
    title: (t) => t.paHealthRecords,
    description: (t) => t.paHealthRecordsDesc,
    icon: Icons.folder_shared_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientTimeline,
  );
  static final documents = CatalogItem(
    id: 'documents',
    title: (t) => t.paDocuments,
    description: (t) => t.paDocumentsDesc,
    icon: Icons.description_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientDocuments,
  );

  /// The proposal's report-explanation chatbot: core, even while its live
  /// model integration is pending (that gap is recorded, not relabelled).
  static final explainReport = CatalogItem(
    id: 'explain-report',
    title: (t) => t.paExplainReport,
    description: (t) => t.paExplainReportDesc,
    icon: Icons.auto_awesome_outlined,
    action: CatalogActionKind.explainReport,
  );
  static final medications = CatalogItem(
    id: 'medications',
    title: (t) => t.paMedications,
    icon: Icons.medication_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientMedications,
  );
  static final sickLeave = CatalogItem(
    id: 'sick-leave',
    title: (t) => t.paSickLeave,
    icon: Icons.event_busy_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientSickLeave,
  );
  static final imaging = CatalogItem(
    id: 'imaging',
    title: (t) => t.imagingTitle,
    icon: Icons.image_search_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientImaging,
  );
  static final allergies = CatalogItem(
    id: 'allergies',
    title: (t) => t.allergiesLabel,
    icon: Icons.warning_amber_rounded,
    accent: PatientAccent.amber,
    action: CatalogActionKind.route,
    route: AppRoutes.patientAllergies,
  );
  static final appointments = CatalogItem(
    id: 'appointments',
    title: (t) => t.allAppointmentsTitle,
    icon: Icons.event_note_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientAppointments,
  );
  static final bookAppointment = CatalogItem(
    id: 'book-appointment',
    title: (t) => t.paBookAppointment,
    description: (t) => t.paBookAppointmentDesc,
    icon: Icons.calendar_month_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientBookLanding,
  );
  static final visitedDoctors = CatalogItem(
    id: 'visited-doctors',
    title: (t) => t.visitedDoctorsTitle,
    icon: Icons.groups_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientVisitedDoctors,
  );
  static final findDoctor = CatalogItem(
    id: 'find-doctor',
    title: (t) => t.paFindDoctor,
    description: (t) => t.paFindDoctorDesc,
    icon: Icons.person_search_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientFindDoctor,
  );

  // --- supplementary: working, outside the proposal ------------------------

  static final nutrition = CatalogItem(
    id: 'nutrition',
    title: (t) => t.navNutrition,
    icon: Icons.restaurant_outlined,
    accent: PatientAccent.green,
    action: CatalogActionKind.route,
    route: AppRoutes.patientNutrition,
    scope: CatalogScope.supplementary,
  );
  static final vitals = CatalogItem(
    id: 'vitals',
    title: (t) => t.paVitalsTrends,
    icon: Icons.monitor_heart_outlined,
    accent: PatientAccent.green,
    action: CatalogActionKind.route,
    route: AppRoutes.patientVitals,
    scope: CatalogScope.supplementary,
  );
  static final summary = CatalogItem(
    id: 'summary',
    title: (t) => t.paHealthSummary,
    icon: Icons.summarize_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientSummary,
    scope: CatalogScope.supplementary,
  );
  static final messages = CatalogItem(
    id: 'messages',
    title: (t) => t.messagesTitle,
    icon: Icons.forum_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientMessages,
    // Owner-approved primary destination (2026-10-13 brief).
    scope: CatalogScope.core,
  );
  static final notifications = CatalogItem(
    id: 'notifications',
    title: (t) => t.paNotifications,
    icon: Icons.notifications_none,
    accent: PatientAccent.amber,
    action: CatalogActionKind.route,
    route: AppRoutes.patientNotifications,
    scope: CatalogScope.supplementary,
  );
  static final homeVisits = CatalogItem(
    id: 'home-visits',
    title: (t) => t.homeVisitsTitle,
    description: (t) => t.paHomeVisitsDesc,
    icon: Icons.add_home_outlined,
    accent: PatientAccent.green,
    action: CatalogActionKind.route,
    route: AppRoutes.patientHomeVisit,
    scope: CatalogScope.supplementary,
  );
  static final billing = CatalogItem(
    id: 'billing',
    title: (t) => t.paBillingPayments,
    icon: Icons.payments_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientBilling,
    scope: CatalogScope.supplementary,
  );
  static final family = CatalogItem(
    id: 'family',
    title: (t) => t.paFamilyLinked,
    icon: Icons.family_restroom_outlined,
    accent: PatientAccent.green,
    action: CatalogActionKind.route,
    route: AppRoutes.patientProfileFamily,
    scope: CatalogScope.supplementary,
  );
  static final feedback = CatalogItem(
    id: 'feedback',
    title: (t) => t.feedbackTitle,
    icon: Icons.rate_review_outlined,
    accent: PatientAccent.amber,
    action: CatalogActionKind.feedback,
    scope: CatalogScope.supplementary,
  );
  static final emergency = CatalogItem(
    id: 'emergency',
    title: (t) => t.htEmergencyTitle,
    description: (t) => t.paEmergencyServicesDesc,
    icon: Icons.emergency_outlined,
    accent: PatientAccent.blue,
    action: CatalogActionKind.emergency,
    scope: CatalogScope.supplementary,
  );
  static final selectHospital = CatalogItem(
    id: 'select-hospital',
    title: (t) => t.htSelectHospital,
    description: (t) => t.htNoHospitals,
    icon: Icons.local_hospital_outlined,
    action: CatalogActionKind.selectHospital,
    scope: CatalogScope.planned,
    status: CatalogStatus.unavailable,
  );
  static final calculators = CatalogItem(
    id: 'calculators',
    title: (t) => t.paHealthCalculators,
    description: (t) => t.paHealthCalculatorsDesc,
    icon: Icons.calculate_outlined,
    accent: PatientAccent.green,
    action: CatalogActionKind.route,
    route: AppRoutes.patientCalculators,
    // Owner-approved current scope (2026-10-13): working estimates.
    scope: CatalogScope.core,
  );
  static final converters = CatalogItem(
    id: 'converters',
    title: (t) => t.paHealthConverters,
    description: (t) => t.paHealthConvertersDesc,
    icon: Icons.swap_horiz,
    accent: PatientAccent.amber,
    action: CatalogActionKind.route,
    route: AppRoutes.patientConverters,
    scope: CatalogScope.supplementary,
  );
  static final specialtyGuide = CatalogItem(
    id: 'specialty-guide',
    title: (t) => t.paSpecialtyGuideTitle,
    description: (t) => t.paSpecialtyGuideIntro,
    icon: Icons.health_and_safety_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientSpecialtyGuide,
    scope: CatalogScope.supplementary,
  );

  /// Virtual Care opens its own explanation page (what exists today vs. the
  /// unbuilt video visits), so it keeps a route.
  static final virtualCare = CatalogItem(
    id: 'virtual-care',
    title: (t) => t.paVirtualCare,
    description: (t) => t.paVirtualCareDesc,
    icon: Icons.video_camera_front_outlined,
    action: CatalogActionKind.route,
    route: '${AppRoutes.patientBookLanding}?mode=virtual',
    scope: CatalogScope.supplementary,
  );

  // --- planned: not built ---------------------------------------------------

  static CatalogItem _planned(
    String id,
    String Function(AppLocalizations t) title,
    IconData icon,
  ) => CatalogItem(
    id: id,
    title: title,
    icon: icon,
    accent: PatientAccent.neutral,
    action: CatalogActionKind.futureWork,
    scope: CatalogScope.planned,
  );

  /// Planned services with their own detail page (still Future work).
  static CatalogItem _plannedDetail(
    String id,
    String Function(AppLocalizations t) title,
    IconData icon,
  ) => CatalogItem(
    id: id,
    title: title,
    icon: icon,
    accent: PatientAccent.neutral,
    action: CatalogActionKind.serviceDetail,
    route: AppRoutes.patientServiceDetail(id),
    scope: CatalogScope.planned,
  );

  /// Outside the proposal, but its detail page opens the working Vitals.
  static final healthTrackers = CatalogItem(
    id: 'health-trackers',
    title: (t) => t.paHealthTrackers,
    icon: Icons.favorite_border_rounded,
    action: CatalogActionKind.serviceDetail,
    route: AppRoutes.patientServiceDetail('health-trackers'),
    scope: CatalogScope.supplementary,
  );

  static final completeCheckup = _plannedDetail(
    'complete-checkup',
    (t) => t.paCompleteCheckup,
    Icons.health_and_safety_outlined,
  );
  static final indoorNavigation = _planned(
    'indoor-navigation',
    (t) => t.paIndoorNavigation,
    Icons.signpost_outlined,
  );
  static final eReferral = _plannedDetail(
    'e-referral',
    (t) => t.paEReferral,
    Icons.forward_to_inbox_outlined,
  );
  static final bloodDonation = _plannedDetail(
    'blood-donation',
    (t) => t.paBloodDonation,
    Icons.bloodtype_outlined,
  );
  static final wearables = _plannedDetail(
    'wearables',
    (t) => t.paWearables,
    Icons.watch_outlined,
  );
  static final waterTracking = _plannedDetail(
    'water-tracking',
    (t) => t.paWaterTracking,
    Icons.water_drop_outlined,
  );
  static final pharmacy = _planned(
    'pharmacy',
    (t) => t.paPharmacy,
    Icons.local_pharmacy_outlined,
  );

  /// Weather and News: no sources are connected (by decision) — the entries
  /// only explain that they are future work.
  static final weather = _planned(
    'weather',
    (t) => t.paWeather,
    Icons.wb_sunny_outlined,
  );
  static final news = _planned(
    'news',
    (t) => t.paNews,
    Icons.newspaper_outlined,
  );

  // --- core destinations that do not exist yet -----------------------------

  /// MyHealth policies: owner-replaceable documents (assets/policies); the
  /// screen marks unapproved text as a draft.
  static final terms = CatalogItem(
    id: 'terms',
    title: (t) => t.paTerms,
    icon: Icons.gavel_outlined,
    accent: PatientAccent.neutral,
    action: CatalogActionKind.route,
    route: AppRoutes.policyTerms,
  );
  static final privacy = CatalogItem(
    id: 'privacy',
    title: (t) => t.paPrivacy,
    icon: Icons.privacy_tip_outlined,
    accent: PatientAccent.neutral,
    action: CatalogActionKind.route,
    route: AppRoutes.policyPrivacy,
  );

  /// Reference shortcut order, followed by preserved core care actions.
  static final quickTools = [emergency, findDoctor, calculators, converters];
  static final moreTools = [
    bookAppointment,
    documents,
    explainReport,
    selectHospital,
  ];

  /// Home / Services "MyHealth services" carousel.
  static final promotions = [
    bookAppointment,
    explainReport,
    virtualCare,
    homeVisits,
  ];

  /// Home Quick Access — daily-care features that are not bottom tabs.
  /// Records, Documents, Explain a Report and Nutrition lead. Account
  /// administration lives in the drawer.
  static final quickAccess = <QuickAccessGroup, List<CatalogItem>>{
    QuickAccessGroup.records: [
      records,
      documents,
      explainReport,
      nutrition,
      medications,
      sickLeave,
      imaging,
      allergies,
    ],
    QuickAccessGroup.care: [
      appointments,
      bookAppointment,
      visitedDoctors,
      messages,
      notifications,
      homeVisits,
    ],
    QuickAccessGroup.wellbeing: [vitals, summary, calculators, converters],
  };

  /// Drawer: supplementary account tools (account basics are core rows).
  static final drawerTools = [family, billing, feedback];

  /// Services tab catalogue.
  static final services = <ServiceGroup, List<CatalogItem>>{
    ServiceGroup.core: [bookAppointment, records, documents, explainReport],
    ServiceGroup.tools: [vitals, nutrition, calculators, converters],
    ServiceGroup.futureExtensions: [
      emergency,
      selectHospital,
      specialtyGuide,
      virtualCare,
      completeCheckup,
      indoorNavigation,
      eReferral,
      bloodDonation,
      healthTrackers,
      wearables,
      waterTracking,
      pharmacy,
      weather,
      news,
    ],
    ServiceGroup.policies: [terms, privacy],
  };
}
