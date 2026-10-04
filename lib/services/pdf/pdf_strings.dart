/// The fixed wording of exported documents, in English and Arabic (Phase 5).
///
/// PDFs are built outside the widget tree, so they cannot use
/// `AppLocalizations`; this is the document's own small string table. Names,
/// clinical free text and identifiers are printed as recorded — never
/// machine-translated. Arabic wording needs review by a fluent speaker before
/// any release (Phase 7).
library;

class PdfStrings {
  const PdfStrings._(this.isArabic);

  static const en = PdfStrings._(false);
  static const ar = PdfStrings._(true);

  static PdfStrings of({required bool arabic}) => arabic ? ar : en;

  final bool isArabic;

  String _t(String en, String ar) => isArabic ? ar : en;

  // --- chrome ---------------------------------------------------------------
  String get clinicTagline =>
      _t('Integrated clinic & patient portal', 'عيادة متكاملة وبوابة للمرضى');
  String get disclaimer => _t(
    'This document is generated from the patient record and is not a '
        'substitute for direct clinical advice.',
    'هذه الوثيقة مستخرجة من سجل المريض ولا تغني عن الاستشارة الطبية '
        'المباشرة.',
  );

  /// Printed only while the app runs on seeded demo data.
  String get demoNote => _t('Synthetic demonstration data.', 'بيانات تجريبية.');

  /// Demo placeholder — replace with the clinic's real details before
  /// release.
  String get clinicContact => _t(
    'Manama, Kingdom of Bahrain  ·  +973 1700 0000  ·  care@myhealth.demo',
    'المنامة، مملكة البحرين  ·  0000 1700 973+  ·  care@myhealth.demo',
  );
  String get patient => _t('PATIENT', 'المريض');
  String id(String v) => _t('ID $v', 'الرقم $v');
  String dob(String v) => _t('DOB $v', 'تاريخ الميلاد $v');
  String bloodType(String v) => _t('Blood type $v', 'فصيلة الدم $v');
  String get noAllergies =>
      _t('No known allergies recorded.', 'لا توجد حساسية مسجلة.');
  String get allergies => _t('ALLERGIES', 'الحساسية');
  String generated(String when) => _t('Generated $when', 'أُنشئت في $when');
  String page(int n, int of) => _t('Page $n of $of', 'صفحة $n من $of');

  // --- provenance block -----------------------------------------------------
  String get provenanceHeading => _t('About this document', 'عن هذه الوثيقة');
  String get issuedBy => _t('Issued by', 'صادرة عن');
  String get source => _t('Source', 'المصدر');
  String get documentDate => _t('Document date', 'تاريخ الوثيقة');
  String get status => _t('Status', 'الحالة');
  String get reference => _t('Reference', 'المرجع');
  String get originalFile => _t('Original file', 'الملف الأصلي');
  String get fingerprint => _t('SHA-256', 'بصمة SHA-256');

  String get sourceClinicRecord =>
      _t('MyHealth Care clinic record', 'سجل عيادة MyHealth Care');
  String get sourcePatientImport => _t(
    'Imported by the patient from an outside document',
    'استورده المريض من وثيقة خارجية',
  );
  String get sourceVitals => _t(
    'Clinic vitals record; readings marked * were entered by the patient',
    'سجل العلامات الحيوية؛ القراءات المعلّمة بـ * أدخلها المريض',
  );
  String get statusIssued => _t('Issued', 'صادرة');
  String get statusFinal => _t('Final', 'نهائي');
  String get statusRecordExtract => _t('Record extract', 'مستخرج من السجل');
  String get statusNotReviewed =>
      _t('Not reviewed by a clinician', 'لم يراجعها طبيب');
  String statusReviewed(String by) => _t('Reviewed by $by', 'راجعها $by');
  String get statusRejected => _t(
    'Reviewed — not accepted into the clinical record',
    'تمت المراجعة — لم تُعتمد في السجل السريري',
  );

  // --- report titles ----------------------------------------------------------
  String get vitalsTitle => _t('Vital signs report', 'تقرير العلامات الحيوية');
  String get certificateTitle => _t('Medical certificate', 'شهادة طبية');
  String get referralTitle => _t('Referral letter', 'خطاب إحالة');
  String get radiologyTitle => _t('Radiology report', 'تقرير الأشعة');
  String get recordTitle => _t('Health record', 'سجل صحي');

