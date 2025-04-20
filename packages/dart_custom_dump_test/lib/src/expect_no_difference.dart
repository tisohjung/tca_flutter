import 'package:dart_custom_dump/dart_custom_dump.dart';
import 'package:dart_custom_dump/src/diff.dart';
import 'package:test/test.dart';

/// Asserts that two values are equal, providing a detailed diff if they are not.
///
/// This is similar to `expect` from the test package, but provides more detailed
/// information about the differences between the values.
void expectNoDifference(dynamic first, dynamic second, {String? reason}) {
  final differences = diff(first, second);
  if (differences != null) {
    final message = StringBuffer();
    if (reason != null) {
      message.writeln(reason);
    }
    message.writeln('Expected values to be equal, but found differences:');
    for (final difference in differences) {
      message.writeln(difference);
    }
    fail(message.toString());
  }
}

/// Asserts that a value changes in a specific way after executing a function.
///
/// This is useful for testing that a value changes in a specific way after
/// executing some code.
void expectDifference<T>(
  T value,
  T Function() operation, {
  required T Function(T) changes,
  String? reason,
}) {
  final before = value;
  final after = operation();
  final expected = changes(value);

  final actualDifferences = diff(before, after);
  if (actualDifferences == null) {
    final message = StringBuffer();
    if (reason != null) {
      message.writeln(reason);
    }
    message.writeln('Expected values to be different, but they were equal');
    fail(message.toString());
  }

  final expectedDifferences = diff(before, expected);
  if (expectedDifferences == null) {
    final message = StringBuffer();
    if (reason != null) {
      message.writeln(reason);
    }
    message.writeln('Expected values to be different, but they were equal');
    fail(message.toString());
  }

  // Compare the actual differences with the expected differences
  final message = StringBuffer();
  if (reason != null) {
    message.writeln(reason);
  }

  var hasUnexpectedDifferences = false;
  for (final difference in actualDifferences) {
    final expectedDifference = expectedDifferences.firstWhere(
      (d) => d.path == difference.path,
      orElse: () => Difference(difference.path, null, null),
    );

    if (customDump(expectedDifference.first) != customDump(difference.first) ||
        customDump(expectedDifference.second) !=
            customDump(difference.second)) {
      hasUnexpectedDifferences = true;
      message.writeln('Unexpected difference at ${difference.path}:');
      message.writeln('  Expected:');
      message.writeln('    - ${customDump(expectedDifference.first)}');
      message.writeln('    + ${customDump(expectedDifference.second)}');
      message.writeln('  Actual:');
      message.writeln('    - ${customDump(difference.first)}');
      message.writeln('    + ${customDump(difference.second)}');
    }
  }

  if (hasUnexpectedDifferences) {
    fail(message.toString());
  }
}
