import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void Function()? _cancelPendingPicker;

Future<({String name, int? size, Future<Uint8List> Function() readBytes})?>
pickAssistantDocument() {
  _cancelPendingPicker?.call();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..style.display = 'none';
  final selected = Completer<web.File?>();

  void finish(web.File? file) {
    if (selected.isCompleted) return;
    _cancelPendingPicker = null;
    input.remove();
    selected.complete(file);
  }

  _cancelPendingPicker = () => finish(null);
  final change = ((web.Event _) => finish(input.files?.item(0))).toJS;
  final cancel = ((web.Event _) => finish(null)).toJS;
  input.addEventListener('change', change);
  input.addEventListener('cancel', cancel);
  try {
    // Keep the input attached until selection or cancellation. The OS file
    // provider can return focus before it delivers the user's file.
    web.document.body!.append(input);
    input.click();
  } on Object catch (error, stackTrace) {
    if (!selected.isCompleted) {
      _cancelPendingPicker = null;
      input.remove();
      selected.completeError(error, stackTrace);
    }
  }
  return selected.future.then((file) {
    input.removeEventListener('change', change);
    input.removeEventListener('cancel', cancel);
    if (file == null) return null;
    return (
      name: file.name,
      size: file.size,
      readBytes: () async =>
          (await file.arrayBuffer().toDart).toDart.asUint8List(),
    );
  });
}
