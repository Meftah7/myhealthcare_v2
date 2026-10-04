/// Camera QR scanner for document verification codes.
///
/// Returns the scanned text (e.g. `MHC-VERIFY:ABCDE-FGHJK`), or null if the
/// user backs out. Android, iOS, macOS and the web only — on other desktops
/// [qrScanSupported] is false and the code is typed instead.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../l10n/app_localizations.dart';

bool get qrScanSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

Future<String?> scanQrCode(BuildContext context) => Navigator.of(
  context,
).push<String>(MaterialPageRoute(builder: (_) => const QrScanScreen()));

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  late final MobileScannerController _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Browsers without a built-in barcode detector fall back to ZXing,
      // which the plugin would fetch from unpkg — blocked by the app's
      // Content-Security-Policy. A copy is served with the app instead.
      MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl(
        'zxing/zxing.min.js',
      );
    }
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final value = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (value == null || value.isEmpty) return;
    _done = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.scanQrTitle)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  t.cameraUnavailable,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ),
          // A target frame and a hint over the camera view.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  t.scanQrHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
