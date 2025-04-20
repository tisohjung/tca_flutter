import 'package:dart_custom_dump/dart_custom_dump.dart';
import 'package:test/test.dart';

class User implements CustomDumpStringConvertible {
  final String name;
  final int age;
  final List<String> favoriteColors;

  User(this.name, this.age, this.favoriteColors);

  @override
  String get customDumpDescription {
    final colors = favoriteColors.map((c) => '"$c"').join(', ');
    return 'User(name: "$name", age: $age, favoriteColors: [$colors])';
  }
}

class SecureUser implements CustomDumpReflectable {
  final String username;
  final String token;

  SecureUser(this.username, this.token);

  @override
  Map<String, dynamic> get customDumpFields => {
    'username': username,
    // token is omitted for security
  };
}

class ID implements CustomDumpRepresentable {
  final String value;

  ID(this.value);

  @override
  dynamic get customDumpValue => value;
}

void main() {
  group('customDump', () {
    test('handles null', () {
      expect(customDump(null), equals('null'));
    });

    test('handles strings', () {
      expect(customDump('hello'), equals('"hello"'));
    });

    test('handles numbers', () {
      expect(customDump(42), equals('42'));
      expect(customDump(3.14), equals('3.14'));
    });

    test('handles booleans', () {
      expect(customDump(true), equals('true'));
      expect(customDump(false), equals('false'));
    });

    test('handles lists', () {
      expect(customDump([]), equals('[]'));
      expect(customDump([1, 2, 3]), equals('[1, 2, 3]'));
      expect(customDump(['a', 'b', 'c']), equals('["a", "b", "c"]'));
    });

    test('handles maps', () {
      expect(customDump({}), equals('{}'));
      expect(customDump({'a': 1, 'b': 2}), equals('{"a": 1, "b": 2}'));
    });

    test('handles CustomDumpStringConvertible', () {
      final user = User('John', 30, ['blue', 'green']);
      expect(
        customDump(user),
        equals(
          'User(name: "John", age: 30, favoriteColors: ["blue", "green"])',
        ),
      );
    });

    test('handles CustomDumpReflectable', () {
      final user = SecureUser('john', 'secret');
      expect(customDump(user), equals('SecureUser(username: "john")'));
    });

    test('handles CustomDumpRepresentable', () {
      final id = ID('123');
      expect(customDump(id), equals('123'));
    });

    test('handles nested structures', () {
      final data = {
        'users': [
          User('John', 30, ['blue']),
          User('Jane', 25, ['red', 'green']),
        ],
        'count': 2,
      };
      expect(
        customDump(data),
        equals(
          '{"users": [User(name: "John", age: 30, favoriteColors: ["blue"]), User(name: "Jane", age: 25, favoriteColors: ["red", "green"])], "count": 2}',
        ),
      );
    });

    test('respects maxDepth', () {
      final data = {
        'a': {
          'b': {
            'c': {'d': 'value'},
          },
        },
      };
      expect(customDump(data, maxDepth: 2), equals('{"a": {"b": ...}}'));
    });
  });
}
