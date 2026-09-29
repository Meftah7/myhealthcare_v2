import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/app_environment.dart';

void main() {
  test('parses the supported runtime modes', () {
    expect(AppMode.parse('demo'), AppMode.demo);
    expect(AppMode.parse('production'), AppMode.production);
  });

  test('rejects an unknown runtime mode', () {
    expect(() => AppMode.parse('staging'), throwsStateError);
  });

  test('test/debug runtime defaults to demo mode', () {
    expect(configuredAppMode, AppMode.demo);
  });
}
