/// Runtime mode selected at build time.
///
/// Debug/profile builds default to demo; release builds default to production.
/// Either can be selected explicitly with `--dart-define=APP_MODE=...`.
enum AppMode {
  demo,
  production;

  bool get isDemo => this == AppMode.demo;

  static AppMode parse(String value) => switch (value) {
    'demo' => AppMode.demo,
    'production' => AppMode.production,
    _ => throw StateError(
      'Unsupported APP_MODE "$value". Use "demo" or "production".',
    ),
  };
}

const _configuredAppMode = String.fromEnvironment(
  'APP_MODE',
  defaultValue: bool.fromEnvironment('dart.vm.product') ? 'production' : 'demo',
);

final configuredAppMode = AppMode.parse(_configuredAppMode);
