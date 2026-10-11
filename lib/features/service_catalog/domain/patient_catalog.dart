/// One typed catalogue for every patient shortcut and service: Home quick
/// tools, the Services carousel, the Services catalogue and Home Quick Access
/// all read from here, so labels, routes and access rules are defined once.
library;

import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';

/// Who may open an item.
enum CatalogAccess {
  /// Browsable without an account (service info, directory, tools).
  public,

  /// Patient-specific data — guests are sent to sign in first and resumed.
  signedIn,
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

  /// An honest "not available in this version" sheet.
  unavailable,
}

/// Quick Access sub-groups (all of them sit below Services on Home).
enum QuickAccessGroup { records, care, account }

/// Services catalogue groups, in display order.
enum ServiceGroup { medical, tools, support, policies }

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
    this.status = CatalogStatus.available,
  });

  /// Stable id (tests, analytics-free keys, widget keys).
  final String id;
  final String Function(AppLocalizations t) title;
  final String Function(AppLocalizations t)? description;
  final IconData icon;
  final PatientAccent accent;
  final CatalogActionKind action;

  /// Destination for [CatalogActionKind.route].
  final String? route;
  final CatalogAccess access;
  final CatalogStatus status;

  bool get isAvailable => status == CatalogStatus.available;
}

/// Every catalogue entry, keyed for reuse.
abstract final class PatientCatalog {
  // --- quick tools / medical services -------------------------------------

  static final emergency = CatalogItem(
    id: 'emergency',
    title: (t) => t.paEmergencyServices,
    description: (t) => t.paEmergencyServicesDesc,
    icon: Icons.emergency_outlined,
    accent: PatientAccent.red,
    action: CatalogActionKind.emergency,
    access: CatalogAccess.public,
  );

  static final findDoctor = CatalogItem(
    id: 'find-doctor',
    title: (t) => t.paFindDoctor,
    description: (t) => t.paFindDoctorDesc,
    icon: Icons.person_search_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientFindDoctor,
    access: CatalogAccess.public,
  );

  static final calculators = CatalogItem(
    id: 'calculators',
    title: (t) => t.paHealthCalculators,
    description: (t) => t.paHealthCalculatorsDesc,
    icon: Icons.calculate_outlined,
    accent: PatientAccent.green,
    action: CatalogActionKind.route,
    route: AppRoutes.patientCalculators,
    access: CatalogAccess.public,
  );

  static final converters = CatalogItem(
    id: 'converters',
    title: (t) => t.paHealthConverters,
    description: (t) => t.paHealthConvertersDesc,
    icon: Icons.swap_horiz,
    accent: PatientAccent.amber,
    action: CatalogActionKind.route,
    route: AppRoutes.patientConverters,
    access: CatalogAccess.public,
  );

  static final indoorNavigation = CatalogItem(
    id: 'indoor-navigation',
    title: (t) => t.paIndoorNavigation,
    description: (t) => t.paIndoorNavigationDesc,
    icon: Icons.signpost_outlined,
    accent: PatientAccent.neutral,
    action: CatalogActionKind.unavailable,
    access: CatalogAccess.public,
    status: CatalogStatus.unavailable,
  );

  static final bookAppointment = CatalogItem(
    id: 'book-appointment',
    title: (t) => t.paBookAppointment,
    description: (t) => t.paBookAppointmentDesc,
    icon: Icons.calendar_month_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientBookLanding,
    access: CatalogAccess.public,
  );

  static final completeCheckup = CatalogItem(
    id: 'complete-checkup',
    title: (t) => t.paCompleteCheckup,
    description: (t) => t.paCompleteCheckupDesc,
    icon: Icons.health_and_safety_outlined,
    accent: PatientAccent.neutral,
    action: CatalogActionKind.unavailable,
    access: CatalogAccess.public,
    status: CatalogStatus.unavailable,
  );

