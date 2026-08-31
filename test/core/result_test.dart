import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/core/failures.dart';
import 'package:myhealthcare/core/result.dart';

void main() {
  group('Result', () {
    test('Ok carries its value', () {
      const r = Ok(42);
      expect(r.isOk, isTrue);
      expect(r.valueOrNull, 42);
      expect(r.failureOrNull, isNull);
    });

    test('Err carries its failure', () {
      const r = Err<int>(NotFoundFailure('nope'));
      expect(r.isErr, isTrue);
      expect(r.valueOrNull, isNull);
      expect(r.failureOrNull, isA<NotFoundFailure>());
    });

    test('map transforms Ok, passes Err through', () {
      expect(const Ok(2).map((v) => v * 3), const Ok(6));
      expect(
        const Err<int>(DatabaseFailure('x')).map((v) => v * 3).isErr,
        isTrue,
      );
    });

    test('flatMap chains fallible steps', () {
      Result<int> parse(String s) {
        final n = int.tryParse(s);
        return n == null ? const Err(ValidationFailure('NaN')) : Ok(n);
      }

      expect(const Ok('10').flatMap(parse), const Ok(10));
      expect(const Ok('nan').flatMap(parse).isErr, isTrue);
    });

    test('fold collapses both branches', () {
      String render(Result<int> r) =>
          r.fold((v) => 'value $v', (f) => 'error ${f.message}');
      expect(render(const Ok(1)), 'value 1');
      expect(render(const Err(AuthFailure('bad'))), 'error bad');
    });

    test('guard converts a thrown object into UnexpectedFailure', () {
      final r = Result.guard<int>(() => throw Exception('boom'));
      expect(r.failureOrNull, isA<UnexpectedFailure>());
    });

    test('guard preserves a thrown Failure', () {
      final r = Result.guard<int>(() => throw const NotFoundFailure('gone'));
      expect(r.failureOrNull, isA<NotFoundFailure>());
    });

    test('guardAsync works', () async {
      final r = await Result.guardAsync<int>(() async => 7);
      expect(r, const Ok(7));
    });
  });
}
