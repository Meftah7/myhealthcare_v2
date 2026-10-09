import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/confirm_dialog.dart';
import '../../../core/presentation/states.dart';
import '../../../core/result.dart';
import '../../../domain/documents/document_rules.dart';
import '../../../domain/repositories/document_service.dart';
import '../../../domain/repositories/export_repository.dart';
import '../../auth/application/session.dart';
import '../../auth/presentation/reauth_prompt.dart';
import '../../patient/presentation/document_download_button.dart';

T _value<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

final documentWorkspaceProvider = FutureProvider.autoDispose
    .family<DocumentWorkspace, String>((ref, id) async {
      ref.watch(currentUserProvider);
      return _value(await ref.watch(documentServiceProvider).workspace(id));
    });

class DocumentWorkspaceScreen extends ConsumerStatefulWidget {
  const DocumentWorkspaceScreen({
    required this.patientId,
    this.appointmentId,
    super.key,
  });
  final String patientId;
  final String? appointmentId;
  @override
  ConsumerState<DocumentWorkspaceScreen> createState() =>
      _DocumentWorkspaceScreenState();
}

class _DocumentWorkspaceScreenState
    extends ConsumerState<DocumentWorkspaceScreen> {
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _diagnosis = TextEditingController();
  final _reason = TextEditingController();
  final _releaseReason = TextEditingController();
  String? _visit, _template, _source;
  final _activity = TextEditingController();
  final _assessment = TextEditingController();
  final _restrictions = TextEditingController();
  String _prepareKey = const Uuid().v4();
  bool _busy = false;
  bool _initialVisitResolved = false;
  String? _error;
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String s(String en, String ar) => _ar ? ar : en;
  DocumentService get service => ref.read(documentServiceProvider);

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _diagnosis.dispose();
    _reason.dispose();
    _releaseReason.dispose();
    _activity.dispose();
    _assessment.dispose();
    _restrictions.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Result<Object?>> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await runWithReauth(context, ref, action);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.failureOrNull?.message;
    });
    if (result.isOk) {
      ref.invalidate(documentWorkspaceProvider(widget.patientId));
    }
  }

  DocumentTemplateChoice? _selected(DocumentWorkspace w) {
    final matches = w.templates.where((t) => t.id == _template);
    return matches.isEmpty ? null : matches.first;
  }

  Map<String, Object?> _fields(
    DocumentWorkspace w, {
    DocumentTemplateChoice? template,
  }) {
    final t = template ?? _selected(w);
    if (t == null) return {};
    final type = t.documentType;
    if (DocumentRules.sourced(type)) return {'sourceId': _source ?? ''};
    if (type == ExportDocument.fitnessCertificate) {
      return {
        'activity': _activity.text.trim(),
        'assessment': _assessment.text.trim(),
        'restrictions': _restrictions.text.trim(),
      };
    }
    if (type != ExportDocument.sickLeaveCertificate) return {};
    return {
      'leaveStart': _start.text.trim(),
      'leaveEnd': _end.text.trim(),
      if (t.disclosure == DisclosureProfile.clinic &&
          _diagnosis.text.trim().isNotEmpty)
        'diagnosis': _diagnosis.text.trim(),
    };
  }

  String _status(DocumentRequestStatus status) => switch (status) {
    DocumentRequestStatus.draft => s('Draft', 'مسودة'),
    DocumentRequestStatus.submitted => s(
      'Awaiting doctor review',
      'بانتظار مراجعة الطبيب',
    ),
    DocumentRequestStatus.approved => s(
      'Approved — ready to issue',
      'معتمد — جاهز للإصدار',
    ),
    DocumentRequestStatus.rejected => s('Rejected', 'مرفوض'),
    DocumentRequestStatus.issued => s('Issued', 'تم الإصدار'),
  };

  String _audience(DisclosureProfile p) => switch (p) {
    DisclosureProfile.clinic => s('Clinic copy', 'نسخة العيادة'),
    DisclosureProfile.employer => s('Employer copy', 'نسخة جهة العمل'),
    DisclosureProfile.school => s('School copy', 'نسخة المدرسة'),
  };

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(documentWorkspaceProvider(widget.patientId));
    final loaded = workspace.valueOrNull;
    if (!_initialVisitResolved && loaded != null) {
      _initialVisitResolved = true;
      if (loaded.visits.any((v) => v.id == widget.appointmentId)) {
        _visit = widget.appointmentId;
      }
    }
    return AppScaffold(
      title: s('Documents', 'الوثائق'),
      centerBody: false,
      body: workspace.when(
        loading: () => const SkeletonList(),
        error: (error, _) => ErrorStateView(
          message: s(
            'Could not open documents. Check your patient-scoped preparation or reprint grant.',
            'تعذر فتح الوثائق. تحقق من صلاحية إعداد الوثائق أو إعادة طباعتها للمريض.',
          ),
          onRetry: () =>
              ref.invalidate(documentWorkspaceProvider(widget.patientId)),
        ),
        data: (w) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.all(Space.md),
              children: [
                Text(
                  w.patientName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: Space.md),
                Text(
                  s('Prepare a request', 'إعداد طلب'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  s(
                    'Clinical documents require a qualified doctor. Attendance and finance require administrative issuance grants. Draft policies cannot be issued.',
                    'تتطلب الوثائق الطبية طبيباً مؤهلاً. يتطلب الحضور والكشف المالي صلاحية إصدار إداري. لا يمكن إصدار سياسة غير معتمدة.',
                  ),
                ),
                const SizedBox(height: Space.md),
                DropdownButtonFormField<String>(
                  key: const ValueKey('documentVisit'),
                  initialValue: _visit,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: s('Visit', 'الزيارة')),
                  items: [
                    for (final v in w.visits)
                      DropdownMenuItem(
                        value: v.id,
                        child: Text(
                          v.date.toLocal().toString().substring(0, 16),
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                          _visit = v;
                          _source = null;
                          _prepareKey = const Uuid().v4();
                        }),
                ),
                const SizedBox(height: Space.md),
                DropdownButtonFormField<String>(
                  key: const ValueKey('documentTemplate'),
                  initialValue: _template,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: s('Language and audience', 'اللغة والجهة'),
                  ),
                  items: [
                    for (final t in w.templates)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(
                          '${DocumentRules.title(t.documentType, arabic: _ar)} · ${t.language == 'ar' ? 'العربية' : 'English'} · ${_audience(t.disclosure)} · ${t.approved ? s('Approved', 'معتمد') : s('Draft policy', 'سياسة مسودة')}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                          _template = v;
                          _source = null;
                          _prepareKey = const Uuid().v4();
                        }),
                ),
                const SizedBox(height: Space.md),
                if (DocumentRules.sourced(
                  _selected(w)?.documentType ??
                      ExportDocument.sickLeaveCertificate,
                )) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey('source-$_template-$_visit'),
                    initialValue: _source,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: s(
                        'Source record or invoice',
                        'السجل أو الفاتورة المصدر',
                      ),
                    ),
                    items: [
                      for (final source in w.sources)
                        if (source.visitId == _visit &&
                            source.documentType == _selected(w)?.documentType)
                          DropdownMenuItem(
                            value: source.id,
                            child: Text(
                              source.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                    ],
                    onChanged: _busy
                        ? null
                        : (id) => setState(() {
                            _source = id;
                            _prepareKey = const Uuid().v4();
                          }),
                  ),
                  if ({
                    ExportDocument.releasedLabReport,
                    ExportDocument.releasedImagingReport,
                  }.contains(_selected(w)?.documentType)) ...[
                    TextField(
                      controller: _releaseReason,
                      decoration: InputDecoration(
                        labelText: s(
                          'Release or withholding reason',
                          'سبب النشر أو الحجب',
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: Space.sm,
                      children: [
                        OutlinedButton(
                          onPressed: _busy || _source == null
                              ? null
                              : () => _run(
                                  () => service.releaseSource(
                                    _source!,
                                    released: true,
                                    reason: _releaseReason.text.trim(),
                                  ),
                                ),
                          child: Text(
                            s(
                              'Doctor: release this exact result',
                              'الطبيب: اعتماد هذه النتيجة للنشر',
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _busy || _source == null
                              ? null
                              : () => _run(
                                  () => service.releaseSource(
                                    _source!,
                                    released: false,
                                    reason: _releaseReason.text.trim(),
                                  ),
                                ),
                          child: Text(
                            s(
                              'Withhold and revoke issued copies',
                              'حجب وإلغاء النسخ الصادرة',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: Space.md),
                ],
                if (_selected(w)?.documentType ==
                    ExportDocument.fitnessCertificate) ...[
                  TextField(
                    controller: _activity,
                    onChanged: (_) => _prepareKey = const Uuid().v4(),
                    enabled: !_busy,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      labelText: s(
                        'Activity assessed',
                        'النشاط الذي تم تقييمه',
                      ),
                    ),
                  ),
                  TextField(
                    controller: _assessment,
                    onChanged: (_) => _prepareKey = const Uuid().v4(),
                    enabled: !_busy,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      labelText: s('Doctor assessment', 'تقييم الطبيب'),
                    ),
                  ),
                  TextField(
                    controller: _restrictions,
                    onChanged: (_) => _prepareKey = const Uuid().v4(),
                    enabled: !_busy,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      labelText: s(
                        'Restrictions (write None if none)',
                        'القيود (اكتب لا توجد عند عدم وجودها)',
                      ),
                    ),
                  ),
                ],
                if ((_selected(w)?.documentType ??
                        ExportDocument.sickLeaveCertificate) ==
                    ExportDocument.sickLeaveCertificate) ...[
                  const SizedBox(height: Space.sm),
                  TextField(
                    key: const ValueKey('leaveStart'),
                    controller: _start,
                    enabled: !_busy,
                    keyboardType: TextInputType.datetime,
                    onChanged: (_) => _prepareKey = const Uuid().v4(),
                    decoration: InputDecoration(
                      labelText: s(
                        'Leave starts (YYYY-MM-DD)',
                        'بداية الإجازة (YYYY-MM-DD)',
                      ),
                      hintText: '2026-10-08',
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  TextField(
                    key: const ValueKey('leaveEnd'),
                    controller: _end,
                    enabled: !_busy,
                    keyboardType: TextInputType.datetime,
                    onChanged: (_) => _prepareKey = const Uuid().v4(),
                    decoration: InputDecoration(
                      labelText: s(
                        'Leave ends (YYYY-MM-DD)',
                        'نهاية الإجازة (YYYY-MM-DD)',
                      ),
                      hintText: '2026-10-10',
                    ),
                  ),
                ],
                if (w.templates.any(
                  (t) =>
                      t.id == _template &&
                      t.documentType == ExportDocument.sickLeaveCertificate &&
                      t.disclosure == DisclosureProfile.clinic,
                )) ...[
                  const SizedBox(height: Space.md),
                  TextField(
                    controller: _diagnosis,
                    enabled: !_busy,
                    maxLength: 300,
                    minLines: 2,
                    maxLines: 4,
                    onChanged: (_) => _prepareKey = const Uuid().v4(),
                    decoration: InputDecoration(
                      labelText: s(
                        'Diagnosis (clinic copy only)',
                        'التشخيص (نسخة العيادة فقط)',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: Space.md),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.md),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _busy || _visit == null || _template == null
                      ? null
                      : () => _run(() async {
                          final result = await service.prepare(
                            PrepareDocument(
                              patientId: widget.patientId,
                              appointmentId: _visit!,
                              templateId: _template!,
                              idempotencyKey: _prepareKey,
                              documentType: _selected(w)!.documentType,
                              content: _fields(w),
                            ),
                          );
                          // Keep form values and retry key after errors. Clear only after a
                          // successful preparation, so the same action cannot duplicate it.
                          if (result.isOk && mounted) {
                            _start.clear();
                            _end.clear();
                            _diagnosis.clear();
                            _prepareKey = const Uuid().v4();
                          }
                          return result;
                        }),
                  icon: const Icon(Icons.note_add_outlined),
                  label: Text(s('Save draft', 'حفظ المسودة')),
                ),
                if (_busy) const LinearProgressIndicator(),
                const SizedBox(height: Space.xl),
                Text(
                  s('Requests and review', 'الطلبات والمراجعة'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (w.requests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.md),
                    child: Text(
                      s(
                        'No requests for this patient.',
                        'لا توجد طلبات لهذا المريض.',
                      ),
                    ),
                  ),
                for (final item in w.requests) ...[
                  const Divider(height: 32),
                  Text(
                    _status(item.request.status),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    item.content.containsKey('leaveStart')
                        ? '${item.content['leaveStart'].toString().split('T').first} – ${item.content['leaveEnd'].toString().split('T').first}'
                        : '${s('Visit', 'الزيارة')}: ${item.visitId}',
                  ),
                  Text(
                    w.templates
                        .where((t) => t.id == item.request.templateId)
                        .map(
                          (t) =>
                              '${DocumentRules.title(t.documentType, arabic: _ar)} · ${t.language} · ${_audience(t.disclosure)}',
                        )
                        .join(),
                  ),
                  const SizedBox(height: Space.sm),
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [
                      if (item.request.status != DocumentRequestStatus.issued)
                        DocumentDownloadButton(
                          build: () async =>
                              _value(await service.preview(item.request.id)),
                          filename: 'draft-document.pdf',
                          label: s('Preview draft', 'معاينة المسودة'),
                        ),
                      if (item.request.status == DocumentRequestStatus.draft)
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => service.submit(
                                    item.request.id,
                                    expectedVersion: item.request.version,
                                  ),
                                ),
                          child: Text(s('Submit for review', 'إرسال للمراجعة')),
                        ),
                      if (item.request.status ==
                          DocumentRequestStatus.submitted)
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => service.approve(
                                    item.request.id,
                                    expectedVersion: item.request.version,
                                  ),
                                ),
                          child: Text(
                            s(
                              'Approve with required authority',
                              'اعتماد بالصلاحية المطلوبة',
                            ),
                          ),
                        ),
                      if (item.request.status == DocumentRequestStatus.approved)
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  () => service.issue(
                                    item.request.id,
                                    expectedVersion: item.request.version,
                                    idempotencyKey:
                                        'issue:${item.request.id}:${item.request.version}',
                                  ),
                                ),
                          child: Text(s('Issue once', 'إصدار مرة واحدة')),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: Space.xl),
                Text(
                  s('Issued copies', 'النسخ الصادرة'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: Space.md),
                TextField(
                  controller: _reason,
                  enabled: !_busy,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: s(
                      'Reason for correction or revocation',
                      'سبب التصحيح أو الإلغاء',
                    ),
                  ),
                ),
                for (final document in w.issued) ...[
                  const Divider(height: 32),
                  Text(DocumentRules.title(document.documentType, arabic: _ar)),
                  SelectableText(
                    document.verificationCode,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (document.supersedesId != null)
                    Text(
                      s(
                        'Replaces an earlier issued version.',
                        'تحل محل نسخة صادرة سابقة.',
                      ),
                    ),
                  Text(
                    document.validity == DocumentValidity.valid
                        ? (document.renderStatus == DocumentRenderStatus.ready
                              ? s('Official copy ready', 'النسخة الرسمية جاهزة')
                              : document.renderStatus ==
                                    DocumentRenderStatus.failed
                              ? s(
                                  'Issued; PDF failed. Retry below.',
                                  'تم الإصدار؛ تعذر إنشاء PDF. أعد المحاولة أدناه.',
                                )
                              : s(
                                  'Issued; PDF pending',
                                  'تم الإصدار؛ ملف PDF قيد الانتظار',
                                ))
                        : s('No longer valid', 'لم تعد صالحة'),
                  ),
                  const SizedBox(height: Space.sm),
                  if (document.validity == DocumentValidity.valid)
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      children: [
                        if (document.renderStatus != DocumentRenderStatus.ready)
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _run(() => service.render(document.id)),
                            child: Text(
                              s(
                                'Generate / retry PDF',
                                'إنشاء / إعادة محاولة PDF',
                              ),
                            ),
                          ),
                        if (document.renderStatus == DocumentRenderStatus.ready)
                          DocumentDownloadButton(
                            build: () async =>
                                _value(await service.download(document.id)),
                            filename:
                                'document-${document.verificationCode}.pdf',
                            label: s('Open issued copy', 'فتح النسخة الصادرة'),
                          ),
                        if (document.renderStatus ==
                                DocumentRenderStatus.ready &&
                            document.deliveryStatus != 'sent')
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () =>
                                      _run(() => service.deliver(document.id)),
                            child: Text(
                              s(
                                'Retry notification delivery',
                                'إعادة محاولة إرسال الإشعار',
                              ),
                            ),
                          ),
                        if (w.requests.any(
                          (r) =>
                              r.request.id == document.requestId &&
                              r.request.status == DocumentRequestStatus.issued,
                        ))
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _run(
                                    () => service.prepareReplacement(
                                      document.id,
                                      templateId: _template,
                                      expectedVersion: w.requests
                                          .firstWhere(
                                            (r) =>
                                                r.request.id ==
                                                document.requestId,
                                          )
                                          .request
                                          .version,
                                      content: _fields(w),
                                      reason: _reason.text.trim(),
                                    ),
                                  ),
                            child: Text(
                              s(
                                'Prepare correction using entered dates',
                                'إعداد تصحيح بالتواريخ المدخلة',
                              ),
                            ),
                          ),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  final yes = await confirm(
                                    context,
                                    title: s(
                                      'Revoke this certificate?',
                                      'إلغاء هذه الشهادة؟',
                                    ),
                                    message: s(
                                      'The issued copy will stop being valid. Its original PDF and history are retained.',
                                      'ستفقد النسخة الصادرة صلاحيتها. سيُحتفظ بملفها الأصلي وسجلها.',
                                    ),
                                    destructive: true,
                                  );
                                  if (yes && mounted) {
                                    await _run(
                                      () => service.revoke(
                                        document.id,
                                        reason: _reason.text.trim(),
                                      ),
                                    );
                                  }
                                },
                          child: Text(s('Revoke certificate', 'إلغاء الشهادة')),
                        ),
                      ],
                    ),
                ],
                const SizedBox(height: Space.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
