// Actions

import 'package:flutter_counter/favorites_action.dart';

sealed class CounterAction {
  const CounterAction();
}

final class CounterIncrementAction extends CounterAction {
  const CounterIncrementAction();
}

final class CounterDecrementAction extends CounterAction {
  const CounterDecrementAction();
}

final class CounterResetAction extends CounterAction {
  const CounterResetAction();
}

final class CounterFavoritesAction extends CounterAction {
  final FavoritesAction action;
  const CounterFavoritesAction(this.action);
}
