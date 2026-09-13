// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get signOutConfirmBody => 'ستحتاج إلى تسجيل الدخول مرة أخرى للمتابعة.';

  @override
  String get account => 'الحساب';

  @override
  String get roleStaff => 'طاقم طبي';

  @override
  String get rolePatient => 'مري/ة';

  @override
  String get roleAdmin => 'مسؤول';

  @override
  String get specialty => 'التخصص';

  @override
  String get jobTitle => 'المسمى الوظيفي';

  @override
  String get licenseNo => 'رقم الترخيص';

  @override
  String get department => 'القسم';

  @override
  String get memberSince => 'عضو منذ';

  @override
  String get managedByAdmin => 'تتم إدارة هذه التفاصيل بواسطة المسؤول.';

  @override
  String get none => 'لا يوجد';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'لغة النظام';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get translationNote =>
      'ترجمة الواجهة بالكامل قيد التطوير؛ حالياً تدعم شاشة الملف الشخصي العربية والإنجليزية.';

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get signInSubtitle =>
      'سجلاتك الطبية ومواعيدك وفريق الرعاية — في مكان واحد هادئ.';

  @override
  String get sessionEndedNotice =>
      'انتهت جلستك بعد 24 دقيقة من عدم النشاط. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailOrNationalIdHelper =>
      'يمكنك أيضاً تسجيل الدخول باستخدام رقم الهوية الوطنية';

  @override
  String get emailOrNationalIdRequired =>
      'أدخل بريدك الإلكتروني أو رقم الهوية الوطنية';

  @override
  String get password => 'كلمة المرور';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get passwordRequired => 'أدخل كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get createPatientAccount => 'إنشاء حساب مريض';

  @override
  String get demoAccounts => 'حسابات تجريبية';

  @override
  String get demoPatient => 'مريض';

  @override
  String get demoStaff => 'طاقم';

  @override
  String get demoAdmin => 'مسؤول';

  @override
  String demoPasswordNote(String password) {
    return 'كلمة المرور لجميع الحسابات: $password';
  }

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get accountSection => 'الحساب';

  @override
  String get detailsSection => 'التفاصيل';

  @override
  String get medicalSectionOptional => 'معلومات طبية (اختياري)';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get validEmailRequired => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get passwordMinLength => '6 أحرف على الأقل';

  @override
  String get phoneOptional => 'رقم الهاتف (اختياري)';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get gender => 'الجنس';

  @override
  String get genderMale => 'ذكر';

  @override
  String get genderFemale => 'أنثى';

  @override
  String get nationalIdOptional => 'رقم الهوية الوطنية (اختياري)';

  @override
  String get bloodType => 'فصيلة الدم';

  @override
  String get chronicConditions => 'الأمراض المزمنة';

  @override
  String get commaSeparatedHelper => 'مفصولة بفواصل';

  @override
  String get allergies => 'الحساسية';

  @override
  String get emergencyContact => 'جهة اتصال للطوارئ';

  @override
  String get requiredField => 'مطلوب';

  @override
  String get presenceOnDuty => 'في الخدمة';

  @override
  String get presenceInConsultation => 'في استشارة';

  @override
  String get presenceOnBreak => 'في استراحة';

  @override
  String get presenceOffShift => 'خارج الدوام';

  @override
  String get genderOther => 'آخر';

  @override
  String get genderUndisclosed => 'يفضل عدم الإفصاح';

  @override
  String get appointmentStatusBooked => 'محجوز';

  @override
  String get appointmentStatusConfirmed => 'مؤكد';

  @override
  String get appointmentStatusInProgress => 'جارٍ';

  @override
  String get appointmentStatusCompleted => 'مكتمل';

  @override
  String get appointmentStatusCancelled => 'ملغى';

  @override
  String get appointmentStatusNoShow => 'لم يحضر';

  @override
  String get walkInStatusWaiting => 'بالانتظار';

  @override
  String get walkInStatusCalled => 'تم النداء';

  @override
  String get walkInStatusInProgress => 'جارٍ';

  @override
  String get walkInStatusDone => 'تم';

  @override
  String get walkInStatusCancelled => 'ملغى';

  @override
  String get referralRequestStatusPending => 'قيد الانتظار';

  @override
  String get referralRequestStatusActioned => 'تم اتخاذ إجراء';

  @override
  String get referralRequestStatusRejected => 'مرفوض';

  @override
  String get riskBandLow => 'منخفض';

  @override
  String get riskBandMedium => 'متوسط';

  @override
  String get riskBandHigh => 'مرتفع';

  @override
  String get recordTypeVisitNote => 'ملاحظة زيارة';

  @override
  String get recordTypeLabResult => 'نتيجة مخبرية';

  @override
  String get recordTypeImaging => 'تصوير';

  @override
  String get recordTypePrescription => 'وصفة طبية';

  @override
  String get recordTypeVaccination => 'تطعيم';

  @override
  String get recordTypeDischarge => 'خروج';

  @override
  String get recordTypeReferral => 'تحويل';

  @override
  String get abnormalFlagNormal => 'طبيعي';

  @override
  String get abnormalFlagLow => 'منخفض';

  @override
  String get abnormalFlagHigh => 'مرتفع';

  @override
  String get abnormalFlagCritical => 'حرج';

  @override
  String get taskKindFollowUpDue => 'متابعة مستحقة';

  @override
  String get taskKindUnreviewedAbnormalLab =>
      'نتيجة مخبرية غير طبيعية لم تُراجع';

  @override
  String get taskKindUnsignedNote => 'ملاحظة غير موقعة';

  @override
  String get taskKindMedicationReview => 'مراجعة الأدوية';

  @override
  String get taskKindReferralAction => 'إجراء تحويل';

  @override
  String get taskKindOther => 'أخرى';

  @override
  String get taskStatusOpen => 'مفتوح';

  @override
  String get taskStatusInProgress => 'جارٍ';

  @override
  String get taskStatusDone => 'تم';

  @override
  String get taskStatusDismissed => 'مرفوض';

  @override
  String get riskFlagKindAbnormalVitals => 'علامات حيوية غير طبيعية';

  @override
  String get riskFlagKindAbnormalLab => 'نتيجة مخبرية غير طبيعية';

  @override
  String get riskFlagKindMedicationGap => 'نقص في الالتزام الدوائي';

  @override
  String get riskFlagKindOverdueFollowUp => 'متابعة متأخرة';

  @override
  String get riskFlagKindOther => 'أخرى';

  @override
  String get severityInfo => 'معلومة';

  @override
  String get severityWarning => 'تحذير';

  @override
  String get severityUrgent => 'عاجل';

  @override
  String get flagSourceRule => 'قائم على قاعدة';

  @override
  String get flagSourceAi => 'ذكاء اصطناعي';

  @override
  String get reminderKindStandard => 'عادي';

  @override
  String get reminderKindEscalated => 'مصعّد';

  @override
  String get reminderKindConfirmRequest => 'طلب تأكيد';

  @override
  String get reminderChannelPush => 'إشعار فوري';

  @override
  String get reminderChannelInApp => 'داخل التطبيق';

  @override
  String get reminderChannelSms => 'رسالة نصية';

  @override
  String get reminderChannelEmail => 'بريد إلكتروني';

  @override
  String get invoiceStatusPending => 'قيد الانتظار';

  @override
  String get invoiceStatusPaid => 'مدفوع';

  @override
  String get invoiceStatusCancelled => 'ملغى';

  @override
  String get invoiceStatusOverdue => 'متأخر';

  @override
  String get homeVisitStatusRequested => 'مطلوب';

  @override
  String get homeVisitStatusScheduled => 'مجدول';

  @override
  String get homeVisitStatusCompleted => 'مكتمل';

  @override
  String get homeVisitStatusDeclined => 'مرفوض';

  @override
  String get homeVisitStatusCancelled => 'ملغى';

  @override
  String get notificationCategoryAppointment => 'موعد';

  @override
  String get notificationCategoryBilling => 'فوترة';

  @override
  String get notificationCategoryLabResult => 'نتيجة مخبرية';

  @override
  String get notificationCategoryPrescription => 'وصفة طبية';

  @override
  String get notificationCategoryMessage => 'رسالة';

  @override
  String get notificationCategorySystem => 'النظام';

  @override
  String get feedbackCategoryBug => 'خطأ تقني';

  @override
  String get feedbackCategoryFeatureRequest => 'طلب ميزة';

  @override
  String get feedbackCategoryGeneralFeedback => 'ملاحظات عامة';

  @override
  String get feedbackCategoryComplaint => 'شكوى';

  @override
  String get feedbackStatusOpen => 'مفتوح';

  @override
  String get feedbackStatusResolved => 'تم الحل';

  @override
  String get aiFeatureCareNavigator => 'Care Navigator';

  @override
  String get aiFeatureClinicalScribe => 'Clinical Scribe';

  @override
  String get aiFeaturePatientSummary => 'ملخص المريض';

  @override
  String get nothingHere => 'لا يوجد شيء هنا.';

  @override
  String get selectItemPlaceholder => 'اختر عنصراً لعرض تفاصيله.';

  @override
  String get confirm => 'تأكيد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get tryAgain => 'إعادة المحاولة';

  @override
  String get riskBadgeLow => 'خطر منخفض';

  @override
  String get riskBadgeMedium => 'خطر متوسط';

  @override
  String get riskBadgeHigh => 'خطر مرتفع';

  @override
  String get severityChipInfo => 'معلومة';

  @override
  String get severityChipReview => 'مراجعة';

  @override
  String get severityChipUrgent => 'عاجل';

  @override
  String get aiDisclaimer =>
      'محتوى مُولّد بالذكاء الاصطناعي — للعلم فقط وليس استشارة طبية. يرجى التأكد مع طبيبك المعالج.';

  @override
  String labReferenceSuffix(String reference) {
    return '، المرجع $reference';
  }

  @override
  String get notificationsTooltip => 'الإشعارات';

  @override
  String notificationsTooltipUnread(int count) {
    return 'الإشعارات ($count غير مقروءة)';
  }

  @override
  String get greetingFallbackName => 'عزيزي';

  @override
  String get sectionYourHealth => 'صحتك';

  @override
  String get sectionUpcomingAppointments => 'المواعيد القادمة';

  @override
  String get sectionQuickActions => 'إجراءات سريعة';

  @override
  String get quickAppointmentTitle => 'موعد سريع';

  @override
  String get quickAppointmentSubtitle => 'عاجل أو عادي — احصل على موعد أسرع';

  @override
  String get quickAppointmentSheetQuestion => 'ما مدى إلحاح هذه الزيارة؟';

  @override
  String get urgencyUrgentTitle => 'عاجل';

  @override
  String get urgencyUrgentSubtitle => 'وجّهني تلقائياً لأقرب طبيب متاح';

  @override
  String get urgencyNormalTitle => 'عادي';

  @override
  String get urgencyNormalSubtitle => 'اختيار القسم والطبيب والوقت بنفسي';

  @override
  String get onSchedule => 'تم تسجيلك في الجدول';

  @override
  String get metricTicket => 'التذكرة';

  @override
  String get metricMedicine => 'الدواء';

  @override
  String get metricLastVisit => 'آخر زيارة';

  @override
  String allergiesInline(String list) {
    return 'الحساسية: $list';
  }

  @override
  String get quickActionVitals => 'العلامات الحيوية';

  @override
  String get quickActionMedications => 'الأدوية';

  @override
  String get quickActionAskDoctor => 'اسأل طبيبك';

  @override
  String get quickActionVisitedDoctors => 'الأطباء الذين زرتهم';

  @override
  String get quickActionSickLeave => 'إجازة مرضية';

  @override
  String get quickActionHomeCare => 'رعاية منزلية';

  @override
  String get quickActionBilling => 'الفواتير';

  @override
  String get couldNotLoadAppointments => 'تعذّر تحميل المواعيد.';

  @override
  String get noUpcomingAppointments => 'لا توجد مواعيد قادمة';

  @override
  String get tapToBookVisit => 'اضغط لحجز زيارة';

  @override
  String carouselPosition(int index, int count) {
    return '$index من $count';
  }

  @override
  String get previousAppointment => 'الموعد السابق';

  @override
  String get nextAppointment => 'الموعد التالي';

  @override
  String get ticketOverline => 'التذكرة';

  @override
  String roomNumber(String room) {
    return 'غرفة $room';
  }

  @override
  String bookedForName(String name) {
    return 'لـ $name';
  }

  @override
  String get appointmentsTitle => 'مواعيدي';

  @override
  String upcomingCount(int count) {
    return 'القادمة ($count)';
  }

  @override
  String get nothingBookedNote =>
      'لا توجد حجوزات. استخدم \"احجز الآن\" أو \"جدولة\" أعلاه.';

  @override
  String historyCount(int count) {
    return 'السجل ($count)';
  }

  @override
  String get noPastVisitsNote => 'لا توجد زيارات سابقة بعد.';

  @override
  String get bookNowTitle => 'احجز الآن';

  @override
  String get bookNowSubtitle => 'أقرب موعد متاح';

  @override
  String get scheduleTitle => 'جدولة';

  @override
  String get scheduleSubtitle => 'اختر تاريخاً';

  @override
  String ticketLabel(String tag) {
    return 'التذكرة $tag';
  }

  @override
  String get reschedule => 'إعادة الجدولة';

  @override
  String get cancelAppointmentTitle => 'إلغاء الموعد؟';

  @override
  String get cancelAppointmentMessage => 'سيؤدي هذا إلى إتاحة الموعد لشخص آخر.';

  @override
  String get cancelItLabel => 'إلغاؤه';

  @override
  String get clinicDaysHelp => 'أيام العيادة: الأحد–الخميس';

  @override
  String get clinicHoursHelp => 'ساعات العيادة: 08:00–20:00';

  @override
  String get pickTimeInRange => 'اختر وقتاً بين 08:00 و20:00.';

  @override
  String bookedOn(String date) {
    return 'تم الحجز $date';
  }

  @override
  String get scheduleAVisitTitle => 'جدولة زيارة';

  @override
  String get couldNotLoadDepartments => 'تعذّر تحميل الأقسام.';

  @override
  String get stepDepartment => 'القسم';

  @override
  String get stepDoctor => 'الطبيب';

  @override
  String get stepReasonForVisit => 'سبب الزيارة';

  @override
  String get stepReasonShort => 'السبب';

  @override
  String get stepDateTime => 'التاريخ والوقت';

  @override
  String get whoIsThisFor => 'لمن هذا الموعد؟';

  @override
  String get myself => 'لنفسي';

  @override
  String bookedForNotice(String name) {
    return 'سيتم حجز هذه الزيارة لـ $name.';
  }

  @override
  String stepProgress(int step, int total, String label) {
    return 'الخطوة $step من $total · $label';
  }

  @override
  String get couldNotLoadDoctors => 'تعذّر تحميل الأطباء';

  @override
  String get noDoctorsListed => 'لا يوجد أطباء مدرجون لهذا القسم بعد.';

  @override
  String get findingSoonestOpening => 'جارٍ البحث عن أقرب موعد متاح…';

  @override
  String soonestOpeningAt(String relDay, String date) {
    return 'أقرب موعد متاح: $relDay، $date';
  }

  @override
  String get couldNotLoadTimes => 'تعذّر تحميل الأوقات.';

  @override
  String get noOpenTimesThatDay =>
      'لا توجد أوقات متاحة في ذلك اليوم. جرّب تاريخاً آخر.';

  @override
  String get recommendedSection => 'موصى به';

  @override
  String get allOpenTimesSection => 'جميع الأوقات المتاحة';

  @override
  String get appointmentBooked => 'تم حجز الموعد';

  @override
  String get reviewAndConfirm => 'المراجعة والتأكيد';

  @override
  String get rowLabelFor => 'لمن';

  @override
  String get rowLabelWhen => 'الموعد';

  @override
  String get confirmBookingButton => 'تأكيد الحجز';

  @override
  String get backButton => 'رجوع';

  @override
  String get couldNotLoadMedications => 'تعذّر تحميل الأدوية.';

  @override
  String get noMedicationsOnRecord => 'لا توجد أدوية مسجلة.';

  @override
  String get currentSectionLabel => 'الحالية';

  @override
  String get pastSectionLabel => 'السابقة';

  @override
  String medDoseFrom(String date) {
    return 'من $date';
  }

  @override
  String medDoseTo(String date) {
    return 'إلى $date';
  }

  @override
  String get imagingTitle => 'الأشعة';

  @override
  String get couldNotLoadImaging => 'تعذّر تحميل نتائج الأشعة.';

  @override
  String get noImagingResultsYet =>
      'لا توجد نتائج أشعة بعد.\nستظهر هنا الأشعة السينية والمسوحات والموجات فوق الصوتية بعد إجراء الفحص.';

  @override
  String get reportPdfLabel => 'تقرير PDF';

  @override
  String get recordTitle => 'السجل';

  @override
  String get couldNotLoadRecord => 'تعذّر تحميل هذا السجل.';

  @override
  String fromYourVisitOn(String date) {
    return 'من زيارتك في $date';
  }

  @override
  String get referralLetterLabel => 'خطاب التحويل';

  @override
  String get resultsSection => 'النتائج';

  @override
  String get extractedTextSection => 'النص المستخرج';

  @override
  String get labColumnAnalyte => 'التحليل';

  @override
  String get labColumnValue => 'القيمة';

  @override
  String get labColumnReference => 'المرجع';

  @override
  String get recordsTitle => 'السجلات';

  @override
  String get timelineSegment => 'الجدول الزمني';

  @override
  String get billsSegment => 'الفواتير';

  @override
  String get vitalSignsReportLabel => 'تقرير العلامات الحيوية';

  @override
  String get allergiesLabel => 'الحساسية';

  @override
  String get couldNotLoadRecords => 'تعذّر تحميل سجلاتك.';

  @override
  String get nothingMatchesFilters => 'لا يوجد ما يطابق هذه الفلاتر بعد.';

  @override
  String get searchRecordsHint => 'ابحث في السجلات';

  @override
  String get filterVisits => 'الزيارات';

  @override
  String get filterLabs => 'التحاليل';

  @override
  String get filterPrescriptions => 'الوصفات الطبية';

  @override
  String get filterVaccinations => 'التطعيمات';

  @override
  String get filterReferrals => 'التحويلات';

  @override
  String get flaggedByAi => 'مُعلَّم بواسطة الذكاء الاصطناعي';

  @override
  String get vitalsRecordedTitle => 'تم تسجيل العلامات الحيوية';

  @override
  String get vitalsTitle => 'العلامات الحيوية';

  @override
  String get couldNotLoadVitals => 'تعذّر تحميل العلامات الحيوية.';

  @override
  String get noVitalsRecordedYet =>
      'لا توجد علامات حيوية مسجلة بعد.\nاحجز زيارة للحصول على أول قراءة.';

  @override
  String get chartBloodPressure => 'ضغط الدم';

  @override
  String get chartWeight => 'الوزن';

  @override
  String get chartGlucose => 'الجلوكوز';

  @override
  String get seriesSystolic => 'الانقباضي';

  @override
  String get seriesDiastolic => 'الانبساطي';

  @override
  String get recentReadingsSection => 'القراءات الأخيرة';

  @override
  String get couldNotCreateDocument => 'تعذّر إنشاء المستند.';

  @override
  String get couldNotLoadInvoices => 'تعذّر تحميل فواتيرك.';

  @override
  String get noInvoicesYet => 'لا توجد فواتير بعد.\nستظهر هنا فواتير زياراتك.';

  @override
  String get openSectionLabel => 'مفتوحة';

  @override
  String get historyLabel => 'السجل';

  @override
  String get outstandingBalance => 'الرصيد المستحق';

  @override
  String get allSettled => 'تمت التسوية بالكامل';

  @override
  String openInvoicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فاتورة مفتوحة',
      many: '$count فاتورة مفتوحة',
      few: '$count فواتير مفتوحة',
      two: 'فاتورتان مفتوحتان',
      one: 'فاتورة واحدة مفتوحة',
      zero: 'لا توجد فواتير مفتوحة',
    );
    return '$_temp0';
  }

  @override
  String overdueAmount(String amount) {
    return '$amount متأخرة';
  }

  @override
  String issuedOn(String date) {
    return 'صدرت في $date';
  }

  @override
  String get subtotalLabel => 'المجموع الفرعي';

  @override
  String taxLabel(String rate) {
    return 'الضريبة ($rate%)';
  }

  @override
  String get totalLabel => 'الإجمالي';

  @override
  String wasDueOn(String date) {
    return 'كان مستحقاً في $date';
  }

  @override
  String dueOn(String date) {
    return 'مستحق في $date';
  }

  @override
  String paidOn(String date) {
    return 'دُفع في $date';
  }

  @override
  String payAmountButton(String amount) {
    return 'ادفع $amount';
  }

  @override
  String get payInvoiceTitle => 'دفع الفاتورة';

  @override
  String amountDue(String amount) {
    return '$amount مستحقة';
  }

  @override
  String get payWithLabel => 'الدفع باستخدام';

  @override
  String get demoPaymentNote =>
      'دفع تجريبي — يتم التحقق من بيانات البطاقة على هذا الجهاز فقط ولا تُخزَّن أو تُرسل إلى أي مكان.';

  @override
  String get nameOnCardLabel => 'الاسم على البطاقة';

  @override
  String get enterNameOnCard => 'أدخل الاسم الموجود على البطاقة';

  @override
  String get cardNumberLabel => 'رقم البطاقة';

  @override
  String get enterFullCardNumber => 'أدخل رقم البطاقة كاملاً';

  @override
  String get cardNumberInvalid => 'رقم البطاقة هذا غير صحيح';

  @override
  String get expiryLabel => 'تاريخ الانتهاء';

  @override
  String get monthRange => 'يجب أن يكون الشهر بين 01 و12';

  @override
  String get cardExpired => 'انتهت صلاحية البطاقة';

  @override
  String get digitsRange => '3–4 أرقام';

  @override
  String get enterSecurityCode => 'أدخل رمز الأمان المكوّن من 3–4 أرقام.';

  @override
  String get paymentReceived => 'تم استلام الدفعة';

  @override
  String cardExpiredOn(String expiry) {
    return 'انتهت الصلاحية في $expiry';
  }

  @override
  String cardExpiresOn(String expiry) {
    return 'تنتهي الصلاحية في $expiry';
  }

  @override
  String get payWithDifferentCard => 'الدفع باستخدام بطاقة أخرى';

  @override
  String get securityCodeHelper =>
      'الأرقام الثلاثة أو الأربعة الموجودة خلف البطاقة';

  @override
  String get savedCardsLabel => 'البطاقات المحفوظة';

  @override
  String get addCardButton => 'إضافة بطاقة';

  @override
  String get couldNotLoadCards => 'تعذّر تحميل البطاقات.';

  @override
  String get noCardsSavedYet => 'لا توجد بطاقات محفوظة بعد.';

  @override
  String get transactionHistoryLabel => 'سجل المعاملات';

  @override
  String get noPaymentsYet => 'لا توجد مدفوعات بعد.';

  @override
  String get defaultChip => 'افتراضية';

  @override
  String get setDefaultButton => 'تعيين كافتراضية';

  @override
  String get removeCardTooltip => 'إزالة البطاقة';

  @override
  String get removeCardTitle => 'إزالة البطاقة؟';

  @override
  String removeCardMessage(String brand, String last4) {
    return 'سيتم إزالة $brand ····$last4.';
  }

  @override
  String get removeButton => 'إزالة';

  @override
  String get addACardTitle => 'إضافة بطاقة';

  @override
  String get saveCardButton => 'حفظ البطاقة';

  @override
  String get cardSavedNote =>
      'يتم حفظ آخر 4 أرقام وتاريخ الانتهاء فقط — أبداً الرقم الكامل أو رمز الأمان.';

  @override
  String get expiredSuffix => 'منتهية';

  @override
  String get markAllReadButton => 'تحديد الكل كمقروء';

  @override
  String get couldNotLoadNotifications => 'تعذّر تحميل إشعاراتك.';

  @override
  String get allCaughtUpMessage => 'أنت على اطلاع بكل شيء.\nلا جديد هنا.';

  @override
  String get last24HoursSection => 'آخر 24 ساعة';

  @override
  String get earlierSection => 'سابقاً';

  @override
  String get openButton => 'فتح';

  @override
  String get onlineStatus => 'متصل';

  @override
  String get askAboutAppHint => 'اسأل عن التطبيق…';

  @override
  String get openCareNavigator => 'فتح Care Navigator';

  @override
  String get hideCareNavigator => 'إخفاء Care Navigator';

  @override
  String get showCareNavigator => 'إظهار Care Navigator';

  @override
  String get taskBoardTitle => 'لوحة المهام';

  @override
  String get couldNotLoadTasks => 'تعذّر تحميل المهام.';

  @override
  String get noOpenTasksMessage =>
      'لا توجد مهام مفتوحة. شغّل فحصاً شاملاً من لوحة التحكم.';

  @override
  String priorityBlendNote(int pct) {
    return 'تمزج الأولوية درجة القاعدة $pct% مع درجة الذكاء الاصطناعي.';
  }

  @override
  String get tasksReprioritised => 'تمت إعادة ترتيب أولويات المهام.';

  @override
  String get prioritiseButton => 'ترتيب الأولوية';

  @override
  String get startAction => 'بدء';

  @override
  String get completeAction => 'إكمال';

  @override
  String get dismissAction => 'تجاهل';

  @override
  String ruleScoreTag(String score) {
    return 'القاعدة $score';
  }

  @override
  String aiScoreTag(String score) {
    return 'الذكاء الاصطناعي $score';
  }

  @override
  String dueTag(String relDay) {
    return 'الاستحقاق $relDay';
  }

  @override
  String get taskKindFollowUpShort => 'متابعة';

  @override
  String get taskKindAbnormalLabShort => 'نتيجة مخبرية غير طبيعية';

  @override
  String get taskKindReferralShort => 'تحويل';

  @override
  String get homeHealthCareTitle => 'الرعاية المنزلية';

  @override
  String get requestAVisitButton => 'طلب زيارة';

  @override
  String get couldNotLoadHomeVisitRequests => 'تعذّر تحميل طلباتك.';

  @override
  String get noHomeVisitRequestsMessage =>
      'لا توجد طلبات زيارة منزلية.\nاطلب من طبيب زيارتك في المنزل عندما يصعب الوصول إلى العيادة.';

  @override
  String preferredOn(String date) {
    return 'المفضل $date';
  }

  @override
  String clinicNote(String note) {
    return 'العيادة: $note';
  }

  @override
  String get cancelRequestButton => 'إلغاء الطلب';

  @override
  String get requestAHomeVisitTitle => 'طلب زيارة منزلية';

  @override
  String get homeAddressLabel => 'عنوان المنزل';

  @override
  String get homeAddressHint => 'المبنى، الشارع، المجمع، المنطقة';

  @override
  String get whyHomeVisitNeededLabel => 'لماذا تحتاج زيارة منزلية؟';

  @override
  String get departmentOptionalLabel => 'القسم (اختياري)';

  @override
  String get notSureOption => 'غير متأكد';

  @override
  String preferredDateLabel(String date) {
    return 'التاريخ المفضل: $date';
  }

  @override
  String get sendRequestButton => 'إرسال الطلب';

  @override
  String get requestSentToClinic => 'تم إرسال الطلب إلى العيادة.';

  @override
  String get clinicWillConfirmNote =>
      'ستقوم العيادة بتأكيد موعد أو التواصل معك.';

  @override
  String get homeVisitsTitle => 'الزيارات المنزلية';

  @override
  String get couldNotLoadQueue => 'تعذّر تحميل قائمة الانتظار.';

  @override
  String preferredAndRequestedOn(String preferred, String requested) {
    return 'المفضل $preferred  ·  طُلب في $requested';
  }

  @override
  String noteLabel(String note) {
    return 'ملاحظة: $note';
  }

  @override
  String get scheduleButton => 'جدولة';

  @override
  String get declineButton => 'رفض';

  @override
  String get markCompletedButton => 'تحديد كمكتمل';

  @override
  String get scheduleThisVisitTitle => 'جدولة هذه الزيارة';

  @override
  String get declineThisRequestTitle => 'رفض هذا الطلب';

  @override
  String get scheduleHint => 'مثال: ستزور الممرضة يوم الثلاثاء 10:00';

  @override
  String get declineHint => 'سبب رفض الطلب';

  @override
  String get couldNotLoadCertificates => 'تعذّر تحميل شهاداتك.';

  @override
  String get noSickLeaveCertificatesMessage =>
      'لا توجد شهادات إجازة مرضية.\nيمكن لطبيبك إصدار واحدة بعد الزيارة.';

  @override
  String get activeChip => 'سارية';

  @override
  String dateRangeDays(String from, String to, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يوماً',
      few: '$days أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: 'لا أيام',
    );
    return '$from – $to  ·  $_temp0';
  }

  @override
  String get certificatePdfLabel => 'شهادة PDF';

  @override
  String get newMessageButton => 'رسالة جديدة';

  @override
  String get couldNotLoadMessages => 'تعذّر تحميل رسائلك.';

  @override
  String get onceSeenDoctorMessage => 'بمجرد زيارتك لطبيب يمكنك مراسلته هنا.';

  @override
  String get noConversationsYetMessage =>
      'لا توجد محادثات بعد.\nاضغط على \"رسالة جديدة\" لطرح سؤال غير عاجل.';

  @override
  String get yourDoctorFallback => 'طبيبك';

  @override
  String get openPatientChartTooltip => 'فتح ملف المريض';

  @override
  String get couldNotLoadConversation => 'تعذّر تحميل هذه المحادثة.';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد.';

  @override
  String get sendNonUrgentQuestionMessage =>
      'أرسل لطبيبك سؤالاً غير عاجل.\nفي حالات الطوارئ، اتصل بعيادتك.';

  @override
  String get writeMessageHint => 'اكتب رسالة';

  @override
  String get youPrefix => 'أنت: ';

  @override
  String get messagesTitle => 'الرسائل';

  @override
  String get couldNotLoadInbox => 'تعذّر تحميل بريدك الوارد.';

  @override
  String get noPatientMessages => 'لا توجد رسائل من المرضى.';

  @override
  String get somethingIsBrokenOption => 'هناك خلل ما';

  @override
  String get sendFeedbackTitle => 'إرسال ملاحظات';

  @override
  String get feedbackIntroText =>
      'أخبر الفريق بما يعمل بشكل جيد، وما لا يعمل، أو ما تتمنى أن يقدمه التطبيق.';

  @override
  String get aboutLabel => 'حول';

  @override
  String get yourMessageLabel => 'رسالتك';

  @override
  String get sendButton => 'إرسال';

  @override
  String get feedbackThanksMessage => 'شكراً — تم إرسال ملاحظاتك إلى الفريق.';

  @override
  String get nutritionTitle => 'التغذية';

  @override
  String get calculatorSegment => 'الحاسبة';

  @override
  String get mealPlanSegment => 'خطة الوجبات';

  @override
  String get foodsSegment => 'الأطعمة';

  @override
  String get aboutYouSection => 'عنك';

  @override
  String get ageLabel => 'العمر';

  @override
  String get sexLabel => 'الجنس';

  @override
  String get weightKgLabel => 'الوزن (كجم)';

  @override
  String get heightCmLabel => 'الطول (سم)';

  @override
  String get activityLabel => 'النشاط';

  @override
  String get activitySedentary => 'خامل الحركة';

  @override
  String get activityLightlyActive => 'نشاط خفيف (1–3 أيام/أسبوع)';

  @override
  String get activityModeratelyActive => 'نشاط متوسط (3–5 أيام/أسبوع)';

  @override
  String get activityVeryActive => 'نشاط عالٍ (6–7 أيام/أسبوع)';

  @override
  String get activityExtraActive => 'نشاط مرتفع جداً (عمل بدني)';

  @override
  String get goalLabel => 'الهدف';

  @override
  String get goalMaintain => 'الحفاظ على الوزن';

  @override
  String get goalLose => 'إنقاص الوزن';

  @override
  String get goalGain => 'زيادة الوزن';

  @override
  String get weeklyRateLabel => 'المعدل الأسبوعي';

  @override
  String get weeklyRate025 => '0.25 كجم / أسبوع';

  @override
  String get weeklyRate05 => '0.5 كجم / أسبوع';

  @override
  String get weeklyRate10 => '1.0 كجم / أسبوع';

  @override
  String get calculateTargetsButton => 'احسب الأهداف';

  @override
  String get preferencesSection => 'التفضيلات';

  @override
  String get macroSplitNote => 'توزيع الماكرو المستخدم لأهدافك ولخطة وجباتك.';

  @override
  String get presetBalanced => 'متوازن';

  @override
  String get presetLowFat => 'قليل الدهون';

  @override
  String get presetLowCarb => 'قليل الكربوهيدرات';

  @override
  String get presetHighCarb => 'عالي الكربوهيدرات';

  @override
  String get presetHighProtein => 'عالي البروتين';

  @override
  String get dailyTargetsSection => 'الأهداف اليومية';

  @override
  String get macroCalories => 'السعرات الحرارية';

  @override
  String get macroProtein => 'البروتين';

  @override
  String get macroCarbs => 'الكربوهيدرات';

  @override
  String get macroFat => 'الدهون';

  @override
  String get macroSugar => 'السكر';

  @override
  String get macroSatFat => 'الدهون المشبعة';

  @override
  String get unitKcalPerDay => 'سعرة / يوم';

  @override
  String get unitPerDay => 'في اليوم';

  @override
  String get unitDailyCap => 'الحد الأقصى اليومي';

  @override
  String bmrTdeeNote(int bmr, int tdee) {
    return 'معدل الأيض الأساسي $bmr سعرة · إجمالي الطاقة اليومي $tdee سعرة. إرشادي فقط — يمكن لطبيبك تخصيصه لحالتك.';
  }

  @override
  String get searchFoodsHint => 'ابحث عن الأطعمة';

  @override
  String get allCategoriesChip => 'الكل';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر',
      many: '$count عنصراً',
      few: '$count عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'لا توجد عناصر',
    );
    return '$_temp0';
  }

  @override
  String get noFoodsMatch => 'لا توجد أطعمة تطابق هذا البحث.';

  @override
  String servingLabel(String value) {
    return 'الحصة $value';
  }

  @override
  String get also => 'أيضاً';

  @override
  String containsAllergens(String list) {
    return 'يحتوي على: $list';
  }

  @override
  String get includeDessertTitle => 'إضافة حلوى';

  @override
  String get includeDessertSubtitle =>
      'يقسّم اليوم إلى أربع وجبات بدلاً من ثلاث';

  @override
  String get buildMyDayButton => 'إنشاء خطة يومي';

  @override
  String get runCalculatorFirstNote =>
      'شغّل الحاسبة أولاً — بعدها سيتم توزيع هدف السعرات والماكرو على الوجبات هنا.';

  @override
  String get yourDayTitle => 'يومك';

  @override
  String get mealBreakfast => 'الفطور';

  @override
  String get mealLunch => 'الغداء';

  @override
  String get mealDinner => 'العشاء';

  @override
  String get mealDessert => 'الحلوى';

  @override
  String get switchToLightMode => 'التبديل إلى الوضع الفاتح';

  @override
  String get switchToDarkMode => 'التبديل إلى الوضع الداكن';

  @override
  String get profileTooltip => 'الملف الشخصي';

  @override
  String get setYourAvailabilityTooltip => 'تحديد حالة توفرك';

  @override
  String get couldNotUpdatePresence => 'تعذّر تحديث حالة تواجدك.';

  @override
  String get panelAnalyticsTitle => 'تحليلات اللوحة';

  @override
  String get couldNotComputeAnalytics => 'تعذّر حساب التحليلات.';

  @override
  String lastNDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'آخر $days يوم',
      many: 'آخر $days يوماً',
      few: 'آخر $days أيام',
      two: 'آخر يومين',
      one: 'آخر يوم واحد',
      zero: 'آخر يوم',
    );
    return '$_temp0';
  }

  @override
  String get noShowRateLabel => 'معدل عدم الحضور';

  @override
  String noShowRateCaption(int kept, int total) {
    return '$kept من أصل $total مواعيد تم الالتزام بها';
  }

  @override
  String get cancellationRateLabel => 'معدل الإلغاء';

  @override
  String cancelledCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إلغاء',
      many: '$count إلغاءً',
      few: '$count إلغاءات',
      two: 'إلغاءان',
      one: 'إلغاء واحد',
      zero: 'لا إلغاءات',
    );
    return '$_temp0';
  }

  @override
  String get completedLabel => 'مكتملة';

  @override
  String perDayCaption(String value) {
    return '$value يومياً';
  }

  @override
  String get upcomingLabel => 'قادمة';

  @override
  String get bookedOrConfirmedCaption => 'محجوزة أو مؤكدة';

  @override
  String get staffDirectoryTitle => 'دليل الطاقم الطبي';

  @override
  String get couldNotLoadStaffDirectory => 'تعذّر تحميل دليل الطاقم الطبي.';

  @override
  String get noStaffOnRecord => 'لا يوجد طاقم مسجَّل.';

  @override
  String cliniciansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طبيب',
      many: '$count طبيباً',
      few: '$count أطباء',
      two: 'طبيبان',
      one: 'طبيب واحد',
      zero: 'لا يوجد أطباء',
    );
    return '$_temp0';
  }

  @override
  String get myActivityTitle => 'نشاطي';

  @override
  String get recordsTab => 'السجلات';

  @override
  String get prescriptionsTab => 'الوصفات الطبية';

  @override
  String get couldNotLoadYourRecords => 'تعذّر تحميل سجلاتك.';

  @override
  String get noRecordsAuthoredYet => 'لم تقم بإنشاء أي سجلات بعد.';

  @override
  String get couldNotLoadYourPrescriptions => 'تعذّر تحميل وصفاتك الطبية.';

  @override
  String get noPrescriptionsIssuedYet => 'لم تُصدر أي وصفات طبية بعد.';

  @override
  String get currentMedicationChip => 'قيد الاستخدام';

  @override
  String get yourShiftHeader => 'مناوبتك';

  @override
  String get quickActionsHeader => 'إجراءات سريعة';

  @override
  String get todaysQueueHeader => 'قائمة انتظار اليوم';

  @override
  String get scheduleAction => 'الجدول';

  @override
  String get riskFlagsHeader => 'إشارات الخطر';

  @override
  String get patientsAction => 'المرضى';

  @override
  String get tasksHeader => 'المهام';

  @override
  String get taskBoardAction => 'لوحة المهام';

  @override
  String departmentWalkInsHeader(int count) {
    return 'مراجعو القسم دون موعد ($count)';
  }

  @override
  String get yourQueueIsClear => 'قائمة انتظارك فارغة';

  @override
  String get nobodyWaitingOpenWeek =>
      'لا أحد ينتظر — افتح أسبوعك للتخطيط مسبقاً';

  @override
  String nextPatientLabel(String who) {
    return 'التالي · $who';
  }

  @override
  String get todayLabel => 'اليوم';

  @override
  String get inQueueLabel => 'في الانتظار';

  @override
  String get openFlagsLabel => 'إشارات مفتوحة';

  @override
  String get couldNotLoadYourQueue => 'تعذّر تحميل قائمة انتظارك.';

  @override
  String get nobodyWaitingQueueClear => 'لا أحد ينتظر — قائمة انتظارك فارغة.';

  @override
  String get moreActionsTooltip => 'إجراءات إضافية';

  @override
  String get openChartAction => 'فتح الملف الطبي';

  @override
  String get addNoteAction => 'إضافة ملاحظة';

  @override
  String get transferVisitAction => 'نقل الزيارة';

  @override
  String get cancelVisitAction => 'إلغاء الزيارة';

  @override
  String get markNoShowAction => 'تسجيل كعدم حضور';

  @override
  String get cancelThisVisitTitle => 'إلغاء هذه الزيارة؟';

  @override
  String get patientWillNeedToRebook => 'سيحتاج المريض إلى إعادة الحجز.';

  @override
  String get markAsNoShowTitle => 'تسجيل كعدم حضور؟';

  @override
  String get recordsPatientDidNotAttend => 'يسجّل هذا أن المريض لم يحضر.';

  @override
  String get checkedInLabel => 'تم تسجيل الوصول';

  @override
  String get couldNotLoadRiskFlags => 'تعذّر تحميل إشارات الخطر.';

  @override
  String get noOpenRiskFlagsRunScan =>
      'لا توجد إشارات خطر مفتوحة. شغّل فحص اللوحة للتحديث.';

  @override
  String get acknowledgeTooltip => 'تأكيد الاطلاع';

  @override
  String moreOnPatientsTab(int count) {
    return '+$count أخرى في تبويب المرضى';
  }

  @override
  String get noOpenTasksRunScan =>
      'لا توجد مهام مفتوحة. شغّل فحص اللوحة من الإجراءات السريعة.';

  @override
  String get markDoneTooltip => 'تسجيل كمنجزة';

  @override
  String get newNoteAction => 'ملاحظة جديدة';

  @override
  String get addClinicalNoteForTitle => 'إضافة ملاحظة سريرية لـ…';

  @override
  String get prescribeAction => 'وصف دواء';

  @override
  String get prescribeForTitle => 'وصف دواء لـ…';

  @override
  String get labResultAction => 'نتيجة مختبر';

  @override
  String get enterLabResultForTitle => 'إدخال نتيجة مختبر لـ…';

  @override
  String get aiScribeAction => 'الكاتب الذكي';

  @override
  String get scribeVisitNoteForTitle => 'تدوين ملاحظة الزيارة لـ…';

  @override
  String get patientSummaryAction => 'ملخص المريض';

  @override
  String get summariseTitle => 'تلخيص…';

  @override
  String get patientLookupAction => 'البحث عن مريض';

  @override
  String messagesActionWithCount(int n) {
    return 'الرسائل ($n)';
  }

  @override
  String get panelScanAction => 'فحص اللوحة';

  @override
  String get scanningPanelForRisks => 'جارٍ فحص اللوحة بحثاً عن المخاطر…';

  @override
  String panelScanCompleteFlags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اكتمل فحص اللوحة — $count إشارة مفتوحة.',
      many: 'اكتمل فحص اللوحة — $count إشارة مفتوحة.',
      few: 'اكتمل فحص اللوحة — $count إشارات مفتوحة.',
      two: 'اكتمل فحص اللوحة — إشارتان مفتوحتان.',
      one: 'اكتمل فحص اللوحة — إشارة واحدة مفتوحة.',
      zero: 'اكتمل فحص اللوحة — لا إشارات مفتوحة.',
    );
    return '$_temp0';
  }

  @override
  String get searchByNameOrNationalId => 'ابحث بالاسم أو الرقم الوطني';

  @override
  String get couldNotLoadPatients => 'تعذّر تحميل المرضى.';

  @override
  String get noPatientsMatchSearch => 'لا يوجد مرضى مطابقون لهذا البحث.';

  @override
  String idLabel(String id) {
    return 'الرقم التعريفي $id';
  }

  @override
  String get transferAVisitTitle => 'نقل زيارة';

  @override
  String get reassignVisitNote =>
      'أعد تعيين زيارة من اليوم إلى طبيب آخر. تعود الحالة إلى \"محجوزة\" ليتمكن من قبولها مجدداً.';

  @override
  String get nothingInQueueToTransfer =>
      'لا توجد زيارة في قائمة انتظارك لنقلها.';

  @override
  String get visitLabel => 'الزيارة';

  @override
  String get couldNotLoadDirectory => 'تعذّر تحميل الدليل.';

  @override
  String get transferToLabel => 'النقل إلى';

  @override
  String get visitTransferred => 'تم نقل الزيارة.';

  @override
  String get compressTheDay => 'تصغير عرض اليوم';

  @override
  String get expandTheDay => 'توسيع عرض اليوم';

  @override
  String get previousDayTooltip => 'اليوم السابق';

  @override
  String get nextDayTooltip => 'اليوم التالي';

  @override
  String get previousTooltip => 'السابق';

  @override
  String get nextLabel => 'التالي';

  @override
  String get couldNotLoadYourCalendar => 'تعذّر تحميل جدولك.';

  @override
  String get nothingBookedThisDay => 'لا يوجد شيء محجوز في هذا اليوم.';

  @override
  String get todaysQueueCaps => 'قائمة انتظار اليوم';

  @override
  String waitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ينتظرون',
      many: '$count ينتظرون',
      few: '$count ينتظرون',
      two: 'شخصان ينتظران',
      one: 'شخص واحد ينتظر',
      zero: 'لا أحد ينتظر',
    );
    return '$_temp0';
  }

  @override
  String get tapPatientOrPressNext =>
      'اضغط على مريض، أو اضغط \"التالي\" للبدء.';

  @override
  String get lastPatientInQueue => 'آخر مريض في قائمة الانتظار';

  @override
  String nowLabel(String name) {
    return 'الآن: $name';
  }

  @override
  String get noMorePatients => 'لا مزيد من المرضى';

  @override
  String reasonLabel(String reason) {
    return 'السبب: $reason';
  }

  @override
  String ageYearsAbbrev(int age) {
    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$age سنة',
      many: '$age سنة',
      few: '$age سنوات',
      two: 'سنتان',
      one: 'سنة واحدة',
      zero: 'بدون عمر',
    );
    return '$_temp0';
  }

  @override
  String allergiesInlineLabel(String list) {
    return 'الحساسية: $list';
  }

  @override
  String get couldNotLoadYourProfile => 'تعذّر تحميل ملفك الشخصي.';

  @override
  String get accountSubtitle => 'التخصص والقسم والترخيص';

  @override
  String get myActivitySubtitle => 'الملاحظات والوصفات التي قمت بإنشائها';

  @override
  String get staffDirectorySubtitle =>
      'الأطباء والتخصصات وحالة التواجد المباشرة';

  @override
  String get panelAnalyticsSubtitle => 'معدل عدم الحضور، الإلغاءات، الاستخدام';

  @override
  String get preferencesSubtitle => 'المظهر، حجم الخط، اللغة، التنبيهات';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get enterEmailOrNationalId => 'أدخل بريدك الإلكتروني أو رقمك الوطني.';

  @override
  String get forgotPasswordQuestion => 'نسيت كلمة المرور؟';

  @override
  String get forgotPasswordBody =>
      'أدخل البريد الإلكتروني أو الرقم الوطني المسجّل في حسابك وسننقلك لتعيين كلمة مرور جديدة.';

  @override
  String get emailOrNationalIdLabel => 'البريد الإلكتروني أو الرقم الوطني';

  @override
  String get continueButton => 'متابعة';

  @override
  String get backToSignIn => 'العودة لتسجيل الدخول';

  @override
  String get verifyItsYouTitle => 'تحقق من هويتك';

  @override
  String get codeNotRightError => 'هذا الرمز غير صحيح. حاول مرة أخرى.';

  @override
  String get enterSixDigitCode => 'أدخل الرمز المكوّن من 6 أرقام';

  @override
  String almostThereName(String name) {
    return 'أوشكت على الانتهاء يا $name';
  }

  @override
  String get sixDigitCodeSentNote =>
      'أرسلنا رمز تحقق مكوّناً من 6 أرقام إلى جهازك.';

  @override
  String get verifyButton => 'تحقق';

  @override
  String get codeResentLabel => 'تم إعادة إرسال الرمز';

  @override
  String get resendCodeLabel => 'إعادة إرسال الرمز';

  @override
  String demoCodeNote(String code) {
    return 'نسخة تجريبية — رمز التحقق هو $code.';
  }

  @override
  String get setNewPasswordTitle => 'تعيين كلمة مرور جديدة';

  @override
  String get startFromForgotPasswordNote =>
      'ابدأ من شاشة \"نسيت كلمة المرور\" حتى نعرف الحساب المطلوب إعادة تعيينه.';

  @override
  String get newPasswordTitle => 'كلمة مرور جديدة';

  @override
  String get newPasswordLabel => 'كلمة مرور جديدة (8 أحرف على الأقل)';

  @override
  String get atLeast8Characters => '8 أحرف على الأقل';

  @override
  String get confirmNewPasswordLabel => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get updatePasswordButton => 'تحديث كلمة المرور';

  @override
  String get passwordUpdatedSnackbar =>
      'تم تحديث كلمة المرور — سجّل الدخول بكلمة المرور الجديدة.';

  @override
  String get aiHealthSummaryTitle => 'ملخص الذكاء الاصطناعي الصحي';

  @override
  String get regenerateTooltip => 'إعادة الإنشاء';

  @override
  String regeneratedAt(String when) {
    return 'أُعيد الإنشاء في $when';
  }

  @override
  String couldNotGenerateSummary(String error) {
    return 'تعذّر إنشاء الملخص.\n$error';
  }

  @override
  String get thingsToCheckHeader => 'أمور يجب مراجعتها';

  @override
  String get trendsHeader => 'الاتجاهات';

  @override
  String get keyEventsHeader => 'الأحداث الرئيسية';

  @override
  String generatedMeta(String when, String model, String version) {
    return 'أُنشئ في $when  ·  $model  ·  $version';
  }

  @override
  String get aiClinicalScribeTitle => 'الكاتب السريري الذكي';

  @override
  String get visitNoteTitle => 'ملاحظة الزيارة';

  @override
  String visitNoteWithPatient(String name) {
    return 'ملاحظة الزيارة · $name';
  }

  @override
  String get dictationLabel => 'الإملاء';

  @override
  String get dictationHint =>
      'اكتب أو الصق ملاحظات الزيارة بلغة عادية — سيقوم الكاتب الذكي بتنظيمها.';

  @override
  String get structuringEllipsis => 'جارٍ التنظيم…';

  @override
  String get structureWithAi => 'تنظيم بالذكاء الاصطناعي';

  @override
  String get structuredNoteHeader => 'الملاحظة المنظَّمة';

  @override
  String get chiefComplaintLabel => 'الشكوى الرئيسية';

  @override
  String get hpiLabel => 'تاريخ المرض الحالي';

  @override
  String get assessmentLabel => 'التقييم';

  @override
  String get planLabel => 'الخطة';

  @override
  String get suggestedIcdNote => 'رموز ICD-10 المقترحة — تأكد منها قبل الترميز';

  @override
  String get saveAsVisitNote => 'حفظ كملاحظة زيارة';

  @override
  String get savedToPatientRecord => 'تم الحفظ في سجل المريض.';

  @override
  String get clinicalNoteFallbackTitle => 'ملاحظة سريرية';

  @override
  String get patientChartFallbackTitle => 'الملف الطبي للمريض';

  @override
  String get aiSummaryTooltip => 'ملخص الذكاء الاصطناعي';

  @override
  String get couldNotLoadThisPatient => 'تعذّر تحميل بيانات هذا المريض.';

  @override
  String get recentVitalsHeader => 'العلامات الحيوية الأخيرة';

  @override
  String get couldNotLoadMedicationsChart => 'تعذّر تحميل الأدوية';

  @override
  String get noActiveMedications => 'لا توجد أدوية فعّالة';

  @override
  String get noVitalsOnRecord => 'لا توجد علامات حيوية مسجلة';

  @override
  String get couldNotLoadTimelineChart => 'تعذّر تحميل الجدول الزمني';

  @override
  String get noRecordsYet => 'لا توجد سجلات بعد';

  @override
  String get addClinicalNoteAction => 'إضافة ملاحظة سريرية';

  @override
  String get aiScribeANoteAction => 'تدوين ملاحظة بالذكاء الاصطناعي';

  @override
  String get prescribeMedicationAction => 'وصف دواء';

  @override
  String get enterLabResultAction => 'إدخال نتيجة مختبر';

  @override
  String get labResultFallbackTitle => 'نتيجة مختبر';

  @override
  String get issueSickLeaveAction => 'إصدار إجازة مرضية';

  @override
  String get titleLabel => 'العنوان';

  @override
  String get noteFieldLabel => 'الملاحظة';

  @override
  String get noteAdded => 'تمت إضافة الملاحظة.';

  @override
  String get medicationNameLabel => 'اسم الدواء';

  @override
  String get doseOptionalLabel => 'الجرعة (اختياري)';

  @override
  String get frequencyOptionalLabel => 'التكرار (اختياري)';

  @override
  String get medicationPrescribed => 'تم وصف الدواء.';

  @override
  String get panelTitleLabel => 'اللوحة / العنوان';

  @override
  String get analyteLabel => 'المحلَّل';

  @override
  String get valueLabel => 'القيمة';

  @override
  String get unitLabel => 'الوحدة';

  @override
  String get refLowLabel => 'الحد المرجعي الأدنى';

  @override
  String get refHighLabel => 'الحد المرجعي الأعلى';

  @override
  String get labResultRecorded => 'تم تسجيل نتيجة المختبر.';

  @override
  String get reasonDiagnosisLabel => 'السبب / التشخيص';

  @override
  String get acuteViralIllnessHint => 'مثال: مرض فيروسي حاد';

  @override
  String fromDateLabel(String date) {
    return 'من: $date';
  }

  @override
  String toDateLabel(String date) {
    return 'إلى: $date';
  }

  @override
  String get notesOptionalLabel => 'ملاحظات (اختياري)';

  @override
  String get certificateIssued => 'تم إصدار الشهادة.';

  @override
  String daysCountPlain(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يوماً',
      few: '$days أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: 'لا أيام',
    );
    return '$_temp0';
  }

  @override
  String get saveButton => 'حفظ';

  @override
  String get addButton => 'إضافة';

  @override
  String get consultationFallbackTitle => 'الاستشارة';

  @override
  String get couldNotLoadThisAppointment => 'تعذّر تحميل هذا الموعد.';

  @override
  String get couldNotLoadThePatient => 'تعذّر تحميل بيانات المريض.';

  @override
  String get clinicalNoteHeader => 'الملاحظة السريرية';

  @override
  String get historyExamHint => 'التاريخ المرضي، الفحص، التقييم، الخطة…';

  @override
  String get openAiScribeAction => 'فتح الكاتب الذكي';

  @override
  String get noMedicationsAdded => 'لم تتم إضافة أي أدوية.';

  @override
  String get removeTooltip => 'إزالة';

  @override
  String get addMedicationAction => 'إضافة دواء';

  @override
  String get referralHeader => 'التحويل';

  @override
  String get referralRequestedAwaitingAdmin =>
      'تم طلب التحويل — بانتظار موافقة الإدارة';

  @override
  String get requestAReferralAction => 'طلب تحويل';

  @override
  String get visitSummaryOptionalLabel => 'ملخص الزيارة (اختياري)';

  @override
  String get visitSummaryHint => 'سطر واحد — نتيجة هذه الزيارة';

  @override
  String get completeConsultationAction => 'إنهاء الاستشارة';

  @override
  String get addNoteMedOrReferralFirst =>
      'أضف ملاحظة أو دواءً أو طلب تحويل أولاً.';

  @override
  String get referralRequestedSnackbar => 'تم طلب التحويل.';

  @override
  String get completeConsultationTitle => 'إنهاء الاستشارة؟';

  @override
  String get completeConsultationBody =>
      'سيتم حفظ الملاحظة وأي أدوية في سجل المريض وإغلاق الزيارة.';

  @override
  String get consultationCompletedSnackbar => 'تم إنهاء الاستشارة.';

  @override
  String get patientCalledInNote => 'تم استدعاء المريض.';

  @override
  String get callPatientAction => 'استدعاء المريض';

  @override
  String get patientCalledSnackbar => 'تم استدعاء المريض.';

  @override
  String get patientArrivedAction => 'وصل المريض';

  @override
  String get consultationStartedSnackbar => 'بدأت الاستشارة.';

  @override
  String get markedAsNoShowSnackbar => 'تم التسجيل كعدم حضور.';

  @override
  String get patientNotShownAction => 'لم يحضر المريض';

  @override
  String get consultationCompletedHeader => 'اكتملت الاستشارة';

  @override
  String get adminWillDecideReferralNote =>
      'ستقرر الإدارة ما إذا كان هذا تحويلاً داخل القسم أو تحويلاً خارجياً، وإلى أين.';

  @override
  String get clinicalReasonForReferralLabel => 'السبب السريري للتحويل';

  @override
  String get adminStatusAvailable => 'متاح';

  @override
  String get adminStatusMeeting => 'في اجتماع';

  @override
  String get adminStatusAway => 'غائب';

  @override
  String get adminStatusOff => 'غير متصل';

  @override
  String get accountSubtitleAdmin => 'الاسم والبريد الإلكتروني وتاريخ الانضمام';

  @override
  String get auditLogTitle => 'سجل التدقيق';

  @override
  String get auditLogSubtitle => 'كل ما تغيّر، الأحدث أولاً';

  @override
  String get systemAnalyticsTitle => 'تحليلات النظام';

  @override
  String get systemAnalyticsSubtitle =>
      'الأرقام الرئيسية، عدم الحضور والاستخدام';

  @override
  String get capacityForecastTitle => 'توقعات السعة';

  @override
  String get capacityForecastSubtitle =>
      'أكثر الساعات ازدحاماً وأين يتجاوز الطلب العرض';

  @override
  String get aiSettingsTitle => 'إعدادات الذكاء الاصطناعي';

  @override
  String get aiSettingsSubtitle => 'الميزات، الوضع التجريبي، مفتاح API';

  @override
  String get aiActivityTitle => 'نشاط الذكاء الاصطناعي';

  @override
  String get aiActivitySubtitle => 'أي واجهة أجابت، النموذج المباشر أم البديل';

  @override
  String get preferencesSubtitleAdmin =>
      'المظهر، حجم الخط، اللغة، التنبيهات، الأصوات';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get roleLabel => 'الدور';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get feedbackTitle => 'الملاحظات';

  @override
  String get allFilterChip => 'الكل';

  @override
  String get couldNotLoadFeedback => 'تعذّر تحميل الملاحظات.';

  @override
  String get noFeedbackInView => 'لا توجد ملاحظات في هذا العرض.';

  @override
  String get anonymousFallback => 'مجهول';

  @override
  String get reopenAction => 'إعادة الفتح';

  @override
  String get markResolvedAction => 'تحديد كمُعالَجة';

  @override
  String get couldNotLoadAuditLog => 'تعذّر تحميل سجل التدقيق.';

  @override
  String get noAuditEntriesYet => 'لا توجد إدخالات تدقيق بعد.';

  @override
  String byActorLabel(String actor) {
    return 'بواسطة $actor';
  }

  @override
  String get couldNotLoadAiLog => 'تعذّر تحميل سجل الذكاء الاصطناعي.';

  @override
  String get noAiActivityRecordedYet =>
      'لا يوجد نشاط للذكاء الاصطناعي مسجَّل بعد.';

  @override
  String aiCallsSummary(int total, int live, int offline) {
    return '$total استدعاء · $live عبر النموذج المباشر · $offline دون اتصال';
  }

  @override
  String get liveModelLabel => 'النموذج المباشر';

  @override
  String get offlineLabel => 'دون اتصال';

  @override
  String get directoryHeader => 'الدليل';

  @override
  String get couldNotLoadSystemStats => 'تعذّر تحميل إحصاءات النظام.';

  @override
  String get staffCountLabel => 'الطاقم الطبي';

  @override
  String get adminsLabel => 'المسؤولون';

  @override
  String get departmentsLabel => 'الأقسام';

  @override
  String get openRiskFlagsLabel => 'إشارات الخطر المفتوحة';

  @override
  String get appointmentsLast90DaysHeader => 'المواعيد · آخر 90 يوماً';

  @override
  String get couldNotLoadAppointmentStats => 'تعذّر تحميل إحصاءات المواعيد.';

  @override
  String get noShowRiskModelNote =>
      'تأتي توقعات مخاطر عدم الحضور من نموذج الانحدار اللوجستي غير المتصل (RQ2).';

  @override
  String get allAppointmentsTitle => 'المواعيد';

  @override
  String get couldNotLoadAppointmentsAdmin => 'تعذّر تحميل المواعيد.';

  @override
  String get noAppointmentsInView => 'لا توجد مواعيد في هذا العرض.';

  @override
  String get unassignedLabel => 'غير مُعيَّن';

  @override
  String get recomputeTooltip => 'إعادة الحساب';

  @override
  String get couldNotComputeForecast => 'تعذّر حساب التوقعات.';

  @override
  String get forecastExplainerNote =>
      'أكثر الفترات ازدحاماً لكل يوم من أيام الأسبوع، استناداً إلى سجل المواعيد. الإشارة تعني أن الطلب بلغ ذروته عند سعة طبيب واحد بالساعة أو تجاوزها.';

  @override
  String get demandLevelHigh => 'طلب مرتفع';

  @override
  String get demandLevelModerate => 'متوسط';

  @override
  String get demandLevelLow => 'خفيف';

  @override
  String get overflowRiskLabel => 'خطر تجاوز السعة';

  @override
  String get noHistoryYet => 'لا يوجد سجل بعد';

  @override
  String peakWindowSummary(String window, int count) {
    return 'الذروة $window · حتى $count/ساعة';
  }

  @override
  String get billingTitle => 'الفوترة';

  @override
  String get couldNotLoadInvoicesAdmin => 'تعذّر تحميل الفواتير.';

  @override
  String get noInvoicesInView => 'لا توجد فواتير في هذا العرض.';

  @override
  String get markPaidAction => 'تحديد كمدفوعة';

  @override
  String get cancelThisInvoiceTitle => 'إلغاء هذه الفاتورة؟';

  @override
  String get patientWillNoLongerOweIt => 'لن يعد المريض مديناً بها.';

  @override
  String get cancelInvoiceAction => 'إلغاء الفاتورة';

  @override
  String invoiceMarkedStatus(String status) {
    return 'تم تحديد الفاتورة كـ $status.';
  }

  @override
  String get newDepartmentAction => 'قسم جديد';

  @override
  String get noDepartmentsYet => 'لا توجد أقسام بعد.';

  @override
  String get editAction => 'تعديل';

  @override
  String get deleteAction => 'حذف';

  @override
  String deleteConfirmTitle(String name) {
    return 'حذف $name؟';
  }

  @override
  String get cannotBeUndoneNote => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String itemDeletedSnackbar(String name) {
    return 'تم حذف $name';
  }

  @override
  String get editDepartmentTitle => 'تعديل القسم';

  @override
  String get descriptionOptionalLabel => 'الوصف (اختياري)';

  @override
  String get couldNotLoadSettings => 'تعذّر تحميل الإعدادات.';

  @override
  String get aiFeaturesEnabledTitle => 'تفعيل ميزات الذكاء الاصطناعي';

  @override
  String get aiFeaturesEnabledSubtitle =>
      'أوقف التفعيل لإخفاء جميع واجهات الذكاء الاصطناعي تماماً.';

  @override
  String get forceMockModeTitle => 'فرض الوضع التجريبي';

  @override
  String get forceMockModeSubtitle =>
      'استخدام المساعد الحتمي غير المتصل حتى عند تعيين مفتاح. يُنصح به للعروض التوضيحية.';

  @override
  String get llmProviderHeader =>
      'مزوّد النموذج اللغوي (Google Gemini، الفئة المجانية)';

  @override
  String get demoDataHeader => 'البيانات التجريبية';

  @override
  String get reseedDemoDataTitle => 'إعادة توليد البيانات التجريبية';

  @override
  String get reseedDemoDataSubtitle =>
      'محو وإعادة توليد مجموعة البيانات الاصطناعية.';

  @override
  String get reseedConfirmTitle => 'إعادة التوليد؟';

  @override
  String get reseedConfirmBody =>
      'سيؤدي هذا إلى حذف جميع البيانات الحالية وإعادة توليد مجموعة البيانات التجريبية.';

  @override
  String get reseedAction => 'إعادة التوليد';

  @override
  String reseededSnackbar(int patients, int appointments) {
    return 'تمت إعادة التوليد: $patients مريض، $appointments موعد.';
  }

  @override
  String get modelFieldLabel => 'النموذج';

  @override
  String get modelFieldHelper => 'مثال: gemini-2.0-flash، gemini-2.5-flash';

  @override
  String get apiKeySetTitle => 'تم تعيين مفتاح API';

  @override
  String get apiKeyStoredNote => 'مخزَّن في مخزن النظام الآمن.';

  @override
  String get replaceAction => 'استبدال';

  @override
  String get apiKeyFieldLabel => 'مفتاح API';

  @override
  String get apiKeyHelper =>
      'aistudio.google.com/apikey — لا يُسجَّل أو يُحفظ أبداً';

  @override
  String get noApiKeySet => 'لا يوجد مفتاح API معيَّن.';

  @override
  String get connectionOkMessage => 'الاتصال ناجح — استجاب النموذج.';

  @override
  String connectionFailedMessage(String error) {
    return 'فشل: $error';
  }

  @override
  String get testConnectionAction => 'اختبار الاتصال';

  @override
  String get systemHealthHeader => 'سلامة النظام';

  @override
  String get analyticsAction => 'التحليلات';

  @override
  String get recentActivityHeader => 'النشاط الأخير';

  @override
  String get allClearTitle => 'لا يوجد ما يستدعي الانتباه';

  @override
  String get noQueuesWaitingSubtitle =>
      'لا توجد فواتير أو تقارير أو طلبات زيارة أو تحويل بانتظارك';

  @override
  String unpaidInvoiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فاتورة غير مدفوعة',
      many: '$count فاتورة غير مدفوعة',
      few: '$count فواتير غير مدفوعة',
      two: 'فاتورتان غير مدفوعتين',
      one: 'فاتورة واحدة غير مدفوعة',
      zero: 'لا فواتير غير مدفوعة',
    );
    return '$_temp0';
  }

  @override
  String openReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تقرير مفتوح',
      many: '$count تقريراً مفتوحاً',
      few: '$count تقارير مفتوحة',
      two: 'تقريران مفتوحان',
      one: 'تقرير واحد مفتوح',
      zero: 'لا تقارير مفتوحة',
    );
    return '$_temp0';
  }

  @override
  String visitRequestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب زيارة',
      many: '$count طلب زيارة',
      few: '$count طلبات زيارة',
      two: 'طلبا زيارة',
      one: 'طلب زيارة واحد',
      zero: 'لا طلبات زيارة',
    );
    return '$_temp0';
  }

  @override
  String referralRequestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب تحويل',
      many: '$count طلب تحويل',
      few: '$count طلبات تحويل',
      two: 'طلبا تحويل',
      one: 'طلب تحويل واحد',
      zero: 'لا طلبات تحويل',
    );
    return '$_temp0';
  }

  @override
  String thingsNeedYouTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أمر يحتاج انتباهك',
      many: '$count أمراً يحتاج انتباهك',
      few: '$count أمور تحتاج انتباهك',
      two: 'أمران يحتاجان انتباهك',
      one: 'أمر واحد يحتاج انتباهك',
      zero: 'لا شيء يحتاج انتباهك',
    );
    return '$_temp0';
  }

  @override
  String get viewDetailedAnalytics => 'عرض التحليلات التفصيلية';

  @override
  String get referralRequestsTitle => 'طلبات التحويل';

  @override
  String get noReferralRequestsWaiting => 'لا توجد طلبات تحويل بانتظارك.';

  @override
  String get aClinicianFallback => 'أحد الأطباء';

  @override
  String requestedByOn(String name, String date) {
    return 'طلبه $name · $date';
  }

  @override
  String get actionButton => 'تنفيذ';

  @override
  String get rejectAction => 'رفض';

  @override
  String patientReferredSnackbar(String name) {
    return 'تم تحويل $name.';
  }

  @override
  String get rejectThisRequestTitle => 'رفض هذا الطلب';

  @override
  String get whyNoReferralNeededHint => 'لماذا لا حاجة للتحويل؟';

  @override
  String get actionReferralTitle => 'تنفيذ التحويل';

  @override
  String get anotherDepartmentSegment => 'قسم آخر';

  @override
  String get anotherHospitalSegment => 'مستشفى آخر';

  @override
  String get hospitalLabel => 'المستشفى';

  @override
  String get departmentLabel => 'القسم';

  @override
  String get noteForRecordOptionalLabel => 'ملاحظة للسجل (اختياري)';

  @override
  String get referPatientAction => 'تحويل المريض';

  @override
  String get addUserAction => 'إضافة مستخدم';

  @override
  String get broadcastAction => 'بث إشعار';

  @override
  String get createInvoiceAction => 'إنشاء فاتورة';

  @override
  String feedbackActionWithCount(int count) {
    return 'الملاحظات ($count)';
  }

  @override
  String get homeVisitsAction => 'الزيارات المنزلية';

  @override
  String homeVisitsActionWithCount(int count) {
    return 'الزيارات المنزلية ($count)';
  }

  @override
  String get referralsAction => 'التحويلات';

  @override
  String referralsActionWithCount(int count) {
    return 'التحويلات ($count)';
  }

  @override
  String get reseedDataAction => 'إعادة توليد البيانات';

  @override
  String get addAPersonTitle => 'إضافة…';

  @override
  String get reseedDemoDataConfirmTitle => 'إعادة توليد البيانات التجريبية؟';

  @override
  String get reseedWipeWarningBody =>
      'سيؤدي هذا إلى حذف كل حساب وموعد وسجل وإعادة بناء مجموعة البيانات التجريبية. سيتم تسجيل خروجك.';

  @override
  String get reseedingEllipsis => 'جارٍ إعادة التوليد…';

  @override
  String reseededFullSnackbar(int patients, int staff, int appointments) {
    return 'تمت إعادة التوليد: $patients مريض، $staff من الطاقم الطبي، $appointments موعد.';
  }

  @override
  String sentToCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُرسل إلى $count شخص.',
      many: 'أُرسل إلى $count شخصاً.',
      few: 'أُرسل إلى $count أشخاص.',
      two: 'أُرسل إلى شخصين.',
      one: 'أُرسل إلى شخص واحد.',
      zero: 'لم يُرسل لأحد',
    );
    return '$_temp0';
  }

  @override
  String get broadcastNotificationTitle => 'بث إشعار';

  @override
  String get sendToLabel => 'الإرسال إلى';

  @override
  String get allPatientsOption => 'جميع المرضى';

  @override
  String get allStaffOption => 'جميع الطاقم الطبي';

  @override
  String get everyoneOption => 'الجميع';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get messageLabel => 'الرسالة';

  @override
  String get createAnInvoiceTitle => 'إنشاء فاتورة';

  @override
  String get amountBdBeforeTaxLabel =>
      'المبلغ (بالدينار البحريني، قبل الضريبة)';

  @override
  String get whatIsThisForOptionalLabel => 'ما سبب هذه الفاتورة؟ (اختياري)';

  @override
  String taxTotalDueNote(String total, String date) {
    return '+ ضريبة 10% = الإجمالي $total د.ب · الاستحقاق $date';
  }

  @override
  String get raiseInvoiceAction => 'إصدار الفاتورة';

  @override
  String invoiceRaisedSnackbar(String amount) {
    return 'تم إصدار الفاتورة — $amount د.ب.';
  }

  @override
  String get userManagementTitle => 'إدارة المستخدمين';

  @override
  String get searchByNameOrEmailHint => 'ابحث بالاسم أو البريد الإلكتروني';

  @override
  String get addPatientAction => 'إضافة مريض';

  @override
  String get addStaffAction => 'إضافة طاقم طبي';

  @override
  String get addAdminAction => 'إضافة مسؤول';

  @override
  String get couldNotLoadUsers => 'تعذّر تحميل المستخدمين.';

  @override
  String get noUsersInGroup => 'لا يوجد مستخدمون في هذه المجموعة.';

  @override
  String noUsersMatchQuery(String query) {
    return 'لا يوجد مستخدمون مطابقون لـ ”$query“.';
  }

  @override
  String emailDeactivatedLabel(String email) {
    return '$email · معطَّل';
  }

  @override
  String get deactivateAction => 'تعطيل';

  @override
  String get reactivateAction => 'إعادة التفعيل';

  @override
  String get resetPasswordAction => 'إعادة تعيين كلمة المرور';

  @override
  String get bookAppointmentAction => 'حجز موعد';

  @override
  String get referAction => 'تحويل';

  @override
  String userDeactivatedSnackbar(String name) {
    return 'تم تعطيل $name';
  }

  @override
  String userReactivatedSnackbar(String name) {
    return 'تمت إعادة تفعيل $name';
  }

  @override
  String passwordResetForSnackbar(String name) {
    return 'تمت إعادة تعيين كلمة المرور لـ $name';
  }

  @override
  String get nationalIdLabel => 'الرقم الوطني';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get accountActiveLabel => 'نشط';

  @override
  String get accountDeactivatedLabel => 'معطَّل';

  @override
  String get joinedLabel => 'تاريخ الانضمام';

  @override
  String get newTemporaryPasswordTitle => 'كلمة مرور مؤقتة جديدة';

  @override
  String get resetAction => 'إعادة تعيين';

  @override
  String get addAnAdministratorTitle => 'إضافة مسؤول';

  @override
  String get addAPatientTitle => 'إضافة مريض';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get temporaryPasswordLabel => 'كلمة مرور مؤقتة (8 أحرف على الأقل)';

  @override
  String get createAction => 'إنشاء';

  @override
  String createdSnackbar(String name) {
    return 'تم إنشاء $name';
  }

  @override
  String get addStaffMemberTitle => 'إضافة عضو طاقم طبي';

  @override
  String get doctorOption => 'طبيب';

  @override
  String get nurseOption => 'ممرض/ة';

  @override
  String get specialtyUnitOptionalLabel => 'التخصص / الوحدة (اختياري)';

  @override
  String get specialtyOptionalLabel => 'التخصص (اختياري)';

  @override
  String get noneOption => 'لا شيء';

  @override
  String get bookAnAppointmentTitle => 'حجز موعد';

  @override
  String forPatientLabel(String name) {
    return 'للمريض $name';
  }

  @override
  String get clinicDaysHelpText => 'أيام العيادة: الأحد–الخميس';

  @override
  String get clinicHoursHelpText => 'ساعات العيادة: 08:00–20:00';

  @override
  String get chooseDepartmentFirstHelper => 'اختر القسم أولاً';

  @override
  String get noDoctorsInDepartmentHelper => 'لا يوجد أطباء في هذا القسم';

  @override
  String get doctorLabel => 'الطبيب';

  @override
  String get dateLabel => 'التاريخ';

  @override
  String get timeLabel => 'الوقت';

  @override
  String get pickTimeBetweenNote => 'اختر وقتاً بين 08:00 و20:00.';

  @override
  String get visitTypeFieldLabel => 'نوع الزيارة';

  @override
  String get reasonOptionalLabel => 'السبب (اختياري)';

  @override
  String appointmentBookedForSnackbar(String name) {
    return 'تم حجز موعد لـ $name';
  }

  @override
  String get reasonForReferralLabel => 'سبب التحويل';

  @override
  String patientReferredToSnackbar(String name, String destination) {
    return 'تم تحويل $name إلى $destination';
  }
}
