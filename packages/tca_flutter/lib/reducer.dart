import 'package:tca_flutter/effect.dart';

/// Represents the result of a reducer operation, containing the new state and any effects.
class ReducerResult<State, Action> {
  final State state;
  final List<Effect<Action>> effects;

  const ReducerResult({
    required this.state,
    this.effects = const [],
  });
}

/// A reducer describes how to evolve the current state into the next state given an action.
class Reducer<State, Action> {
  final List<Effect<Action>> Function(State, Action) _reduce;

  const Reducer(this._reduce);

  /// Runs the reducer with the given state and action.
  ReducerResult<State, Action> reduce(State state, Action action) {
    final effects = _reduce(state, action);
    return ReducerResult(
      state: state,
      effects: effects,
    );
  }

  /// Combines multiple reducers into a single reducer.
  factory Reducer.combine(List<Reducer<State, Action>> reducers) {
    return Reducer((state, action) {
      final effects = <Effect<Action>>[];
      for (final reducer in reducers) {
        effects.addAll(reducer._reduce(state, action));
      }
      return effects;
    });
  }

  /// Creates a new reducer that transforms the state type.
  Reducer<LocalState, LocalAction> transform<LocalState, LocalAction>({
    required LocalState Function(State) get,
    required State Function(State, LocalState) set,
    required Action Function(LocalAction) toGlobalAction,
  }) {
    return Reducer((localState, localAction) {
      final globalState = set(localState as State, localState);
      final effects = _reduce(globalState, toGlobalAction(localAction));
      localState = get(globalState);
      return effects
          .map((e) => e.map<LocalAction>((a) => a as LocalAction))
          .toList();
    });
  }
}
