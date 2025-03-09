import 'dart:async';

/// Represents a side effect that can be performed by the application.
class Effect<Action> {
  final Future<List<Action>> Function() _run;
  final Operation operation;

  const Effect(this._run, this.operation);

  /// Runs the effect and returns a future that completes with a list of actions.
  Future<List<Action>> run() => _run();

  /// Creates an effect that never produces any actions.
  static Effect<Action> none<Action>() {
    return Effect(() async => [], NoneOperation());
  }

  /// Combines multiple effects into a single effect.
  static Effect<Action> merge<Action>(List<Effect<Action>> effects) {
    return Effect(
      () async {
        final results = await Future.wait(effects.map((e) => e.run()));
        return results.expand((actions) => actions).toList();
      },
      MergeOperation(effects),
    );
  }

  /// Creates an effect that runs after a delay.
  static Effect<Action> delay<Action>(
    Duration duration,
    Effect<Action> effect,
  ) {
    return Effect(() async {
      await Future.delayed(duration);
      return effect.run();
    }, effect.operation);
  }

  /// Creates an effect from a function that can send actions
  static Effect<Action> runEffect<Action>({
    TaskPriority? priority,
    required Future<void> Function(Send<Action> send) operation,
    void Function(Object error, Send<Action> send)? catchHandler,
  }) {
    return Effect(
      () async => [],
      RunOperation(priority, operation, catchHandler),
    );
  }

  static Effect<Action> send<Action>(Action action) {
    return Effect(
      () async => [action],
      PublisherOperation<Action>((send) async => send(action)),
    );
  }

  /// Creates an effect that can send multiple actions over time
  static Effect<Action> publisher<Action>(
    Future<void> Function(void Function(Action) send) operation,
  ) {
    return Effect(
      () {
        final completer = Completer<List<Action>>();
        final actions = <Action>[];
        final task = Task();

        Future<void> run() async {
          try {
            if (task.isCancelled) {
              completer.complete([]);
              return;
            }

            // Create a wrapper for the send function that checks cancellation
            void sendAction(Action action) {
              if (!task.isCancelled && !completer.isCompleted) {
                actions.add(action);
              }
            }

            // Race between the operation and cancellation
            await Future.any([
              operation(sendAction).then((_) {
                if (!task.isCancelled && !completer.isCompleted) {
                  completer.complete(actions);
                }
              }),
              task.cancelled.then((_) {
                if (!completer.isCompleted) {
                  completer.complete(actions);
                }
              })
            ]);
          } catch (e) {
            if (!task.isCancelled && !completer.isCompleted) {
              completer.completeError(e);
            }
          }
        }

        run();

        return CancellableFuture(
          completer.future,
          onCancel: () => task.cancel(),
        );
      },
      PublisherOperation(operation),
    );
  }

  // static Effect<Action> concatenate<Action>(List<Effect<Action>> effects) {
  //   return Effect<Action>._(ConcatenateOperation(effects));
  // }

  Effect<T> map<T>(T Function(Action) transform) {
    return Effect(
      () async => (await _run()).map(transform).toList(),
      operation,
    );
  }

  /// Makes an effect cancellable with the given ID
  Effect<Action> cancellable({required Object id}) {
    print("Making effect cancellable with ID: $id");
    return Effect(
      () {
        final completer = Completer<List<Action>>();
        final actions = <Action>[];
        final task = TaskManager.instance.getTask(id);
        print("Got task for ID: $id, cancelled: ${task.isCancelled}");

        Future<void> run() async {
          try {
            if (task.isCancelled) {
              print("Task already cancelled, completing with empty list");
              completer.complete([]);
              return;
            }

            // Race between the operation and cancellation
            print("Starting race between operation and cancellation");
            await Future.any([
              _run().then((result) {
                print("Operation completed with ${result.length} actions");
                if (!task.isCancelled && !completer.isCompleted) {
                  print("Completing with result");
                  completer.complete(result);
                } else {
                  print(
                      "Task cancelled or completer already completed, not completing with result");
                }
              }),
              task.cancelled.then((_) {
                print("Task cancelled, completing with empty list");
                if (!completer.isCompleted) {
                  completer.complete([]);
                }
              })
            ]);
          } catch (e) {
            print("Error in cancellable: $e");
            if (!task.isCancelled && !completer.isCompleted) {
              completer.completeError(e);
            }
          }
        }

        run();

        return CancellableFuture(
          completer.future,
          onCancel: () {
            print("CancellableFuture onCancel called for ID: $id");
            task.cancel();
          },
        );
      },
      CancellableOperation(operation, id),
    );
  }

  /// Creates an effect that cancels any running effect with the given ID
  static Effect<Action> cancel<Action>(Object id) {
    // Note: The actual cancellation happens in the Store class when it processes this effect
    // This method just creates an effect with a CancelOperation
    return Effect(
      () async {
        // Log for debugging
        print("Effect.cancel called for ID: $id");
        return [];
      },
      CancelOperation(id),
    );
  }
}

