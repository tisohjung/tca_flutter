import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tca_flutter/effect.dart';
import 'package:tca_flutter/reducer.dart';
import 'package:tca_flutter/root_store.dart';
import 'package:tca_flutter/with-perception-tracking/with_perception_tracking.dart';

/// A store represents the runtime that powers the application. It is the object that you will pass
/// around to widgets that need to interact with the application.
///
/// You will typically construct a single one of these at the root of your application:
///
/// ```dart
/// void main() {
///   runApp(
///     MyApp(
///       store: Store(
///         initialState: AppFeature.State(),
///         reducer: AppFeature(),
///       ),
///     ),
///   );
/// }
/// ```
class Store<State, Action> extends ChangeNotifier {
  final bool _canCacheChildren = true;
  final Map<ScopeId, dynamic> _children = {};
  Reducer<State, Action> _reducer;
  State _state;
  final List<Effect<Action>> _effects = [];

  /// Current state of the store
  State get state => _state;

  /// Creates a new store with the given initial state and reducer
  Store({
    required State initialState,
    required Reducer<State, Action> reducer,
  }) : this._(
          rootStore: RootStore<State, Action>(
            initialState: initialState,
            reducer: reducer,
          ),
          toState: _ToState.keyPath((state) => state as State),
          fromAction: (action) => action,
        );

  Store._({
    required RootStore<State, Action> rootStore,
    required _ToState<State> toState,
    required Function(Action) fromAction,
  })  : _reducer = rootStore.reducer,
        _state = rootStore.state;

  /// Sends an action to the store
  ///
  /// This method returns a [Future] that completes when all effects from the action are finished.
  /// You can use this to coordinate async work:
  ///
  /// ```dart
  /// await store.send(LoadDataAction());
  /// ```
  void send(Action action) {
    final result = withPerceptionTracking(() {
      return _reducer.reduce(_state, action);
    });

    // Since we're modifying state in place, we should always notify
    notifyListeners();

    _effects.add(result.effect);
    result.effect.run().then((actions) {
      for (final action in actions) {
        send(action);
      }
    });
  }

  /// Scopes the store to expose child state and actions
  ///
  /// This is useful for creating focused stores for child widgets:
  ///
  /// ```dart
  /// LoginView(
  ///   store: store.scope(
  ///     state: (state) => state.login,
  ///     action: (action) => AppAction.login(action),
  ///   ),
  /// )
  /// ```
  Store<ChildState, ChildAction> scope<ChildState, ChildAction>({
    required ChildState Function(State state) state,
    required Action Function(ChildAction action) action,
  }) {
    final id = ScopeId(state: state, action: action);
    if (_canCacheChildren && _children.containsKey(id)) {
      return _children[id] as Store<ChildState, ChildAction>;
    }

    final childStore = Store<ChildState, ChildAction>(
      initialState: state(_state),
      reducer: _reducer.transform(
        get: state,
        set: (globalState, localState) => globalState,
        toGlobalAction: action,
      ),
    );

    if (_canCacheChildren) {
      _children[id] = childStore;
    }
    return childStore;
  }

  /// Dispose of the store and clean up resources
  @override
  void dispose() {
    for (final child in _children.values) {
      (child as Store).dispose();
    }
    _children.clear();
    super.dispose();
  }
}

/// Internal class to handle state transformations
class _ToState<State> {
  final Function(dynamic) _transform;

  _ToState.keyPath(this._transform);

  _ToState<ChildState> append<ChildState>(
    ChildState Function(State state) transform,
  ) {
    return _ToState.keyPath((dynamic state) => transform(_transform(state)));
  }

  State call(dynamic state) => _transform(state);
}

/// Internal class to identify scoped stores
class ScopeId {
  final Function state;
  final Function action;

  ScopeId({
    required this.state,
    required this.action,
  });

  @override
  bool operator ==(Object other) {
    return other is ScopeId && other.state == state && other.action == action;
  }

  @override
  int get hashCode => Object.hash(state, action);
}
