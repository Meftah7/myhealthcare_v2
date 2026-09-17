// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profile => 'Profile';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'You will need to sign in again to continue.';

  @override
  String get account => 'Account';

  @override
  String get roleStaff => 'Medical staff';

  @override
  String get rolePatient => 'Patient';

  @override
  String get rolePatientMale => 'Patient';

  @override
  String get rolePatientFemale => 'Patient';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get specialty => 'Specialty';

  @override
  String get jobTitle => 'Job title';

  @override
  String get licenseNo => 'License no.';

  @override
  String get department => 'Department';

  @override
  String get memberSince => 'Member since';

  @override
  String get managedByAdmin =>
      'These details are managed by your administrator.';

  @override
  String get none => '—';

  @override
  String get preferences => 'Preferences';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get translationNote =>
      'Full UI translation is in progress — for now the profile screen supports English and Arabic.';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle =>
      'Your records, appointments and care team — in one calm place.';

  @override
  String get sessionEndedNotice =>
      'Your session ended after 24 minutes of inactivity. Please sign in again.';

  @override
  String get email => 'Email';

  @override
  String get emailOrNationalIdHelper =>
      'You can also sign in with your national ID';

  @override
  String get emailOrNationalIdRequired => 'Enter your email or national ID';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get createPatientAccount => 'Create a patient account';

  @override
  String get demoAccounts => 'Demo accounts';

  @override
  String get demoPatient => 'Patient';

  @override
  String get demoStaff => 'Staff';

  @override
  String get demoAdmin => 'Admin';

  @override
  String demoPasswordNote(String password) {
    return 'Password for all accounts: $password';
  }

  @override
  String get createAccount => 'Create account';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get accountSection => 'Account';

  @override
  String get settingsSection => 'Settings';

  @override
  String get detailsSection => 'Details';

  @override
  String get medicalSectionOptional => 'Medical (optional)';

  @override
  String get fullName => 'Full name';

  @override
  String get validEmailRequired => 'Enter a valid email';

  @override
  String get passwordMinLength => 'At least 6 characters';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get gender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get nationalIdOptional => 'National ID (optional)';

  @override
  String get bloodType => 'Blood type';

  @override
  String get chronicConditions => 'Chronic conditions';

  @override
  String get commaSeparatedHelper => 'Comma-separated';

  @override
  String get allergies => 'Allergies';

  @override
  String get emergencyContact => 'Emergency contact';

  @override
  String get requiredField => 'Required';

  @override
  String get presenceOnDuty => 'On duty';

  @override
  String get presenceInConsultation => 'In consultation';

  @override
  String get presenceOnBreak => 'On break';

  @override
  String get presenceOffShift => 'Off shift';

  @override
  String get genderOther => 'Other';

  @override
  String get genderUndisclosed => 'Prefer not to say';

  @override
  String get appointmentStatusBooked => 'Booked';

  @override
  String get appointmentStatusConfirmed => 'Confirmed';

  @override
  String get appointmentStatusInProgress => 'In progress';

  @override
  String get appointmentStatusCompleted => 'Completed';

  @override
  String get appointmentStatusCancelled => 'Cancelled';

  @override
  String get appointmentStatusNoShow => 'No-show';

  @override
  String get walkInStatusWaiting => 'Waiting';

  @override
  String get walkInStatusCalled => 'Called';

  @override
  String get walkInStatusInProgress => 'In progress';

  @override
  String get walkInStatusDone => 'Done';

  @override
  String get walkInStatusCancelled => 'Cancelled';

  @override
  String get referralRequestStatusPending => 'Pending';

  @override
  String get referralRequestStatusActioned => 'Actioned';

  @override
  String get referralRequestStatusRejected => 'Rejected';

  @override
  String get riskBandLow => 'Low';

  @override
  String get riskBandMedium => 'Medium';

  @override
  String get riskBandHigh => 'High';

  @override
  String get recordTypeVisitNote => 'Visit note';

  @override
  String get recordTypeLabResult => 'Lab result';

  @override
  String get recordTypeImaging => 'Imaging';

  @override
  String get recordTypePrescription => 'Prescription';

  @override
  String get recordTypeVaccination => 'Vaccination';

  @override
  String get recordTypeDischarge => 'Discharge';

  @override
  String get recordTypeReferral => 'Referral';

  @override
  String get abnormalFlagNormal => 'Normal';

  @override
  String get abnormalFlagLow => 'Low';

  @override
  String get abnormalFlagHigh => 'High';

  @override
  String get abnormalFlagCritical => 'Critical';

  @override
  String get taskKindFollowUpDue => 'Follow-up due';

  @override
  String get taskKindUnreviewedAbnormalLab => 'Unreviewed abnormal lab';

  @override
  String get taskKindUnsignedNote => 'Unsigned note';

  @override
  String get taskKindMedicationReview => 'Medication review';

  @override
  String get taskKindReferralAction => 'Referral action';

  @override
  String get taskKindOther => 'Other';

  @override
  String get taskStatusOpen => 'Open';

  @override
  String get taskStatusInProgress => 'In progress';

  @override
  String get taskStatusDone => 'Done';

  @override
  String get taskStatusDismissed => 'Dismissed';

  @override
  String get riskFlagKindAbnormalVitals => 'Abnormal vitals';

  @override
  String get riskFlagKindAbnormalLab => 'Abnormal lab';

  @override
  String get riskFlagKindMedicationGap => 'Medication gap';

  @override
  String get riskFlagKindOverdueFollowUp => 'Overdue follow-up';

  @override
  String get riskFlagKindOther => 'Other';

  @override
  String get severityInfo => 'Info';

  @override
  String get severityWarning => 'Warning';

  @override
  String get severityUrgent => 'Urgent';

  @override
  String get flagSourceRule => 'Rule-based';

  @override
  String get flagSourceAi => 'AI';

  @override
  String get reminderKindStandard => 'Standard';

  @override
  String get reminderKindEscalated => 'Escalated';

  @override
  String get reminderKindConfirmRequest => 'Confirmation request';

  @override
  String get reminderChannelPush => 'Push';

  @override
  String get reminderChannelInApp => 'In-app';

  @override
  String get reminderChannelSms => 'SMS';

  @override
  String get reminderChannelEmail => 'Email';

  @override
  String get invoiceStatusPending => 'Pending';

  @override
  String get invoiceStatusPaid => 'Paid';

  @override
  String get invoiceStatusCancelled => 'Cancelled';

  @override
  String get invoiceStatusOverdue => 'Overdue';

  @override
  String get homeVisitStatusRequested => 'Requested';

  @override
  String get homeVisitStatusScheduled => 'Scheduled';

  @override
  String get homeVisitStatusCompleted => 'Completed';

  @override
  String get homeVisitStatusDeclined => 'Declined';

  @override
  String get homeVisitStatusCancelled => 'Cancelled';

  @override
  String get notificationCategoryAppointment => 'Appointment';

  @override
  String get notificationCategoryBilling => 'Billing';

  @override
  String get notificationCategoryLabResult => 'Lab result';

  @override
  String get notificationCategoryPrescription => 'Prescription';

  @override
  String get notificationCategoryMessage => 'Message';

  @override
  String get notificationCategorySystem => 'System';

  @override
  String get feedbackCategoryBug => 'Bug';

  @override
  String get feedbackCategoryFeatureRequest => 'Feature request';

  @override
  String get feedbackCategoryGeneralFeedback => 'General feedback';

  @override
  String get feedbackCategoryComplaint => 'Complaint';

  @override
  String get feedbackStatusOpen => 'Open';

  @override
  String get feedbackStatusResolved => 'Resolved';

  @override
  String get aiFeatureCareNavigator => 'Care Navigator';

  @override
  String get aiFeatureClinicalScribe => 'Clinical Scribe';

  @override
  String get aiFeaturePatientSummary => 'Patient Summary';

  @override
  String get nothingHere => 'Nothing here.';

  @override
  String get selectItemPlaceholder => 'Select an item to see its details.';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get tryAgain => 'Try again';

  @override
  String get riskBadgeLow => 'Low risk';

  @override
  String get riskBadgeMedium => 'Medium risk';

  @override
  String get riskBadgeHigh => 'High risk';

  @override
  String get severityChipInfo => 'Info';

  @override
  String get severityChipReview => 'Review';

  @override
  String get severityChipUrgent => 'Urgent';

  @override
  String get aiDisclaimer =>
      'AI-generated — informational only, not medical advice. Verify with your clinician.';

  @override
  String labReferenceSuffix(String reference) {
    return ', reference $reference';
  }

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String notificationsTooltipUnread(int count) {
    return 'Notifications ($count unread)';
  }

  @override
  String get greetingFallbackName => 'there';

  @override
  String get sectionYourHealth => 'Your health';

  @override
  String get sectionUpcomingAppointments => 'Upcoming appointments';

  @override
  String get sectionQuickActions => 'Quick actions';

  @override
  String get quickAppointmentTitle => 'Quick appointment';

  @override
  String get quickAppointmentSubtitle => 'Urgent or normal — get seen sooner';

  @override
  String get quickAppointmentSheetQuestion => 'How urgent is this visit?';

  @override
  String get urgencyUrgentTitle => 'Urgent';

  @override
  String get urgencyUrgentSubtitle =>
      'Auto-route me to the soonest available doctor';

  @override
  String get urgencyNormalTitle => 'Normal';

  @override
  String get urgencyNormalSubtitle =>
      'Choose a department, doctor and time myself';

  @override
  String get onSchedule => 'You\'re on the schedule';

  @override
  String get metricTicket => 'Ticket';

  @override
  String get metricMedicine => 'Medicine';

  @override
  String get metricLastVisit => 'Last visit';

  @override
  String allergiesInline(String list) {
    return 'Allergies: $list';
  }

  @override
  String get quickActionVitals => 'Vitals';

  @override
  String get quickActionMedications => 'Medications';

  @override
  String get quickActionAskDoctor => 'Ask your doctor';

  @override
  String get quickActionVisitedDoctors => 'Visited doctors';

  @override
  String get quickActionSickLeave => 'Sick leave';

  @override
  String get quickActionHomeCare => 'Home care';

  @override
  String get quickActionBilling => 'Billing';

  @override
  String get couldNotLoadAppointments => 'Could not load appointments.';

  @override
  String get noUpcomingAppointments => 'No upcoming appointments';

  @override
  String get tapToBookVisit => 'Tap to book a visit';

  @override
  String carouselPosition(int index, int count) {
    return '$index of $count';
  }

  @override
  String get previousAppointment => 'Previous appointment';

  @override
  String get nextAppointment => 'Next appointment';

  @override
  String get ticketOverline => 'TICKET';

  @override
  String roomNumber(String room) {
    return 'Room $room';
  }

  @override
  String bookedForName(String name) {
    return 'For $name';
  }

  @override
  String get appointmentsTitle => 'My appointments';

  @override
  String upcomingCount(int count) {
    return 'Upcoming ($count)';
  }

  @override
  String get nothingBookedNote =>
      'Nothing booked. Use Book now or Schedule above.';

  @override
  String historyCount(int count) {
    return 'History ($count)';
  }

  @override
  String get noPastVisitsNote => 'No past visits yet.';

  @override
  String get bookNowTitle => 'Book now';

  @override
  String get bookNowSubtitle => 'Soonest opening';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get scheduleSubtitle => 'Pick a date';

  @override
  String ticketLabel(String tag) {
    return 'Ticket $tag';
  }

  @override
  String get reschedule => 'Reschedule';

  @override
  String get cancelAppointmentTitle => 'Cancel appointment?';

  @override
  String get cancelAppointmentMessage =>
      'This frees the slot for someone else.';

  @override
  String get cancelItLabel => 'Cancel it';

  @override
  String get clinicDaysHelp => 'Clinic days: Sunday–Thursday';

  @override
  String get clinicHoursHelp => 'Clinic hours: 08:00–20:00';

  @override
  String get pickTimeInRange => 'Pick a time between 08:00 and 20:00.';

  @override
  String bookedOn(String date) {
    return 'Booked $date';
  }

  @override
  String get scheduleAVisitTitle => 'Schedule a visit';

  @override
  String get couldNotLoadDepartments => 'Could not load departments.';

  @override
  String get stepDepartment => 'Department';

  @override
  String get stepDoctor => 'Doctor';

  @override
  String get stepReasonForVisit => 'Reason for visit';

  @override
  String get stepReasonShort => 'Reason';

  @override
  String get stepDateTime => 'Date & time';

  @override
  String get whoIsThisFor => 'Who is this for?';

  @override
  String get myself => 'Myself';

  @override
  String bookedForNotice(String name) {
    return 'This visit will be booked for $name.';
  }

  @override
  String stepProgress(int step, int total, String label) {
    return 'Step $step of $total · $label';
  }

  @override
  String get couldNotLoadDoctors => 'Could not load doctors';

  @override
  String get noDoctorsListed => 'No doctors listed for this department yet.';

  @override
  String get findingSoonestOpening => 'Finding the soonest opening…';

  @override
  String soonestOpeningAt(String relDay, String date) {
    return 'Soonest opening: $relDay, $date';
  }

  @override
  String get couldNotLoadTimes => 'Could not load times.';

  @override
  String get noOpenTimesThatDay => 'No open times that day. Try another date.';

  @override
  String get recommendedSection => 'Recommended';

  @override
  String get allOpenTimesSection => 'All open times';

  @override
  String get appointmentBooked => 'Appointment booked';

  @override
  String get reviewAndConfirm => 'Review & confirm';

  @override
  String get rowLabelFor => 'For';

  @override
  String get rowLabelWhen => 'When';

  @override
  String get confirmBookingButton => 'Confirm booking';

  @override
  String get backButton => 'Back';

  @override
  String get couldNotLoadMedications => 'Could not load medications.';

  @override
  String get noMedicationsOnRecord => 'No medications on record.';

  @override
  String get currentSectionLabel => 'Current';

  @override
  String get pastSectionLabel => 'Past';

  @override
  String medDoseFrom(String date) {
    return 'from $date';
  }

  @override
  String medDoseTo(String date) {
    return 'to $date';
  }

  @override
  String get imagingTitle => 'Imaging';

  @override
  String get couldNotLoadImaging => 'Could not load your imaging results.';

  @override
  String get noImagingResultsYet =>
      'No imaging results yet.\nX-rays, scans and ultrasounds show up here after a study.';

  @override
  String get reportPdfLabel => 'Report PDF';

  @override
  String get recordTitle => 'Record';

  @override
  String get couldNotLoadRecord => 'Could not load this record.';

  @override
  String fromYourVisitOn(String date) {
    return 'From your visit on $date';
  }

  @override
  String get referralLetterLabel => 'Referral letter';

  @override
  String get resultsSection => 'Results';

  @override
  String get extractedTextSection => 'Extracted text';

  @override
  String get labColumnAnalyte => 'Analyte';

  @override
  String get labColumnValue => 'Value';

  @override
  String get labColumnReference => 'Reference';

  @override
  String get recordsTitle => 'Records';

  @override
  String get timelineSegment => 'Timeline';

  @override
  String get billsSegment => 'Bills';

  @override
  String get vitalSignsReportLabel => 'Vital signs report';

  @override
  String get allergiesLabel => 'Allergies';

  @override
  String get couldNotLoadRecords => 'Could not load your records.';

  @override
  String get nothingMatchesFilters => 'Nothing matches these filters yet.';

  @override
  String get searchRecordsHint => 'Search records';

  @override
  String get filterVisits => 'Visits';

  @override
  String get filterLabs => 'Labs';

  @override
  String get filterPrescriptions => 'Prescriptions';

  @override
  String get filterVaccinations => 'Vaccinations';

  @override
  String get filterReferrals => 'Referrals';

  @override
  String get flaggedByAi => 'flagged by AI';

  @override
  String get vitalsRecordedTitle => 'Vitals recorded';

  @override
  String get vitalsTitle => 'Vitals';

  @override
  String get couldNotLoadVitals => 'Could not load vitals.';

  @override
  String get noVitalsRecordedYet =>
      'No vitals recorded yet.\nBook a visit to get your first reading.';

  @override
  String get chartBloodPressure => 'Blood pressure';

  @override
  String get chartWeight => 'Weight';

  @override
  String get chartGlucose => 'Glucose';

  @override
  String get seriesSystolic => 'Systolic';

  @override
  String get seriesDiastolic => 'Diastolic';

  @override
  String get recentReadingsSection => 'Recent readings';

  @override
  String get couldNotCreateDocument => 'Could not create the document.';

  @override
  String get couldNotLoadInvoices => 'Could not load your invoices.';

  @override
  String get noInvoicesYet =>
      'No invoices yet.\nBills for your visits will appear here.';

  @override
  String get openSectionLabel => 'Open';

  @override
  String get historyLabel => 'History';

  @override
  String get outstandingBalance => 'Outstanding balance';

  @override
  String get allSettled => 'All settled';

  @override
  String openInvoicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open invoices',
      one: '$count open invoice',
    );
    return '$_temp0';
  }

  @override
  String overdueAmount(String amount) {
    return '$amount overdue';
  }

  @override
  String issuedOn(String date) {
    return 'Issued $date';
  }

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String taxLabel(String rate) {
    return 'Tax ($rate%)';
  }

  @override
  String get totalLabel => 'Total';

  @override
  String wasDueOn(String date) {
    return 'Was due $date';
  }

  @override
  String dueOn(String date) {
    return 'Due $date';
  }

  @override
  String paidOn(String date) {
    return 'Paid $date';
  }

  @override
  String payAmountButton(String amount) {
    return 'Pay $amount';
  }

  @override
  String get payInvoiceTitle => 'Pay invoice';

  @override
  String amountDue(String amount) {
    return '$amount due';
  }

  @override
  String get payWithLabel => 'Pay with';

  @override
  String get demoPaymentNote =>
      'Demo payment — card details are checked on this device and never stored or sent anywhere.';

  @override
  String get nameOnCardLabel => 'Name on card';

  @override
  String get enterNameOnCard => 'Enter the name on the card';

  @override
  String get cardNumberLabel => 'Card number';

  @override
  String get enterFullCardNumber => 'Enter a full card number';

  @override
  String get cardNumberInvalid => 'That card number is not valid';

  @override
  String get expiryLabel => 'Expiry';

  @override
  String get monthRange => 'Month must be 01–12';

  @override
  String get cardExpired => 'Card has expired';

  @override
  String get digitsRange => '3–4 digits';

  @override
  String get enterSecurityCode => 'Enter the 3–4 digit security code.';

  @override
  String get paymentReceived => 'Payment received';

  @override
  String cardExpiredOn(String expiry) {
    return 'Expired $expiry';
  }

  @override
  String cardExpiresOn(String expiry) {
    return 'Expires $expiry';
  }

  @override
  String get payWithDifferentCard => 'Pay with a different card';

  @override
  String get securityCodeHelper => 'The 3–4 digits on the back of the card';

  @override
  String get savedCardsLabel => 'Saved cards';

  @override
  String get addCardButton => 'Add card';

  @override
  String get couldNotLoadCards => 'Could not load cards.';

  @override
  String get noCardsSavedYet => 'No cards saved yet.';

  @override
  String get transactionHistoryLabel => 'Transaction history';

  @override
  String get noPaymentsYet => 'No payments yet.';

  @override
  String get defaultChip => 'Default';

  @override
  String get setDefaultButton => 'Set default';

  @override
  String get removeCardTooltip => 'Remove card';

  @override
  String get removeCardTitle => 'Remove card?';

  @override
  String removeCardMessage(String brand, String last4) {
    return '$brand ····$last4 will be removed.';
  }

  @override
  String get removeButton => 'Remove';

  @override
  String get addACardTitle => 'Add a card';

  @override
  String get saveCardButton => 'Save card';

  @override
  String get cardSavedNote =>
      'Only the last 4 digits and expiry are saved — never the full number or CVC.';

  @override
  String get expiredSuffix => 'expired';

  @override
  String get markAllReadButton => 'Mark all read';

  @override
  String get couldNotLoadNotifications => 'Could not load your notifications.';

  @override
  String get allCaughtUpMessage => 'You\'re all caught up.\nNothing new here.';

  @override
  String get last24HoursSection => 'Last 24 hours';

  @override
  String get earlierSection => 'Earlier';

  @override
  String get openButton => 'Open';

  @override
  String get onlineStatus => 'Online';

  @override
  String get askAboutAppHint => 'Ask about the app…';

  @override
  String get openCareNavigator => 'Open Care Navigator';

  @override
  String get hideCareNavigator => 'Hide Care Navigator';

  @override
  String get showCareNavigator => 'Show Care Navigator';

  @override
  String get taskBoardTitle => 'Task board';

  @override
  String get couldNotLoadTasks => 'Could not load tasks.';

  @override
  String get noOpenTasksMessage =>
      'No open tasks. Run a panel scan from the dashboard.';

  @override
  String priorityBlendNote(int pct) {
    return 'Priority blends the rule score $pct% with the AI score.';
  }

  @override
  String get tasksReprioritised => 'Tasks re-prioritised.';

  @override
  String get prioritiseButton => 'Prioritise';

  @override
  String get startAction => 'Start';

  @override
  String get completeAction => 'Complete';

  @override
  String get dismissAction => 'Dismiss';

  @override
  String ruleScoreTag(String score) {
    return 'rule $score';
  }

  @override
  String aiScoreTag(String score) {
    return 'AI $score';
  }

  @override
  String dueTag(String relDay) {
    return 'due $relDay';
  }

  @override
  String get taskKindFollowUpShort => 'Follow-up';

  @override
  String get taskKindAbnormalLabShort => 'Abnormal lab';

  @override
  String get taskKindReferralShort => 'Referral';

  @override
  String get homeHealthCareTitle => 'Home health care';

  @override
  String get requestAVisitButton => 'Request a visit';

  @override
  String get couldNotLoadHomeVisitRequests => 'Could not load your requests.';

  @override
  String get noHomeVisitRequestsMessage =>
      'No home-visit requests.\nAsk for a clinician to visit you at home when getting to the clinic is hard.';

  @override
  String preferredOn(String date) {
    return 'Preferred $date';
  }

  @override
  String clinicNote(String note) {
    return 'Clinic: $note';
  }

  @override
  String get cancelRequestButton => 'Cancel request';

  @override
  String get requestAHomeVisitTitle => 'Request a home visit';

  @override
  String get homeAddressLabel => 'Home address';

  @override
  String get homeAddressHint => 'Building, road, block, area';

  @override
  String get whyHomeVisitNeededLabel => 'Why is a home visit needed?';

  @override
  String get departmentOptionalLabel => 'Department (optional)';

  @override
  String get notSureOption => 'Not sure';

  @override
  String preferredDateLabel(String date) {
    return 'Preferred date: $date';
  }

  @override
  String get sendRequestButton => 'Send request';

  @override
  String get requestSentToClinic => 'Request sent to the clinic.';

  @override
  String get clinicWillConfirmNote =>
      'The clinic will confirm a time or follow up with you.';

  @override
  String get homeVisitsTitle => 'Home visits';

  @override
  String get couldNotLoadQueue => 'Could not load the queue.';

  @override
  String preferredAndRequestedOn(String preferred, String requested) {
    return 'Preferred $preferred  ·  requested $requested';
  }

  @override
  String noteLabel(String note) {
    return 'Note: $note';
  }

  @override
  String get scheduleButton => 'Schedule';

  @override
  String get declineButton => 'Decline';

  @override
  String get markCompletedButton => 'Mark completed';

  @override
  String get scheduleThisVisitTitle => 'Schedule this visit';

  @override
  String get declineThisRequestTitle => 'Decline this request';

  @override
  String get scheduleHint => 'e.g. Nurse will visit Tue 10:00';

  @override
  String get declineHint => 'Reason the request was declined';

  @override
  String get couldNotLoadCertificates => 'Could not load your certificates.';

  @override
  String get noSickLeaveCertificatesMessage =>
      'No sick-leave certificates.\nYour doctor can issue one after a visit.';

  @override
  String get activeChip => 'Active';

  @override
  String dateRangeDays(String from, String to, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return '$from – $to  ·  $_temp0';
  }

  @override
  String get certificatePdfLabel => 'Certificate PDF';

  @override
  String get newMessageButton => 'New message';

  @override
  String get couldNotLoadMessages => 'Could not load your messages.';

  @override
  String get onceSeenDoctorMessage =>
      'Once you have seen a doctor you can message them here.';

  @override
  String get noConversationsYetMessage =>
      'No conversations yet.\nTap \"New message\" to ask a non-urgent question.';

  @override
  String get yourDoctorFallback => 'Your doctor';

  @override
  String get openPatientChartTooltip => 'Open patient chart';

  @override
  String get couldNotLoadConversation => 'Could not load this conversation.';

  @override
  String get noMessagesYet => 'No messages yet.';

  @override
  String get sendNonUrgentQuestionMessage =>
      'Send your doctor a non-urgent question.\nFor emergencies, call your clinic.';

  @override
  String get writeMessageHint => 'Write a message';

  @override
  String get youPrefix => 'You: ';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get couldNotLoadInbox => 'Could not load your inbox.';

  @override
  String get noPatientMessages => 'No patient messages.';

  @override
  String get somethingIsBrokenOption => 'Something is broken';

  @override
  String get sendFeedbackTitle => 'Send feedback';

  @override
  String get feedbackIntroText =>
      'Tell the team what is working, what is not, or what you wish the app did.';

  @override
  String get aboutLabel => 'About';

  @override
  String get yourMessageLabel => 'Your message';

  @override
  String get sendButton => 'Send';

  @override
  String get feedbackThanksMessage =>
      'Thanks — your feedback was sent to the team.';

  @override
  String get nutritionTitle => 'Nutrition';

  @override
  String get calculatorSegment => 'Calculator';

  @override
  String get mealPlanSegment => 'Meal plan';

  @override
  String get foodsSegment => 'Foods';

  @override
  String get aboutYouSection => 'About you';

  @override
  String get ageLabel => 'Age';

  @override
  String get sexLabel => 'Sex';

  @override
  String get weightKgLabel => 'Weight (kg)';

  @override
  String get heightCmLabel => 'Height (cm)';

  @override
  String get activityLabel => 'Activity';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activityLightlyActive => 'Lightly active (1–3 days/wk)';

  @override
  String get activityModeratelyActive => 'Moderately active (3–5 days/wk)';

  @override
  String get activityVeryActive => 'Very active (6–7 days/wk)';

  @override
  String get activityExtraActive => 'Extra active (physical job)';

  @override
  String get goalLabel => 'Goal';

  @override
  String get goalMaintain => 'Maintain weight';

  @override
  String get goalLose => 'Lose weight';

  @override
  String get goalGain => 'Gain weight';

  @override
  String get weeklyRateLabel => 'Weekly rate';

  @override
  String get weeklyRate025 => '0.25 kg / week';

  @override
  String get weeklyRate05 => '0.5 kg / week';

  @override
  String get weeklyRate10 => '1.0 kg / week';

  @override
  String get calculateTargetsButton => 'Calculate targets';

  @override
  String get preferencesSection => 'Preferences';

  @override
  String get macroSplitNote =>
      'The macro split used for your targets and your meal plan.';

  @override
  String get presetBalanced => 'Balanced';

  @override
  String get presetLowFat => 'Low fat';

  @override
  String get presetLowCarb => 'Low carb';

  @override
  String get presetHighCarb => 'High carb';

  @override
  String get presetHighProtein => 'High protein';

  @override
  String get dailyTargetsSection => 'Daily targets';

  @override
  String get macroCalories => 'Calories';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroFat => 'Fat';

  @override
  String get macroSugar => 'Sugar';

  @override
  String get macroSatFat => 'Sat. fat';

  @override
  String get unitKcalPerDay => 'kcal / day';

  @override
  String get unitPerDay => 'per day';

  @override
  String get unitDailyCap => 'daily cap';

  @override
  String bmrTdeeNote(int bmr, int tdee) {
    return 'BMR $bmr kcal · TDEE $tdee kcal. A guide only — your clinician can tailor this to your care.';
  }

  @override
  String get searchFoodsHint => 'Search foods';

  @override
  String get allCategoriesChip => 'All';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get noFoodsMatch => 'No foods match that search.';

  @override
  String servingLabel(String value) {
    return 'Serving $value';
  }

  @override
  String get also => 'Also';

  @override
  String containsAllergens(String list) {
    return 'Contains: $list';
  }

  @override
  String get includeDessertTitle => 'Include a dessert';

  @override
  String get includeDessertSubtitle =>
      'Splits the day into four meals instead of three';

  @override
  String get buildMyDayButton => 'Build my day';

  @override
  String get runCalculatorFirstNote =>
      'Run the Calculator first — then your calorie and macro goal is split across the meals here.';

  @override
  String get yourDayTitle => 'Your day';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealDessert => 'Dessert';

  @override
  String get switchToLightMode => 'Switch to light mode';

  @override
  String get switchToDarkMode => 'Switch to dark mode';

  @override
  String get profileTooltip => 'Profile';

  @override
  String get setYourAvailabilityTooltip => 'Set your availability';

  @override
  String get couldNotUpdatePresence => 'Could not update your presence.';

  @override
  String get panelAnalyticsTitle => 'Panel analytics';

  @override
  String get couldNotComputeAnalytics => 'Could not compute analytics.';

  @override
  String lastNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Last $days days',
      one: 'Last $days day',
    );
    return '$_temp0';
  }

  @override
  String get noShowRateLabel => 'No-show rate';

  @override
  String noShowRateCaption(int kept, int total) {
    return '$kept of $total kept slots';
  }

  @override
  String get cancellationRateLabel => 'Cancellation rate';

  @override
  String cancelledCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cancelled',
      one: '$count cancelled',
    );
    return '$_temp0';
  }

  @override
  String get completedLabel => 'Completed';

  @override
  String perDayCaption(String value) {
    return '$value per day';
  }

  @override
  String get upcomingLabel => 'Upcoming';

  @override
  String get bookedOrConfirmedCaption => 'booked or confirmed';

  @override
  String get staffDirectoryTitle => 'Staff directory';

  @override
  String get couldNotLoadStaffDirectory =>
      'Could not load the staff directory.';

  @override
  String get noStaffOnRecord => 'No staff on record.';

  @override
  String cliniciansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clinicians',
      one: '$count clinician',
    );
    return '$_temp0';
  }

  @override
  String get myActivityTitle => 'My activity';

  @override
  String get recordsTab => 'Records';

  @override
  String get prescriptionsTab => 'Prescriptions';

  @override
  String get couldNotLoadYourRecords => 'Could not load your records.';

  @override
  String get noRecordsAuthoredYet => 'You have not authored any records yet.';

  @override
  String get couldNotLoadYourPrescriptions =>
      'Could not load your prescriptions.';

  @override
  String get noPrescriptionsIssuedYet =>
      'You have not issued any prescriptions yet.';

  @override
  String get currentMedicationChip => 'Active';

  @override
  String get yourShiftHeader => 'Your shift';

  @override
  String get quickActionsHeader => 'Quick actions';

  @override
  String get todaysQueueHeader => 'Today’s queue';

  @override
  String get scheduleAction => 'Schedule';

  @override
  String get riskFlagsHeader => 'Risk flags';

  @override
  String get patientsAction => 'Patients';

  @override
  String get tasksHeader => 'Tasks';

  @override
  String get taskBoardAction => 'Task board';

  @override
  String departmentWalkInsHeader(int count) {
    return 'Department walk-ins ($count)';
  }

  @override
  String get yourQueueIsClear => 'Your queue is clear';

  @override
  String get nobodyWaitingOpenWeek =>
      'Nobody waiting — open your week to plan ahead';

  @override
  String nextPatientLabel(String who) {
    return 'Next · $who';
  }

  @override
  String get todayLabel => 'Today';

  @override
  String get inQueueLabel => 'In queue';

  @override
  String get openFlagsLabel => 'Open flags';

  @override
  String get couldNotLoadYourQueue => 'Could not load your queue.';

  @override
  String get nobodyWaitingQueueClear => 'Nobody waiting — your queue is clear.';

  @override
  String get moreActionsTooltip => 'More actions';

  @override
  String get openChartAction => 'Open chart';

  @override
  String get addNoteAction => 'Add note';

  @override
  String get transferVisitAction => 'Transfer visit';

  @override
  String get cancelVisitAction => 'Cancel visit';

  @override
  String get markNoShowAction => 'Mark no-show';

  @override
  String get cancelThisVisitTitle => 'Cancel this visit?';

  @override
  String get patientWillNeedToRebook => 'The patient will need to rebook.';

  @override
  String get markAsNoShowTitle => 'Mark as no-show?';

  @override
  String get recordsPatientDidNotAttend =>
      'This records that the patient did not attend.';

  @override
  String get checkedInLabel => 'checked in';

  @override
  String get couldNotLoadRiskFlags => 'Could not load risk flags.';

  @override
  String get noOpenRiskFlagsRunScan =>
      'No open risk flags. Run a panel scan to refresh.';

  @override
  String get acknowledgeTooltip => 'Acknowledge';

  @override
  String moreOnPatientsTab(int count) {
    return '+$count more on the Patients tab';
  }

  @override
  String get noOpenTasksRunScan =>
      'No open tasks. Run a panel scan from Quick actions.';

  @override
  String get markDoneTooltip => 'Mark done';

  @override
  String get newNoteAction => 'New note';

  @override
  String get addClinicalNoteForTitle => 'Add a clinical note for…';

  @override
  String get prescribeAction => 'Prescribe';

  @override
  String get prescribeForTitle => 'Prescribe for…';

  @override
  String get labResultAction => 'Lab result';

  @override
  String get enterLabResultForTitle => 'Enter a lab result for…';

  @override
  String get aiScribeAction => 'AI Scribe';

  @override
  String get scribeVisitNoteForTitle => 'Scribe a visit note for…';

  @override
  String get patientSummaryAction => 'Patient summary';

  @override
  String get summariseTitle => 'Summarise…';

  @override
  String get patientLookupAction => 'Patient lookup';

  @override
  String messagesActionWithCount(int n) {
    return 'Messages ($n)';
  }

  @override
  String get panelScanAction => 'Panel scan';

  @override
  String get scanningPanelForRisks => 'Scanning the panel for risks…';

  @override
  String panelScanCompleteFlags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Panel scan complete — $count open flags.',
      one: 'Panel scan complete — $count open flag.',
    );
    return '$_temp0';
  }

  @override
  String get searchByNameOrNationalId => 'Search by name or national ID';

  @override
  String get couldNotLoadPatients => 'Could not load patients.';

  @override
  String get noPatientsMatchSearch => 'No patients match that search.';

  @override
  String idLabel(String id) {
    return 'ID $id';
  }

  @override
  String get transferAVisitTitle => 'Transfer a visit';

  @override
  String get reassignVisitNote =>
      'Reassign a visit from today to another clinician. It returns to \"booked\" so they can re-accept it.';

  @override
  String get nothingInQueueToTransfer => 'Nothing in your queue to transfer.';

  @override
  String get visitLabel => 'Visit';

  @override
  String get couldNotLoadDirectory => 'Could not load the directory.';

  @override
  String get transferToLabel => 'Transfer to';

  @override
  String get visitTransferred => 'Visit transferred.';

  @override
  String get compressTheDay => 'Compress the day';

  @override
  String get expandTheDay => 'Expand the day';

  @override
  String get previousDayTooltip => 'Previous day';

  @override
  String get nextDayTooltip => 'Next day';

  @override
  String get previousTooltip => 'Previous';

  @override
  String get nextLabel => 'Next';

  @override
  String get onboardingPage1Title => 'Understand your health at a glance';

  @override
  String get onboardingPage1Body =>
      'AI-summarised labs, records and vitals turn into one clear picture of how you\'re doing.';

  @override
  String get onboardingPage2Title => 'Book the right appointment, faster';

  @override
  String get onboardingPage2Body =>
      'Risk-ranked booking gets you to the right specialist without the back-and-forth.';

  @override
  String get onboardingPage3Title => 'One app, your whole care team';

  @override
  String get onboardingPage3Body =>
      'Patients, staff and admins share one app, so everyone stays on the same page.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get couldNotLoadYourCalendar => 'Could not load your calendar.';

  @override
  String get nothingBookedThisDay => 'Nothing booked on this day.';

  @override
  String get todaysQueueCaps => 'TODAY\'S QUEUE';

  @override
  String waitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting',
      one: '$count waiting',
    );
    return '$_temp0';
  }

  @override
  String get tapPatientOrPressNext => 'Tap a patient, or press Next to begin.';

  @override
  String get lastPatientInQueue => 'Last patient in the queue';

  @override
  String nowLabel(String name) {
    return 'Now: $name';
  }

  @override
  String get noMorePatients => 'No more patients';

  @override
  String reasonLabel(String reason) {
    return 'Reason: $reason';
  }

  @override
  String ageYearsAbbrev(int age) {
    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$age yrs',
      one: '$age yr',
    );
    return '$_temp0';
  }

  @override
  String allergiesInlineLabel(String list) {
    return 'Allergies: $list';
  }

  @override
  String get couldNotLoadYourProfile => 'Could not load your profile.';

  @override
  String get accountSubtitle => 'Specialty, department, licence';

  @override
  String get myActivitySubtitle => 'Notes and prescriptions you have authored';

  @override
  String get staffDirectorySubtitle =>
      'Clinicians, specialties and live presence';

  @override
  String get panelAnalyticsSubtitle =>
      'No-show rate, cancellations, utilisation';

  @override
  String get preferencesSubtitle => 'Theme, text size, language, alerts';

  @override
  String get resetPasswordTitle => 'Reset your password';

  @override
  String get enterEmailOrNationalId => 'Enter your email or national ID.';

  @override
  String get forgotPasswordQuestion => 'Forgot your password?';

  @override
  String get forgotPasswordBody =>
      'Enter the email or national ID on your account and we’ll take you to set a new password.';

  @override
  String get emailOrNationalIdLabel => 'Email or national ID';

  @override
  String get continueButton => 'Continue';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get verifyItsYouTitle => 'Verify it’s you';

  @override
  String get codeNotRightError => 'That code is not right. Try again.';

  @override
  String get enterSixDigitCode => 'Enter your 6-digit code';

  @override
  String almostThereName(String name) {
    return 'Almost there, $name';
  }

  @override
  String get sixDigitCodeSentNote =>
      'We sent a 6-digit verification code to your device.';

  @override
  String get verifyButton => 'Verify';

  @override
  String get codeResentLabel => 'Code re-sent';

  @override
  String get resendCodeLabel => 'Resend code';

  @override
  String demoCodeNote(String code) {
    return 'Demo build — the verification code is $code.';
  }

  @override
  String get setNewPasswordTitle => 'Set a new password';

  @override
  String get startFromForgotPasswordNote =>
      'Start from the \"Forgot password\" screen so we know which account to reset.';

  @override
  String get newPasswordTitle => 'New password';

  @override
  String get newPasswordLabel => 'New password (8+ characters)';

  @override
  String get atLeast8Characters => 'At least 8 characters';

  @override
  String get confirmNewPasswordLabel => 'Confirm new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get updatePasswordButton => 'Update password';

  @override
  String get passwordUpdatedSnackbar =>
      'Password updated — sign in with your new password.';

  @override
  String get aiHealthSummaryTitle => 'AI health summary';

  @override
  String get regenerateTooltip => 'Regenerate';

  @override
  String regeneratedAt(String when) {
    return 'Regenerated $when';
  }

  @override
  String couldNotGenerateSummary(String error) {
    return 'Could not generate a summary.\n$error';
  }

  @override
  String get thingsToCheckHeader => 'Things to check';

  @override
  String get trendsHeader => 'Trends';

  @override
  String get keyEventsHeader => 'Key events';

  @override
  String generatedMeta(String when, String model, String version) {
    return 'Generated $when  ·  $model  ·  $version';
  }

  @override
  String get aiClinicalScribeTitle => 'AI Clinical Scribe';

  @override
  String get visitNoteTitle => 'Visit note';

  @override
  String visitNoteWithPatient(String name) {
    return 'Visit note · $name';
  }

  @override
  String get dictationLabel => 'Dictation';

  @override
  String get dictationHint =>
      'Type or paste your visit notes in plain language — the scribe will structure them.';

  @override
  String get structuringEllipsis => 'Structuring…';

  @override
  String get structureWithAi => 'Structure with AI';

  @override
  String get structuredNoteHeader => 'Structured note';

  @override
  String get chiefComplaintLabel => 'Chief complaint';

  @override
  String get hpiLabel => 'History of present illness';

  @override
  String get assessmentLabel => 'Assessment';

  @override
  String get planLabel => 'Plan';

  @override
  String get suggestedIcdNote => 'Suggested ICD-10 — confirm before coding';

  @override
  String get saveAsVisitNote => 'Save as visit note';

  @override
  String get savedToPatientRecord => 'Saved to the patient record.';

  @override
  String get clinicalNoteFallbackTitle => 'Clinical note';

  @override
  String get patientChartFallbackTitle => 'Patient chart';

  @override
  String get aiSummaryTooltip => 'AI summary';

  @override
  String get couldNotLoadThisPatient => 'Could not load this patient.';

  @override
  String get recentVitalsHeader => 'Recent vitals';

  @override
  String get couldNotLoadMedicationsChart => 'Could not load medications';

  @override
  String get noActiveMedications => 'No active medications';

  @override
  String get noVitalsOnRecord => 'No vitals on record';

  @override
  String get couldNotLoadTimelineChart => 'Could not load timeline';

  @override
  String get noRecordsYet => 'No records yet';

  @override
  String get addClinicalNoteAction => 'Add clinical note';

  @override
  String get aiScribeANoteAction => 'AI Scribe a note';

  @override
  String get prescribeMedicationAction => 'Prescribe medication';

  @override
  String get enterLabResultAction => 'Enter lab result';

  @override
  String get labResultFallbackTitle => 'Lab result';

  @override
  String get issueSickLeaveAction => 'Issue sick leave';

  @override
  String get titleLabel => 'Title';

  @override
  String get noteFieldLabel => 'Note';

  @override
  String get noteAdded => 'Note added.';

  @override
  String get medicationNameLabel => 'Medication name';

  @override
  String get doseOptionalLabel => 'Dose (optional)';

  @override
  String get frequencyOptionalLabel => 'Frequency (optional)';

  @override
  String get medicationPrescribed => 'Medication prescribed.';

  @override
  String get panelTitleLabel => 'Panel / title';

  @override
  String get analyteLabel => 'Analyte';

  @override
  String get valueLabel => 'Value';

  @override
  String get unitLabel => 'Unit';

  @override
  String get refLowLabel => 'Ref low';

  @override
  String get refHighLabel => 'Ref high';

  @override
  String get labResultRecorded => 'Lab result recorded.';

  @override
  String get reasonDiagnosisLabel => 'Reason / diagnosis';

  @override
  String get acuteViralIllnessHint => 'e.g. Acute viral illness';

  @override
  String fromDateLabel(String date) {
    return 'From: $date';
  }

  @override
  String toDateLabel(String date) {
    return 'To: $date';
  }

  @override
  String get notesOptionalLabel => 'Notes (optional)';

  @override
  String get certificateIssued => 'Certificate issued.';

  @override
  String daysCountPlain(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return '$_temp0';
  }

  @override
  String get saveButton => 'Save';

  @override
  String get addButton => 'Add';

  @override
  String get consultationFallbackTitle => 'Consultation';

  @override
  String get couldNotLoadThisAppointment => 'Could not load this appointment.';

  @override
  String get couldNotLoadThePatient => 'Could not load the patient.';

  @override
  String get clinicalNoteHeader => 'Clinical note';

  @override
  String get historyExamHint => 'History, examination, assessment, plan…';

  @override
  String get openAiScribeAction => 'Open AI Scribe';

  @override
  String get noMedicationsAdded => 'No medications added.';

  @override
  String get removeTooltip => 'Remove';

  @override
  String get addMedicationAction => 'Add medication';

  @override
  String get referralHeader => 'Referral';

  @override
  String get referralRequestedAwaitingAdmin =>
      'Referral requested — awaiting admin';

  @override
  String get requestAReferralAction => 'Request a referral';

  @override
  String get visitSummaryOptionalLabel => 'Visit summary (optional)';

  @override
  String get visitSummaryHint => 'One line — the outcome of this visit';

  @override
  String get completeConsultationAction => 'Complete consultation';

  @override
  String get addNoteMedOrReferralFirst =>
      'Add a note, a medication or a referral request first.';

  @override
  String get referralRequestedSnackbar => 'Referral requested.';

  @override
  String get completeConsultationTitle => 'Complete consultation?';

  @override
  String get completeConsultationBody =>
      'The note and any medications will be saved to the patient record and the visit will be closed.';

  @override
  String get consultationCompletedSnackbar => 'Consultation completed.';

  @override
  String get patientCalledInNote => 'Patient has been called in.';

  @override
  String get callPatientAction => 'Call patient';

  @override
  String get patientCalledSnackbar => 'Patient called.';

  @override
  String get patientArrivedAction => 'Patient arrived';

  @override
  String get consultationStartedSnackbar => 'Consultation started.';

  @override
  String get markedAsNoShowSnackbar => 'Marked as no-show.';

  @override
  String get patientNotShownAction => 'Patient not shown';

  @override
  String get consultationCompletedHeader => 'Consultation completed';

  @override
  String get adminWillDecideReferralNote =>
      'The admin will decide whether this is a department or an external referral, and where.';

  @override
  String get clinicalReasonForReferralLabel => 'Clinical reason for referral';

  @override
  String get adminStatusAvailable => 'Available';

  @override
  String get adminStatusMeeting => 'In a meeting';

  @override
  String get adminStatusAway => 'Away';

  @override
  String get adminStatusOff => 'Off';

  @override
  String get accountSubtitleAdmin => 'Name, email, member since';

  @override
  String get auditLogTitle => 'Audit log';

  @override
  String get auditLogSubtitle => 'Everything that has changed, newest first';

  @override
  String get systemAnalyticsTitle => 'System analytics';

  @override
  String get systemAnalyticsSubtitle =>
      'Headline counts, no-show and utilisation';

  @override
  String get capacityForecastTitle => 'Capacity forecast';

  @override
  String get capacityForecastSubtitle =>
      'Busiest hours and where demand outruns supply';

  @override
  String get aiSettingsTitle => 'AI settings';

  @override
  String get aiSettingsSubtitle => 'Features, mock mode, API key';

  @override
  String get aiActivityTitle => 'AI activity';

  @override
  String get aiActivitySubtitle =>
      'Which surface answered, live model or fallback';

  @override
  String get preferencesSubtitleAdmin =>
      'Theme, text size, language, alerts, sounds';

  @override
  String get nameLabel => 'Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get roleLabel => 'Role';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get allFilterChip => 'All';

  @override
  String get couldNotLoadFeedback => 'Could not load feedback.';

  @override
  String get noFeedbackInView => 'No feedback in this view.';

  @override
  String get anonymousFallback => 'Anonymous';

  @override
  String get reopenAction => 'Re-open';

  @override
  String get markResolvedAction => 'Mark resolved';

  @override
  String get couldNotLoadAuditLog => 'Could not load the audit log.';

  @override
  String get noAuditEntriesYet => 'No audit entries yet.';

  @override
  String byActorLabel(String actor) {
    return 'by $actor';
  }

  @override
  String get couldNotLoadAiLog => 'Could not load the AI log.';

  @override
  String get noAiActivityRecordedYet => 'No AI activity recorded yet.';

  @override
  String aiCallsSummary(int total, int live, int offline) {
    return '$total calls · $live via the live model · $offline offline';
  }

  @override
  String get liveModelLabel => 'live model';

  @override
  String get offlineLabel => 'offline';

  @override
  String get directoryHeader => 'Directory';

  @override
  String get couldNotLoadSystemStats => 'Could not load system stats.';

  @override
  String get staffCountLabel => 'Staff';

  @override
  String get adminsLabel => 'Admins';

  @override
  String get departmentsLabel => 'Departments';

  @override
  String get openRiskFlagsLabel => 'Open risk flags';

  @override
  String get appointmentsLast90DaysHeader => 'Appointments · last 90 days';

  @override
  String get couldNotLoadAppointmentStats =>
      'Could not load appointment stats.';

  @override
  String get noShowRiskModelNote =>
      'No-show risk predictions come from the offline logistic-regression model (RQ2).';

  @override
  String get allAppointmentsTitle => 'Appointments';

  @override
  String get couldNotLoadAppointmentsAdmin => 'Could not load appointments.';

  @override
  String get noAppointmentsInView => 'No appointments in this view.';

  @override
  String get unassignedLabel => 'Unassigned';

  @override
  String get recomputeTooltip => 'Recompute';

  @override
  String get couldNotComputeForecast => 'Could not compute the forecast.';

  @override
  String get forecastExplainerNote =>
      'Busiest window per weekday, from appointment history. A flag means peak demand has been running at or above a single clinician’s hourly capacity.';

  @override
  String get demandLevelHigh => 'High demand';

  @override
  String get demandLevelModerate => 'Moderate';

  @override
  String get demandLevelLow => 'Light';

  @override
  String get overflowRiskLabel => 'Overflow risk';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String peakWindowSummary(String window, int count) {
    return 'Peak $window · up to $count/hr';
  }

  @override
  String get billingTitle => 'Billing';

  @override
  String get couldNotLoadInvoicesAdmin => 'Could not load invoices.';

  @override
  String get noInvoicesInView => 'No invoices in this view.';

  @override
  String get markPaidAction => 'Mark paid';

  @override
  String get cancelThisInvoiceTitle => 'Cancel this invoice?';

  @override
  String get patientWillNoLongerOweIt => 'The patient will no longer owe it.';

  @override
  String get cancelInvoiceAction => 'Cancel invoice';

  @override
  String invoiceMarkedStatus(String status) {
    return 'Invoice marked $status.';
  }

  @override
  String get newDepartmentAction => 'New department';

  @override
  String get noDepartmentsYet => 'No departments yet.';

  @override
  String get editAction => 'Edit';

  @override
  String get deleteAction => 'Delete';

  @override
  String deleteConfirmTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get cannotBeUndoneNote => 'This cannot be undone.';

  @override
  String itemDeletedSnackbar(String name) {
    return '$name deleted';
  }

  @override
  String get editDepartmentTitle => 'Edit department';

  @override
  String get descriptionOptionalLabel => 'Description (optional)';

  @override
  String get couldNotLoadSettings => 'Could not load settings.';

  @override
  String get aiFeaturesEnabledTitle => 'AI features enabled';

  @override
  String get aiFeaturesEnabledSubtitle =>
      'Turn off to hide all AI surfaces entirely.';

  @override
  String get forceMockModeTitle => 'Force mock mode';

  @override
  String get forceMockModeSubtitle =>
      'Use the offline deterministic assistant even when a key is set. Recommended for demos.';

  @override
  String get llmProviderHeader => 'LLM provider (Google Gemini, free tier)';

  @override
  String get demoDataHeader => 'Demo data';

  @override
  String get reseedDemoDataTitle => 'Re-seed demo data';

  @override
  String get reseedDemoDataSubtitle =>
      'Wipe and regenerate the synthetic dataset.';

  @override
  String get reseedConfirmTitle => 'Re-seed?';

  @override
  String get reseedConfirmBody =>
      'This deletes all current data and regenerates the demo dataset.';

  @override
  String get reseedAction => 'Re-seed';

  @override
  String reseededSnackbar(int patients, int appointments) {
    return 'Re-seeded: $patients patients, $appointments appointments.';
  }

  @override
  String get modelFieldLabel => 'Model';

  @override
  String get modelFieldHelper => 'e.g. gemini-2.0-flash, gemini-2.5-flash';

  @override
  String get apiKeySetTitle => 'API key set';

  @override
  String get apiKeyStoredNote => 'Stored in the OS secure store.';

  @override
  String get replaceAction => 'Replace';

  @override
  String get apiKeyFieldLabel => 'API key';

  @override
  String get apiKeyHelper =>
      'aistudio.google.com/apikey — never logged or committed';

  @override
  String get noApiKeySet => 'No API key set.';

  @override
  String get connectionOkMessage => 'Connection OK — the model responded.';

  @override
  String connectionFailedMessage(String error) {
    return 'Failed: $error';
  }

  @override
  String get testConnectionAction => 'Test connection';

  @override
  String get systemHealthHeader => 'System health';

  @override
  String get analyticsAction => 'Analytics';

  @override
  String get recentActivityHeader => 'Recent activity';

  @override
  String get allClearTitle => 'All clear';

  @override
  String get noQueuesWaitingSubtitle =>
      'No invoices, reports, visit or referral requests waiting';

  @override
  String unpaidInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unpaid invoices',
      one: '$count unpaid invoice',
    );
    return '$_temp0';
  }

  @override
  String openReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open reports',
      one: '$count open report',
    );
    return '$_temp0';
  }

  @override
  String visitRequestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visit requests',
      one: '$count visit request',
    );
    return '$_temp0';
  }

  @override
  String referralRequestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count referral requests',
      one: '$count referral request',
    );
    return '$_temp0';
  }

  @override
  String thingsNeedYouTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things need you',
      one: '$count thing needs you',
    );
    return '$_temp0';
  }

  @override
  String get viewDetailedAnalytics => 'View detailed analytics';

  @override
  String get referralRequestsTitle => 'Referral requests';

  @override
  String get noReferralRequestsWaiting => 'No referral requests waiting.';

  @override
  String get aClinicianFallback => 'A clinician';

  @override
  String requestedByOn(String name, String date) {
    return 'Requested by $name · $date';
  }

  @override
  String get actionButton => 'Action';

  @override
  String get rejectAction => 'Reject';

  @override
  String patientReferredSnackbar(String name) {
    return '$name referred.';
  }

  @override
  String get rejectThisRequestTitle => 'Reject this request';

  @override
  String get whyNoReferralNeededHint => 'Why is no referral needed?';

  @override
  String get actionReferralTitle => 'Action referral';

  @override
  String get anotherDepartmentSegment => 'Another department';

  @override
  String get anotherHospitalSegment => 'Another hospital';

  @override
  String get hospitalLabel => 'Hospital';

  @override
  String get departmentLabel => 'Department';

  @override
  String get noteForRecordOptionalLabel => 'Note for the record (optional)';

  @override
  String get referPatientAction => 'Refer patient';

  @override
  String get addUserAction => 'Add user';

  @override
  String get broadcastAction => 'Broadcast';

  @override
  String get createInvoiceAction => 'Create invoice';

  @override
  String feedbackActionWithCount(int count) {
    return 'Feedback ($count)';
  }

  @override
  String get homeVisitsAction => 'Home visits';

  @override
  String homeVisitsActionWithCount(int count) {
    return 'Home visits ($count)';
  }

  @override
  String get referralsAction => 'Referrals';

  @override
  String referralsActionWithCount(int count) {
    return 'Referrals ($count)';
  }

  @override
  String get reseedDataAction => 'Re-seed data';

  @override
  String get addAPersonTitle => 'Add a…';

  @override
  String get reseedDemoDataConfirmTitle => 'Re-seed demo data?';

  @override
  String get reseedWipeWarningBody =>
      'This wipes every account, appointment and record and rebuilds the demo dataset. You will be signed out.';

  @override
  String get reseedingEllipsis => 'Re-seeding…';

  @override
  String reseededFullSnackbar(int patients, int staff, int appointments) {
    return 'Re-seeded: $patients patients, $staff staff, $appointments appointments.';
  }

  @override
  String sentToCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sent to $count people.',
      one: 'Sent to $count person.',
    );
    return '$_temp0';
  }

  @override
  String get broadcastNotificationTitle => 'Broadcast a notification';

  @override
  String get sendToLabel => 'Send to';

  @override
  String get allPatientsOption => 'All patients';

  @override
  String get allStaffOption => 'All staff';

  @override
  String get everyoneOption => 'Everyone';

  @override
  String get categoryLabel => 'Category';

  @override
  String get messageLabel => 'Message';

  @override
  String get createAnInvoiceTitle => 'Create an invoice';

  @override
  String get amountBdBeforeTaxLabel => 'Amount (BD, before tax)';

  @override
  String get whatIsThisForOptionalLabel => 'What is this for? (optional)';

  @override
  String taxTotalDueNote(String total, String date) {
    return '+ 10% tax = BD $total total · due $date';
  }

  @override
  String get raiseInvoiceAction => 'Raise invoice';

  @override
  String invoiceRaisedSnackbar(String amount) {
    return 'Invoice raised — BD $amount.';
  }

  @override
  String get userManagementTitle => 'User management';

  @override
  String get searchByNameOrEmailHint => 'Search by name or email';

  @override
  String get addPatientAction => 'Add patient';

  @override
  String get addStaffAction => 'Add staff';

  @override
  String get addAdminAction => 'Add admin';

  @override
  String get couldNotLoadUsers => 'Could not load users.';

  @override
  String get noUsersInGroup => 'No users in this group.';

  @override
  String noUsersMatchQuery(String query) {
    return 'No users match “$query”.';
  }

  @override
  String emailDeactivatedLabel(String email) {
    return '$email · deactivated';
  }

  @override
  String get deactivateAction => 'Deactivate';

  @override
  String get reactivateAction => 'Reactivate';

  @override
  String get resetPasswordAction => 'Reset password';

  @override
  String get bookAppointmentAction => 'Book appointment';

  @override
  String get referAction => 'Refer';

  @override
  String userDeactivatedSnackbar(String name) {
    return '$name deactivated';
  }

  @override
  String userReactivatedSnackbar(String name) {
    return '$name reactivated';
  }

  @override
  String passwordResetForSnackbar(String name) {
    return 'Password reset for $name';
  }

  @override
  String get nationalIdLabel => 'National ID';

  @override
  String get statusLabel => 'Status';

  @override
  String get accountActiveLabel => 'Active';

  @override
  String get accountDeactivatedLabel => 'Deactivated';

  @override
  String get joinedLabel => 'Joined';

  @override
  String get newTemporaryPasswordTitle => 'New temporary password';

  @override
  String get resetAction => 'Reset';

  @override
  String get addAnAdministratorTitle => 'Add an administrator';

  @override
  String get addAPatientTitle => 'Add a patient';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get temporaryPasswordLabel => 'Temporary password (8+ chars)';

  @override
  String get createAction => 'Create';

  @override
  String createdSnackbar(String name) {
    return '$name created';
  }

  @override
  String get addStaffMemberTitle => 'Add staff member';

  @override
  String get doctorOption => 'Doctor';

  @override
  String get nurseOption => 'Nurse';

  @override
  String get specialtyUnitOptionalLabel => 'Specialty / unit (optional)';

  @override
  String get specialtyOptionalLabel => 'Specialty (optional)';

  @override
  String get noneOption => 'None';

  @override
  String get bookAnAppointmentTitle => 'Book an appointment';

  @override
  String forPatientLabel(String name) {
    return 'For $name';
  }

  @override
  String get clinicDaysHelpText => 'Clinic days: Sunday–Thursday';

  @override
  String get clinicHoursHelpText => 'Clinic hours: 08:00–20:00';

  @override
  String get chooseDepartmentFirstHelper => 'Choose a department first';

  @override
  String get noDoctorsInDepartmentHelper => 'No doctors in this department';

  @override
  String get doctorLabel => 'Doctor';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get pickTimeBetweenNote => 'Pick a time between 08:00 and 20:00.';

  @override
  String get visitTypeFieldLabel => 'Visit type';

  @override
  String get reasonOptionalLabel => 'Reason (optional)';

  @override
  String appointmentBookedForSnackbar(String name) {
    return 'Appointment booked for $name';
  }

  @override
  String get reasonForReferralLabel => 'Reason for referral';

  @override
  String patientReferredToSnackbar(String name, String destination) {
    return '$name referred to $destination';
  }

  @override
  String get textSizeLabel => 'Text size';

  @override
  String textSizeCaption(String level) {
    return '$level — applies to text across the whole app';
  }

  @override
  String get textScaleSmaller => 'Smaller';

  @override
  String get textScaleSmall => 'Small';

  @override
  String get textScaleDefault => 'Default';

  @override
  String get textScaleLarge => 'Large';

  @override
  String get textScaleLarger => 'Larger';

  @override
  String get notificationChannelsLabel => 'Notification channels';

  @override
  String get smsLabel => 'SMS';

  @override
  String get soundsLabel => 'Sounds';

  @override
  String get soundsSubtitle =>
      'A short cue when a message arrives, and when a working status changes';

  @override
  String get notificationChannelsCaption =>
      'Where appointment reminders and care alerts reach you.';

  @override
  String get personalInfoTitle => 'Personal info';

  @override
  String get personalInfoSubtitle => 'Name, contact, date of birth';

  @override
  String get healthDetailsTitle => 'Health details';

  @override
  String get healthDetailsSubtitle => 'Blood type, allergies, conditions';

  @override
  String get walletTitle => 'Wallet';

  @override
  String get walletSubtitle => 'Saved cards and payment history';

  @override
  String get familyNetworkTitle => 'Family network';

  @override
  String get familyNetworkSubtitle => 'People linked to your account';

  @override
  String get profileUpdatedSnackbar => 'Profile updated.';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get cprLabel => 'CPR';

  @override
  String cprDigitsHelper(int count) {
    return '$count/9 digits';
  }

  @override
  String get dateOfBirthDdmmyyyyLabel => 'Date of birth (DD/MM/YYYY)';

  @override
  String get genderFieldLabel => 'Gender';

  @override
  String get healthDetailsUpdatedSnackbar => 'Health details updated.';

  @override
  String get bloodTypeLabel => 'Blood type';

  @override
  String get unknownOption => 'Unknown';

  @override
  String get separateWithCommasHelper => 'Separate with commas';

  @override
  String get chronicConditionsLabel => 'Chronic conditions';

  @override
  String get emergencyContactLabel => 'Emergency contact';

  @override
  String get emergencyContactHint => 'Name · phone';

  @override
  String get sharedWithCliniciansNote =>
      'Shared with the clinicians who treat you.';

  @override
  String get couldNotLoadYourAllergies => 'Could not load your allergies.';

  @override
  String get shownToCliniciansNote =>
      'Shown to every clinician who treats you and printed on your reports. Keep it accurate.';

  @override
  String get addYourAllergiesAction => 'Add your allergies';

  @override
  String get updateAllergiesAction => 'Update allergies';

  @override
  String get knownAllergiesLabel => 'Known allergies';

  @override
  String get noAllergiesRecordedTitle => 'No allergies recorded';

  @override
  String get noAllergiesRecordedSubtitle =>
      'If you have any drug, food or other allergies, add them so your care team can see them.';

  @override
  String get couldNotLoadFamilyMembers => 'Could not load family members.';

  @override
  String get noFamilyMembersLinkedYet => 'No family members linked yet.';

  @override
  String get addFamilyMemberAction => 'Add family member';

  @override
  String removeConfirmTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get unlinksFromFamilyNetworkNote =>
      'This unlinks them from your family network.';

  @override
  String get editFamilyMemberTitle => 'Edit family member';

  @override
  String get relationshipLabel => 'Relationship';

  @override
  String get firstNameRequiredLabel => 'First name *';

  @override
  String get lastNameRequiredLabel => 'Last name *';

  @override
  String get cprOptionalLabel => 'CPR (optional)';

  @override
  String get dobDdmmyyyyOptionalLabel => 'Date of birth (DD/MM/YYYY, optional)';

  @override
  String get genderOptionalLabel => 'Gender (optional)';

  @override
  String get bloodTypeOptionalLabel => 'Blood type (optional)';

  @override
  String get saveChangesAction => 'Save changes';

  @override
  String cprValueLabel(String value) {
    return 'CPR $value';
  }

  @override
  String get familyRelationshipSpouse => 'Spouse';

  @override
  String get familyRelationshipChild => 'Child';

  @override
  String get familyRelationshipParent => 'Parent';

  @override
  String get familyRelationshipSibling => 'Sibling';

  @override
  String get familyRelationshipGuardian => 'Guardian';

  @override
  String get familyRelationshipOther => 'Other';

  @override
  String get visitedDoctorsTitle => 'Visited doctors';

  @override
  String get couldNotLoadYourCareTeam => 'Could not load your care team.';

  @override
  String get noPastVisitsYetMessage =>
      'No past visits yet.\nDoctors you see will appear here.';

  @override
  String visitCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visits',
      one: '$count visit',
    );
    return '$_temp0';
  }

  @override
  String lastVisitLabel(String date) {
    return 'Last $date';
  }

  @override
  String nextVisitLabel(String date) {
    return 'Next $date';
  }

  @override
  String get generalDepartmentFallback => 'General';

  @override
  String get bookAgainAction => 'Book again';

  @override
  String get navHome => 'Home';

  @override
  String get navNutrition => 'Nutrition';

  @override
  String get navAppointments => 'Appointments';

  @override
  String get navRecords => 'Records';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navPatients => 'Patients';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navUsers => 'Users';

  @override
  String get navDepartments => 'Departments';

  @override
  String get navBilling => 'Billing';

  @override
  String get pickPatientPlaceholder => 'Pick a patient to open their chart.';

  @override
  String idValueLabel(String value) {
    return 'ID $value';
  }
}