  static final eReferral = CatalogItem(
    id: 'e-referral',
    title: (t) => t.paEReferral,
    description: (t) => t.paEReferralDesc,
    icon: Icons.forward_to_inbox_outlined,
    accent: PatientAccent.neutral,
    action: CatalogActionKind.unavailable,
    access: CatalogAccess.public,
    status: CatalogStatus.unavailable,
  );

  static final bloodDonation = CatalogItem(
    id: 'blood-donation',
    title: (t) => t.paBloodDonation,
    description: (t) => t.paBloodDonationDesc,
    icon: Icons.bloodtype_outlined,
    accent: PatientAccent.neutral,
    action: CatalogActionKind.unavailable,
    access: CatalogAccess.public,
    status: CatalogStatus.unavailable,
  );

  static final virtualCare = CatalogItem(
    id: 'virtual-care',
    title: (t) => t.paVirtualCare,
    description: (t) => t.paVirtualCareDesc,
    icon: Icons.video_camera_front_outlined,
    action: CatalogActionKind.route,
    route: '${AppRoutes.patientBookLanding}?mode=virtual',
    access: CatalogAccess.public,
  );

  // --- support / policies --------------------------------------------------

  static final news = CatalogItem(
    id: 'news',
    title: (t) => t.paLatestNews,
    description: (t) => t.paLatestNewsDesc,
    icon: Icons.newspaper_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientNews,
    access: CatalogAccess.public,
  );

  static final contactUs = CatalogItem(
    id: 'contact-us',
    title: (t) => t.paContactUs,
    description: (t) => t.paContactUsDesc,
    icon: Icons.support_agent_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientMessages,
  );

  static final terms = CatalogItem(
    id: 'terms',
    title: (t) => t.paTerms,
    icon: Icons.gavel_outlined,
    accent: PatientAccent.neutral,
    // No published MyHealth terms document exists in this build;
    // shown honestly rather than copying another provider's policy.
    action: CatalogActionKind.unavailable,
    access: CatalogAccess.public,
    status: CatalogStatus.unavailable,
  );

  static final privacy = CatalogItem(
    id: 'privacy',
    title: (t) => t.paPrivacy,
    icon: Icons.privacy_tip_outlined,
    accent: PatientAccent.neutral,
    // No published MyHealth privacy document exists in this build;
    // shown honestly rather than copying another provider's policy.
    action: CatalogActionKind.unavailable,
    access: CatalogAccess.public,
    status: CatalogStatus.unavailable,
  );

  // --- Quick Access: every relocated patient feature ----------------------

