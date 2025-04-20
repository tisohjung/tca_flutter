<!-- 
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

# Dart Custom Dump

A collection of tools for debugging, diffing, and testing your application's data structures.

This package is a Dart port of the [Swift Custom Dump](https://github.com/pointfreeco/swift-custom-dump) package.

## Features

- `customDump`: A better alternative to `print` for debugging
- `diff`: Compare two values and show their differences
- `expectNoDifference`: Test assertions with detailed diffs
- `expectDifference`: Test that values change in specific ways

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  dart_custom_dump: ^0.0.1
```

## Usage

### Custom Dump

```dart
import 'package:dart_custom_dump/dart_custom_dump.dart';

class User {
  final String name;
  final int age;
  final List<String> favoriteColors;

  User(this.name, this.age, this.favoriteColors);
}

void main() {
  final user = User('John', 30, ['blue', 'green']);
  print(customDump(user));
  // Prints:
  // User(name: "John", age: 30, favoriteColors: ["blue", "green"])
}
```

### Diff

```dart
import 'package:dart_custom_dump/dart_custom_dump.dart';

void main() {
  final before = {'name': 'John', 'age': 30};
  final after = {'name': 'Jane', 'age': 31};
  
  final differences = diff(before, after);
  if (differences != null) {
    for (final difference in differences) {
      print(difference);
    }
  }
  // Prints:
  // .name:
  //   - "John"
  //   + "Jane"
  // .age:
  //   - 30
  //   + 31
}
```

### Testing

```dart
import 'package:dart_custom_dump/dart_custom_dump.dart';
import 'package:test/test.dart';

void main() {
  test('user updates correctly', () {
    final user = User('John', 30, ['blue']);
    
    expectDifference(user, () {
      user.favoriteColors.add('green');
      return user;
    }, changes: (user) {
      user.favoriteColors.add('green');
      return user;
    });
  });
}
```

## Additional information

For more information about the original Swift package, see the [Swift Custom Dump repository](https://github.com/pointfreeco/swift-custom-dump).

To contribute to this package, please open an issue or pull request on the [GitHub repository](https://github.com/minhoyi/dart_custom_dump).
