/// Web: the browser Notification API. Alerts show only while the app is open
/// in a tab; permission is the browser's, per site.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'device_notifier.dart';

DeviceNotifier createDeviceNotifier() => _BrowserNotifier();

class _BrowserNotifier implements DeviceNotifier {
  bool get _supported => web.window.has('Notification');

  AlertPermission _map(String value) => switch (value) {
    'granted' => AlertPermission.granted,
    'denied' => AlertPermission.denied,
    _ => AlertPermission.notRequested,
  };

  @override
  Future<AlertPermission> permission() async {
    if (!_supported) return AlertPermission.unsupported;
    return _map(web.Notification.permission);
  }

  @override
  Future<AlertPermission> requestPermission() async {
    if (!_supported) return AlertPermission.unsupported;
    final result = await web.Notification.requestPermission().toDart;
    return _map(result.toDart);
  }

  @override
  Future<void> show({required String title, required String body}) async {
    web.Notification(title, web.NotificationOptions(body: body));
  }
}
