/// One button for "turn this into a PDF and hand it to me" (P10-01).
///
/// Owns the busy state and the failure SnackBar so every document screen —
/// vitals, radiology, sick leave — gets the same behaviour for free.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../services/pdf/clinic_pdf.dart';

class DocumentDownloadButton extends StatefulWidget {
  const DocumentDownloadButton({
    required this.label,
    required this.filename,
    required this.build,
    this.icon = Icons.picture_as_pdf_outlined,
    this.dense = false,
    super.key,
  });

  final String label;
  final String filename;
  final Future<Uint8List> Function() build;
  final IconData icon;

  /// Render as a compact icon button (list rows) rather than a full button.
  final bool dense;

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
      await ClinicPdf.present(bytes, filename: widget.filename);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create the document.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      label: Text(widget.label),
    );
  }
}
