import 'custom_dump.dart';

/// A class representing a difference between two values.
class Difference {
  final String path;
  final dynamic first;
  final dynamic second;

  Difference(this.path, this.first, this.second);

  @override
  String toString() {
    return '$path:\n  - ${customDump(first)}\n  + ${customDump(second)}';
  }
}

/// Compares two values and returns a list of differences between them.
///
/// Returns null if the values are equal.
List<Difference>? diff(dynamic first, dynamic second, {String path = ''}) {
  if (first == second) return null;

  if (first is List && second is List) {
    return _diffLists(first, second, path);
  }

  if (first is Map && second is Map) {
    return _diffMaps(first, second, path);
  }

  return [Difference(path, first, second)];
}

List<Difference>? _diffLists(List first, List second, String path) {
  final differences = <Difference>[];

  for (var i = 0; i < first.length || i < second.length; i++) {
    final elementPath = '$path[$i]';

    if (i >= first.length) {
      differences.add(Difference(elementPath, null, second[i]));
    } else if (i >= second.length) {
      differences.add(Difference(elementPath, first[i], null));
    } else {
      final elementDiff = diff(first[i], second[i], path: elementPath);
      if (elementDiff != null) {
        differences.addAll(elementDiff);
      }
    }
  }

  return differences.isEmpty ? null : differences;
}

List<Difference>? _diffMaps(Map first, Map second, String path) {
  final differences = <Difference>[];
  final allKeys = {...first.keys, ...second.keys};

  for (final key in allKeys) {
    final elementPath = '$path.${key is String ? key : customDump(key)}';

    if (!second.containsKey(key)) {
      differences.add(Difference(elementPath, first[key], null));
    } else if (!first.containsKey(key)) {
      differences.add(Difference(elementPath, null, second[key]));
    } else {
      final elementDiff = diff(first[key], second[key], path: elementPath);
      if (elementDiff != null) {
        differences.addAll(elementDiff);
      }
    }
  }

  return differences.isEmpty ? null : differences;
}
