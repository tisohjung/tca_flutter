// Actions
import 'package:flutter_counter/counter_action.dart';
import 'package:flutter_counter/favorites_action.dart';
import 'package:flutter_counter/favorites_store.dart';
import 'package:tca_flutter/tca_flutter.dart';

class CounterReducer extends Reducer<CounterState, CounterAction> {
  CounterReducer()
      : super((state, action) {
          switch (action) {
            case CounterIncrementAction():
              state.count++;
              return [];
            case CounterDecrementAction():
              state = state.copyWith(count: state.count - 1);
              return [];
            case CounterResetAction():
              state = state.copyWith(count: 0);
              return [];
            case CounterFavoritesAction(action: final favoritesAction):
              switch (favoritesAction) {
                case FavoritesAddAction():
                  state = state.copyWith(
                    favorites: state.favorites.copyWith(
                      numbers: {
                        ...state.favorites.numbers,
                        favoritesAction.number
                      },
                    ),
                  );
                  return [];
                case FavoritesRemoveAction():
                  state = state.copyWith(
                    favorites: state.favorites.copyWith(
                      numbers: {...state.favorites.numbers}
                        ..remove(favoritesAction.number),
                    ),
                  );
                  return [];
              }
          }
        });
}

// State
// ignore: must_be_immutable
class CounterState extends TCAState {
  int count;
  FavoritesState favorites;

  CounterState({
    this.count = 0,
    FavoritesState? favorites,
  }) : favorites = favorites ?? FavoritesState();

  @override
  List<Object?> get props => [count, favorites];

  @override
  CounterState copyWith({
    int? count,
    FavoritesState? favorites,
  }) {
    return CounterState(
      count: count ?? this.count,
      favorites: favorites ?? this.favorites,
    );
  }
}
