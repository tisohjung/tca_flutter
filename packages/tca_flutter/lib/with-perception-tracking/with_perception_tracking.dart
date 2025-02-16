/// A token that represents an active perception tracking scope.
class PerceptionTrackingToken {
  final Set<Object> _accesses = {};
  bool _isActive = true;

  /// The set of all accessed properties during the perception tracking.
  Set<Object> get accesses => Set.unmodifiable(_accesses);

  /// Marks this token as inactive.
  void dispose() {
    _isActive = false;
  }

  /// Records an access to the given property.
  void record(Object property) {
    if (_isActive) {
      _accesses.add(property);
    }
  }
}

/// The currently active perception tracking token.
PerceptionTrackingToken? _currentToken;

/// Executes the given computation with perception tracking and returns both its result
/// and a set of properties that were accessed during the computation.
///
/// Example usage:
/// ```dart
/// final (value, accesses) = withPerceptionTracking(() {
///   return someComputation();
/// });
/// ```
///
/// The function returns a tuple containing:
/// - The result of the computation
/// - A set of properties that were accessed during the computation
T withPerceptionTracking<T>(T Function() operation) {
  // Create a new token for this tracking session
  final token = PerceptionTrackingToken();

  // Store the previous token to restore it later
  final previousToken = _currentToken;
  _currentToken = token;

  try {
    // Execute the operation
    final result = operation();
    return result;
  } finally {
    // Restore the previous token and mark this one as inactive
    _currentToken = previousToken;
    token.dispose();
  }
}

/// Returns the current perception tracking token if one is active.
PerceptionTrackingToken? get currentToken => _currentToken;

/// A mixin that can be used to make properties trackable.
mixin PerceptionTracking {
  /// Tracks access to a property with the given key.
  void trackAccess(Object key) {
    _currentToken?.record(key);
  }
}