  static final records = CatalogItem(
    id: 'records',
    title: (t) => t.paHealthRecords,
    icon: Icons.folder_shared_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientTimeline,
  );
  static final documents = CatalogItem(
    id: 'documents',
    title: (t) => t.paDocuments,
    icon: Icons.description_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientDocuments,
  );
  static final explainReport = CatalogItem(
    id: 'explain-report',
    title: (t) => t.paExplainReport,
    description: (t) => t.paExplainReportDesc,
    icon: Icons.auto_awesome_outlined,
    action: CatalogActionKind.explainReport,
  );
  static final nutrition = CatalogItem(
    id: 'nutrition',
    title: (t) => t.navNutrition,
    icon: Icons.restaurant_outlined,
    accent: PatientAccent.green,
    action: CatalogActionKind.route,
    route: AppRoutes.patientNutrition,
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
  static final vitals = CatalogItem(
    id: 'vitals',
    title: (t) => t.paVitalsTrends,
    icon: Icons.monitor_heart_outlined,
    accent: PatientAccent.green,
    action: CatalogActionKind.route,
    route: AppRoutes.patientVitals,
  );
  static final summary = CatalogItem(
    id: 'summary',
    title: (t) => t.paHealthSummary,
    icon: Icons.summarize_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientSummary,
  );

  static final appointments = CatalogItem(
    id: 'appointments',
    title: (t) => t.allAppointmentsTitle,
    icon: Icons.event_note_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientAppointments,
  );
  static final bookPrivate = CatalogItem(
    id: 'book',
    title: (t) => t.paBookAppointment,
    icon: Icons.calendar_month_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientBookLanding,
    access: CatalogAccess.public,
  );
  static final visitedDoctors = CatalogItem(
    id: 'visited-doctors',
    title: (t) => t.visitedDoctorsTitle,
    icon: Icons.groups_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientVisitedDoctors,
  );
  static final messages = CatalogItem(
    id: 'messages',
    title: (t) => t.messagesTitle,
    icon: Icons.forum_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientMessages,
  );
  static final notifications = CatalogItem(
    id: 'notifications',
    title: (t) => t.paNotifications,
    icon: Icons.notifications_none,
    accent: PatientAccent.amber,
    action: CatalogActionKind.route,
    route: AppRoutes.patientNotifications,
  );
  static final homeVisits = CatalogItem(
    id: 'home-visits',
    title: (t) => t.homeVisitsTitle,
    icon: Icons.add_home_outlined,
    accent: PatientAccent.green,
    action: CatalogActionKind.route,
    route: AppRoutes.patientHomeVisit,
  );
  static final billing = CatalogItem(
    id: 'billing',
    title: (t) => t.paBillingPayments,
    icon: Icons.payments_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientBilling,
  );

  static final profile = CatalogItem(
    id: 'profile',
    title: (t) => t.paMyProfile,
    icon: Icons.account_circle_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientSettings,
  );
  static final personal = CatalogItem(
    id: 'personal',
    title: (t) => t.paPersonalInformation,
    icon: Icons.badge_outlined,
    action: CatalogActionKind.route,
    route: AppRoutes.patientProfilePersonal,
  );
  static final healthDetails = CatalogItem(
    id: 'health-details',
    title: (t) => t.healthDetailsTitle,
    icon: Icons.favorite_outline,
    accent: PatientAccent.red,
    action: CatalogActionKind.route,
    route: AppRoutes.patientProfileHealth,
  );
  static final family = CatalogItem(
    id: 'family',
    title: (t) => t.paFamilyLinked,
    icon: Icons.family_restroom_outlined,
    accent: PatientAccent.green,
    action: CatalogActionKind.route,
    route: AppRoutes.patientProfileFamily,
  );
  static final preferences = CatalogItem(
    id: 'preferences',
    title: (t) => t.paPreferences,
    icon: Icons.tune,
    accent: PatientAccent.neutral,
    action: CatalogActionKind.route,
    route: AppRoutes.patientProfilePreferences,
  );
  static final feedback = CatalogItem(
    id: 'feedback',
    title: (t) => t.feedbackTitle,
    icon: Icons.rate_review_outlined,
    accent: PatientAccent.amber,
    action: CatalogActionKind.feedback,
  );

  /// First quick-tools page, then the additional tools page.
  static final quickTools = [emergency, findDoctor, calculators, converters];
  static final moreTools = [
    findDoctor,
    calculators,
    converters,
    indoorNavigation,
  ];

  /// Home "Services" carousel promotions.
  static final promotions = [
    bookAppointment,
    explainReport,
    virtualCare,
    homeVisits,
  ];

  /// Home Quick Access — every patient feature that is no longer a bottom tab
  /// or a Home section. High-priority entries lead.
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
      vitals,
      summary,
    ],
    QuickAccessGroup.care: [
      appointments,
      bookPrivate,
      visitedDoctors,
      messages,
      notifications,
      homeVisits,
      billing,
    ],
    QuickAccessGroup.account: [
      profile,
      personal,
      healthDetails,
      family,
      preferences,
      feedback,
    ],
  };

  /// Services tab catalogue.
  static final services = <ServiceGroup, List<CatalogItem>>{
    ServiceGroup.medical: [
      emergency,
      bookAppointment,
      completeCheckup,
      indoorNavigation,
      eReferral,
      bloodDonation,
    ],
    ServiceGroup.tools: [vitals, calculators, converters, nutrition],
    ServiceGroup.support: [news, contactUs],
    ServiceGroup.policies: [terms, privacy],
  };
}
