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
      () async {
        final actions = <Action>[];
        await operation((action) => actions.add(action));
        return actions;
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