  // --- sections & labels ------------------------------------------------------
  String get summary => _t('Summary', 'الملخص');
  String get summaryNote => _t(
    'A text summary of each measurement over the period, for readers who '
        'cannot use the table.',
    'ملخص نصي لكل قياس خلال الفترة، لمن لا يستطيع استخدام الجدول.',
  );
  String get readingHistory => _t('Reading history', 'سجل القراءات');
  String get noVitals =>
      _t('No vitals have been recorded yet.', 'لم تُسجل علامات حيوية بعد.');
  String mostRecent(String when) =>
      _t('Most recent reading — $when', 'آخر قراءة — $when');
  String readingsCount(int n) => _t('$n readings', '$n قراءات');
  String metricSummary(int n, String low, String high, String latest) => _t(
    '$n readings, from $low to $high; latest $latest.',
    '$n قراءات، من $low إلى $high؛ الأخيرة $latest.',
  );
  String get bloodPressure => _t('Blood pressure', 'ضغط الدم');
  String get heartRate => _t('Heart rate', 'نبض القلب');
  String get oxygen => _t('Oxygen saturation', 'تشبع الأكسجين');
  String get temperature => _t('Temperature', 'درجة الحرارة');
  String get weight => _t('Weight', 'الوزن');
  String get height => _t('Height', 'الطول');
  String get bmi => _t('BMI', 'مؤشر كتلة الجسم');
  String get glucose => _t('Glucose', 'الجلوكوز');
  String get date => _t('Date', 'التاريخ');
  List<String> get vitalsHeaders => isArabic
      ? const [
          'التاريخ',
          'الضغط',
          'النبض',
          'الأكسجين',
          'الحرارة',
          'الوزن',
          'الجلوكوز',
        ]
      : const ['Date', 'BP', 'HR', 'SpO₂', 'Temp', 'Weight', 'Glucose'];

  String get certificate => _t('Certificate', 'الشهادة');
  String get certificateBody => _t(
    'This is to certify that the above-named patient was examined and, in my '
        'medical opinion, is unfit for work or study for the period stated '
        'below.',
    'أشهد بأن المريض المذكور أعلاه قد تم فحصه، وأنه في رأيي الطبي غير لائق '
        'للعمل أو الدراسة خلال الفترة المذكورة أدناه.',
  );
  String get reason => _t('Reason', 'السبب');
  String get from => _t('From', 'من');
  String get toInclusive => _t('To (inclusive)', 'إلى (شاملًا)');
  String get total => _t('Total', 'المجموع');
  String days(int n) => _t('$n day${n == 1 ? '' : 's'}', '$n يوم');
  String get notes => _t('Notes', 'ملاحظات');
  String get issuedByHeading => _t('Issued by', 'صادرة عن');
  String get clinician => _t('Clinician', 'الطبيب');
  String get dateIssued => _t('Date issued', 'تاريخ الإصدار');
  String get signature =>
      _t('Signature / clinic stamp', 'التوقيع / ختم العيادة');
  String issuedOn(String d) => _t('Issued $d', 'صدرت في $d');

  String get referral => _t('Referral', 'الإحالة');
  String get referralBody => _t(
    'The above-named patient is referred to the service below for further '
        'assessment and management. Relevant history is held in the patient '
        'record and can be shared on request.',
    'يُحال المريض المذكور أعلاه إلى الجهة أدناه لمزيد من التقييم والعلاج. '
        'التاريخ المرضي محفوظ في سجل المريض ويمكن مشاركته عند الطلب.',
  );
  String get referredTo => _t('Referred to', 'محال إلى');
  String get referralReason => _t('Reason for referral', 'سبب الإحالة');
  String get referredBy => _t('Referred by', 'محال من');
  String get referringClinic => _t('Referring clinic', 'الجهة المحيلة');

  String get study => _t('Study', 'الفحص');
  String get examination => _t('Examination', 'نوع الفحص');
  String get datePerformed => _t('Date performed', 'تاريخ الإجراء');
  String get facility => _t('Facility', 'المنشأة');
  String get reportingClinician => _t('Reporting clinician', 'الطبيب المقرر');
  String get findings => _t('Findings', 'النتائج');
  String get noFindings => _t(
    'No findings were recorded with this study.',
    'لم تُسجل نتائج لهذا الفحص.',
  );

  String get details => _t('Details', 'التفاصيل');
  String get recordType => _t('Record type', 'نوع السجل');
  String get results => _t('Results', 'النتائج');
  String get content => _t('Content', 'المحتوى');
  String get extractedText => _t(
    'Text extracted from the original file',
    'النص المستخرج من الملف الأصلي',
  );
  List<String> get labHeaders => isArabic
      ? const ['التحليل', 'القيمة', 'المرجع', 'التقييم']
      : const ['Analyte', 'Value', 'Reference', 'Flag'];
  String get noRange => _t('No range', 'بلا نطاق');

