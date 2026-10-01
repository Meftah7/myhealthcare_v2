/// The pre-seeded demo database shipped with the web build.
///
/// Generating the demo data in the browser means thousands of inserts, each a
/// round trip to the database worker — seconds in Chrome, minutes in Safari
/// (every iPhone browser), where the splash looked frozen. The web build
/// instead ships `demo_seed.sqlite`, produced at build time by the same
/// [Seeder] (`tool/demo_db/generate_demo_db_test.dart`), and a brand-new
/// browser database starts as a copy of it. Returns null when there is no
/// snapshot (development, production builds); the app then seeds as before.
library;

export 'demo_snapshot_stub.dart'
    if (dart.library.js_interop) 'demo_snapshot_web.dart';
