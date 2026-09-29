/// Alerts shown by the device itself — the "push" reminder channel (Phase 5).
///
/// Scope, stated plainly: this prototype has no push server, so an alert can
/// only be shown while MyHealth Care is open in the browser. A reminder that
/// falls due while the app is closed is delivered to the in-app inbox the
/// next time it opens (see `ReminderDispatcher`), and the settings screen
/// says so.
library;

import 'device_notifier_stub.dart'
    if (dart.library.js_interop) 'device_notifier_web.dart'
    as platform;

/// Whether the device will show alerts.
enum AlertPermission {
  granted,

  /// The person (or the browser) refused. Not retried; in-app still works.
  denied,

  /// Never asked yet.
  notRequested,

  /// This device cannot show alerts at all.
  unsupported,
}

abstract interface class DeviceNotifier {
  Future<AlertPermission> permission();

  /// Asks the person. Call only from a user gesture (a button tap).
  Future<AlertPermission> requestPermission();

  /// Shows one alert. Throws if the device fails to show it (a transient
  /// failure the dispatcher retries).
  Future<void> show({required String title, required String body});
}

/// The notifier for the platform the app runs on.
DeviceNotifier platformDeviceNotifier() => platform.createDeviceNotifier();

/// A device that shows no alerts — tests and platforms without support.
class UnsupportedDeviceNotifier implements DeviceNotifier {
  const UnsupportedDeviceNotifier();

  @override
  Future<AlertPermission> permission() async => AlertPermission.unsupported;

  @override
  Future<AlertPermission> requestPermission() async =>
      AlertPermission.unsupported;

  @override
  Future<void> show({required String title, required String body}) =>
      throw UnsupportedError('Device alerts are not supported here.');
}
