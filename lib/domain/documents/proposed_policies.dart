import '../repositories/document_policy_repository.dart';
import '../repositories/document_service.dart';
import '../repositories/export_repository.dart';
import 'document_rules.dart';

/// Proposed product defaults, not clinic-approved or legally certified text.
/// Approval is an explicit, audited administrator operation per version.
abstract final class ProposedDocumentPolicies {
  static List<DocumentPolicyDraft> all() => [
    ...sickLeave(),
    for (final type in DocumentRules.supported.where(
      (t) => t != ExportDocument.sickLeaveCertificate,
    ))
      for (final language in ['en', 'ar'])
        for (final audience
            in (DocumentRules.externalAllowed(type)
                ? DisclosureProfile.values
                : [DisclosureProfile.clinic]))
          DocumentPolicyDraft(
            id: '${type.name}-v1-$language-${audience.name}',
            document: type,
            version: 1,
            language: language,
            disclosure: audience,
            clinicalSignatureRequired: DocumentRules.clinical(type),
            wording:
                '${DocumentRules.title(type, arabic: language == 'ar')}\n'
                '${language == 'ar' ? 'العيادة' : 'Clinic'}: {clinicName}\n'
                '${language == 'ar' ? 'المريض' : 'Patient'}: {patientName}\n'
                '${language == 'ar' ? 'تاريخ الزيارة' : 'Visit date'}: {visitDate}\n'
                '${DocumentRules.requiredFields(type).contains('sourceText') ? '{sourceText}\n' : ''}'
                '${type == ExportDocument.fitnessCertificate ? (language == 'ar' ? 'النشاط: {activity}\nالتقييم: {assessment}\nالقيود: {restrictions}\n' : 'Activity: {activity}\nAssessment: {assessment}\nRestrictions: {restrictions}\n') : ''}'
                '${language == 'ar' ? 'المصدر' : 'Issuer'}: {issuerName}\n'
                '${DocumentRules.clinical(type) ? (language == 'ar' ? 'الترخيص: {license}\n' : 'Licence: {license}\n') : ''}'
                '${language == 'ar' ? 'التحقق' : 'Verification'}: {verificationCode}',
          ),
  ];
  static List<DocumentPolicyDraft> sickLeave() => [
    for (final language in ['en', 'ar'])
      for (final disclosure in DisclosureProfile.values)
        DocumentPolicyDraft(
          id: 'sick-leave-v1-$language-${disclosure.name}',
          document: ExportDocument.sickLeaveCertificate,
          version: 1,
          language: language,
          disclosure: disclosure,
          clinicalSignatureRequired: true,
          wording: language == 'ar'
              ? 'تشهد {clinicName} بأن {patientName} راجع العيادة بتاريخ {visitDate}، '
                    'ويوصى بإجازة من {leaveStart} إلى {leaveEnd}. '
                    'الطبيب: {issuerName}. رقم الترخيص: {license}. '
                    'رمز التحقق: {verificationCode}.'
                    '${disclosure == DisclosureProfile.clinic ? ' السبب السريري: {diagnosis}.' : ''}'
              : '{clinicName} confirms that {patientName} attended on {visitDate}. '
                    'Leave is recommended from {leaveStart} through {leaveEnd}. '
                    'Clinician: {issuerName}. Licence: {license}. '
                    'Verification: {verificationCode}.'
                    '${disclosure == DisclosureProfile.clinic ? ' Clinical reason: {diagnosis}.' : ''}',
        ),
  ];
}
