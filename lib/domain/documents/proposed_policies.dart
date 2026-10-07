import '../repositories/document_policy_repository.dart';
import '../repositories/document_service.dart';
import '../repositories/export_repository.dart';

/// Proposed product defaults, not clinic-approved or legally certified text.
/// Approval is an explicit, audited administrator operation per version.
abstract final class ProposedDocumentPolicies {
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
