/// One button for "turn this into a PDF and hand it to me" (P10-01).
///
/// Owns the busy state and the failure SnackBar so every document screen —
/// vitals, radiology, sick leave — gets the same behaviour for free. A
/// failure says what stopped it (no access, a missing original, or the
/// document could not be built) and offers "Try again" when that can help.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/failures.dart';
import '../../../core/presentation/quick_actions.dart';
import '../../../l10n/app_localizations.dart';

class DocumentDownloadButton extends StatefulWidget {
  const DocumentDownloadButton({
    required this.label,
    required this.filename,
    required this.build,
    this.icon = Icons.picture_as_pdf_outlined,
    this.dense = false,
    this.asQuickAction = false,
    super.key,
  });

  final String label;
  final String filename;
  final Future<Uint8List> Function() build;
  final IconData icon;

  /// Render as a compact icon button (list rows) rather than a full button.
  final bool dense;
  final bool asQuickAction;

  @override
  State<DocumentDownloadButton> createState() => _DocumentDownloadButtonState();
}

class _DocumentDownloadButtonState extends State<DocumentDownloadButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await widget.build();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => DocumentPreviewScreen(
            bytes: bytes,
            filename: widget.filename,
            title: widget.label,
          ),
        ),
      );
    } on Object catch (error, stack) {
      debugPrint('Document "${widget.filename}" failed: $error\n$stack');
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        // Say which boundary stopped it; offer a retry only when one could
        // succeed.
        final denied = error is AccessDeniedFailure;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(switch (error) {
              AccessDeniedFailure() => t.accessDeniedBody,
              Failure(:final message) => message,
              _ => t.couldNotCreateDocument,
            }),
            action: denied
                ? null
                : SnackBarAction(label: t.tryAgain, onPressed: _run),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asQuickAction) {
      return QuickActionTile(
        icon: _busy ? Icons.hourglass_top : widget.icon,
        label: widget.label,
        onTap: _busy ? null : _run,
      );
    }
    if (widget.dense) {
      return IconButton(
        onPressed: _busy ? null : _run,
        tooltip: widget.label,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(widget.icon),
      );
    }
    return OutlinedButton.icon(
      onPressed: _busy ? null : _run,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon, size: 18),
      // Wraps rather than clips so this reads the same as the plain
      // OutlinedButton.icon shortcuts it sits beside, even in a half-width cell.
      label: Text(
        widget.label,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Shows a generated PDF in-app, with share / save and print actions.
///
/// Works the same on mobile, desktop and web — unlike the bare print
/// dialog, which on desktop shows no preview and saves nothing.
class DocumentPreviewScreen extends StatelessWidget {
  const DocumentPreviewScreen({
    required this.bytes,
    required this.filename,
    required this.title,
    super.key,
  });

  final Uint8List bytes;
  final String filename;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: (_) async => bytes,
        pdfFileName: filename,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}
