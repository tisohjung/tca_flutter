import 'package:tca_flutter/tca_flutter.dart';

// MARK: - Feature domain

sealed class BasicsAction {
  const BasicsAction();
  static const increment = Increment();
  static const decrement = Decrement();
  static const factRequest = FactRequest();
}

final class Increment extends BasicsAction {
  const Increment();
}

final class Decrement extends BasicsAction {
  const Decrement();
}

final class FactRequest extends BasicsAction {
  const FactRequest();
}

final class FactResponse extends BasicsAction {
  final String fact;
  const FactResponse(this.fact);
}

class BasicsState {
  int count;
  String? fact;
  bool isLoading;

  BasicsState({
    this.count = 0,
    this.fact,
    this.isLoading = false,
  });

  @override
  String toString() =>
      'BasicsState(count: $count, fact: $fact, isLoading: $isLoading)';
}

// MARK: - Feature business logic

class BasicsReducer extends Reducer<BasicsState, BasicsAction> {
  BasicsReducer()
      : super((state, action) {
          switch (action) {
            case Increment():
              state.count++;
              return Effect.none();
            case Decrement():
              state.count--;
              return Effect.none();
            case FactRequest():
              state.isLoading = true;
              state.fact = null;
              return Effect.publisher((send) async {
                await Future.delayed(const Duration(seconds: 1));
                send(FactResponse('Fact about ${state.count}'));
              });
            case FactResponse(fact: final fact):
              state.fact = fact;
              state.isLoading = false;
              return Effect.none();
          }
        });
}
