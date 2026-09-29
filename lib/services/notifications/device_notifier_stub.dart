/// Non-web builds: no device alerts in this prototype (native platforms are
/// outside the release scope).
library;

import 'device_notifier.dart';

DeviceNotifier createDeviceNotifier() => const UnsupportedDeviceNotifier();
