import 'package:flutter_counter/favorites_action.dart';
import 'package:tca_flutter/tca_flutter.dart';

// ignore: must_be_immutable
class FavoritesState extends TCAState {
  Set<int> numbers;

  FavoritesState({this.numbers = const {}});

  @override
  List<Object?> get props => [numbers];

  @override
  FavoritesState copyWith({Set<int>? numbers}) {
    return FavoritesState(numbers: numbers ?? this.numbers);
  }
}

class FavoritesReducer extends Reducer<FavoritesState, FavoritesAction> {
  FavoritesReducer()
      : super(
          (state, action) {
            switch (action) {
              case FavoritesAddAction(number: final number):
                state = state.copyWith(
                  numbers: {...state.numbers, number},
                );
                return [];
              case FavoritesRemoveAction(number: final number):
                state = state.copyWith(
                  numbers: {...state.numbers}..remove(number),
                );
                return [];
            }
          },
        );
}
