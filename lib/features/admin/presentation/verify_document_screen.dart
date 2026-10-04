/// Staff/admin check of a printed certificate or referral letter: enter the
/// verification code and see what the genuine document states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/result.dart';
import '../../../core/utils/format.dart';
import '../../../domain/repositories/document_verification_repository.dart';
import '../../../domain/repositories/export_repository.dart';
import '../../../l10n/app_localizations.dart';
import 'qr_scan_screen.dart';

/// Opens the verify screen as a full-screen page.
Future<void> openVerifyDocument(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const VerifyDocumentScreen()));

class VerifyDocumentScreen extends ConsumerStatefulWidget {
  const VerifyDocumentScreen({super.key});

  @override
  ConsumerState<VerifyDocumentScreen> createState() =>
      _VerifyDocumentScreenState();
}

class _VerifyDocumentScreenState extends ConsumerState<VerifyDocumentScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  /// null = not checked yet; `(found: false)` = no such code.
  ({bool found, DocumentVerification? doc, String? error})? _result;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// Scan the document's QR, then check it straight away.
  Future<void> _scan() async {
    final value = await scanQrCode(context);
    if (value == null || !mounted) return;
    _code.text = value.replaceFirst('MHC-VERIFY:', '');
    await _verify();
  }

  Future<void> _verify() async {
    final input = _code.text.trim().replaceFirst('MHC-VERIFY:', '');
    if (input.isEmpty) return;
    setState(() => _busy = true);
    final r = await ref
        .read(documentVerificationRepositoryProvider)
        .verify(input);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = switch (r) {
        Ok(:final value) => (found: value != null, doc: value, error: null),
        Err(:final failure) => (
          found: false,
          doc: null,
          error: failure.message,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(t.verifyDocumentTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          Text(t.verifyDocumentHint, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Space.md),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: t.verifyCodeLabel,
              hintText: 'ABCDE-FGHJK',
              suffixIcon: qrScanSupported
                  ? IconButton(
                      tooltip: t.scanQrTitle,
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _busy ? null : _scan,
                    )
                  : null,
            ),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: Space.sm),
          FilledButton.icon(
            onPressed: _busy ? null : _verify,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_outlined),
            label: Text(t.verifyAction),
          ),
          const SizedBox(height: Space.lg),
          if (result != null)
            if (result.doc case final doc?)
              _GenuineCard(doc: doc)
            else
              AppCard(
                color: theme.colorScheme.errorContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.gpp_bad_outlined,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        result.error ?? t.verifyNotFound,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _GenuineCard extends StatelessWidget {
  const _GenuineCard({required this.doc});

  final DocumentVerification doc;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: theme.colorScheme.primary),
              const SizedBox(width: Space.sm),
              Text(t.verifyGenuine, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(t.verifyGenuineBody, style: theme.textTheme.bodySmall),
          const SizedBox(height: Space.md),
          row(t.verifyCodeLabel, doc.code),
          row(t.verifyDocumentType, switch (doc.documentType) {
            ExportDocument.sickLeaveCertificate => t.verifyTypeCertificate,
            ExportDocument.referralLetter => t.verifyTypeReferral,
            _ => doc.documentType.name,
          }),
          row(t.verifyPatient, doc.patientName),
          row(t.verifyIssuedBy, doc.issuer),
          row(t.verifyIssuedOn, fmtDateTime(doc.issuedAt)),
          const Divider(),
          for (final line in doc.summary)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xxs),
              child: Text(line, style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}
