/// A protocol that types can conform to to control how they are dumped.
abstract class CustomDumpStringConvertible {
  /// A textual representation of this instance, suitable for debugging.
  String get customDumpDescription;
}

/// A protocol that types can conform to to control how they are dumped.
abstract class CustomDumpReflectable {
  /// A map of field names to values that should be dumped.
  Map<String, dynamic> get customDumpFields;
}

/// A protocol that types can conform to to control how they are dumped.
abstract class CustomDumpRepresentable {
  /// A value that should be dumped instead of this instance.
  dynamic get customDumpValue;
}

/// Dumps the given value's contents using its mirror representation.
///
/// This is a better alternative to `print` for debugging because it:
/// - Handles recursive data structures
/// - Formats output in a more readable way
/// - Shows the structure of the data more clearly
String customDump(dynamic value, {int maxDepth = 10}) {
  if (value == null) return 'null';

  if (value is CustomDumpStringConvertible) {
    return value.customDumpDescription;
  }

  if (value is CustomDumpReflectable) {
    return _dumpFields(
      value.runtimeType.toString(),
      value.customDumpFields,
      maxDepth,
    );
  }

  if (value is CustomDumpRepresentable) {
    final dumpValue = value.customDumpValue;
    if (dumpValue is String) {
      return dumpValue;
    }
    return customDump(dumpValue, maxDepth: maxDepth);
  }

  if (value is String) {
    return '"$value"';
  }

  if (value is num || value is bool) {
    return value.toString();
  }

  if (value is List) {
    if (value.isEmpty) return '[]';
    if (maxDepth <= 0) return '...';
    final items = value
        .map((e) => customDump(e, maxDepth: maxDepth - 1))
        .join(', ');
    return '[$items]';
  }

  if (value is Map) {
    if (value.isEmpty) return '{}';
    if (maxDepth <= 0) return '...';
    final items = value.entries
        .map(
          (e) =>
              '${customDump(e.key, maxDepth: maxDepth - 1)}: ${customDump(e.value, maxDepth: maxDepth - 1)}',
        )
        .join(', ');
    return '{$items}';
  }

  // For other objects, just return their string representation
  return value.toString();
}

String _dumpFields(
  String className,
  Map<String, dynamic> fields,
  int maxDepth,
) {
  if (maxDepth <= 0) return '$className(...)';
  if (fields.isEmpty) return className;

  final fieldStrings = fields.entries
      .map((e) => '${e.key}: ${customDump(e.value, maxDepth: maxDepth - 1)}')
      .join(', ');

  return '$className($fieldStrings)';
}
