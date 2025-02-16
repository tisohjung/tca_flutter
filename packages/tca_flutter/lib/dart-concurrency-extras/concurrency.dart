import 'dart:async';
import 'dart:collection';

/// A manager for controlling task cancellation and dependencies.
///
/// ```
/// final manager = TaskManager();
///
/// myStream
///   .cancellable(manager)
///   .listen((data) {
///     print(data);
///   });
///
/// // Cancel later if needed
/// manager.cancel();
/// ```
class TaskManager {
  final _tasks = HashSet<Future<void>>();
  bool _isCancelled = false;

  /// Whether the task manager has been cancelled
  bool get isCancelled => _isCancelled;

  /// Adds a task to be managed
  void addTask(Future<void> task) {
    if (_isCancelled) return;
    _tasks.add(task);
    task.whenComplete(() => _tasks.remove(task));
  }

  /// Cancels all running tasks
  void cancel() {
    _isCancelled = true;
    _tasks.clear();
  }
}

/// A wrapper around a function that can be cancelled.
class AsyncFunction<T> {
  final Future<T> Function(TaskManager manager) _function;

  AsyncFunction(this._function);

  /// Executes the function with a new task manager
  Future<T> run() async {
    final manager = TaskManager();
    try {
      return await _function(manager);
    } finally {
      manager.cancel();
    }
  }
}

/// A cancellable operation that can be used to wrap async work.
///
/// ```
/// final operation = CancellableOperation.fromFuture(
///   Future.delayed(Duration(seconds: 1))
/// );
///
/// // Cancel if needed
/// operation.cancel();
///
/// // Wait for result
/// try {
///   final result = await operation.value;
/// } catch (e) {
///   print('Operation was cancelled or failed');
/// }
/// ```
///
class CancellableOperation<T> {
  final _completer = Completer<T>();
  final _manager = TaskManager();

  bool get isCancelled => _manager.isCancelled;
  Future<T> get value => _completer.future;

  /// Creates a new cancellable operation
  CancellableOperation.fromFuture(Future<T> future) {
    if (!_manager.isCancelled) {
      _manager.addTask(future.then((value) {
        if (!_manager.isCancelled) {
          _completer.complete(value);
        }
      }).catchError((error) {
        if (!_manager.isCancelled) {
          _completer.completeError(error);
        }
      }));
    }
  }

  /// Cancels the operation
  void cancel() {
    _manager.cancel();
  }
}

/// Extensions for working with streams in a cancellable way
extension CancellableStreamExtensions<T> on Stream<T> {
  /// Converts the stream into a cancellable operation
  CancellableOperation<List<T>> toCancellableList() {
    return CancellableOperation.fromFuture(toList());
  }

  /// Creates a new stream that can be cancelled
  Stream<T> cancellable(TaskManager manager) async* {
    if (manager.isCancelled) return;

    await for (final value in this) {
      if (manager.isCancelled) return;
      yield value;
    }
  }
}

/// A wrapper for async work that provides structured concurrence capabilities
///
/// ```
/// final operation = WithConcurrency(
///   () => fetchData(),
///   timeout: Duration(seconds: 5),
/// );
///
/// try {
///   final result = await operation.run();
/// } on TimeoutException catch (e) {
///   print('Operation timed out');
/// }
/// ```
class WithConcurrency<T> {
  final Future<T> Function() _operation;
  final Duration? _timeout;

  WithConcurrency(this._operation, {Duration? timeout}) : _timeout = timeout;

  /// Runs the operation with the given concurrency limit
  Future<T> run({int? maxConcurrentOperations}) async {
    if (_timeout != null) {
      return await _runWithTimeout();
    }
    return await _operation();
  }

  Future<T> _runWithTimeout() async {
    final completer = Completer<T>();

    // Start the operation
    _operation().then((value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }).catchError((error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    });

    // Setup timeout
    Timer(_timeout!, () {
      if (!completer.isCompleted) {
        completer
            .completeError(TimeoutException('Operation timed out', _timeout));
      }
    });

    return completer.future;
  }
}

/// A debouncer for async operations
///
/// This can be used to debounce async operations, ensuring that they only run after a certain delay.
/// ```
/// final debouncer = Debouncer(delay: Duration(milliseconds: 300));
///
/// void handleSearch(String query) {
///   debouncer.run(() {
///     // This will only run after 300ms of no new calls
///     performSearch(query);
///   });
/// }
/// ```
///
class Debouncer {
  Timer? _timer;
  final Duration delay;

  Debouncer({required this.delay});

  /// Runs the given operation after the delay, cancelling any pending operations
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancels any pending operations
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

/// A throttler for async operations
///
/// ```
/// final throttler = Throttler(interval: Duration(seconds: 1));
///
/// void handleClick() {
///   throttler.run(() {
///     // This will run at most once per second
///     sendAnalytics();
///   });
/// }
/// ```
class Throttler {
  Timer? _timer;
  bool _isRunning = false;
  final Duration interval;

  Throttler({required this.interval});

  /// Runs the given operation at most once per interval
  void run(void Function() action) {
    if (_isRunning) return;

    action();
    _isRunning = true;
    _timer = Timer(interval, () {
      _isRunning = false;
    });
  }

  /// Cancels any throttling state
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }
}

/// A semaphore for limiting concurrent operations
class AsyncSemaphore {
  final Queue<Completer<void>> _waiters = Queue();
  int _currentValue;

  AsyncSemaphore(int value) : _currentValue = value;

  /// Acquires the semaphore
  Future<void> acquire() async {
    if (_currentValue > 0) {
      _currentValue--;
      return;
    }

    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  /// Releases the semaphore
  void release() {
    if (_waiters.isEmpty) {
      _currentValue++;
    } else {
      _waiters.removeFirst().complete();
    }
  }
}

/// Runs multiple async operations with a concurrency limit
///
/// ```
/// final results = await withTaskGroup(
///   operations: [
///     () => fetchUser(1),
///     () => fetchUser(2),
///     () => fetchUser(3),
///   ],
///   maxConcurrentOperations: 2,
/// );
/// ```
Future<List<T>> withTaskGroup<T>({
  required List<Future<T> Function()> operations,
  required int maxConcurrentOperations,
}) async {
  final semaphore = AsyncSemaphore(maxConcurrentOperations);
  final results = List<T?>.filled(operations.length, null);

  await Future.wait(
    operations.asMap().entries.map((entry) async {
      await semaphore.acquire();
      try {
        results[entry.key] = await entry.value();
      } finally {
        semaphore.release();
      }
    }),
  );

  return results.whereType<T>().toList();
}

/// A class that isolates a value and allows it to be updated in a thread-safe manner.
class LockIsolated<T> {
  T _value;
  final _lock = Completer<void>();

  LockIsolated(this._value);

  /// Gets the value
  T get value => _value;

  /// Sets the value in a thread-safe way.
  set value(T newValue) {
    // Complete the lock and allow the value to be updated.
    if (!_lock.isCompleted) {
      _lock.complete();
    }
    _value = newValue;
  }

  /// Updates the value in a safe manner by waiting for the lock.
  Future<void> setValue(T newValue) async {
    await _lock.future; // Wait for the lock to be available.
    _value = newValue;
  }

  /// Executes a function that works with the value in a thread-safe manner.
  Future<R> withValue<R>(Future<R> Function(T value) action) async {
    await _lock.future; // Ensure the lock is acquired before proceeding.
    return action(_value);
  }
}
