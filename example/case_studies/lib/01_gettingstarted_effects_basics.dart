import 'package:flutter/material.dart';
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

// MARK: - Feature view
class BasicsView extends StatelessWidget {
  final Store<BasicsState, BasicsAction> store;

  const BasicsView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Count: ${store.state.count}'),
                if (store.state.isLoading)
                  const CircularProgressIndicator()
                else if (store.state.fact != null)
                  Text(store.state.fact!),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => store.send(BasicsAction.decrement),
                      child: const Text('-'),
                    ),
                    FilledButton(
                      onPressed: () => store.send(BasicsAction.increment),
                      child: const Text('+'),
                    ),
                  ],
                ),
                FilledButton(
                  onPressed: () => store.send(BasicsAction.factRequest),
                  child: const Text('Get Fact'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
