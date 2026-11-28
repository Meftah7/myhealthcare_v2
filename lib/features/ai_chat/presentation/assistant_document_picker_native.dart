import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../services/documents/document_text.dart';

Future<({String name, int? size, Future<Uint8List> Function() readBytes})?>
pickAssistantDocument() async {
  // Mobile document providers sometimes label supported files as generic data.
  // Validate the selected document in the app instead of relying on that label.
  final mobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  final file = await FilePicker.pickFile(
    type: mobile ? FileType.any : FileType.custom,
    allowedExtensions: mobile ? null : DocumentFormat.pickerExtensions,
  );
  if (file == null) return null;
  return (
    name: file.name,
    size: file.lengthSync(),
    readBytes: () => readBoundedDocumentBytes(file.readAsByteStream()),
  );
}
