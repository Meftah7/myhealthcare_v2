// Every route the app links to resolves: all AppRoutes constants and every
// literal path passed to push/go anywhere in lib/. A dead link (a button
// that would open the router's error page) fails this test.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/app/router.dart';

import '../support/sessions.dart';

Set<String> _routes() {
  final router = File('lib/app/router.dart').readAsStringSync();
  final consts = <String, String>{
    for (final m in RegExp(
      r"static const (\w+) = '([^']+)';",
    ).allMatches(router))
      m[1]!: m[2]!,
  };
  String resolve(String v) => v.replaceAllMapped(
    RegExp(r'\$(\w+)'),
    (m) => consts[m[1]] != null ? resolve(consts[m[1]]!) : m[0]!,
  );
  final paths = {for (final v in consts.values) resolve(v)};
  for (final f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    for (final m in RegExp(
      r"""\.(?:push|go|replace|pushReplacement)(?:<\w+>)?\(\s*'(/[^'$]*)'""",
    ).allMatches(f.readAsStringSync())) {
      paths.add(m[1]!);
    }
  }
  return {
    for (final p in paths)
      if (p.startsWith('/') && !p.contains(r'$')) p.split('?').first,
  };
}

void main() {
  test('every linked route resolves', () async {
    final (c, _) = await seededContainer();
    final router = c.read(routerProvider);
    final missing = <String>[];
    final routes = _routes();
    expect(routes.length, greaterThan(60), reason: 'route scan found routes');
    for (final path in routes) {
      final match = router.configuration.findMatch(Uri.parse(path));
      if (match.isError || match.isEmpty) missing.add(path);
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });
}
