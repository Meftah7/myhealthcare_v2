import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../app/router.dart';
import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../core/utils/format.dart';
import '../../../domain/documents/document_rules.dart';
import '../../../domain/repositories/document_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session.dart';
import '../../patient/presentation/document_download_button.dart';

final issuedDocumentsProvider = StreamProvider.autoDispose
    .family<List<IssuedDocument>, String>((ref, id) {
      ref.watch(currentUserProvider);
      return ref.watch(documentServiceProvider).watchForPatient(id);
    });

/// Documents the care team issued (sick leave, certificates, summaries):
/// view the official PDF in the app, or download the same authorized bytes.
class IssuedDocumentsScreen extends ConsumerWidget {
  const IssuedDocumentsScreen({this.patientId, super.key});
  final String? patientId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final subject = patientId ?? ref.watch(currentUserProvider)?.id ?? '';
    final documents = ref.watch(issuedDocumentsProvider(subject));
    return AppScaffold(
      title: t.paIssuedDocumentsTitle,
      onRefresh: () async => ref.invalidate(issuedDocumentsProvider(subject)),
      children: documents.when(
        loading: () => const [SkeletonList()],
        error: (e, _) => [
          PatientStateView(
            kind: PatientStateKind.error,
            title: t.paDocumentsLoadError,
            actionLabel: t.tryAgain,
            onAction: () => ref.invalidate(issuedDocumentsProvider(subject)),
          ),
        ],
        data: (items) => [
          Text(
            t.paIssuedDocumentsIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PatientPalette.of(context).textMuted,
            ),
          ),
          const SizedBox(height: Space.md),
          if (items.isEmpty)
            PatientStateView(
              kind: PatientStateKind.empty,
              icon: Icons.description_outlined,
              title: t.paNoIssuedDocuments,
              message: t.paNoIssuedDocumentsBody,
              actionLabel: t.paHealthRecords,
              onAction: () => context.go(AppRoutes.patientTimeline),
            )
          else
            for (final d in items) ...[
              _IssuedDocumentCard(document: d),
              const SizedBox(height: Space.sm),
            ],
        ],
      ),
    );
  }
}

class _IssuedDocumentCard extends ConsumerWidget {
  const _IssuedDocumentCard({required this.document});
  final IssuedDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = PatientPalette.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final d = document;
    final ready =
        d.validity == DocumentValidity.valid &&
        d.renderStatus == DocumentRenderStatus.ready;
    final (
      String status,
      PatientAccent accent,
      IconData icon,
    ) = d.validity != DocumentValidity.valid
        ? (t.paDocRevoked, PatientAccent.red, Icons.block)
        : ready
        ? (t.paDocReady, PatientAccent.green, Icons.check_circle_outline)
        : (t.paDocNotReady, PatientAccent.amber, Icons.hourglass_empty);
    final filename = '${d.documentType.name}-${d.verificationCode}.pdf';
    Future<Uint8List> bytes() async =>
        switch (await ref.read(documentServiceProvider).download(d.id)) {
          Ok(:final value) => value,
          Err(:final failure) => throw failure,
        };
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(icon: Icons.verified_outlined),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DocumentRules.title(d.documentType, arabic: ar),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (d.issuedAt != null) fmtDate(d.issuedAt!.toLocal()),
                        d.language.toUpperCase(),
                        if (d.supersedesId != null) t.paDocReplacement,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(status, accent: accent, icon: icon),
              Text(
                t.paVerificationCode,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                ),
              ),
              SelectableText(
                d.verificationCode,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: AppFonts.mono,
                  color: palette.text,
                ),
              ),
            ],
          ),
          if (!ready && d.validity == DocumentValidity.valid) ...[
            const SizedBox(height: Space.xs),
            Text(t.paDocNotReadyBody, style: theme.textTheme.bodySmall),
          ],
          if (ready) ...[
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                DocumentDownloadButton(
                  filename: filename,
                  label: t.paViewDocument,
                  icon: Icons.visibility_outlined,
                  build: bytes,
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await Printing.sharePdf(
                        bytes: await bytes(),
                        filename: filename,
                      );
                    } on Object {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.paDocumentsLoadError)),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_outlined),
                  label: Text(t.paDownloadOriginal),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
