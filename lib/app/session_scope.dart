/// What survives a change of signed-in account, and what does not.
///
/// A provider listed in [deviceScopedProviders] describes the device or the
/// app itself (storage, repositories, display preferences, navigation).
/// *Everything else* is treated as belonging to the signed-in user and is
/// discarded whenever the session ends or the account changes: chart and
/// record caches, drafts, AI summaries and chat, search boxes, schedule
/// focus, nutrition state. The list is an allowlist on purpose — a provider
/// added later is cleared by default, so a shared device can't leak one
/// person's data to the next because someone forgot to reset it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di.dart';
import '../features/ai_chat/application/care_navigator.dart';
import '../features/auth/application/session.dart';
import 'router.dart';
import 'settings/ui_prefs.dart';

Set<ProviderOrFamily> get deviceScopedProviders => {
  // Platform, storage, identity plumbing.
  appModeProvider,
  sharedPreferencesProvider,
  appDatabaseProvider,
  passwordHasherProvider,
  authContextProvider,
  accessPolicyProvider,
  recoveryDeliveryProvider,
  aiKeyStoreProvider,
  reminderSchedulerProvider,
  deviceNotifierProvider,
  reminderDispatcherProvider,
  outboxDispatcherProvider,
  seederProvider,
  appBootstrapProvider,
  // Repositories hold no user state — every call re-authorizes.
  authRepositoryProvider,
  userRepositoryProvider,
  patientRepositoryProvider,
  departmentRepositoryProvider,
  appointmentRepositoryProvider,
  billingRepositoryProvider,
  paymentGatewayProvider,
  familyLinkRepositoryProvider,
  sickLeaveRepositoryProvider,
  careMessageRepositoryProvider,
  homeVisitRepositoryProvider,
  walkInTicketRepositoryProvider,
  encounterDraftRepositoryProvider,
  encounterRepositoryProvider,
  resultReviewRepositoryProvider,
  exportRepositoryProvider,
  referralRequestRepositoryProvider,
  notificationRepositoryProvider,
  recordRepositoryProvider,
  vitalsRepositoryProvider,
  medicationRepositoryProvider,
  taskRepositoryProvider,
  riskRepositoryProvider,
  aiSummaryRepositoryProvider,
  auditRepositoryProvider,
  settingsRepositoryProvider,
  feedbackRepositoryProvider,
  aiUsageRepositoryProvider,
  careTeamRepositoryProvider,
  staffCredentialRepositoryProvider,
  // The session itself and navigation.
  sessionProvider,
  currentUserProvider,
  routerProvider,
  // Device display preferences.
  motionPreferenceProvider,
  themeModeProvider,
  localeProvider,
  textScaleProvider,
  soundsEnabledProvider,
  highContrastProvider,
  hasSeenOnboardingProvider,
  clinicScheduleProvider,
  settingsSaveFailureProvider,
  adminStatusProvider,
  careNavPlacementProvider,
};

/// Invalidate every live provider that is not device-scoped.
void discardUserScopedState(ProviderContainer container) {
  final keep = deviceScopedProviders;
  final discard = <ProviderBase<Object?>>{};
  for (final element in container.getAllProviderElements()) {
    final provider = element.origin;
    final family = provider.from;
    if (keep.contains(provider) || (family != null && keep.contains(family))) {
      continue;
    }
    discard.add(provider);
  }
  for (final provider in discard) {
    container.invalidate(provider);
  }
}
