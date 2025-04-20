import 'package:dart_custom_dump/dart_custom_dump.dart';
import 'package:test/test.dart';

void main() {
  group('diff', () {
    test('returns null for equal values', () {
      expect(diff(1, 1), isNull);
      expect(diff('hello', 'hello'), isNull);
      expect(diff([1, 2, 3], [1, 2, 3]), isNull);
      expect(diff({'a': 1}, {'a': 1}), isNull);
    });

    test('handles primitive differences', () {
      final differences = diff(1, 2);
      expect(differences, hasLength(1));
      expect(differences![0].path, equals(''));
      expect(differences[0].first, equals(1));
      expect(differences[0].second, equals(2));
    });

    test('handles list differences', () {
      final differences = diff([1, 2, 3], [1, 4, 3]);
      expect(differences, hasLength(1));
      expect(differences![0].path, equals('[1]'));
      expect(differences[0].first, equals(2));
      expect(differences[0].second, equals(4));
    });

    test('handles list length differences', () {
      final differences = diff([1, 2], [1, 2, 3]);
      expect(differences, hasLength(1));
      expect(differences![0].path, equals('[2]'));
      expect(differences[0].first, isNull);
      expect(differences[0].second, equals(3));
    });

    test('handles map differences', () {
      final differences = diff({'a': 1, 'b': 2}, {'a': 1, 'b': 3});
      expect(differences, hasLength(1));
      expect(differences![0].path, equals('.b'));
      expect(differences[0].first, equals(2));
      expect(differences[0].second, equals(3));
    });

    test('handles map key differences', () {
      final differences = diff({'a': 1}, {'b': 1});
      expect(differences, hasLength(2));
      expect(differences![0].path, equals('.a'));
      expect(differences[0].first, equals(1));
      expect(differences[0].second, isNull);
      expect(differences[1].path, equals('.b'));
      expect(differences[1].first, isNull);
      expect(differences[1].second, equals(1));
    });

    test('handles nested differences', () {
      final differences = diff(
        {
          'users': [
            {'name': 'John', 'age': 30},
            {'name': 'Jane', 'age': 25},
          ],
        },
        {
          'users': [
            {'name': 'John', 'age': 31},
            {'name': 'Jane', 'age': 25},
          ],
        },
      );
      expect(differences, hasLength(1));
      expect(differences![0].path, equals('.users[0].age'));
      expect(differences[0].first, equals(30));
      expect(differences[0].second, equals(31));
    });
  });
}
