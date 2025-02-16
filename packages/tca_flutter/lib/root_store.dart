import 'dart:async';
import 'dart:developer';

import 'package:tca_flutter/tca_flutter.dart';

class RootStore<State, Action> {
  List<dynamic> bufferedActions = [];
  final StreamController<void> _didSet = StreamController<void>.broadcast();
  Stream<void> get didSet => _didSet.stream;
  final Map<String, CancellableOperation> effectCancellables = {};
  bool isSending = false;
  final Reducer<State, Action> reducer;
  late State _state;
  State get state => _state;
  set state(State newState) {
    _state = newState;
    _didSet.add(null);
  }

  RootStore({required State initialState, required this.reducer}) {
    state = initialState;
  }

  Future<void>? send(Action action, {Action? originatingAction}) {
    Future<void>? open() {
      bufferedActions.add(action);
      if (isSending) {
        return null;
      }

      isSending = true;
      var currentState = state;
      var tasks = <Future<void>>[];

      // Clean up the buffered actions
      void cleanup() {
        bufferedActions.clear();
        state = currentState;
        isSending = false;
        if (bufferedActions.isNotEmpty) {
          var task = send(bufferedActions.removeLast() as Action,
              originatingAction: originatingAction);
          if (task != null) {
            tasks.add(task);
          }
        }
      }

      // Process each action
      for (var action in bufferedActions) {
        var result = reducer.reduce(currentState, action as Action);
        currentState = result.state;

        switch (result.effect.operation.runtimeType) {
          case NoneOperation _:
            break;
          case PublisherOperation _:
            var uuid = DateTime.now().toString();
            var didComplete = false;
            var effectCancellable = result.effect.run().then((actions) {
              if (!didComplete) {
                didComplete = true;
                for (final effectAction in actions) {
                  var task = send(effectAction, originatingAction: action);
                  if (task != null) {
                    tasks.add(task);
                  }
                }
              }
            });
            effectCancellables[uuid] = CancellableOperation(effectCancellable);
            break;
          case RunOperation _:
            var task = Future<void>(() async {
              try {
                await result.effect.run();
              } catch (error) {
                // Handle error if needed
              }
            });
            tasks.add(task);
            break;
        }
      }

      cleanup();
      return tasks.isEmpty ? null : Future.wait(tasks);
    }

    return open();
  }

  void reportIssue(String s) {
    log(s);
  }

  debugCaseOutput(effectAction) {
    effectAction.toString();
  }
}

class CancellableOperation {
  final Future<void> _future;
  CancellableOperation(this._future);

  void cancel() {
    // Implement cancellation logic
  }
}
