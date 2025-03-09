import 'dart:developer';

import 'package:tca_flutter/effect.dart';

/// Represents the result of a reducer operation, containing the new state and any effects.
class ReducerResult<State, Action> {
  final State state;
  final Effect<Action> effect;

  const ReducerResult({
    required this.state,
    required this.effect,
  });
}

/// A reducer describes how to evolve the current state into the next state given an action.
class Reducer<State, Action> {
  final Effect<Action> Function(State, Action) _reduce;

  const Reducer(this._reduce);

  /// Creates a new reducer that prints debug information before and after the reduction.
  Reducer<State, Action> debug({
    String prefix = '',
    bool printState = true,
    bool printAction = true,
  }) {
    return Reducer((state, action) {
      if (printAction) {
        log('${prefix}Action: $action');
      }
      if (printState) {
        log('${prefix}State before: $state');
      }

      final effect = _reduce(state, action);

      if (printState) {
        log('${prefix}State after: $state');
      }
      log('$prefix---');

      return effect;
    });
  }

  /// Runs the reducer with the given state and action.
  ReducerResult<State, Action> reduce(State state, Action action) {
    final effect = _reduce(state, action);
    return ReducerResult(
      state: state, // State is modified in place place by _reduce
      effect: effect,
    );
  }

  /// Combines multiple reducers into a single reducer.
  factory Reducer.combine(List<Reducer<State, Action>> reducers) {
    return Reducer((state, action) {
      final effects = <Effect<Action>>[];
      for (final reducer in reducers) {
        effects.add(reducer._reduce(state, action));
      }
      return Effect.merge(effects);
    });
  }

  /// Creates a new reducer that transforms the state type.
  Reducer<LocalState, LocalAction> transform<LocalState, LocalAction>({
    required LocalState Function(State) get,
    required State Function(LocalState) set,
    required Action Function(LocalAction) toGlobalAction,
  }) {
    return Reducer((localState, localAction) {
      final globalState = set(localState);
      final effect = _reduce(globalState, toGlobalAction(localAction));
      return effect.map<LocalAction>((a) => a as LocalAction);
    });
  }

  /// Creates a pullback reducer that operates on parent state/action using a child reducer.
  static Reducer<ParentState, ParentAction>
      pullback<ParentState, ParentAction, ChildState, ChildAction>({
    required Reducer<ChildState, ChildAction> child,
    required ChildState Function(ParentState) toChildState,
    required void Function(ParentState, ChildState) fromChildState,
    required ChildAction? Function(ParentAction) toChildAction,
  }) {
    return Reducer((parentState, parentAction) {
      final childAction = toChildAction(parentAction);
      if (childAction == null) {
        return Effect.none();
      }

      final childStateBeforeUpdate = toChildState(parentState);
      final effect = child._reduce(childStateBeforeUpdate, childAction);
      fromChildState(parentState, childStateBeforeUpdate);

      return effect.map((action) => action as ParentAction);
    });
  }

  /// Scopes the reducer to operate on child state and actions
  ///
  /// This is useful for creating focused reducers that operate on a subset of the state:
  ///
  /// ```dart
  /// final childReducer = parentReducer.scope(
  ///   toChildState: (state) => state.child,
  ///   fromChildState: (state, childState) => state.child = childState,
  ///   toChildAction: (action) => action is ChildAction ? action : null,
  ///   createParentState: () => ParentState(),
  /// );
  /// ```
  Reducer<ChildState, ChildAction> scope<ChildState, ChildAction>({
    required ChildState Function(State) toChildState,
    required void Function(State, ChildState) fromChildState,
    required ChildAction? Function(Action) toChildAction,
    required State Function() createParentState,
  }) {
    return transform<ChildState, ChildAction>(
      get: toChildState,
      set: (childState) {
        final parentState = createParentState();
        fromChildState(parentState, childState);
        return parentState;
      },
      toGlobalAction: (childAction) {
        final action = toChildAction(childAction as Action);
        if (action == null) {
          throw StateError(
              'Child action could not be converted to parent action');
        }
        return action as Action;
      },
    );
  }
}
