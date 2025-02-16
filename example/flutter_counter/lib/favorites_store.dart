import 'package:flutter_counter/favorites_action.dart';
import 'package:tca_flutter/tca_flutter.dart';

// ignore: must_be_immutable
class FavoritesState {
  Set<int> numbers;

  FavoritesState({this.numbers = const {}});

  @override
  String toString() => 'FavoritesState(numbers: $numbers)';
}

class FavoritesReducer extends Reducer<FavoritesState, FavoritesAction> {
  FavoritesReducer()
      : super(
          (state, action) {
            switch (action) {
              case FavoritesAddAction(number: final number):
                state.numbers = {...state.numbers, number};
                return Effect.none();
              case FavoritesRemoveAction(number: final number):
                state.numbers = {...state.numbers}..remove(number);
                return Effect.none();
            }
          },
        );
}
