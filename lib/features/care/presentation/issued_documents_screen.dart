import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../domain/documents/document_rules.dart';
import '../../../domain/repositories/document_service.dart';
import '../../auth/application/session.dart';
import '../../patient/presentation/document_download_button.dart';

final issuedDocumentsProvider = StreamProvider.autoDispose
    .family<List<IssuedDocument>, String>((ref, id) {
      ref.watch(currentUserProvider);
      return ref.watch(documentServiceProvider).watchForPatient(id);
    });

class IssuedDocumentsScreen extends ConsumerWidget {
  const IssuedDocumentsScreen({this.patientId, super.key});
  final String? patientId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final subject = patientId ?? ref.watch(currentUserProvider)?.id ?? '';
    final documents = ref.watch(issuedDocumentsProvider(subject));
    return AppScaffold(
      title: ar ? 'الوثائق الصادرة' : 'Issued documents',
      centerBody: false,
      body: documents.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: ar ? 'تعذر تحميل الوثائق.' : 'Could not load documents.',
          onRetry: () => ref.invalidate(issuedDocumentsProvider(subject)),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.description_outlined,
                message: ar
                    ? 'لا توجد نسخ صادرة بعد.'
                    : 'No issued copies yet.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final d = items[index];
                  final ready =
                      d.validity == DocumentValidity.valid &&
                      d.renderStatus == DocumentRenderStatus.ready;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DocumentRules.title(d.documentType, arabic: ar),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SelectableText(d.verificationCode),
                      Text(
                        '${d.language} · ${d.issuedAt?.toLocal().toString().split('.').first ?? ''}',
                      ),
                      if (d.supersedesId != null)
                        Text(ar ? 'نسخة بديلة.' : 'Replacement version.'),
                      Text(
                        d.validity != DocumentValidity.valid
                            ? (ar
                                  ? 'ملغاة أو مستبدلة'
                                  : 'Revoked or superseded')
                            : ready
                            ? (ar
                                  ? 'النسخة الرسمية جاهزة'
                                  : 'Official copy ready')
                            : (ar
                                  ? 'ملف PDF غير جاهز؛ تواصل مع العيادة.'
                                  : 'PDF is not ready; contact the clinic.'),
                      ),
                      if (ready)
                        DocumentDownloadButton(
                          filename:
                              '${d.documentType.name}-${d.verificationCode}.pdf',
                          label: ar ? 'فتح النسخة الصادرة' : 'Open issued copy',
                          build: () async => switch (await ref
                              .read(documentServiceProvider)
                              .download(d.id)) {
                            Ok(:final value) => value,
                            Err(:final failure) => throw failure,
                          },
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
