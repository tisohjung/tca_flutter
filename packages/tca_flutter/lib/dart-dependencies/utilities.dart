Future<T> withValue<T>(T value, Future<T> Function(T) operation) async {
  return operation(value);
}
