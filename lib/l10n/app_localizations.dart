import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to continue.'**
  String get signOutConfirmBody;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Medical staff'**
  String get roleStaff;

  /// No description provided for @rolePatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get rolePatient;

  /// No description provided for @rolePatientMale.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get rolePatientMale;

  /// No description provided for @rolePatientFemale.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get rolePatientFemale;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @specialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialty;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get jobTitle;

  /// No description provided for @licenseNo.
  ///
  /// In en, this message translates to:
  /// **'License no.'**
  String get licenseNo;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @managedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'These details are managed by your administrator.'**
  String get managedByAdmin;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get none;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @translationNote.
  ///
  /// In en, this message translates to:
  /// **'Full UI translation is in progress — for now the profile screen supports English and Arabic.'**
  String get translationNote;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your records, appointments and care team — in one calm place.'**
  String get signInSubtitle;

  /// No description provided for @sessionEndedNotice.
  ///
  /// In en, this message translates to:
  /// **'Your session ended after 24 minutes of inactivity. Please sign in again.'**
  String get sessionEndedNotice;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailOrNationalIdHelper.
  ///
  /// In en, this message translates to:
  /// **'You can also sign in with your national ID'**
  String get emailOrNationalIdHelper;

  /// No description provided for @emailOrNationalIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or national ID'**
  String get emailOrNationalIdRequired;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordRequired;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @createPatientAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a patient account'**
  String get createPatientAccount;

  /// No description provided for @demoAccounts.
  ///
  /// In en, this message translates to:
  /// **'Demo accounts'**
  String get demoAccounts;

  /// No description provided for @demoPatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get demoPatient;

  /// No description provided for @demoStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get demoStaff;

  /// No description provided for @demoAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get demoAdmin;

  /// No description provided for @demoPasswordNote.
  ///
  /// In en, this message translates to:
  /// **'Password for all accounts: {password}'**
  String demoPasswordNote(String password);

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @settingsSection.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSection;

  /// No description provided for @detailsSection.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsSection;

  /// No description provided for @medicalSectionOptional.
  ///
  /// In en, this message translates to:
  /// **'Medical (optional)'**
  String get medicalSectionOptional;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validEmailRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @nationalIdOptional.
  ///
  /// In en, this message translates to:
  /// **'National ID (optional)'**
  String get nationalIdOptional;

  /// No description provided for @bloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood type'**
  String get bloodType;

  /// No description provided for @chronicConditions.
  ///
  /// In en, this message translates to:
  /// **'Chronic conditions'**
  String get chronicConditions;

  /// No description provided for @commaSeparatedHelper.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated'**
  String get commaSeparatedHelper;

  /// No description provided for @allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContact;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @presenceOnDuty.
  ///
  /// In en, this message translates to:
  /// **'On duty'**
  String get presenceOnDuty;

  /// No description provided for @presenceInConsultation.
  ///
  /// In en, this message translates to:
  /// **'In consultation'**
  String get presenceInConsultation;

  /// No description provided for @presenceOnBreak.
  ///
  /// In en, this message translates to:
  /// **'On break'**
  String get presenceOnBreak;

  /// No description provided for @presenceOffShift.
  ///
  /// In en, this message translates to:
  /// **'Off shift'**
  String get presenceOffShift;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @genderUndisclosed.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderUndisclosed;

  /// No description provided for @appointmentStatusBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get appointmentStatusBooked;

  /// No description provided for @appointmentStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get appointmentStatusConfirmed;

  /// No description provided for @appointmentStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get appointmentStatusInProgress;

  /// No description provided for @appointmentStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get appointmentStatusCompleted;

  /// No description provided for @appointmentStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get appointmentStatusCancelled;

  /// No description provided for @appointmentStatusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get appointmentStatusNoShow;

  /// No description provided for @walkInStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get walkInStatusWaiting;

  /// No description provided for @walkInStatusCalled.
  ///
  /// In en, this message translates to:
  /// **'Called'**
  String get walkInStatusCalled;

  /// No description provided for @walkInStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get walkInStatusInProgress;

  /// No description provided for @walkInStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get walkInStatusDone;

  /// No description provided for @walkInStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get walkInStatusCancelled;

  /// No description provided for @referralRequestStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get referralRequestStatusPending;

  /// No description provided for @referralRequestStatusActioned.
  ///
  /// In en, this message translates to:
  /// **'Actioned'**
  String get referralRequestStatusActioned;

  /// No description provided for @referralRequestStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get referralRequestStatusRejected;

  /// No description provided for @riskBandLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get riskBandLow;

  /// No description provided for @riskBandMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get riskBandMedium;

  /// No description provided for @riskBandHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get riskBandHigh;

  /// No description provided for @recordTypeVisitNote.
  ///
  /// In en, this message translates to:
  /// **'Visit note'**
  String get recordTypeVisitNote;

  /// No description provided for @recordTypeLabResult.
  ///
  /// In en, this message translates to:
  /// **'Lab result'**
  String get recordTypeLabResult;

  /// No description provided for @recordTypeImaging.
  ///
  /// In en, this message translates to:
  /// **'Imaging'**
  String get recordTypeImaging;

  /// No description provided for @recordTypePrescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get recordTypePrescription;

  /// No description provided for @recordTypeVaccination.
  ///
  /// In en, this message translates to:
  /// **'Vaccination'**
  String get recordTypeVaccination;

  /// No description provided for @recordTypeDischarge.
  ///
  /// In en, this message translates to:
  /// **'Discharge'**
  String get recordTypeDischarge;

  /// No description provided for @recordTypeReferral.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get recordTypeReferral;

  /// No description provided for @abnormalFlagNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get abnormalFlagNormal;

  /// No description provided for @abnormalFlagLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get abnormalFlagLow;

  /// No description provided for @abnormalFlagHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get abnormalFlagHigh;

  /// No description provided for @abnormalFlagCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get abnormalFlagCritical;

  /// No description provided for @taskKindFollowUpDue.
  ///
  /// In en, this message translates to:
  /// **'Follow-up due'**
  String get taskKindFollowUpDue;

  /// No description provided for @taskKindUnreviewedAbnormalLab.
  ///
  /// In en, this message translates to:
  /// **'Unreviewed abnormal lab'**
  String get taskKindUnreviewedAbnormalLab;

  /// No description provided for @taskKindUnsignedNote.
  ///
  /// In en, this message translates to:
  /// **'Unsigned note'**
  String get taskKindUnsignedNote;

  /// No description provided for @taskKindMedicationReview.
  ///
  /// In en, this message translates to:
  /// **'Medication review'**
  String get taskKindMedicationReview;

  /// No description provided for @taskKindReferralAction.
  ///
  /// In en, this message translates to:
  /// **'Referral action'**
  String get taskKindReferralAction;

  /// No description provided for @taskKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get taskKindOther;

  /// No description provided for @taskStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get taskStatusOpen;

  /// No description provided for @taskStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get taskStatusInProgress;

  /// No description provided for @taskStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskStatusDone;

  /// No description provided for @taskStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get taskStatusDismissed;

  /// No description provided for @riskFlagKindAbnormalVitals.
  ///
  /// In en, this message translates to:
  /// **'Abnormal vitals'**
  String get riskFlagKindAbnormalVitals;

  /// No description provided for @riskFlagKindAbnormalLab.
  ///
  /// In en, this message translates to:
  /// **'Abnormal lab'**
  String get riskFlagKindAbnormalLab;

  /// No description provided for @riskFlagKindMedicationGap.
  ///
  /// In en, this message translates to:
  /// **'Medication gap'**
  String get riskFlagKindMedicationGap;

  /// No description provided for @riskFlagKindOverdueFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Overdue follow-up'**
  String get riskFlagKindOverdueFollowUp;

  /// No description provided for @riskFlagKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get riskFlagKindOther;

  /// No description provided for @severityInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get severityInfo;

  /// No description provided for @severityWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get severityWarning;

  /// No description provided for @severityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get severityUrgent;

  /// No description provided for @flagSourceRule.
  ///
  /// In en, this message translates to:
  /// **'Rule-based'**
  String get flagSourceRule;

  /// No description provided for @flagSourceAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get flagSourceAi;

  /// No description provided for @reminderKindStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get reminderKindStandard;

  /// No description provided for @reminderKindEscalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated'**
  String get reminderKindEscalated;

  /// No description provided for @reminderKindConfirmRequest.
  ///
  /// In en, this message translates to:
  /// **'Confirmation request'**
  String get reminderKindConfirmRequest;

  /// No description provided for @reminderChannelPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get reminderChannelPush;

  /// No description provided for @reminderChannelInApp.
  ///
  /// In en, this message translates to:
  /// **'In-app'**
  String get reminderChannelInApp;

  /// No description provided for @reminderChannelSms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get reminderChannelSms;

  /// No description provided for @reminderChannelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get reminderChannelEmail;

  /// No description provided for @invoiceStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get invoiceStatusPending;

  /// No description provided for @invoiceStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get invoiceStatusPaid;

  /// No description provided for @invoiceStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get invoiceStatusCancelled;

  /// No description provided for @invoiceStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get invoiceStatusOverdue;

  /// No description provided for @homeVisitStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get homeVisitStatusRequested;

  /// No description provided for @homeVisitStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get homeVisitStatusScheduled;

  /// No description provided for @homeVisitStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get homeVisitStatusCompleted;

  /// No description provided for @homeVisitStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get homeVisitStatusDeclined;

  /// No description provided for @homeVisitStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get homeVisitStatusCancelled;

  /// No description provided for @notificationCategoryAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get notificationCategoryAppointment;

  /// No description provided for @notificationCategoryBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get notificationCategoryBilling;

  /// No description provided for @notificationCategoryLabResult.
  ///
  /// In en, this message translates to:
  /// **'Lab result'**
  String get notificationCategoryLabResult;

  /// No description provided for @notificationCategoryPrescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get notificationCategoryPrescription;

  /// No description provided for @notificationCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get notificationCategoryMessage;

  /// No description provided for @notificationCategorySystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notificationCategorySystem;

  /// No description provided for @feedbackCategoryBug.
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get feedbackCategoryBug;

  /// No description provided for @feedbackCategoryFeatureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature request'**
  String get feedbackCategoryFeatureRequest;

  /// No description provided for @feedbackCategoryGeneralFeedback.
  ///
  /// In en, this message translates to:
  /// **'General feedback'**
  String get feedbackCategoryGeneralFeedback;

  /// No description provided for @feedbackCategoryComplaint.
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get feedbackCategoryComplaint;

  /// No description provided for @feedbackStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get feedbackStatusOpen;

  /// No description provided for @feedbackStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get feedbackStatusResolved;

  /// No description provided for @aiFeatureCareNavigator.
  ///
  /// In en, this message translates to:
  /// **'Care Navigator'**
  String get aiFeatureCareNavigator;

  /// No description provided for @aiFeatureClinicalScribe.
  ///
  /// In en, this message translates to:
  /// **'Clinical Scribe'**
  String get aiFeatureClinicalScribe;

  /// No description provided for @aiFeaturePatientSummary.
  ///
  /// In en, this message translates to:
  /// **'Patient Summary'**
  String get aiFeaturePatientSummary;

  /// No description provided for @nothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here.'**
  String get nothingHere;

  /// No description provided for @selectItemPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select an item to see its details.'**
  String get selectItemPlaceholder;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @riskBadgeLow.
  ///
  /// In en, this message translates to:
  /// **'Low risk'**
  String get riskBadgeLow;

  /// No description provided for @riskBadgeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium risk'**
  String get riskBadgeMedium;

  /// No description provided for @riskBadgeHigh.
  ///
  /// In en, this message translates to:
  /// **'High risk'**
  String get riskBadgeHigh;

  /// No description provided for @severityChipInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get severityChipInfo;

  /// No description provided for @severityChipReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get severityChipReview;

  /// No description provided for @severityChipUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get severityChipUrgent;

  /// No description provided for @aiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI-generated — informational only, not medical advice. Verify with your clinician.'**
  String get aiDisclaimer;

  /// No description provided for @labReferenceSuffix.
  ///
  /// In en, this message translates to:
  /// **', reference {reference}'**
  String labReferenceSuffix(String reference);

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @notificationsTooltipUnread.
  ///
  /// In en, this message translates to:
  /// **'Notifications ({count} unread)'**
  String notificationsTooltipUnread(int count);

  /// No description provided for @greetingFallbackName.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get greetingFallbackName;

  /// No description provided for @sectionYourHealth.
  ///
  /// In en, this message translates to:
  /// **'Your health'**
  String get sectionYourHealth;

  /// No description provided for @sectionUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming appointments'**
  String get sectionUpcomingAppointments;

  /// No description provided for @sectionQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get sectionQuickActions;

  /// No description provided for @quickAppointmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick appointment'**
  String get quickAppointmentTitle;

  /// No description provided for @quickAppointmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent or normal — get seen sooner'**
  String get quickAppointmentSubtitle;

  /// No description provided for @quickAppointmentSheetQuestion.
  ///
  /// In en, this message translates to:
  /// **'How urgent is this visit?'**
  String get quickAppointmentSheetQuestion;

  /// No description provided for @urgencyUrgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgencyUrgentTitle;

  /// No description provided for @urgencyUrgentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-route me to the soonest available doctor'**
  String get urgencyUrgentSubtitle;

  /// No description provided for @urgencyNormalTitle.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get urgencyNormalTitle;

  /// No description provided for @urgencyNormalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a department, doctor and time myself'**
  String get urgencyNormalSubtitle;

  /// No description provided for @onSchedule.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the schedule'**
  String get onSchedule;

  /// No description provided for @metricTicket.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get metricTicket;

  /// No description provided for @metricMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get metricMedicine;

  /// No description provided for @metricLastVisit.
  ///
  /// In en, this message translates to:
  /// **'Last visit'**
  String get metricLastVisit;

  /// No description provided for @allergiesInline.
  ///
  /// In en, this message translates to:
  /// **'Allergies: {list}'**
  String allergiesInline(String list);

  /// No description provided for @quickActionVitals.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get quickActionVitals;

  /// No description provided for @quickActionMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get quickActionMedications;

  /// No description provided for @quickActionAskDoctor.
  ///
  /// In en, this message translates to:
  /// **'Ask your doctor'**
  String get quickActionAskDoctor;

  /// No description provided for @quickActionVisitedDoctors.
  ///
  /// In en, this message translates to:
  /// **'Visited doctors'**
  String get quickActionVisitedDoctors;

  /// No description provided for @quickActionSickLeave.
  ///
  /// In en, this message translates to:
  /// **'Sick leave'**
  String get quickActionSickLeave;

  /// No description provided for @quickActionHomeCare.
  ///
  /// In en, this message translates to:
  /// **'Home care'**
  String get quickActionHomeCare;

  /// No description provided for @quickActionBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get quickActionBilling;

  /// No description provided for @couldNotLoadAppointments.
  ///
  /// In en, this message translates to:
  /// **'Could not load appointments.'**
  String get couldNotLoadAppointments;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments'**
  String get noUpcomingAppointments;

  /// No description provided for @tapToBookVisit.
  ///
  /// In en, this message translates to:
  /// **'Tap to book a visit'**
  String get tapToBookVisit;

  /// No description provided for @carouselPosition.
  ///
  /// In en, this message translates to:
  /// **'{index} of {count}'**
  String carouselPosition(int index, int count);

  /// No description provided for @previousAppointment.
  ///
  /// In en, this message translates to:
  /// **'Previous appointment'**
  String get previousAppointment;

  /// No description provided for @nextAppointment.
  ///
  /// In en, this message translates to:
  /// **'Next appointment'**
  String get nextAppointment;

  /// No description provided for @ticketOverline.
  ///
  /// In en, this message translates to:
  /// **'TICKET'**
  String get ticketOverline;

  /// No description provided for @roomNumber.
  ///
  /// In en, this message translates to:
  /// **'Room {room}'**
  String roomNumber(String room);

  /// No description provided for @bookedForName.
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String bookedForName(String name);

  /// No description provided for @appointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'My appointments'**
  String get appointmentsTitle;

  /// No description provided for @upcomingCount.
  ///
  /// In en, this message translates to:
  /// **'Upcoming ({count})'**
  String upcomingCount(int count);

  /// No description provided for @nothingBookedNote.
  ///
  /// In en, this message translates to:
  /// **'Nothing booked. Use Book now or Schedule above.'**
  String get nothingBookedNote;

  /// No description provided for @historyCount.
  ///
  /// In en, this message translates to:
  /// **'History ({count})'**
  String historyCount(int count);

  /// No description provided for @noPastVisitsNote.
  ///
  /// In en, this message translates to:
  /// **'No past visits yet.'**
  String get noPastVisitsNote;

  /// No description provided for @bookNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get bookNowTitle;

  /// No description provided for @bookNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Soonest opening'**
  String get bookNowSubtitle;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @scheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get scheduleSubtitle;

  /// No description provided for @ticketLabel.
  ///
  /// In en, this message translates to:
  /// **'Ticket {tag}'**
  String ticketLabel(String tag);

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @cancelAppointmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel appointment?'**
  String get cancelAppointmentTitle;

  /// No description provided for @cancelAppointmentMessage.
  ///
  /// In en, this message translates to:
  /// **'This frees the slot for someone else.'**
  String get cancelAppointmentMessage;

  /// No description provided for @cancelItLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel it'**
  String get cancelItLabel;

  /// No description provided for @clinicDaysHelp.
  ///
  /// In en, this message translates to:
  /// **'Clinic days: Sunday–Thursday'**
  String get clinicDaysHelp;

  /// No description provided for @clinicHoursHelp.
  ///
  /// In en, this message translates to:
  /// **'Clinic hours: 08:00–20:00'**
  String get clinicHoursHelp;

  /// No description provided for @pickTimeInRange.
  ///
  /// In en, this message translates to:
  /// **'Pick a time between 08:00 and 20:00.'**
  String get pickTimeInRange;

  /// No description provided for @clinicHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Clinic hours'**
  String get clinicHoursTitle;

  /// No description provided for @clinicHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open days and hours'**
  String get clinicHoursSubtitle;

  /// No description provided for @openDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Open days'**
  String get openDaysLabel;

  /// No description provided for @openTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get openTimeLabel;

  /// No description provided for @closeTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get closeTimeLabel;

  /// No description provided for @clinicHoursSaved.
  ///
  /// In en, this message translates to:
  /// **'Clinic hours updated.'**
  String get clinicHoursSaved;

  /// No description provided for @bookedOn.
  ///
  /// In en, this message translates to:
  /// **'Booked {date}'**
  String bookedOn(String date);

  /// No description provided for @scheduleAVisitTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule a visit'**
  String get scheduleAVisitTitle;

  /// No description provided for @couldNotLoadDepartments.
  ///
  /// In en, this message translates to:
  /// **'Could not load departments.'**
  String get couldNotLoadDepartments;

  /// No description provided for @stepDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get stepDepartment;

  /// No description provided for @stepDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get stepDoctor;

  /// No description provided for @stepReasonForVisit.
  ///
  /// In en, this message translates to:
  /// **'Reason for visit'**
  String get stepReasonForVisit;

  /// No description provided for @stepReasonShort.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get stepReasonShort;

  /// No description provided for @stepDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get stepDateTime;

  /// No description provided for @whoIsThisFor.
  ///
  /// In en, this message translates to:
  /// **'Who is this for?'**
  String get whoIsThisFor;

  /// No description provided for @myself.
  ///
  /// In en, this message translates to:
  /// **'Myself'**
  String get myself;

  /// No description provided for @bookedForNotice.
  ///
  /// In en, this message translates to:
  /// **'This visit will be booked for {name}.'**
  String bookedForNotice(String name);

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total} · {label}'**
  String stepProgress(int step, int total, String label);

  /// No description provided for @couldNotLoadDoctors.
  ///
  /// In en, this message translates to:
  /// **'Could not load doctors'**
  String get couldNotLoadDoctors;

  /// No description provided for @noDoctorsListed.
  ///
  /// In en, this message translates to:
  /// **'No doctors listed for this department yet.'**
  String get noDoctorsListed;

  /// No description provided for @findingSoonestOpening.
  ///
  /// In en, this message translates to:
  /// **'Finding the soonest opening…'**
  String get findingSoonestOpening;

  /// No description provided for @soonestOpeningAt.
  ///
  /// In en, this message translates to:
  /// **'Soonest opening: {relDay}, {date}'**
  String soonestOpeningAt(String relDay, String date);

  /// No description provided for @couldNotLoadTimes.
  ///
  /// In en, this message translates to:
  /// **'Could not load times.'**
  String get couldNotLoadTimes;

  /// No description provided for @noOpenTimesThatDay.
  ///
  /// In en, this message translates to:
  /// **'No open times that day. Try another date.'**
  String get noOpenTimesThatDay;

  /// No description provided for @recommendedSection.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommendedSection;

  /// No description provided for @allOpenTimesSection.
  ///
  /// In en, this message translates to:
  /// **'All open times'**
  String get allOpenTimesSection;

  /// No description provided for @appointmentBooked.
  ///
  /// In en, this message translates to:
  /// **'Appointment booked'**
  String get appointmentBooked;

  /// No description provided for @reviewAndConfirm.
  ///
  /// In en, this message translates to:
  /// **'Review & confirm'**
  String get reviewAndConfirm;

  /// No description provided for @rowLabelFor.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get rowLabelFor;

  /// No description provided for @rowLabelWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get rowLabelWhen;

  /// No description provided for @confirmBookingButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get confirmBookingButton;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @couldNotLoadMedications.
  ///
  /// In en, this message translates to:
  /// **'Could not load medications.'**
  String get couldNotLoadMedications;

  /// No description provided for @noMedicationsOnRecord.
  ///
  /// In en, this message translates to:
  /// **'No medications on record.'**
  String get noMedicationsOnRecord;

  /// No description provided for @currentSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentSectionLabel;

  /// No description provided for @pastSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get pastSectionLabel;

  /// No description provided for @medDoseFrom.
  ///
  /// In en, this message translates to:
  /// **'from {date}'**
  String medDoseFrom(String date);

  /// No description provided for @medDoseTo.
  ///
  /// In en, this message translates to:
  /// **'to {date}'**
  String medDoseTo(String date);

  /// No description provided for @imagingTitle.
  ///
  /// In en, this message translates to:
  /// **'Imaging'**
  String get imagingTitle;

  /// No description provided for @couldNotLoadImaging.
  ///
  /// In en, this message translates to:
  /// **'Could not load your imaging results.'**
  String get couldNotLoadImaging;

  /// No description provided for @noImagingResultsYet.
  ///
  /// In en, this message translates to:
  /// **'No imaging results yet.\nX-rays, scans and ultrasounds show up here after a study.'**
  String get noImagingResultsYet;

  /// No description provided for @reportPdfLabel.
  ///
  /// In en, this message translates to:
  /// **'Report PDF'**
  String get reportPdfLabel;

  /// No description provided for @recordTitle.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordTitle;

  /// No description provided for @couldNotLoadRecord.
  ///
  /// In en, this message translates to:
  /// **'Could not load this record.'**
  String get couldNotLoadRecord;

  /// No description provided for @fromYourVisitOn.
  ///
  /// In en, this message translates to:
  /// **'From your visit on {date}'**
  String fromYourVisitOn(String date);

  /// No description provided for @referralLetterLabel.
  ///
  /// In en, this message translates to:
  /// **'Referral letter'**
  String get referralLetterLabel;

  /// No description provided for @resultsSection.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsSection;

  /// No description provided for @extractedTextSection.
  ///
  /// In en, this message translates to:
  /// **'Extracted text'**
  String get extractedTextSection;

  /// No description provided for @labColumnAnalyte.
  ///
  /// In en, this message translates to:
  /// **'Analyte'**
  String get labColumnAnalyte;

  /// No description provided for @labColumnValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get labColumnValue;

  /// No description provided for @labColumnReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get labColumnReference;

  /// No description provided for @recordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get recordsTitle;

  /// No description provided for @timelineSegment.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineSegment;

  /// No description provided for @medicationsSegment.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get medicationsSegment;

  /// No description provided for @billsSegment.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get billsSegment;

  /// No description provided for @vitalSignsReportLabel.
  ///
  /// In en, this message translates to:
  /// **'Vital signs report'**
  String get vitalSignsReportLabel;

  /// No description provided for @allergiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergiesLabel;

  /// No description provided for @couldNotLoadRecords.
  ///
  /// In en, this message translates to:
  /// **'Could not load your records.'**
  String get couldNotLoadRecords;

  /// No description provided for @nothingMatchesFilters.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches these filters yet.'**
  String get nothingMatchesFilters;

  /// No description provided for @searchRecordsHint.
  ///
  /// In en, this message translates to:
  /// **'Search records'**
  String get searchRecordsHint;

  /// No description provided for @filterVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get filterVisits;

  /// No description provided for @filterLabs.
  ///
  /// In en, this message translates to:
  /// **'Labs'**
  String get filterLabs;

  /// No description provided for @filterPrescriptions.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get filterPrescriptions;

  /// No description provided for @filterVaccinations.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations'**
  String get filterVaccinations;

  /// No description provided for @filterReferrals.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get filterReferrals;

  /// No description provided for @flaggedByAi.
  ///
  /// In en, this message translates to:
  /// **'flagged by AI'**
  String get flaggedByAi;

  /// No description provided for @vitalsRecordedTitle.
  ///
  /// In en, this message translates to:
  /// **'Vitals recorded'**
  String get vitalsRecordedTitle;

  /// No description provided for @vitalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get vitalsTitle;

  /// No description provided for @couldNotLoadVitals.
  ///
  /// In en, this message translates to:
  /// **'Could not load vitals.'**
  String get couldNotLoadVitals;

  /// No description provided for @noVitalsRecordedYet.
  ///
  /// In en, this message translates to:
  /// **'No vitals recorded yet.\nBook a visit to get your first reading.'**
  String get noVitalsRecordedYet;

  /// No description provided for @chartBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure'**
  String get chartBloodPressure;

  /// No description provided for @chartWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get chartWeight;

  /// No description provided for @chartGlucose.
  ///
  /// In en, this message translates to:
  /// **'Glucose'**
  String get chartGlucose;

  /// No description provided for @seriesSystolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get seriesSystolic;

  /// No description provided for @seriesDiastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get seriesDiastolic;

  /// No description provided for @recentReadingsSection.
  ///
  /// In en, this message translates to:
  /// **'Recent readings'**
  String get recentReadingsSection;

  /// No description provided for @couldNotCreateDocument.
  ///
  /// In en, this message translates to:
  /// **'Could not create the document.'**
  String get couldNotCreateDocument;

  /// No description provided for @couldNotLoadInvoices.
  ///
  /// In en, this message translates to:
  /// **'Could not load your invoices.'**
  String get couldNotLoadInvoices;

  /// No description provided for @noInvoicesYet.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet.\nBills for your visits will appear here.'**
  String get noInvoicesYet;

  /// No description provided for @openSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openSectionLabel;

  /// No description provided for @historyLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyLabel;

  /// No description provided for @outstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding balance'**
  String get outstandingBalance;

  /// No description provided for @allSettled.
  ///
  /// In en, this message translates to:
  /// **'All settled'**
  String get allSettled;

  /// No description provided for @openInvoicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} open invoice} other{{count} open invoices}}'**
  String openInvoicesCount(int count);

  /// No description provided for @overdueAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} overdue'**
  String overdueAmount(String amount);

  /// No description provided for @issuedOn.
  ///
  /// In en, this message translates to:
  /// **'Issued {date}'**
  String issuedOn(String date);

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax ({rate}%)'**
  String taxLabel(String rate);

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @wasDueOn.
  ///
  /// In en, this message translates to:
  /// **'Was due {date}'**
  String wasDueOn(String date);

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOn(String date);

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid {date}'**
  String paidOn(String date);

  /// No description provided for @payAmountButton.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmountButton(String amount);

  /// No description provided for @payInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay invoice'**
  String get payInvoiceTitle;

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'{amount} due'**
  String amountDue(String amount);

  /// No description provided for @payWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get payWithLabel;

  /// No description provided for @demoPaymentNote.
  ///
  /// In en, this message translates to:
  /// **'Demo payment — card details are checked on this device and never stored or sent anywhere.'**
  String get demoPaymentNote;

  /// No description provided for @nameOnCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Name on card'**
  String get nameOnCardLabel;

  /// No description provided for @enterNameOnCard.
  ///
  /// In en, this message translates to:
  /// **'Enter the name on the card'**
  String get enterNameOnCard;

  /// No description provided for @cardNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get cardNumberLabel;

  /// No description provided for @enterFullCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a full card number'**
  String get enterFullCardNumber;

  /// No description provided for @cardNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'That card number is not valid'**
  String get cardNumberInvalid;

  /// No description provided for @expiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get expiryLabel;

  /// No description provided for @monthRange.
  ///
  /// In en, this message translates to:
  /// **'Month must be 01–12'**
  String get monthRange;

  /// No description provided for @cardExpired.
  ///
  /// In en, this message translates to:
  /// **'Card has expired'**
  String get cardExpired;

  /// No description provided for @digitsRange.
  ///
  /// In en, this message translates to:
  /// **'3–4 digits'**
  String get digitsRange;

  /// No description provided for @enterSecurityCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 3–4 digit security code.'**
  String get enterSecurityCode;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get paymentReceived;

  /// No description provided for @cardExpiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired {expiry}'**
  String cardExpiredOn(String expiry);

  /// No description provided for @cardExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {expiry}'**
  String cardExpiresOn(String expiry);

  /// No description provided for @payWithDifferentCard.
  ///
  /// In en, this message translates to:
  /// **'Pay with a different card'**
  String get payWithDifferentCard;

  /// No description provided for @securityCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'The 3–4 digits on the back of the card'**
  String get securityCodeHelper;

  /// No description provided for @savedCardsLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved cards'**
  String get savedCardsLabel;

  /// No description provided for @addCardButton.
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get addCardButton;

  /// No description provided for @couldNotLoadCards.
  ///
  /// In en, this message translates to:
  /// **'Could not load cards.'**
  String get couldNotLoadCards;

  /// No description provided for @noCardsSavedYet.
  ///
  /// In en, this message translates to:
  /// **'No cards saved yet.'**
  String get noCardsSavedYet;

  /// No description provided for @transactionHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get transactionHistoryLabel;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments yet.'**
  String get noPaymentsYet;

  /// No description provided for @defaultChip.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultChip;

  /// No description provided for @setDefaultButton.
  ///
  /// In en, this message translates to:
  /// **'Set default'**
  String get setDefaultButton;

  /// No description provided for @removeCardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove card'**
  String get removeCardTooltip;

  /// No description provided for @removeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove card?'**
  String get removeCardTitle;

  /// No description provided for @removeCardMessage.
  ///
  /// In en, this message translates to:
  /// **'{brand} ····{last4} will be removed.'**
  String removeCardMessage(String brand, String last4);

  /// No description provided for @removeButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeButton;

  /// No description provided for @addACardTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a card'**
  String get addACardTitle;

  /// No description provided for @saveCardButton.
  ///
  /// In en, this message translates to:
  /// **'Save card'**
  String get saveCardButton;

  /// No description provided for @cardSavedNote.
  ///
  /// In en, this message translates to:
  /// **'Only the last 4 digits and expiry are saved — never the full number or CVC.'**
  String get cardSavedNote;

  /// No description provided for @expiredSuffix.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get expiredSuffix;

  /// No description provided for @paymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsTitle;

  /// No description provided for @walletBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance'**
  String get walletBalanceLabel;

  /// No description provided for @topUpButton.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get topUpButton;

  /// No description provided for @topUpWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Top up wallet'**
  String get topUpWalletTitle;

  /// No description provided for @topUpAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get topUpAmountLabel;

  /// No description provided for @enterTopUpAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get enterTopUpAmount;

  /// No description provided for @topUpAmountTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get topUpAmountTooSmall;

  /// No description provided for @walletTopUpNote.
  ///
  /// In en, this message translates to:
  /// **'This is a demo top-up — no real money moves, and the balance is stored on this device only.'**
  String get walletTopUpNote;

  /// No description provided for @topUpAmountButton.
  ///
  /// In en, this message translates to:
  /// **'Top up {amount}'**
  String topUpAmountButton(String amount);

  /// No description provided for @walletToppedUpMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallet topped up'**
  String get walletToppedUpMessage;

  /// No description provided for @payWithWalletLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance'**
  String get payWithWalletLabel;

  /// No description provided for @walletBalanceAvailable.
  ///
  /// In en, this message translates to:
  /// **'{amount} available'**
  String walletBalanceAvailable(String amount);

  /// No description provided for @insufficientWalletBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Not enough balance to cover this invoice'**
  String get insufficientWalletBalanceHint;

  /// No description provided for @walletBalancePaidMessage.
  ///
  /// In en, this message translates to:
  /// **'Paid from wallet balance'**
  String get walletBalancePaidMessage;

  /// No description provided for @markAllReadButton.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllReadButton;

  /// No description provided for @couldNotLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Could not load your notifications.'**
  String get couldNotLoadNotifications;

  /// No description provided for @allCaughtUpMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.\nNothing new here.'**
  String get allCaughtUpMessage;

  /// No description provided for @last24HoursSection.
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get last24HoursSection;

  /// No description provided for @earlierSection.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlierSection;

  /// No description provided for @openButton.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openButton;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineStatus;

  /// No description provided for @askAboutAppHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about the app…'**
  String get askAboutAppHint;

  /// No description provided for @openCareNavigator.
  ///
  /// In en, this message translates to:
  /// **'Open Care Navigator'**
  String get openCareNavigator;

  /// No description provided for @hideCareNavigator.
  ///
  /// In en, this message translates to:
  /// **'Hide Care Navigator'**
  String get hideCareNavigator;

  /// No description provided for @showCareNavigator.
  ///
  /// In en, this message translates to:
  /// **'Show Care Navigator'**
  String get showCareNavigator;

  /// No description provided for @taskBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Task board'**
  String get taskBoardTitle;

  /// No description provided for @couldNotLoadTasks.
  ///
  /// In en, this message translates to:
  /// **'Could not load tasks.'**
  String get couldNotLoadTasks;

  /// No description provided for @noOpenTasksMessage.
  ///
  /// In en, this message translates to:
  /// **'No open tasks. Run a panel scan from the dashboard.'**
  String get noOpenTasksMessage;

  /// No description provided for @priorityBlendNote.
  ///
  /// In en, this message translates to:
  /// **'Priority blends the rule score {pct}% with the AI score.'**
  String priorityBlendNote(int pct);

  /// No description provided for @tasksReprioritised.
  ///
  /// In en, this message translates to:
  /// **'Tasks re-prioritised.'**
  String get tasksReprioritised;

  /// No description provided for @prioritiseButton.
  ///
  /// In en, this message translates to:
  /// **'Prioritise'**
  String get prioritiseButton;

  /// No description provided for @startAction.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startAction;

  /// No description provided for @completeAction.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeAction;

  /// No description provided for @dismissAction.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissAction;

  /// No description provided for @ruleScoreTag.
  ///
  /// In en, this message translates to:
  /// **'rule {score}'**
  String ruleScoreTag(String score);

  /// No description provided for @aiScoreTag.
  ///
  /// In en, this message translates to:
  /// **'AI {score}'**
  String aiScoreTag(String score);

  /// No description provided for @dueTag.
  ///
  /// In en, this message translates to:
  /// **'due {relDay}'**
  String dueTag(String relDay);

  /// No description provided for @taskKindFollowUpShort.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get taskKindFollowUpShort;

  /// No description provided for @taskKindAbnormalLabShort.
  ///
  /// In en, this message translates to:
  /// **'Abnormal lab'**
  String get taskKindAbnormalLabShort;

  /// No description provided for @taskKindReferralShort.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get taskKindReferralShort;

  /// No description provided for @homeHealthCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Home health care'**
  String get homeHealthCareTitle;

  /// No description provided for @requestAVisitButton.
  ///
  /// In en, this message translates to:
  /// **'Request a visit'**
  String get requestAVisitButton;

  /// No description provided for @couldNotLoadHomeVisitRequests.
  ///
  /// In en, this message translates to:
  /// **'Could not load your requests.'**
  String get couldNotLoadHomeVisitRequests;

  /// No description provided for @noHomeVisitRequestsMessage.
  ///
  /// In en, this message translates to:
  /// **'No home-visit requests.\nAsk for a clinician to visit you at home when getting to the clinic is hard.'**
  String get noHomeVisitRequestsMessage;

  /// No description provided for @preferredOn.
  ///
  /// In en, this message translates to:
  /// **'Preferred {date}'**
  String preferredOn(String date);

  /// No description provided for @clinicNote.
  ///
  /// In en, this message translates to:
  /// **'Clinic: {note}'**
  String clinicNote(String note);

  /// No description provided for @cancelRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequestButton;

  /// No description provided for @requestAHomeVisitTitle.
  ///
  /// In en, this message translates to:
  /// **'Request a home visit'**
  String get requestAHomeVisitTitle;

  /// No description provided for @homeAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Home address'**
  String get homeAddressLabel;

  /// No description provided for @homeAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Building, road, block, area'**
  String get homeAddressHint;

  /// No description provided for @whyHomeVisitNeededLabel.
  ///
  /// In en, this message translates to:
  /// **'Why is a home visit needed?'**
  String get whyHomeVisitNeededLabel;

  /// No description provided for @departmentOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Department (optional)'**
  String get departmentOptionalLabel;

  /// No description provided for @notSureOption.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get notSureOption;

  /// No description provided for @preferredDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred date: {date}'**
  String preferredDateLabel(String date);

  /// No description provided for @sendRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequestButton;

  /// No description provided for @requestSentToClinic.
  ///
  /// In en, this message translates to:
  /// **'Request sent to the clinic.'**
  String get requestSentToClinic;

  /// No description provided for @clinicWillConfirmNote.
  ///
  /// In en, this message translates to:
  /// **'The clinic will confirm a time or follow up with you.'**
  String get clinicWillConfirmNote;

  /// No description provided for @homeVisitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Home visits'**
  String get homeVisitsTitle;

  /// No description provided for @couldNotLoadQueue.
  ///
  /// In en, this message translates to:
  /// **'Could not load the queue.'**
  String get couldNotLoadQueue;

  /// No description provided for @preferredAndRequestedOn.
  ///
  /// In en, this message translates to:
  /// **'Preferred {preferred}  ·  requested {requested}'**
  String preferredAndRequestedOn(String preferred, String requested);

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String noteLabel(String note);

  /// No description provided for @scheduleButton.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleButton;

  /// No description provided for @declineButton.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineButton;

  /// No description provided for @markCompletedButton.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get markCompletedButton;

  /// No description provided for @scheduleThisVisitTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule this visit'**
  String get scheduleThisVisitTitle;

  /// No description provided for @declineThisRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this request'**
  String get declineThisRequestTitle;

  /// No description provided for @scheduleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Nurse will visit Tue 10:00'**
  String get scheduleHint;

  /// No description provided for @declineHint.
  ///
  /// In en, this message translates to:
  /// **'Reason the request was declined'**
  String get declineHint;

  /// No description provided for @couldNotLoadCertificates.
  ///
  /// In en, this message translates to:
  /// **'Could not load your certificates.'**
  String get couldNotLoadCertificates;

  /// No description provided for @noSickLeaveCertificatesMessage.
  ///
  /// In en, this message translates to:
  /// **'No sick-leave certificates.\nYour doctor can issue one after a visit.'**
  String get noSickLeaveCertificatesMessage;

  /// No description provided for @activeChip.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeChip;

  /// No description provided for @dateRangeDays.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}  ·  {days, plural, one{{days} day} other{{days} days}}'**
  String dateRangeDays(String from, String to, int days);

  /// No description provided for @certificatePdfLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate PDF'**
  String get certificatePdfLabel;

  /// No description provided for @newMessageButton.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessageButton;

  /// No description provided for @couldNotLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'Could not load your messages.'**
  String get couldNotLoadMessages;

  /// No description provided for @onceSeenDoctorMessage.
  ///
  /// In en, this message translates to:
  /// **'Once you have seen a doctor you can message them here.'**
  String get onceSeenDoctorMessage;

  /// No description provided for @noConversationsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.\nTap \"New message\" to ask a non-urgent question.'**
  String get noConversationsYetMessage;

  /// No description provided for @yourDoctorFallback.
  ///
  /// In en, this message translates to:
  /// **'Your doctor'**
  String get yourDoctorFallback;

  /// No description provided for @openPatientChartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open patient chart'**
  String get openPatientChartTooltip;

  /// No description provided for @couldNotLoadConversation.
  ///
  /// In en, this message translates to:
  /// **'Could not load this conversation.'**
  String get couldNotLoadConversation;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get noMessagesYet;

  /// No description provided for @sendNonUrgentQuestionMessage.
  ///
  /// In en, this message translates to:
  /// **'Send your doctor a non-urgent question.\nFor emergencies, call your clinic.'**
  String get sendNonUrgentQuestionMessage;

  /// No description provided for @writeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get writeMessageHint;

  /// No description provided for @youPrefix.
  ///
  /// In en, this message translates to:
  /// **'You: '**
  String get youPrefix;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @couldNotLoadInbox.
  ///
  /// In en, this message translates to:
  /// **'Could not load your inbox.'**
  String get couldNotLoadInbox;

  /// No description provided for @noPatientMessages.
  ///
  /// In en, this message translates to:
  /// **'No patient messages.'**
  String get noPatientMessages;

  /// No description provided for @somethingIsBrokenOption.
  ///
  /// In en, this message translates to:
  /// **'Something is broken'**
  String get somethingIsBrokenOption;

  /// No description provided for @sendFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedbackTitle;

  /// No description provided for @feedbackIntroText.
  ///
  /// In en, this message translates to:
  /// **'Tell the team what is working, what is not, or what you wish the app did.'**
  String get feedbackIntroText;

  /// No description provided for @aboutLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutLabel;

  /// No description provided for @yourMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get yourMessageLabel;

  /// No description provided for @sendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendButton;

  /// No description provided for @feedbackThanksMessage.
  ///
  /// In en, this message translates to:
  /// **'Thanks — your feedback was sent to the team.'**
  String get feedbackThanksMessage;

  /// No description provided for @nutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionTitle;

  /// No description provided for @calculatorSegment.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calculatorSegment;

  /// No description provided for @mealPlanSegment.
  ///
  /// In en, this message translates to:
  /// **'Meal plan'**
  String get mealPlanSegment;

  /// No description provided for @foodsSegment.
  ///
  /// In en, this message translates to:
  /// **'Foods'**
  String get foodsSegment;

  /// No description provided for @aboutYouSection.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get aboutYouSection;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @sexLabel.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get sexLabel;

  /// No description provided for @weightKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKgLabel;

  /// No description provided for @heightCmLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCmLabel;

  /// No description provided for @activityLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityLabel;

  /// No description provided for @activitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get activitySedentary;

  /// No description provided for @activityLightlyActive.
  ///
  /// In en, this message translates to:
  /// **'Lightly active (1–3 days/wk)'**
  String get activityLightlyActive;

  /// No description provided for @activityModeratelyActive.
  ///
  /// In en, this message translates to:
  /// **'Moderately active (3–5 days/wk)'**
  String get activityModeratelyActive;

  /// No description provided for @activityVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Very active (6–7 days/wk)'**
  String get activityVeryActive;

  /// No description provided for @activityExtraActive.
  ///
  /// In en, this message translates to:
  /// **'Extra active (physical job)'**
  String get activityExtraActive;

  /// No description provided for @goalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalLabel;

  /// No description provided for @goalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain weight'**
  String get goalMaintain;

  /// No description provided for @goalLose.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get goalLose;

  /// No description provided for @goalGain.
  ///
  /// In en, this message translates to:
  /// **'Gain weight'**
  String get goalGain;

  /// No description provided for @weeklyRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly rate'**
  String get weeklyRateLabel;

  /// No description provided for @weeklyRate025.
  ///
  /// In en, this message translates to:
  /// **'0.25 kg / week'**
  String get weeklyRate025;

  /// No description provided for @weeklyRate05.
  ///
  /// In en, this message translates to:
  /// **'0.5 kg / week'**
  String get weeklyRate05;

  /// No description provided for @weeklyRate10.
  ///
  /// In en, this message translates to:
  /// **'1.0 kg / week'**
  String get weeklyRate10;

  /// No description provided for @calculateTargetsButton.
  ///
  /// In en, this message translates to:
  /// **'Calculate targets'**
  String get calculateTargetsButton;

  /// No description provided for @preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSection;

  /// No description provided for @macroSplitNote.
  ///
  /// In en, this message translates to:
  /// **'The macro split used for your targets and your meal plan.'**
  String get macroSplitNote;

  /// No description provided for @presetBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get presetBalanced;

  /// No description provided for @presetLowFat.
  ///
  /// In en, this message translates to:
  /// **'Low fat'**
  String get presetLowFat;

  /// No description provided for @presetLowCarb.
  ///
  /// In en, this message translates to:
  /// **'Low carb'**
  String get presetLowCarb;

  /// No description provided for @presetHighCarb.
  ///
  /// In en, this message translates to:
  /// **'High carb'**
  String get presetHighCarb;

  /// No description provided for @presetHighProtein.
  ///
  /// In en, this message translates to:
  /// **'High protein'**
  String get presetHighProtein;

  /// No description provided for @dailyTargetsSection.
  ///
  /// In en, this message translates to:
  /// **'Daily targets'**
  String get dailyTargetsSection;

  /// No description provided for @macroCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get macroCalories;

  /// No description provided for @macroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get macroProtein;

  /// No description provided for @macroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get macroCarbs;

  /// No description provided for @macroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get macroFat;

  /// No description provided for @macroSugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get macroSugar;

  /// No description provided for @macroSatFat.
  ///
  /// In en, this message translates to:
  /// **'Sat. fat'**
  String get macroSatFat;

  /// No description provided for @unitKcalPerDay.
  ///
  /// In en, this message translates to:
  /// **'kcal / day'**
  String get unitKcalPerDay;

  /// No description provided for @unitPerDay.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get unitPerDay;

  /// No description provided for @unitDailyCap.
  ///
  /// In en, this message translates to:
  /// **'daily cap'**
  String get unitDailyCap;

  /// No description provided for @bmrTdeeNote.
  ///
  /// In en, this message translates to:
  /// **'BMR {bmr} kcal · TDEE {tdee} kcal. A guide only — your clinician can tailor this to your care.'**
  String bmrTdeeNote(int bmr, int tdee);

  /// No description provided for @searchFoodsHint.
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get searchFoodsHint;

  /// No description provided for @allCategoriesChip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategoriesChip;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @noFoodsMatch.
  ///
  /// In en, this message translates to:
  /// **'No foods match that search.'**
  String get noFoodsMatch;

  /// No description provided for @servingLabel.
  ///
  /// In en, this message translates to:
  /// **'Serving {value}'**
  String servingLabel(String value);

  /// No description provided for @also.
  ///
  /// In en, this message translates to:
  /// **'Also'**
  String get also;

  /// No description provided for @containsAllergens.
  ///
  /// In en, this message translates to:
  /// **'Contains: {list}'**
  String containsAllergens(String list);

  /// No description provided for @includeDessertTitle.
  ///
  /// In en, this message translates to:
  /// **'Include a dessert'**
  String get includeDessertTitle;

  /// No description provided for @includeDessertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Splits the day into four meals instead of three'**
  String get includeDessertSubtitle;

  /// No description provided for @buildMyDayButton.
  ///
  /// In en, this message translates to:
  /// **'Build my day'**
  String get buildMyDayButton;

  /// No description provided for @runCalculatorFirstNote.
  ///
  /// In en, this message translates to:
  /// **'Run the Calculator first — then your calorie and macro goal is split across the meals here.'**
  String get runCalculatorFirstNote;

  /// No description provided for @yourDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Your day'**
  String get yourDayTitle;

  /// No description provided for @mealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// No description provided for @mealDessert.
  ///
  /// In en, this message translates to:
  /// **'Dessert'**
  String get mealDessert;

  /// No description provided for @switchToLightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get switchToLightMode;

  /// No description provided for @switchToDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get switchToDarkMode;

  /// No description provided for @profileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTooltip;

  /// No description provided for @setYourAvailabilityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set your availability'**
  String get setYourAvailabilityTooltip;

  /// No description provided for @couldNotUpdatePresence.
  ///
  /// In en, this message translates to:
  /// **'Could not update your presence.'**
  String get couldNotUpdatePresence;

  /// No description provided for @panelAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Panel analytics'**
  String get panelAnalyticsTitle;

  /// No description provided for @couldNotComputeAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Could not compute analytics.'**
  String get couldNotComputeAnalytics;

  /// No description provided for @lastNDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Last {days} day} other{Last {days} days}}'**
  String lastNDays(int days);

  /// No description provided for @noShowRateLabel.
  ///
  /// In en, this message translates to:
  /// **'No-show rate'**
  String get noShowRateLabel;

  /// No description provided for @noShowRateCaption.
  ///
  /// In en, this message translates to:
  /// **'{kept} of {total} kept slots'**
  String noShowRateCaption(int kept, int total);

  /// No description provided for @cancellationRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation rate'**
  String get cancellationRateLabel;

  /// No description provided for @cancelledCaption.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} cancelled} other{{count} cancelled}}'**
  String cancelledCaption(int count);

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @perDayCaption.
  ///
  /// In en, this message translates to:
  /// **'{value} per day'**
  String perDayCaption(String value);

  /// No description provided for @upcomingLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingLabel;

  /// No description provided for @bookedOrConfirmedCaption.
  ///
  /// In en, this message translates to:
  /// **'booked or confirmed'**
  String get bookedOrConfirmedCaption;

  /// No description provided for @staffDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff directory'**
  String get staffDirectoryTitle;

  /// No description provided for @couldNotLoadStaffDirectory.
  ///
  /// In en, this message translates to:
  /// **'Could not load the staff directory.'**
  String get couldNotLoadStaffDirectory;

  /// No description provided for @noStaffOnRecord.
  ///
  /// In en, this message translates to:
  /// **'No staff on record.'**
  String get noStaffOnRecord;

  /// No description provided for @cliniciansCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} clinician} other{{count} clinicians}}'**
  String cliniciansCount(int count);

  /// No description provided for @myActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'My activity'**
  String get myActivityTitle;

  /// No description provided for @recordsTab.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get recordsTab;

  /// No description provided for @prescriptionsTab.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptionsTab;

  /// No description provided for @couldNotLoadYourRecords.
  ///
  /// In en, this message translates to:
  /// **'Could not load your records.'**
  String get couldNotLoadYourRecords;

  /// No description provided for @noRecordsAuthoredYet.
  ///
  /// In en, this message translates to:
  /// **'You have not authored any records yet.'**
  String get noRecordsAuthoredYet;

  /// No description provided for @couldNotLoadYourPrescriptions.
  ///
  /// In en, this message translates to:
  /// **'Could not load your prescriptions.'**
  String get couldNotLoadYourPrescriptions;

  /// No description provided for @noPrescriptionsIssuedYet.
  ///
  /// In en, this message translates to:
  /// **'You have not issued any prescriptions yet.'**
  String get noPrescriptionsIssuedYet;

  /// No description provided for @currentMedicationChip.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get currentMedicationChip;

  /// No description provided for @yourShiftHeader.
  ///
  /// In en, this message translates to:
  /// **'Your shift'**
  String get yourShiftHeader;

  /// No description provided for @quickActionsHeader.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActionsHeader;

  /// No description provided for @todaysQueueHeader.
  ///
  /// In en, this message translates to:
  /// **'Today’s queue'**
  String get todaysQueueHeader;

  /// No description provided for @scheduleAction.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleAction;

  /// No description provided for @riskFlagsHeader.
  ///
  /// In en, this message translates to:
  /// **'Risk flags'**
  String get riskFlagsHeader;

  /// No description provided for @patientsAction.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patientsAction;

  /// No description provided for @tasksHeader.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksHeader;

  /// No description provided for @taskBoardAction.
  ///
  /// In en, this message translates to:
  /// **'Task board'**
  String get taskBoardAction;

  /// No description provided for @departmentWalkInsHeader.
  ///
  /// In en, this message translates to:
  /// **'Department walk-ins ({count})'**
  String departmentWalkInsHeader(int count);

  /// No description provided for @yourQueueIsClear.
  ///
  /// In en, this message translates to:
  /// **'Your queue is clear'**
  String get yourQueueIsClear;

  /// No description provided for @nobodyWaitingOpenWeek.
  ///
  /// In en, this message translates to:
  /// **'Nobody waiting — open your week to plan ahead'**
  String get nobodyWaitingOpenWeek;

  /// No description provided for @nextPatientLabel.
  ///
  /// In en, this message translates to:
  /// **'Next · {who}'**
  String nextPatientLabel(String who);

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @inQueueLabel.
  ///
  /// In en, this message translates to:
  /// **'In queue'**
  String get inQueueLabel;

  /// No description provided for @openFlagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Open flags'**
  String get openFlagsLabel;

  /// No description provided for @couldNotLoadYourQueue.
  ///
  /// In en, this message translates to:
  /// **'Could not load your queue.'**
  String get couldNotLoadYourQueue;

  /// No description provided for @nobodyWaitingQueueClear.
  ///
  /// In en, this message translates to:
  /// **'Nobody waiting — your queue is clear.'**
  String get nobodyWaitingQueueClear;

  /// No description provided for @moreActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActionsTooltip;

  /// No description provided for @openChartAction.
  ///
  /// In en, this message translates to:
  /// **'Open chart'**
  String get openChartAction;

  /// No description provided for @addNoteAction.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNoteAction;

  /// No description provided for @transferVisitAction.
  ///
  /// In en, this message translates to:
  /// **'Transfer visit'**
  String get transferVisitAction;

  /// No description provided for @cancelVisitAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel visit'**
  String get cancelVisitAction;

  /// No description provided for @markNoShowAction.
  ///
  /// In en, this message translates to:
  /// **'Mark no-show'**
  String get markNoShowAction;

  /// No description provided for @cancelThisVisitTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this visit?'**
  String get cancelThisVisitTitle;

  /// No description provided for @patientWillNeedToRebook.
  ///
  /// In en, this message translates to:
  /// **'The patient will need to rebook.'**
  String get patientWillNeedToRebook;

  /// No description provided for @markAsNoShowTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as no-show?'**
  String get markAsNoShowTitle;

  /// No description provided for @recordsPatientDidNotAttend.
  ///
  /// In en, this message translates to:
  /// **'This records that the patient did not attend.'**
  String get recordsPatientDidNotAttend;

  /// No description provided for @checkedInLabel.
  ///
  /// In en, this message translates to:
  /// **'checked in'**
  String get checkedInLabel;

  /// No description provided for @couldNotLoadRiskFlags.
  ///
  /// In en, this message translates to:
  /// **'Could not load risk flags.'**
  String get couldNotLoadRiskFlags;

  /// No description provided for @noOpenRiskFlagsRunScan.
  ///
  /// In en, this message translates to:
  /// **'No open risk flags. Run a panel scan to refresh.'**
  String get noOpenRiskFlagsRunScan;

  /// No description provided for @acknowledgeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledgeTooltip;

  /// No description provided for @moreOnPatientsTab.
  ///
  /// In en, this message translates to:
  /// **'+{count} more on the Patients tab'**
  String moreOnPatientsTab(int count);

  /// No description provided for @noOpenTasksRunScan.
  ///
  /// In en, this message translates to:
  /// **'No open tasks. Run a panel scan from Quick actions.'**
  String get noOpenTasksRunScan;

  /// No description provided for @markDoneTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get markDoneTooltip;

  /// No description provided for @newNoteAction.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get newNoteAction;

  /// No description provided for @addClinicalNoteForTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a clinical note for…'**
  String get addClinicalNoteForTitle;

  /// No description provided for @prescribeAction.
  ///
  /// In en, this message translates to:
  /// **'Prescribe'**
  String get prescribeAction;

  /// No description provided for @prescribeForTitle.
  ///
  /// In en, this message translates to:
  /// **'Prescribe for…'**
  String get prescribeForTitle;

  /// No description provided for @labResultAction.
  ///
  /// In en, this message translates to:
  /// **'Lab result'**
  String get labResultAction;

  /// No description provided for @enterLabResultForTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a lab result for…'**
  String get enterLabResultForTitle;

  /// No description provided for @aiScribeAction.
  ///
  /// In en, this message translates to:
  /// **'AI Scribe'**
  String get aiScribeAction;

  /// No description provided for @scribeVisitNoteForTitle.
  ///
  /// In en, this message translates to:
  /// **'Scribe a visit note for…'**
  String get scribeVisitNoteForTitle;

  /// No description provided for @patientSummaryAction.
  ///
  /// In en, this message translates to:
  /// **'Patient summary'**
  String get patientSummaryAction;

  /// No description provided for @summariseTitle.
  ///
  /// In en, this message translates to:
  /// **'Summarise…'**
  String get summariseTitle;

  /// No description provided for @patientLookupAction.
  ///
  /// In en, this message translates to:
  /// **'Patient lookup'**
  String get patientLookupAction;

  /// No description provided for @messagesActionWithCount.
  ///
  /// In en, this message translates to:
  /// **'Messages ({n})'**
  String messagesActionWithCount(int n);

  /// No description provided for @panelScanAction.
  ///
  /// In en, this message translates to:
  /// **'Panel scan'**
  String get panelScanAction;

  /// No description provided for @scanningPanelForRisks.
  ///
  /// In en, this message translates to:
  /// **'Scanning the panel for risks…'**
  String get scanningPanelForRisks;

  /// No description provided for @panelScanCompleteFlags.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Panel scan complete — {count} open flag.} other{Panel scan complete — {count} open flags.}}'**
  String panelScanCompleteFlags(int count);

  /// No description provided for @searchByNameOrNationalId.
  ///
  /// In en, this message translates to:
  /// **'Search by name or national ID'**
  String get searchByNameOrNationalId;

  /// No description provided for @couldNotLoadPatients.
  ///
  /// In en, this message translates to:
  /// **'Could not load patients.'**
  String get couldNotLoadPatients;

  /// No description provided for @noPatientsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No patients match that search.'**
  String get noPatientsMatchSearch;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID {id}'**
  String idLabel(String id);

  /// No description provided for @transferAVisitTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer a visit'**
  String get transferAVisitTitle;

  /// No description provided for @reassignVisitNote.
  ///
  /// In en, this message translates to:
  /// **'Reassign a visit from today to another clinician. It returns to \"booked\" so they can re-accept it.'**
  String get reassignVisitNote;

  /// No description provided for @nothingInQueueToTransfer.
  ///
  /// In en, this message translates to:
  /// **'Nothing in your queue to transfer.'**
  String get nothingInQueueToTransfer;

  /// No description provided for @visitLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get visitLabel;

  /// No description provided for @couldNotLoadDirectory.
  ///
  /// In en, this message translates to:
  /// **'Could not load the directory.'**
  String get couldNotLoadDirectory;

  /// No description provided for @transferToLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer to'**
  String get transferToLabel;

  /// No description provided for @visitTransferred.
  ///
  /// In en, this message translates to:
  /// **'Visit transferred.'**
  String get visitTransferred;

  /// No description provided for @compressTheDay.
  ///
  /// In en, this message translates to:
  /// **'Compress the day'**
  String get compressTheDay;

  /// No description provided for @expandTheDay.
  ///
  /// In en, this message translates to:
  /// **'Expand the day'**
  String get expandTheDay;

  /// No description provided for @previousDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDayTooltip;

  /// No description provided for @nextDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDayTooltip;

  /// No description provided for @previousTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousTooltip;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Your health at a glance'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Body.
  ///
  /// In en, this message translates to:
  /// **'AI-summarised labs, records and vitals turn into one clear picture of how you\'re doing.'**
  String get onboardingPage1Body;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Book the right appointment, faster'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Risk-ranked booking gets you to the right specialist without the back-and-forth.'**
  String get onboardingPage2Body;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'One app, your whole care team'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Patients, staff and admins share one app, so everyone stays on the same page.'**
  String get onboardingPage3Body;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @couldNotLoadYourCalendar.
  ///
  /// In en, this message translates to:
  /// **'Could not load your calendar.'**
  String get couldNotLoadYourCalendar;

  /// No description provided for @nothingBookedThisDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing booked on this day.'**
  String get nothingBookedThisDay;

  /// No description provided for @todaysQueueCaps.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S QUEUE'**
  String get todaysQueueCaps;

  /// No description provided for @waitingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} waiting} other{{count} waiting}}'**
  String waitingCount(int count);

  /// No description provided for @tapPatientOrPressNext.
  ///
  /// In en, this message translates to:
  /// **'Tap a patient, or press Next to begin.'**
  String get tapPatientOrPressNext;

  /// No description provided for @lastPatientInQueue.
  ///
  /// In en, this message translates to:
  /// **'Last patient in the queue'**
  String get lastPatientInQueue;

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'Now: {name}'**
  String nowLabel(String name);

  /// No description provided for @noMorePatients.
  ///
  /// In en, this message translates to:
  /// **'No more patients'**
  String get noMorePatients;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String reasonLabel(String reason);

  /// No description provided for @ageYearsAbbrev.
  ///
  /// In en, this message translates to:
  /// **'{age, plural, one{{age} yr} other{{age} yrs}}'**
  String ageYearsAbbrev(int age);

  /// No description provided for @allergiesInlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Allergies: {list}'**
  String allergiesInlineLabel(String list);

  /// No description provided for @couldNotLoadYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile.'**
  String get couldNotLoadYourProfile;

  /// No description provided for @accountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Specialty, department, licence'**
  String get accountSubtitle;

  /// No description provided for @myActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notes and prescriptions you have authored'**
  String get myActivitySubtitle;

  /// No description provided for @staffDirectorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clinicians, specialties and live presence'**
  String get staffDirectorySubtitle;

  /// No description provided for @panelAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No-show rate, cancellations, utilisation'**
  String get panelAnalyticsSubtitle;

  /// No description provided for @preferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, text size, language, alerts'**
  String get preferencesSubtitle;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPasswordTitle;

  /// No description provided for @enterEmailOrNationalId.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or national ID.'**
  String get enterEmailOrNationalId;

  /// No description provided for @forgotPasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordQuestion;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the email or national ID on your account and we’ll take you to set a new password.'**
  String get forgotPasswordBody;

  /// No description provided for @emailOrNationalIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Email or national ID'**
  String get emailOrNationalIdLabel;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @setNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get setNewPasswordTitle;

  /// No description provided for @startFromForgotPasswordNote.
  ///
  /// In en, this message translates to:
  /// **'Start from the \"Forgot password\" screen so we know which account to reset.'**
  String get startFromForgotPasswordNote;

  /// No description provided for @newPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password (8+ characters)'**
  String get newPasswordLabel;

  /// No description provided for @atLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Characters;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @updatePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePasswordButton;

  /// No description provided for @passwordUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Password updated — sign in with your new password.'**
  String get passwordUpdatedSnackbar;

  /// No description provided for @aiHealthSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'AI health summary'**
  String get aiHealthSummaryTitle;

  /// No description provided for @regenerateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerateTooltip;

  /// No description provided for @regeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Regenerated {when}'**
  String regeneratedAt(String when);

  /// No description provided for @couldNotGenerateSummary.
  ///
  /// In en, this message translates to:
  /// **'Could not generate a summary.\n{error}'**
  String couldNotGenerateSummary(String error);

  /// No description provided for @thingsToCheckHeader.
  ///
  /// In en, this message translates to:
  /// **'Things to check'**
  String get thingsToCheckHeader;

  /// No description provided for @trendsHeader.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trendsHeader;

  /// No description provided for @keyEventsHeader.
  ///
  /// In en, this message translates to:
  /// **'Key events'**
  String get keyEventsHeader;

  /// No description provided for @generatedMeta.
  ///
  /// In en, this message translates to:
  /// **'Generated {when}  ·  {model}  ·  {version}'**
  String generatedMeta(String when, String model, String version);

  /// No description provided for @aiClinicalScribeTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Clinical Scribe'**
  String get aiClinicalScribeTitle;

  /// No description provided for @visitNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit note'**
  String get visitNoteTitle;

  /// No description provided for @visitNoteWithPatient.
  ///
  /// In en, this message translates to:
  /// **'Visit note · {name}'**
  String visitNoteWithPatient(String name);

  /// No description provided for @dictationLabel.
  ///
  /// In en, this message translates to:
  /// **'Dictation'**
  String get dictationLabel;

  /// No description provided for @dictationHint.
  ///
  /// In en, this message translates to:
  /// **'Type or paste your visit notes in plain language — the scribe will structure them.'**
  String get dictationHint;

  /// No description provided for @structuringEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Structuring…'**
  String get structuringEllipsis;

  /// No description provided for @structureWithAi.
  ///
  /// In en, this message translates to:
  /// **'Structure with AI'**
  String get structureWithAi;

  /// No description provided for @structuredNoteHeader.
  ///
  /// In en, this message translates to:
  /// **'Structured note'**
  String get structuredNoteHeader;

  /// No description provided for @chiefComplaintLabel.
  ///
  /// In en, this message translates to:
  /// **'Chief complaint'**
  String get chiefComplaintLabel;

  /// No description provided for @hpiLabel.
  ///
  /// In en, this message translates to:
  /// **'History of present illness'**
  String get hpiLabel;

  /// No description provided for @assessmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get assessmentLabel;

  /// No description provided for @planLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planLabel;

  /// No description provided for @suggestedIcdNote.
  ///
  /// In en, this message translates to:
  /// **'Suggested ICD-10 — confirm before coding'**
  String get suggestedIcdNote;

  /// No description provided for @saveAsVisitNote.
  ///
  /// In en, this message translates to:
  /// **'Save as visit note'**
  String get saveAsVisitNote;

  /// No description provided for @savedToPatientRecord.
  ///
  /// In en, this message translates to:
  /// **'Saved to the patient record.'**
  String get savedToPatientRecord;

  /// No description provided for @clinicalNoteFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Clinical note'**
  String get clinicalNoteFallbackTitle;

  /// No description provided for @patientChartFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient chart'**
  String get patientChartFallbackTitle;

  /// No description provided for @aiSummaryTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI summary'**
  String get aiSummaryTooltip;

  /// No description provided for @couldNotLoadThisPatient.
  ///
  /// In en, this message translates to:
  /// **'Could not load this patient.'**
  String get couldNotLoadThisPatient;

  /// No description provided for @recentVitalsHeader.
  ///
  /// In en, this message translates to:
  /// **'Recent vitals'**
  String get recentVitalsHeader;

  /// No description provided for @couldNotLoadMedicationsChart.
  ///
  /// In en, this message translates to:
  /// **'Could not load medications'**
  String get couldNotLoadMedicationsChart;

  /// No description provided for @noActiveMedications.
  ///
  /// In en, this message translates to:
  /// **'No active medications'**
  String get noActiveMedications;

  /// No description provided for @noVitalsOnRecord.
  ///
  /// In en, this message translates to:
  /// **'No vitals on record'**
  String get noVitalsOnRecord;

  /// No description provided for @couldNotLoadTimelineChart.
  ///
  /// In en, this message translates to:
  /// **'Could not load timeline'**
  String get couldNotLoadTimelineChart;

  /// No description provided for @noRecordsYet.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get noRecordsYet;

  /// No description provided for @addClinicalNoteAction.
  ///
  /// In en, this message translates to:
  /// **'Add clinical note'**
  String get addClinicalNoteAction;

  /// No description provided for @aiScribeANoteAction.
  ///
  /// In en, this message translates to:
  /// **'AI Scribe a note'**
  String get aiScribeANoteAction;

  /// No description provided for @prescribeMedicationAction.
  ///
  /// In en, this message translates to:
  /// **'Prescribe medication'**
  String get prescribeMedicationAction;

  /// No description provided for @enterLabResultAction.
  ///
  /// In en, this message translates to:
  /// **'Enter lab result'**
  String get enterLabResultAction;

  /// No description provided for @labResultFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Lab result'**
  String get labResultFallbackTitle;

  /// No description provided for @issueSickLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Issue sick leave'**
  String get issueSickLeaveAction;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @noteFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteFieldLabel;

  /// No description provided for @noteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note added.'**
  String get noteAdded;

  /// No description provided for @medicationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Medication name'**
  String get medicationNameLabel;

  /// No description provided for @doseOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Dose (optional)'**
  String get doseOptionalLabel;

  /// No description provided for @frequencyOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency (optional)'**
  String get frequencyOptionalLabel;

  /// No description provided for @medicationPrescribed.
  ///
  /// In en, this message translates to:
  /// **'Medication prescribed.'**
  String get medicationPrescribed;

  /// No description provided for @panelTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Panel / title'**
  String get panelTitleLabel;

  /// No description provided for @analyteLabel.
  ///
  /// In en, this message translates to:
  /// **'Analyte'**
  String get analyteLabel;

  /// No description provided for @valueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @refLowLabel.
  ///
  /// In en, this message translates to:
  /// **'Ref low'**
  String get refLowLabel;

  /// No description provided for @refHighLabel.
  ///
  /// In en, this message translates to:
  /// **'Ref high'**
  String get refHighLabel;

  /// No description provided for @labResultRecorded.
  ///
  /// In en, this message translates to:
  /// **'Lab result recorded.'**
  String get labResultRecorded;

  /// No description provided for @reasonDiagnosisLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason / diagnosis'**
  String get reasonDiagnosisLabel;

  /// No description provided for @acuteViralIllnessHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Acute viral illness'**
  String get acuteViralIllnessHint;

  /// No description provided for @fromDateLabel.
  ///
  /// In en, this message translates to:
  /// **'From: {date}'**
  String fromDateLabel(String date);

  /// No description provided for @toDateLabel.
  ///
  /// In en, this message translates to:
  /// **'To: {date}'**
  String toDateLabel(String date);

  /// No description provided for @notesOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptionalLabel;

  /// No description provided for @certificateIssued.
  ///
  /// In en, this message translates to:
  /// **'Certificate issued.'**
  String get certificateIssued;

  /// No description provided for @daysCountPlain.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{{days} day} other{{days} days}}'**
  String daysCountPlain(int days);

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @consultationFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get consultationFallbackTitle;

  /// No description provided for @couldNotLoadThisAppointment.
  ///
  /// In en, this message translates to:
  /// **'Could not load this appointment.'**
  String get couldNotLoadThisAppointment;

  /// No description provided for @couldNotLoadThePatient.
  ///
  /// In en, this message translates to:
  /// **'Could not load the patient.'**
  String get couldNotLoadThePatient;

  /// No description provided for @clinicalNoteHeader.
  ///
  /// In en, this message translates to:
  /// **'Clinical note'**
  String get clinicalNoteHeader;

  /// No description provided for @historyExamHint.
  ///
  /// In en, this message translates to:
  /// **'History, examination, assessment, plan…'**
  String get historyExamHint;

  /// No description provided for @openAiScribeAction.
  ///
  /// In en, this message translates to:
  /// **'Open AI Scribe'**
  String get openAiScribeAction;

  /// No description provided for @noMedicationsAdded.
  ///
  /// In en, this message translates to:
  /// **'No medications added.'**
  String get noMedicationsAdded;

  /// No description provided for @removeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeTooltip;

  /// No description provided for @addMedicationAction.
  ///
  /// In en, this message translates to:
  /// **'Add medication'**
  String get addMedicationAction;

  /// No description provided for @referralHeader.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get referralHeader;

  /// No description provided for @referralRequestedAwaitingAdmin.
  ///
  /// In en, this message translates to:
  /// **'Referral requested — awaiting admin'**
  String get referralRequestedAwaitingAdmin;

  /// No description provided for @requestAReferralAction.
  ///
  /// In en, this message translates to:
  /// **'Request a referral'**
  String get requestAReferralAction;

  /// No description provided for @visitSummaryOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit summary (optional)'**
  String get visitSummaryOptionalLabel;

  /// No description provided for @visitSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'One line — the outcome of this visit'**
  String get visitSummaryHint;

  /// No description provided for @completeConsultationAction.
  ///
  /// In en, this message translates to:
  /// **'Complete consultation'**
  String get completeConsultationAction;

  /// No description provided for @addNoteMedOrReferralFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a note, a medication or a referral request first.'**
  String get addNoteMedOrReferralFirst;

  /// No description provided for @referralRequestedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Referral requested.'**
  String get referralRequestedSnackbar;

  /// No description provided for @completeConsultationTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete consultation?'**
  String get completeConsultationTitle;

  /// No description provided for @completeConsultationBody.
  ///
  /// In en, this message translates to:
  /// **'The note and any medications will be saved to the patient record and the visit will be closed.'**
  String get completeConsultationBody;

  /// No description provided for @consultationCompletedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Consultation completed.'**
  String get consultationCompletedSnackbar;

  /// No description provided for @patientCalledInNote.
  ///
  /// In en, this message translates to:
  /// **'Patient has been called in.'**
  String get patientCalledInNote;

  /// No description provided for @callPatientAction.
  ///
  /// In en, this message translates to:
  /// **'Call patient'**
  String get callPatientAction;

  /// No description provided for @patientCalledSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Patient called.'**
  String get patientCalledSnackbar;

  /// No description provided for @patientArrivedAction.
  ///
  /// In en, this message translates to:
  /// **'Patient arrived'**
  String get patientArrivedAction;

  /// No description provided for @consultationStartedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Consultation started.'**
  String get consultationStartedSnackbar;

  /// No description provided for @markedAsNoShowSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Marked as no-show.'**
  String get markedAsNoShowSnackbar;

  /// No description provided for @patientNotShownAction.
  ///
  /// In en, this message translates to:
  /// **'Patient not shown'**
  String get patientNotShownAction;

  /// No description provided for @consultationCompletedHeader.
  ///
  /// In en, this message translates to:
  /// **'Consultation completed'**
  String get consultationCompletedHeader;

  /// No description provided for @adminWillDecideReferralNote.
  ///
  /// In en, this message translates to:
  /// **'The admin will decide whether this is a department or an external referral, and where.'**
  String get adminWillDecideReferralNote;

  /// No description provided for @clinicalReasonForReferralLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinical reason for referral'**
  String get clinicalReasonForReferralLabel;

  /// No description provided for @adminStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get adminStatusAvailable;

  /// No description provided for @adminStatusMeeting.
  ///
  /// In en, this message translates to:
  /// **'In a meeting'**
  String get adminStatusMeeting;

  /// No description provided for @adminStatusAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get adminStatusAway;

  /// No description provided for @adminStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get adminStatusOff;

  /// No description provided for @accountSubtitleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Name, email, member since'**
  String get accountSubtitleAdmin;

  /// No description provided for @auditLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get auditLogTitle;

  /// No description provided for @auditLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything that has changed, newest first'**
  String get auditLogSubtitle;

  /// No description provided for @systemAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'System analytics'**
  String get systemAnalyticsTitle;

  /// No description provided for @systemAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Headline counts, no-show and utilisation'**
  String get systemAnalyticsSubtitle;

  /// No description provided for @capacityForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Capacity forecast'**
  String get capacityForecastTitle;

  /// No description provided for @capacityForecastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Busiest hours and where demand outruns supply'**
  String get capacityForecastSubtitle;

  /// No description provided for @aiSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI settings'**
  String get aiSettingsTitle;

  /// No description provided for @aiSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Features, mock mode, API key'**
  String get aiSettingsSubtitle;

  /// No description provided for @aiActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'AI activity'**
  String get aiActivityTitle;

  /// No description provided for @aiActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Which surface answered, live model or fallback'**
  String get aiActivitySubtitle;

  /// No description provided for @preferencesSubtitleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Theme, text size, language, alerts, sounds'**
  String get preferencesSubtitleAdmin;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackTitle;

  /// No description provided for @allFilterChip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilterChip;

  /// No description provided for @couldNotLoadFeedback.
  ///
  /// In en, this message translates to:
  /// **'Could not load feedback.'**
  String get couldNotLoadFeedback;

  /// No description provided for @noFeedbackInView.
  ///
  /// In en, this message translates to:
  /// **'No feedback in this view.'**
  String get noFeedbackInView;

  /// No description provided for @anonymousFallback.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymousFallback;

  /// No description provided for @reopenAction.
  ///
  /// In en, this message translates to:
  /// **'Re-open'**
  String get reopenAction;

  /// No description provided for @markResolvedAction.
  ///
  /// In en, this message translates to:
  /// **'Mark resolved'**
  String get markResolvedAction;

  /// No description provided for @couldNotLoadAuditLog.
  ///
  /// In en, this message translates to:
  /// **'Could not load the audit log.'**
  String get couldNotLoadAuditLog;

  /// No description provided for @noAuditEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No audit entries yet.'**
  String get noAuditEntriesYet;

  /// No description provided for @byActorLabel.
  ///
  /// In en, this message translates to:
  /// **'by {actor}'**
  String byActorLabel(String actor);

  /// No description provided for @couldNotLoadAiLog.
  ///
  /// In en, this message translates to:
  /// **'Could not load the AI log.'**
  String get couldNotLoadAiLog;

  /// No description provided for @noAiActivityRecordedYet.
  ///
  /// In en, this message translates to:
  /// **'No AI activity recorded yet.'**
  String get noAiActivityRecordedYet;

  /// No description provided for @aiCallsSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} calls · {live} via the live model · {offline} offline'**
  String aiCallsSummary(int total, int live, int offline);

  /// No description provided for @liveModelLabel.
  ///
  /// In en, this message translates to:
  /// **'live model'**
  String get liveModelLabel;

  /// No description provided for @offlineLabel.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get offlineLabel;

  /// No description provided for @directoryHeader.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get directoryHeader;

  /// No description provided for @couldNotLoadSystemStats.
  ///
  /// In en, this message translates to:
  /// **'Could not load system stats.'**
  String get couldNotLoadSystemStats;

  /// No description provided for @staffCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staffCountLabel;

  /// No description provided for @adminsLabel.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get adminsLabel;

  /// No description provided for @departmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get departmentsLabel;

  /// No description provided for @openRiskFlagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Open risk flags'**
  String get openRiskFlagsLabel;

  /// No description provided for @appointmentsLast90DaysHeader.
  ///
  /// In en, this message translates to:
  /// **'Appointments · last 90 days'**
  String get appointmentsLast90DaysHeader;

  /// No description provided for @couldNotLoadAppointmentStats.
  ///
  /// In en, this message translates to:
  /// **'Could not load appointment stats.'**
  String get couldNotLoadAppointmentStats;

  /// No description provided for @noShowRiskModelNote.
  ///
  /// In en, this message translates to:
  /// **'No-show risk predictions come from the offline logistic-regression model (RQ2).'**
  String get noShowRiskModelNote;

  /// No description provided for @allAppointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get allAppointmentsTitle;

  /// No description provided for @couldNotLoadAppointmentsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Could not load appointments.'**
  String get couldNotLoadAppointmentsAdmin;

  /// No description provided for @noAppointmentsInView.
  ///
  /// In en, this message translates to:
  /// **'No appointments in this view.'**
  String get noAppointmentsInView;

  /// No description provided for @unassignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassignedLabel;

  /// No description provided for @recomputeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Recompute'**
  String get recomputeTooltip;

  /// No description provided for @couldNotComputeForecast.
  ///
  /// In en, this message translates to:
  /// **'Could not compute the forecast.'**
  String get couldNotComputeForecast;

  /// No description provided for @forecastExplainerNote.
  ///
  /// In en, this message translates to:
  /// **'Busiest window per weekday, from appointment history. A flag means peak demand has been running at or above a single clinician’s hourly capacity.'**
  String get forecastExplainerNote;

  /// No description provided for @demandLevelHigh.
  ///
  /// In en, this message translates to:
  /// **'High demand'**
  String get demandLevelHigh;

  /// No description provided for @demandLevelModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get demandLevelModerate;

  /// No description provided for @demandLevelLow.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get demandLevelLow;

  /// No description provided for @overflowRiskLabel.
  ///
  /// In en, this message translates to:
  /// **'Overflow risk'**
  String get overflowRiskLabel;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @peakWindowSummary.
  ///
  /// In en, this message translates to:
  /// **'Peak {window} · up to {count}/hr'**
  String peakWindowSummary(String window, int count);

  /// No description provided for @billingTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billingTitle;

  /// No description provided for @couldNotLoadInvoicesAdmin.
  ///
  /// In en, this message translates to:
  /// **'Could not load invoices.'**
  String get couldNotLoadInvoicesAdmin;

  /// No description provided for @noInvoicesInView.
  ///
  /// In en, this message translates to:
  /// **'No invoices in this view.'**
  String get noInvoicesInView;

  /// No description provided for @markPaidAction.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get markPaidAction;

  /// No description provided for @cancelThisInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this invoice?'**
  String get cancelThisInvoiceTitle;

  /// No description provided for @patientWillNoLongerOweIt.
  ///
  /// In en, this message translates to:
  /// **'The patient will no longer owe it.'**
  String get patientWillNoLongerOweIt;

  /// No description provided for @cancelInvoiceAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel invoice'**
  String get cancelInvoiceAction;

  /// No description provided for @invoiceMarkedStatus.
  ///
  /// In en, this message translates to:
  /// **'Invoice marked {status}.'**
  String invoiceMarkedStatus(String status);

  /// No description provided for @newDepartmentAction.
  ///
  /// In en, this message translates to:
  /// **'New department'**
  String get newDepartmentAction;

  /// No description provided for @noDepartmentsYet.
  ///
  /// In en, this message translates to:
  /// **'No departments yet.'**
  String get noDepartmentsYet;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteConfirmTitle(String name);

  /// No description provided for @cannotBeUndoneNote.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get cannotBeUndoneNote;

  /// No description provided for @itemDeletedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String itemDeletedSnackbar(String name);

  /// No description provided for @editDepartmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit department'**
  String get editDepartmentTitle;

  /// No description provided for @descriptionOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptionalLabel;

  /// No description provided for @couldNotLoadSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not load settings.'**
  String get couldNotLoadSettings;

  /// No description provided for @aiFeaturesEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'AI features enabled'**
  String get aiFeaturesEnabledTitle;

  /// No description provided for @aiFeaturesEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off to hide all AI surfaces entirely.'**
  String get aiFeaturesEnabledSubtitle;

  /// No description provided for @forceMockModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Force mock mode'**
  String get forceMockModeTitle;

  /// No description provided for @forceMockModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the offline deterministic assistant even when a key is set. Recommended for demos.'**
  String get forceMockModeSubtitle;

  /// No description provided for @llmProviderHeader.
  ///
  /// In en, this message translates to:
  /// **'LLM provider (Google Gemini, free tier)'**
  String get llmProviderHeader;

  /// No description provided for @demoDataHeader.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get demoDataHeader;

  /// No description provided for @reseedDemoDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Re-seed demo data'**
  String get reseedDemoDataTitle;

  /// No description provided for @reseedDemoDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wipe and regenerate the synthetic dataset.'**
  String get reseedDemoDataSubtitle;

  /// No description provided for @reseedConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Re-seed?'**
  String get reseedConfirmTitle;

  /// No description provided for @reseedConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes all current data and regenerates the demo dataset.'**
  String get reseedConfirmBody;

  /// No description provided for @reseedAction.
  ///
  /// In en, this message translates to:
  /// **'Re-seed'**
  String get reseedAction;

  /// No description provided for @reseededSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Re-seeded: {patients} patients, {appointments} appointments.'**
  String reseededSnackbar(int patients, int appointments);

  /// No description provided for @modelFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelFieldLabel;

  /// No description provided for @modelFieldHelper.
  ///
  /// In en, this message translates to:
  /// **'e.g. gemini-2.0-flash, gemini-2.5-flash'**
  String get modelFieldHelper;

  /// No description provided for @apiKeySetTitle.
  ///
  /// In en, this message translates to:
  /// **'API key set'**
  String get apiKeySetTitle;

  /// No description provided for @apiKeyStoredNote.
  ///
  /// In en, this message translates to:
  /// **'Stored in the OS secure store.'**
  String get apiKeyStoredNote;

  /// No description provided for @replaceAction.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replaceAction;

  /// No description provided for @apiKeyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKeyFieldLabel;

  /// No description provided for @apiKeyHelper.
  ///
  /// In en, this message translates to:
  /// **'aistudio.google.com/apikey — never logged or committed'**
  String get apiKeyHelper;

  /// No description provided for @noApiKeySet.
  ///
  /// In en, this message translates to:
  /// **'No API key set.'**
  String get noApiKeySet;

  /// No description provided for @connectionOkMessage.
  ///
  /// In en, this message translates to:
  /// **'Connection OK — the model responded.'**
  String get connectionOkMessage;

  /// No description provided for @connectionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String connectionFailedMessage(String error);

  /// No description provided for @testConnectionAction.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnectionAction;

  /// No description provided for @systemHealthHeader.
  ///
  /// In en, this message translates to:
  /// **'System health'**
  String get systemHealthHeader;

  /// No description provided for @analyticsAction.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsAction;

  /// No description provided for @recentActivityHeader.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivityHeader;

  /// No description provided for @allClearTitle.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get allClearTitle;

  /// No description provided for @noQueuesWaitingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No invoices, reports, visit or referral requests waiting'**
  String get noQueuesWaitingSubtitle;

  /// No description provided for @unpaidInvoiceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} unpaid invoice} other{{count} unpaid invoices}}'**
  String unpaidInvoiceCount(int count);

  /// No description provided for @openReportCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} open report} other{{count} open reports}}'**
  String openReportCount(int count);

  /// No description provided for @visitRequestCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} visit request} other{{count} visit requests}}'**
  String visitRequestCount(int count);

  /// No description provided for @referralRequestCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} referral request} other{{count} referral requests}}'**
  String referralRequestCount(int count);

  /// No description provided for @thingsNeedYouTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} thing needs you} other{{count} things need you}}'**
  String thingsNeedYouTitle(int count);

  /// No description provided for @viewDetailedAnalytics.
  ///
  /// In en, this message translates to:
  /// **'View detailed analytics'**
  String get viewDetailedAnalytics;

  /// No description provided for @referralRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Referral requests'**
  String get referralRequestsTitle;

  /// No description provided for @noReferralRequestsWaiting.
  ///
  /// In en, this message translates to:
  /// **'No referral requests waiting.'**
  String get noReferralRequestsWaiting;

  /// No description provided for @aClinicianFallback.
  ///
  /// In en, this message translates to:
  /// **'A clinician'**
  String get aClinicianFallback;

  /// No description provided for @requestedByOn.
  ///
  /// In en, this message translates to:
  /// **'Requested by {name} · {date}'**
  String requestedByOn(String name, String date);

  /// No description provided for @actionButton.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get actionButton;

  /// No description provided for @rejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectAction;

  /// No description provided for @patientReferredSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{name} referred.'**
  String patientReferredSnackbar(String name);

  /// No description provided for @rejectThisRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this request'**
  String get rejectThisRequestTitle;

  /// No description provided for @whyNoReferralNeededHint.
  ///
  /// In en, this message translates to:
  /// **'Why is no referral needed?'**
  String get whyNoReferralNeededHint;

  /// No description provided for @actionReferralTitle.
  ///
  /// In en, this message translates to:
  /// **'Action referral'**
  String get actionReferralTitle;

  /// No description provided for @anotherDepartmentSegment.
  ///
  /// In en, this message translates to:
  /// **'Another department'**
  String get anotherDepartmentSegment;

  /// No description provided for @anotherHospitalSegment.
  ///
  /// In en, this message translates to:
  /// **'Another hospital'**
  String get anotherHospitalSegment;

  /// No description provided for @hospitalLabel.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get hospitalLabel;

  /// No description provided for @departmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get departmentLabel;

  /// No description provided for @noteForRecordOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Note for the record (optional)'**
  String get noteForRecordOptionalLabel;

  /// No description provided for @referPatientAction.
  ///
  /// In en, this message translates to:
  /// **'Refer patient'**
  String get referPatientAction;

  /// No description provided for @addUserAction.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get addUserAction;

  /// No description provided for @broadcastAction.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcastAction;

  /// No description provided for @createInvoiceAction.
  ///
  /// In en, this message translates to:
  /// **'Create invoice'**
  String get createInvoiceAction;

  /// No description provided for @feedbackActionWithCount.
  ///
  /// In en, this message translates to:
  /// **'Feedback ({count})'**
  String feedbackActionWithCount(int count);

  /// No description provided for @homeVisitsAction.
  ///
  /// In en, this message translates to:
  /// **'Home visits'**
  String get homeVisitsAction;

  /// No description provided for @homeVisitsActionWithCount.
  ///
  /// In en, this message translates to:
  /// **'Home visits ({count})'**
  String homeVisitsActionWithCount(int count);

  /// No description provided for @referralsAction.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get referralsAction;

  /// No description provided for @referralsActionWithCount.
  ///
  /// In en, this message translates to:
  /// **'Referrals ({count})'**
  String referralsActionWithCount(int count);

  /// No description provided for @reseedDataAction.
  ///
  /// In en, this message translates to:
  /// **'Re-seed data'**
  String get reseedDataAction;

  /// No description provided for @addAPersonTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a…'**
  String get addAPersonTitle;

  /// No description provided for @reseedDemoDataConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Re-seed demo data?'**
  String get reseedDemoDataConfirmTitle;

  /// No description provided for @reseedWipeWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This wipes every account, appointment and record and rebuilds the demo dataset. You will be signed out.'**
  String get reseedWipeWarningBody;

  /// No description provided for @reseedingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Re-seeding…'**
  String get reseedingEllipsis;

  /// No description provided for @reseededFullSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Re-seeded: {patients} patients, {staff} staff, {appointments} appointments.'**
  String reseededFullSnackbar(int patients, int staff, int appointments);

  /// No description provided for @sentToCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Sent to {count} person.} other{Sent to {count} people.}}'**
  String sentToCount(int count);

  /// No description provided for @broadcastNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast a notification'**
  String get broadcastNotificationTitle;

  /// No description provided for @sendToLabel.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get sendToLabel;

  /// No description provided for @allPatientsOption.
  ///
  /// In en, this message translates to:
  /// **'All patients'**
  String get allPatientsOption;

  /// No description provided for @allStaffOption.
  ///
  /// In en, this message translates to:
  /// **'All staff'**
  String get allStaffOption;

  /// No description provided for @everyoneOption.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyoneOption;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @createAnInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an invoice'**
  String get createAnInvoiceTitle;

  /// No description provided for @amountBdBeforeTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (BD, before tax)'**
  String get amountBdBeforeTaxLabel;

  /// No description provided for @whatIsThisForOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'What is this for? (optional)'**
  String get whatIsThisForOptionalLabel;

  /// No description provided for @taxTotalDueNote.
  ///
  /// In en, this message translates to:
  /// **'+ 10% tax = BD {total} total · due {date}'**
  String taxTotalDueNote(String total, String date);

  /// No description provided for @raiseInvoiceAction.
  ///
  /// In en, this message translates to:
  /// **'Raise invoice'**
  String get raiseInvoiceAction;

  /// No description provided for @invoiceRaisedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Invoice raised — BD {amount}.'**
  String invoiceRaisedSnackbar(String amount);

  /// No description provided for @userManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'User management'**
  String get userManagementTitle;

  /// No description provided for @searchByNameOrEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email'**
  String get searchByNameOrEmailHint;

  /// No description provided for @addPatientAction.
  ///
  /// In en, this message translates to:
  /// **'Add patient'**
  String get addPatientAction;

  /// No description provided for @addStaffAction.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get addStaffAction;

  /// No description provided for @addAdminAction.
  ///
  /// In en, this message translates to:
  /// **'Add admin'**
  String get addAdminAction;

  /// No description provided for @couldNotLoadUsers.
  ///
  /// In en, this message translates to:
  /// **'Could not load users.'**
  String get couldNotLoadUsers;

  /// No description provided for @noUsersInGroup.
  ///
  /// In en, this message translates to:
  /// **'No users in this group.'**
  String get noUsersInGroup;

  /// No description provided for @noUsersMatchQuery.
  ///
  /// In en, this message translates to:
  /// **'No users match “{query}”.'**
  String noUsersMatchQuery(String query);

  /// No description provided for @emailDeactivatedLabel.
  ///
  /// In en, this message translates to:
  /// **'{email} · deactivated'**
  String emailDeactivatedLabel(String email);

  /// No description provided for @deactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateAction;

  /// No description provided for @reactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivateAction;

  /// No description provided for @resetPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordAction;

  /// No description provided for @bookAppointmentAction.
  ///
  /// In en, this message translates to:
  /// **'Book appointment'**
  String get bookAppointmentAction;

  /// No description provided for @referAction.
  ///
  /// In en, this message translates to:
  /// **'Refer'**
  String get referAction;

  /// No description provided for @userDeactivatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{name} deactivated'**
  String userDeactivatedSnackbar(String name);

  /// No description provided for @userReactivatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{name} reactivated'**
  String userReactivatedSnackbar(String name);

  /// No description provided for @passwordResetForSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Password reset for {name}'**
  String passwordResetForSnackbar(String name);

  /// No description provided for @nationalIdLabel.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalIdLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @accountActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountActiveLabel;

  /// No description provided for @accountDeactivatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get accountDeactivatedLabel;

  /// No description provided for @joinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedLabel;

  /// No description provided for @newTemporaryPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'New temporary password'**
  String get newTemporaryPasswordTitle;

  /// No description provided for @resetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetAction;

  /// No description provided for @addAnAdministratorTitle.
  ///
  /// In en, this message translates to:
  /// **'Add an administrator'**
  String get addAnAdministratorTitle;

  /// No description provided for @addAPatientTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a patient'**
  String get addAPatientTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @temporaryPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Temporary password (8+ chars)'**
  String get temporaryPasswordLabel;

  /// No description provided for @createAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAction;

  /// No description provided for @createdSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{name} created'**
  String createdSnackbar(String name);

  /// No description provided for @addStaffMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Add staff member'**
  String get addStaffMemberTitle;

  /// No description provided for @doctorOption.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorOption;

  /// No description provided for @nurseOption.
  ///
  /// In en, this message translates to:
  /// **'Nurse'**
  String get nurseOption;

  /// No description provided for @specialtyUnitOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialty / unit (optional)'**
  String get specialtyUnitOptionalLabel;

  /// No description provided for @specialtyOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialty (optional)'**
  String get specialtyOptionalLabel;

  /// No description provided for @noneOption.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneOption;

  /// No description provided for @bookAnAppointmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Book an appointment'**
  String get bookAnAppointmentTitle;

  /// No description provided for @forPatientLabel.
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String forPatientLabel(String name);

  /// No description provided for @clinicDaysHelpText.
  ///
  /// In en, this message translates to:
  /// **'Clinic days: Sunday–Thursday'**
  String get clinicDaysHelpText;

  /// No description provided for @clinicHoursHelpText.
  ///
  /// In en, this message translates to:
  /// **'Clinic hours: 08:00–20:00'**
  String get clinicHoursHelpText;

  /// No description provided for @chooseDepartmentFirstHelper.
  ///
  /// In en, this message translates to:
  /// **'Choose a department first'**
  String get chooseDepartmentFirstHelper;

  /// No description provided for @noDoctorsInDepartmentHelper.
  ///
  /// In en, this message translates to:
  /// **'No doctors in this department'**
  String get noDoctorsInDepartmentHelper;

  /// No description provided for @doctorLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @pickTimeBetweenNote.
  ///
  /// In en, this message translates to:
  /// **'Pick a time between 08:00 and 20:00.'**
  String get pickTimeBetweenNote;

  /// No description provided for @visitTypeFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit type'**
  String get visitTypeFieldLabel;

  /// No description provided for @reasonOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptionalLabel;

  /// No description provided for @appointmentBookedForSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Appointment booked for {name}'**
  String appointmentBookedForSnackbar(String name);

  /// No description provided for @reasonForReferralLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for referral'**
  String get reasonForReferralLabel;

  /// No description provided for @patientReferredToSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{name} referred to {destination}'**
  String patientReferredToSnackbar(String name, String destination);

  /// No description provided for @textSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeLabel;

  /// No description provided for @textSizeCaption.
  ///
  /// In en, this message translates to:
  /// **'{level} — applies to text across the whole app'**
  String textSizeCaption(String level);

  /// No description provided for @textScaleSmaller.
  ///
  /// In en, this message translates to:
  /// **'Smaller'**
  String get textScaleSmaller;

  /// No description provided for @textScaleSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get textScaleSmall;

  /// No description provided for @textScaleDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get textScaleDefault;

  /// No description provided for @textScaleLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textScaleLarge;

  /// No description provided for @textScaleLarger.
  ///
  /// In en, this message translates to:
  /// **'Larger'**
  String get textScaleLarger;

  /// No description provided for @notificationChannelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification channels'**
  String get notificationChannelsLabel;

  /// No description provided for @smsLabel.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get smsLabel;

  /// No description provided for @soundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get soundsLabel;

  /// No description provided for @soundsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A short cue when a message arrives, and when a working status changes'**
  String get soundsSubtitle;

  /// No description provided for @notificationChannelsCaption.
  ///
  /// In en, this message translates to:
  /// **'Where appointment reminders and care alerts reach you.'**
  String get notificationChannelsCaption;

  /// No description provided for @personalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get personalInfoTitle;

  /// No description provided for @personalInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, contact, date of birth'**
  String get personalInfoSubtitle;

  /// No description provided for @healthDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Health details'**
  String get healthDetailsTitle;

  /// No description provided for @healthDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blood type, allergies, conditions'**
  String get healthDetailsSubtitle;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTitle;

  /// No description provided for @walletSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved cards and payment history'**
  String get walletSubtitle;

  /// No description provided for @familyNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Family network'**
  String get familyNetworkTitle;

  /// No description provided for @familyNetworkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'People linked to your account'**
  String get familyNetworkSubtitle;

  /// No description provided for @profileUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileUpdatedSnackbar;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @cprLabel.
  ///
  /// In en, this message translates to:
  /// **'CPR'**
  String get cprLabel;

  /// No description provided for @cprDigitsHelper.
  ///
  /// In en, this message translates to:
  /// **'{count}/9 digits'**
  String cprDigitsHelper(int count);

  /// No description provided for @dateOfBirthDdmmyyyyLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (DD/MM/YYYY)'**
  String get dateOfBirthDdmmyyyyLabel;

  /// No description provided for @genderFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderFieldLabel;

  /// No description provided for @healthDetailsUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Health details updated.'**
  String get healthDetailsUpdatedSnackbar;

  /// No description provided for @bloodTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood type'**
  String get bloodTypeLabel;

  /// No description provided for @unknownOption.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownOption;

  /// No description provided for @separateWithCommasHelper.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas'**
  String get separateWithCommasHelper;

  /// No description provided for @chronicConditionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Chronic conditions'**
  String get chronicConditionsLabel;

  /// No description provided for @emergencyContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContactLabel;

  /// No description provided for @emergencyContactHint.
  ///
  /// In en, this message translates to:
  /// **'Name · phone'**
  String get emergencyContactHint;

  /// No description provided for @sharedWithCliniciansNote.
  ///
  /// In en, this message translates to:
  /// **'Shared with the clinicians who treat you.'**
  String get sharedWithCliniciansNote;

  /// No description provided for @couldNotLoadYourAllergies.
  ///
  /// In en, this message translates to:
  /// **'Could not load your allergies.'**
  String get couldNotLoadYourAllergies;

  /// No description provided for @shownToCliniciansNote.
  ///
  /// In en, this message translates to:
  /// **'Shown to every clinician who treats you and printed on your reports. Keep it accurate.'**
  String get shownToCliniciansNote;

  /// No description provided for @addYourAllergiesAction.
  ///
  /// In en, this message translates to:
  /// **'Add your allergies'**
  String get addYourAllergiesAction;

  /// No description provided for @updateAllergiesAction.
  ///
  /// In en, this message translates to:
  /// **'Update allergies'**
  String get updateAllergiesAction;

  /// No description provided for @knownAllergiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Known allergies'**
  String get knownAllergiesLabel;

  /// No description provided for @noAllergiesRecordedTitle.
  ///
  /// In en, this message translates to:
  /// **'No allergies recorded'**
  String get noAllergiesRecordedTitle;

  /// No description provided for @noAllergiesRecordedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If you have any drug, food or other allergies, add them so your care team can see them.'**
  String get noAllergiesRecordedSubtitle;

  /// No description provided for @couldNotLoadFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Could not load family members.'**
  String get couldNotLoadFamilyMembers;

  /// No description provided for @noFamilyMembersLinkedYet.
  ///
  /// In en, this message translates to:
  /// **'No family members linked yet.'**
  String get noFamilyMembersLinkedYet;

  /// No description provided for @addFamilyMemberAction.
  ///
  /// In en, this message translates to:
  /// **'Add family member'**
  String get addFamilyMemberAction;

  /// No description provided for @removeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeConfirmTitle(String name);

  /// No description provided for @unlinksFromFamilyNetworkNote.
  ///
  /// In en, this message translates to:
  /// **'This unlinks them from your family network.'**
  String get unlinksFromFamilyNetworkNote;

  /// No description provided for @editFamilyMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit family member'**
  String get editFamilyMemberTitle;

  /// No description provided for @relationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationshipLabel;

  /// No description provided for @firstNameRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'First name *'**
  String get firstNameRequiredLabel;

  /// No description provided for @lastNameRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name *'**
  String get lastNameRequiredLabel;

  /// No description provided for @cprOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'CPR (optional)'**
  String get cprOptionalLabel;

  /// No description provided for @dobDdmmyyyyOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (DD/MM/YYYY, optional)'**
  String get dobDdmmyyyyOptionalLabel;

  /// No description provided for @genderOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender (optional)'**
  String get genderOptionalLabel;

  /// No description provided for @bloodTypeOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood type (optional)'**
  String get bloodTypeOptionalLabel;

  /// No description provided for @saveChangesAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesAction;

  /// No description provided for @cprValueLabel.
  ///
  /// In en, this message translates to:
  /// **'CPR {value}'**
  String cprValueLabel(String value);

  /// No description provided for @familyRelationshipSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get familyRelationshipSpouse;

  /// No description provided for @familyRelationshipChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get familyRelationshipChild;

  /// No description provided for @familyRelationshipParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get familyRelationshipParent;

  /// No description provided for @familyRelationshipSibling.
  ///
  /// In en, this message translates to:
  /// **'Sibling'**
  String get familyRelationshipSibling;

  /// No description provided for @familyRelationshipGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get familyRelationshipGuardian;

  /// No description provided for @familyRelationshipOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get familyRelationshipOther;

  /// No description provided for @visitedDoctorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Visited doctors'**
  String get visitedDoctorsTitle;

  /// No description provided for @couldNotLoadYourCareTeam.
  ///
  /// In en, this message translates to:
  /// **'Could not load your care team.'**
  String get couldNotLoadYourCareTeam;

  /// No description provided for @noPastVisitsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'No past visits yet.\nDoctors you see will appear here.'**
  String get noPastVisitsYetMessage;

  /// No description provided for @visitCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} visit} other{{count} visits}}'**
  String visitCountLabel(int count);

  /// No description provided for @lastVisitLabel.
  ///
  /// In en, this message translates to:
  /// **'Last {date}'**
  String lastVisitLabel(String date);

  /// No description provided for @nextVisitLabel.
  ///
  /// In en, this message translates to:
  /// **'Next {date}'**
  String nextVisitLabel(String date);

  /// No description provided for @generalDepartmentFallback.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalDepartmentFallback;

  /// No description provided for @bookAgainAction.
  ///
  /// In en, this message translates to:
  /// **'Book again'**
  String get bookAgainAction;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get navNutrition;

  /// No description provided for @navAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get navAppointments;

  /// No description provided for @navRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get navRecords;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navPatients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get navPatients;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get navUsers;

  /// No description provided for @navDepartments.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get navDepartments;

  /// No description provided for @navBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get navBilling;

  /// No description provided for @pickPatientPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Pick a patient to open their chart.'**
  String get pickPatientPlaceholder;

  /// No description provided for @idValueLabel.
  ///
  /// In en, this message translates to:
  /// **'ID {value}'**
  String idValueLabel(String value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
