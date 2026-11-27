import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

bool get hasTouchscreen => switch (defaultTargetPlatform) {
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.fuchsia => true,
  TargetPlatform.windows => Platform.isWindows && _windowsHasTouchscreen(),
  TargetPlatform.macOS || TargetPlatform.linux => false,
};

final _getSystemMetrics = DynamicLibrary.open(
  'user32.dll',
).lookupFunction<Int32 Function(Int32), int Function(int)>('GetSystemMetrics');

bool _windowsHasTouchscreen() {
  const digitizer = 94; // SM_DIGITIZER
  const touch = 0x01 | 0x02; // NID_INTEGRATED_TOUCH | NID_EXTERNAL_TOUCH
  return (_getSystemMetrics(digitizer) & touch) != 0;
}
