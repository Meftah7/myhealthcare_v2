import '../../core/failures.dart';
import '../repositories/document_service.dart';
import '../repositories/export_repository.dart';

abstract final class DocumentRules {
  static const supported = {
    ExportDocument.sickLeaveCertificate,
    ExportDocument.attendanceCertificate,
    ExportDocument.visitSummary,
    ExportDocument.referralLetter,
    ExportDocument.prescriptionCopy,
    ExportDocument.releasedLabReport,
    ExportDocument.releasedImagingReport,
    ExportDocument.fitnessCertificate,
    ExportDocument.financeStatement,
  };
  static bool clinical(ExportDocument type) =>
      type != ExportDocument.attendanceCertificate &&
      type != ExportDocument.financeStatement;
  static bool externalAllowed(ExportDocument type) => {
    ExportDocument.sickLeaveCertificate,
    ExportDocument.attendanceCertificate,
    ExportDocument.fitnessCertificate,
  }.contains(type);
  static bool sourced(ExportDocument type) => {
    ExportDocument.referralLetter,
    ExportDocument.prescriptionCopy,
    ExportDocument.releasedLabReport,
    ExportDocument.releasedImagingReport,
    ExportDocument.financeStatement,
  }.contains(type);
  static String title(ExportDocument type, {bool arabic = false}) =>
      switch (type) {
        ExportDocument.sickLeaveCertificate =>
          arabic ? 'إجازة مرضية' : 'Sick leave',
        ExportDocument.attendanceCertificate =>
          arabic ? 'شهادة حضور' : 'Attendance',
        ExportDocument.visitSummary =>
          arabic ? 'ملخص الزيارة' : 'Visit summary',
        ExportDocument.referralLetter => arabic ? 'خطاب إحالة' : 'Referral',
        ExportDocument.prescriptionCopy =>
          arabic ? 'نسخة الوصفة' : 'Prescription copy',
        ExportDocument.releasedLabReport =>
          arabic ? 'نتيجة مختبر معتمدة للنشر' : 'Released lab report',
        ExportDocument.releasedImagingReport =>
          arabic ? 'تقرير أشعة معتمد للنشر' : 'Released imaging report',
        ExportDocument.fitnessCertificate => arabic ? 'شهادة لياقة' : 'Fitness',
        ExportDocument.financeStatement =>
          arabic ? 'كشف مالي' : 'Finance statement',
        _ => type.name,
      };
  static Set<String> requiredFields(ExportDocument type) => {
    'clinicName',
    'patientName',
    'visitDate',
    'issuerName',
    'verificationCode',
    if (clinical(type)) 'license',
    if (type == ExportDocument.sickLeaveCertificate) ...{
      'leaveStart',
      'leaveEnd',
    },
    if (type == ExportDocument.fitnessCertificate) ...{
      'activity',
      'assessment',
      'restrictions',
    },
    if (sourced(type) || type == ExportDocument.visitSummary) 'sourceText',
  };
  static void validatePolicy(
    ExportDocument type,
    DisclosureProfile audience,
    bool signing,
    String wording,
  ) {
    if (!supported.contains(type) ||
        clinical(type) != signing ||
        (!externalAllowed(type) && audience != DisclosureProfile.clinic)) {
      throw const ValidationFailure(
        'This document requires its defined signing rule and disclosure audience.',
      );
    }
    final required = requiredFields(type);
    final allowed = {
      ...required,
      if (type == ExportDocument.sickLeaveCertificate &&
          audience == DisclosureProfile.clinic)
        'diagnosis',
    };
    final fields = RegExp(
      r'\{([^{}]+)\}',
    ).allMatches(wording).map((m) => m[1]!).toSet();
    if (!fields.containsAll(required) || !allowed.containsAll(fields)) {
      throw const ValidationFailure(
        'Keep the required fields and exclude unsupported clinical disclosures.',
      );
    }
  }
}
