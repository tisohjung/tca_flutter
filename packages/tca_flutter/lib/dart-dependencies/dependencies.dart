import 'dart:async';
import 'dart:collection';

/// A type that represents a dependency that can be accessed in a controlled way.
///
/// 1. Defining Dependencies:
/// ```
/// class AppDependencies {
///   static final logger = Dependency<Logger>(namespace: 'logger');
///   static final database = Dependency<Database>(namespace: 'database');
///   static final api = Dependency<ApiClient>(namespace: 'api');
/// }
/// ```
/// 2. Using Dependencies in Code:
/// ```
/// class UserService {
///   Future<User> getUser(String id) async {
///     final api = AppDependencies.api.value;
///     final logger = AppDependencies.logger.value;
///
///     logger.info('Fetching user: $id');
///     final data = await api.get('/users/$id');
///     return User.fromJson(data);
///   }
/// }
/// ```
/// 3. Setting Up Dependencies:
/// ```
/// void main() {
///   AppDependencies.api.value = ProductionApiClient();
///   AppDependencies.logger.value = ConsoleLogger();
///   AppDependencies.database.value = SqliteDatabase();
///
///   runApp(MyApp());
/// }
/// ```
/// 4. Testing with Dependencies:
/// ```
/// void testUserService() {
///   final context = DependencyContext();
///   final mockApi = MockApiClient();
///
///   context.withDependencies(
///     dependencies: {
///       AppDependencies.api: mockApi,
///       AppDependencies.logger: MockLogger(),
///     },
///     callback: () async {
///       final service = UserService();
///       await service.getUser('123');
///
///       expect(mockApi.getCalls('get'), contains('/users/123'));
///     },
///   );
/// }
/// ```
class Dependency<Value> {
  final _ValueKey<Value> _key;

  const Dependency._(_ValueKey<Value> key) : _key = key;

  /// Creates a new dependency with the given namespace.
  factory Dependency({String? namespace}) {
    return Dependency._(_ValueKey<Value>(namespace: namespace));
  }

  /// Accesses the current value of the dependency.
  Value get value => DependencyValues.instance[_key] as Value;

  /// Updates the value of the dependency.
  set value(Value newValue) {
    DependencyValues.instance[_key] = newValue;
  }
}

/// A class that holds all dependency values.
class DependencyValues {
  static final instance = DependencyValues._();

  final _values = HashMap<_ValueKey, dynamic>();
  final _overrides = <_DependencyScope>[];

  DependencyValues._();

  /// Gets a dependency value.
  operator [](dynamic key) {
    final value = _getValue(key);
    if (value == null) {
      throw DependencyError('No value set for dependency: $key');
    }
    return value;
  }

  /// Sets a dependency value.
  operator []=(dynamic key, dynamic value) {
    _setValue(key, value);
  }

  dynamic _getValue(_ValueKey key) {
    for (final scope in _overrides.reversed) {
      if (scope.values.containsKey(key)) {
        return scope.values[key];
      }
    }
    return _values[key];
  }

  void _setValue(_ValueKey key, dynamic value) {
    if (_overrides.isNotEmpty) {
      _overrides.last.values[key] = value;
    } else {
      _values[key] = value;
    }
  }
}

/// A class that provides dependency overriding capabilities for testing.
class TestDependencyValues extends DependencyValues {
  TestDependencyValues() : super._();

  /// Overrides dependencies for the duration of the test.
  void override<T>(Dependency<T> dependency, T value) {
    this[dependency._key] = value;
  }
}

/// A scope for dependency overrides.
class _DependencyScope {
  final values = HashMap<_ValueKey, dynamic>();
}

/// A key that uniquely identifies a dependency value.
class _ValueKey<T> {
  final String? namespace;
  final String typeName;

  _ValueKey({this.namespace}) : typeName = T.toString();

  @override
  bool operator ==(Object other) {
    return other is _ValueKey &&
        other.namespace == namespace &&
        other.typeName == typeName;
  }

  @override
  int get hashCode => Object.hash(namespace, typeName);

  @override
  String toString() => '${namespace ?? ''}_$typeName';
}

/// Error thrown when a dependency is not found.
class DependencyError extends Error {
  final String message;
  DependencyError(this.message);

  @override
  String toString() => 'DependencyError: $message';
}

/// A context for overriding dependencies in a specific scope.
class DependencyContext {
  final _scope = _DependencyScope();

  /// Runs the given callback with overridden dependencies.
  T withDependencies<T>({
    required Map<Dependency, dynamic> dependencies,
    required T Function() callback,
  }) {
    DependencyValues.instance._overrides.add(_scope);
    try {
      dependencies.forEach((dep, value) {
        _scope.values[dep._key] = value;
      });
      return callback();
    } finally {
      DependencyValues.instance._overrides.removeLast();
    }
  }
}

/// Example dependencies that could be used in an application
class Dependencies {
  /// Date provider dependency
  static final date = Dependency<DateTime Function()>(namespace: 'date');

  /// UUID generator dependency
  static final uuid = Dependency<String Function()>(namespace: 'uuid');

  /// API client dependency
  static final api = Dependency<ApiClient>(namespace: 'api');

  /// URL provider dependency
  static final baseUrl = Dependency<String>(namespace: 'baseUrl');
}

/// Example API client interface
abstract class ApiClient {
  Future<dynamic> get(String path);
  Future<dynamic> post(String path, dynamic data);
  Future<dynamic> put(String path, dynamic data);
  Future<dynamic> delete(String path);
}

/// Example usage in a repository class
class UserRepository {
  Future<Map<String, dynamic>> getUser(String id) async {
    final api = Dependencies.api.value;
    final response = await api.get('/users/$id');
    return response as Map<String, dynamic>;
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    final api = Dependencies.api.value;
    final uuid = Dependencies.uuid.value();
    userData['id'] = uuid;
    await api.post('/users', userData);
  }
}

/// Example usage of dependency overrides in tests
void main() async {
  // Example test setup
  final testContext = DependencyContext();
  final mockApi = MockApiClient();

  testContext.withDependencies(
    dependencies: {
      Dependencies.api: mockApi,
      Dependencies.date: () => DateTime(2024, 1, 1),
      Dependencies.uuid: () => 'test-uuid',
    },
    callback: () async {
      final repository = UserRepository();
      await repository.createUser({'name': 'Test User'});

      // Verify mock calls...
    },
  );
}

/// Example mock API client for testing
class MockApiClient implements ApiClient {
  final _calls = <String, List<dynamic>>{};

  List<dynamic> getCalls(String method) => _calls[method] ?? [];

  @override
  Future<dynamic> get(String path) async {
    _calls['get'] = [...getCalls('get'), path];
    return {'id': 'test-id', 'name': 'Test User'};
  }

  @override
  Future<dynamic> post(String path, data) async {
    _calls['post'] = [
      ...getCalls('post'),
      {'path': path, 'data': data}
    ];
  }

  @override
  Future<dynamic> put(String path, data) async {
    _calls['put'] = [
      ...getCalls('put'),
      {'path': path, 'data': data}
    ];
  }

  @override
  Future<dynamic> delete(String path) async {
    _calls['delete'] = [...getCalls('delete'), path];
  }
}
