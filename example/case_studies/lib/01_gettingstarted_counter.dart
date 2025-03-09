import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

// MARK: - Feature domain

// State
class CounterState {
  int count;
  CounterState({this.count = 0});

  @override
  String toString() => 'CounterState(count: $count)';
}

// Actions
sealed class CounterAction {
  const CounterAction();
}

final class CounterIncrement extends CounterAction {
  const CounterIncrement();
}

final class CounterDecrement extends CounterAction {
  const CounterDecrement();
}

// Feature
class Counter {
  static final reducer = Reducer<CounterState, CounterAction>((state, action) {
    switch (action) {
      case CounterIncrement():
        state.count++;
        return Effect.none();
      case CounterDecrement():
        state.count--;
        return Effect.none();
    }
  });

  // Action creators
  static const increment = CounterIncrement();
  static const decrement = CounterDecrement();
}

// MARK: - Feature view

class CounterDemoView extends StatelessWidget {
  final Store<CounterState, CounterAction> store;

  const CounterDemoView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter Demo')),
      body: Center(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Count'),
                Text(
                  '${store.state.count}',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => store.send(Counter.decrement),
                      child: const Text('-'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () => store.send(Counter.increment),
                      child: const Text('+'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
