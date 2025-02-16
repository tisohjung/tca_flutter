// Actions
import 'package:flutter_counter/counter_action.dart';
import 'package:flutter_counter/favorites_action.dart';
import 'package:flutter_counter/favorites_store.dart';
import 'package:tca_flutter/tca_flutter.dart';

class CounterReducer extends Reducer<CounterState, CounterAction> {
  CounterReducer()
      : super((state, action) {
          Effect.merge([
            _counterReducer(state, action),
          ]);
        });

  static Effect<CounterAction> _counterReducer(
      CounterState state, CounterAction action) {
    switch (action) {
      case CounterIncrementAction():
        state.count++;
        return Effect.none();
      case CounterDecrementAction():
        state.count--;
        return Effect.none();
      case CounterResetAction():
        state.count = 0;
        return Effect.none();
      case CounterFavoritesAction():
        // Handle by the pulled-back favorites reducer
        return Effect.none();
    }
  }
}

// State
class CounterState {
  int count;
  FavoritesState favorites;

  CounterState({
    this.count = 0,
    FavoritesState? favorites,
  }) : favorites = favorites ?? FavoritesState();

  @override
  String toString() => 'CounterState(count: $count, favorites: $favorites)';
}
