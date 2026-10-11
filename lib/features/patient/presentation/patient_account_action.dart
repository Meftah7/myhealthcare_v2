import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';

/// Shared account destinations for the native drawer and permanent sidebar.
enum PatientAccountAction {
  preferences(Icons.tune, AppRoutes.patientProfilePreferences),
  profile(Icons.account_circle_outlined, AppRoutes.patientSettings),
  personal(Icons.badge_outlined, AppRoutes.patientProfilePersonal),
  health(Icons.favorite_outline, AppRoutes.patientProfileHealth);

  const PatientAccountAction(this.icon, this.route);
  final IconData icon;
  final String route;

  String title(AppLocalizations t) => switch (this) {
    preferences => t.paSettingsPreferences,
    profile => t.paMyProfile,
    personal => t.paPersonalInformation,
    health => t.healthDetailsTitle,
  };
}