class Send<Action> {
  final void Function(Action action) send;

  Send(this.send);

  void call(Action action) {
    if (!isCancelled()) {
      send(action);
    }
  }

  void callWithAnimation(Action action, Animation? animation) {
    call(action);
    // Handle animation if required
  }
}

class TaskPriority {}

bool isCancelled() {
  return false; // Placeholder for cancellation logic
}

// Public Operation class and its subclasses
abstract class Operation {}

class NoneOperation extends Operation {}

class PublisherOperation<Action> extends Operation {
  final Future<void> Function(void Function(Action) send) operation;
  PublisherOperation(this.operation);
}

class RunOperation<Action> extends Operation {
  final TaskPriority? priority;
  final Future<void> Function(Send<Action> send) operation;
  final void Function(Object error, Send<Action> send)? catchHandler;
  RunOperation(this.priority, this.operation, this.catchHandler);
}

class MergeOperation<Action> extends Operation {
  final List<Effect<Action>> effects;
  MergeOperation(this.effects);
}

class ConcatenateOperation<Action> extends Operation {
  final List<Effect<Action>> effects;
  ConcatenateOperation(this.effects);
}

class MapOperation<Action, T> extends Operation {
  final Effect<Action> effect;
  final T Function(Action action) transform;
  MapOperation(this.effect, this.transform);
}

class Animation {}

/// Operation that makes an effect cancellable with an ID
class CancellableOperation<Action> extends Operation {
  final Operation operation;
  final Object id;

  CancellableOperation(this.operation, this.id);
}

/// Operation that cancels effects with a specific ID
class CancelOperation<Action> extends Operation {
  final Object id;

  CancelOperation(this.id);
}

class CancelToken {
  bool _isCancelled = false;
  final _listeners = <void Function()>[];

  bool get isCancelled => _isCancelled;

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void cancel() {
    _isCancelled = true;
    for (final listener in _listeners) {
      listener();
    }
  }
}

class CancellableFuture<T> implements Future<T> {
  final Future<T> _future;
  final void Function() _onCancel;
  bool _isCancelled = false;

  CancellableFuture(this._future, {required void Function() onCancel})
      : _onCancel = onCancel;

  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      _onCancel();
    }
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
          {Function? onError}) =>
      _future.then(onValue, onError: onError);

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  Stream<T> asStream() => _future.asStream();

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);
}

/// A task that can be cancelled.
/// This is used by effects to manage cancellation.
class Task {
  bool _isCancelled = false;
  final _cancelCompleter = Completer<void>();
  Timer? _timer;

  /// Whether the task has been cancelled.
  bool get isCancelled => _isCancelled;

  /// A future that completes when the task is cancelled.
  Future<void> get cancelled => _cancelCompleter.future;

  /// Cancels the task.
  void cancel() {
    if (!_isCancelled) {
      print("Task cancelled");
      _isCancelled = true;
      _timer?.cancel();
      if (!_cancelCompleter.isCompleted) {
        _cancelCompleter.complete();
      }
    }
  }

  /// Creates a delay that can be cancelled.
  /// This is a replacement for Future.delayed that can be cancelled.
  Future<void> delay(Duration duration) {
    if (_isCancelled) {
      print("Task already cancelled, not starting delay");
      return Future.value();
    }

    print("Starting delay of ${duration.inMilliseconds}ms");
    final completer = Completer<void>();
    _timer = Timer(duration, () {
      if (!_isCancelled) {
        print("Delay completed normally");
        completer.complete();
      } else {
        print("Delay completed but task was cancelled");
      }
    });

    return Future.any([
      completer.future,
      cancelled.then((_) {
        print("Delay interrupted by cancellation");
        return null;
      })
    ]);
  }
}

/// A manager for tasks that can be cancelled by ID.
class TaskManager {
  static final _instance = TaskManager._();
  final _tasks = <Object, Task>{};

  TaskManager._();

  /// Gets the singleton instance of the task manager.
  static TaskManager get instance => _instance;

  /// Gets a task for the given ID, creating one if it doesn't exist.
  /// If a task with this ID already exists and is cancelled, it will be replaced.
  Task getTask(Object id) {
    final existingTask = _tasks[id];
    if (existingTask != null && !existingTask.isCancelled) {
      return existingTask;
    }

    final newTask = Task();
    _tasks[id] = newTask;
    return newTask;
  }

  /// Cancels the task with the given ID.
  void cancel(Object id) {
    final task = _tasks[id];
    if (task != null) {
      task.cancel();
      _tasks.remove(id);
    }
  }

  /// Clears all tasks.
  void clear() {
    for (final task in _tasks.values) {
      task.cancel();
    }
    _tasks.clear();
  }
}
