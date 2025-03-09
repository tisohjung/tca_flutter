import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

// MARK: - Feature domain

// State
class SharedStateState {
  int count;
  bool isPrime;

  SharedStateState({
    this.count = 0,
    this.isPrime = false,
  });

  @override
  String toString() => 'SharedStateState(count: $count, isPrime: $isPrime)';
}

// Actions
sealed class SharedStateAction {
  const SharedStateAction();
}

final class SharedStateIncrement extends SharedStateAction {
  const SharedStateIncrement();
}

final class SharedStateDecrement extends SharedStateAction {
  const SharedStateDecrement();
}

final class SharedStateCheckPrime extends SharedStateAction {
  const SharedStateCheckPrime();
}

// Feature
class SharedState {
  static bool _isPrime(int n) {
    if (n <= 1) return false;
    for (int i = 2; i <= n ~/ 2; i++) {
      if (n % i == 0) return false;
    }
    return true;
  }

  static final reducer =
      Reducer<SharedStateState, SharedStateAction>((state, action) {
    switch (action) {
      case SharedStateIncrement():
        state.count++;
        state.isPrime = _isPrime(state.count);
        return Effect.none();
      case SharedStateDecrement():
        state.count--;
        state.isPrime = _isPrime(state.count);
        return Effect.none();
      case SharedStateCheckPrime():
        state.isPrime = _isPrime(state.count);
        return Effect.none();
    }
  });

  // Action creators
  static const increment = SharedStateIncrement();
  static const decrement = SharedStateDecrement();
  static const checkPrime = SharedStateCheckPrime();
}

// MARK: - Feature view

class SharedStateView extends StatelessWidget {
  final Store<SharedStateState, SharedStateAction> store;

  const SharedStateView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shared State Demo')),
      body: Center(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Current number is ${store.state.isPrime ? "" : "not "}prime',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${store.state.count}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: store.state.isPrime ? Colors.green : Colors.red,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => store.send(SharedState.decrement),
                      child: const Text('-'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () => store.send(SharedState.increment),
                      child: const Text('+'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => store.send(SharedState.checkPrime),
                  child: const Text('Check Prime'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