  // --- patient-facing interpretation (Phase 2) ------------------------------
  String age(int years) => _t('Age $years', 'العمر $years');
  String get conditions => _t('CONDITIONS', 'الحالات المزمنة');
  String get medications => _t('CURRENT MEDICATIONS', 'الأدوية الحالية');
  String get flagNormal => _t('Normal', 'طبيعي');
  String get flagLow => _t('Low', 'منخفض');
  String get flagHigh => _t('High', 'مرتفع');
  String get flagCritical => _t('Critical', 'حرج');
  String get previous => _t('Previous', 'السابقة');
  List<String> get labHeadersWithPrevious => isArabic
      ? const ['التحليل', 'القيمة', 'المرجع', 'التقييم', 'السابقة']
      : const ['Analyte', 'Value', 'Reference', 'Flag', 'Previous'];
  String get whatThisMeans => _t('What this means', 'ماذا يعني هذا');
  String abnormalNote(int n) => _t(
    '$n result${n == 1 ? ' is' : 's are'} outside the reference range '
        '(highlighted). One result on its own is not a diagnosis — please '
        'discuss it with your doctor.',
    '$n من النتائج خارج النطاق المرجعي (مظللة). النتيجة الواحدة وحدها ليست '
        'تشخيصًا — يرجى مناقشتها مع طبيبك.',
  );
  String get criticalNote => _t(
    'A result is marked critical. If you have not already been contacted, '
        'contact the clinic today.',
    'إحدى النتائج حرجة. إن لم يتواصل معك أحد بعد، تواصل مع العيادة اليوم.',
  );
  String get allNormalNote => _t(
    'All results with a reference range are within it.',
    'جميع النتائج ذات النطاق المرجعي ضمن الحدود.',
  );
  String get typicalRange =>
      _t('Typical adult range', 'النطاق المعتاد للبالغين');
  String get vitalsRangeNote => _t(
    'Ranges are typical for adults at rest and are a guide only. Values '
        'outside them are highlighted; your doctor may set different targets '
        'for you.',
    'النطاقات معتادة للبالغين في حالة الراحة وهي للإرشاد فقط. القيم خارجها '
        'مظللة، وقد يحدد طبيبك أهدافًا مختلفة لك.',
  );
  String truncated(int shown, int total) => _t(
    'Showing the first $shown of $total characters. The full text is in the '
        'original file.',
    'يُعرض أول $shown من أصل $total حرفًا. النص الكامل في الملف الأصلي.',
  );
  String get licenceNo => _t('Licence no.', 'رقم الترخيص');
  String get nextAppointment => _t('Next appointment', 'الموعد القادم');
  String get followUp => _t('Follow-up', 'المتابعة');
  String get noFollowUp => _t(
    'No upcoming appointment is booked. Book one in the app if your doctor '
        'asked you to return.',
    'لا يوجد موعد قادم. احجز موعدًا من التطبيق إذا طلب طبيبك المراجعة.',
  );

  // --- visit summary --------------------------------------------------------
  String get visitTitle => _t('Visit summary', 'ملخص الزيارة');
  String get visit => _t('Visit', 'الزيارة');
  String get department => _t('Department', 'القسم');
  String get vitalsAtVisit =>
      _t('Vital signs at this visit', 'العلامات الحيوية في الزيارة');
  String get visitRecords => _t('Notes and results', 'الملاحظات والنتائج');
  String get visitMedications =>
      _t('Medications from this visit', 'أدوية هذه الزيارة');
  String get nothingRecorded =>
      _t('Nothing was recorded for this visit.', 'لم يُسجل شيء لهذه الزيارة.');

  // --- referral urgency & verification --------------------------------------
  String get urgency => _t('Urgency', 'درجة الاستعجال');
  String get urgencyRoutine => _t('Routine', 'روتيني');
  String get urgencyUrgent =>
      _t('Urgent — please see soon', 'عاجل — يرجى الفحص قريبًا');
  String get urgencyEmergency =>
      _t('Emergency — see immediately', 'طارئ — يرجى الفحص فورًا');
  String get verificationHeading =>
      _t('Verify this document', 'التحقق من الوثيقة');
  String get verificationCode => _t('Verification code', 'رمز التحقق');
  String get verificationHelp => _t(
    'Clinic staff can confirm this document is genuine by entering the code '
        '(or scanning the QR) in MyHealth Care → Verify document.',
    'يمكن لموظفي العيادة التأكد من صحة هذه الوثيقة بإدخال الرمز (أو مسح رمز '
        'QR) في MyHealth Care ← التحقق من وثيقة.',
  );
}
