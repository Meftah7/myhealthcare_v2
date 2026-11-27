@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/features/ai_chat/presentation/assistant_document_picker.dart';
import 'package:web/web.dart' as web;

const _inputSelector = 'input[type="file"]';

void main() {
  test('a delayed selection survives the browser returning focus', () async {
    final selection = pickAssistantDocument();
    final input =
        web.document.querySelector(_inputSelector)! as web.HTMLInputElement;
    expect(input.accept, isEmpty);

    web.window.dispatchEvent(web.Event('focus'));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(input.isConnected, isTrue);

    final bytes = Uint8List.fromList('%PDF-1.7'.codeUnits);
    final transfer = web.DataTransfer();
    transfer.items.add(
      web.File(
        [bytes.toJS].toJS,
        'phone.PDF',
        web.FilePropertyBag(type: 'application/octet-stream'),
      ),
    );
    input.files = transfer.files;
    input.dispatchEvent(web.Event('change'));

    final file = (await selection)!;
    expect(file.name, 'phone.PDF');
    expect(file.size, bytes.length);
    expect(await file.readBytes(), bytes);
    expect(web.document.querySelector(_inputSelector), isNull);
  });

  test('cancelling or opening a new chooser clears the previous one', () async {
    final first = pickAssistantDocument();
    final second = pickAssistantDocument();
    expect(await first, isNull);
    expect(web.document.querySelectorAll(_inputSelector).length, 1);

    web.document
        .querySelector(_inputSelector)!
        .dispatchEvent(web.Event('cancel'));
    expect(await second, isNull);
    expect(web.document.querySelector(_inputSelector), isNull);
  });
}
