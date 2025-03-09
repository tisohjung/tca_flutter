import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

import '01_gettingstarted_counter_basics.dart';

// MARK: - Feature domain

// State
class TwoCountersState {
  CounterState counter1;
  CounterState counter2;

  TwoCountersState({
    CounterState? counter1,
    CounterState? counter2,
  })  : counter1 = counter1 ?? CounterState(),
        counter2 = counter2 ?? CounterState();

  @override
  String toString() =>
      'TwoCountersState(counter1: $counter1, counter2: $counter2)';
}

// Actions
sealed class TwoCountersAction {
  const TwoCountersAction();
}

final class Counter1Action extends TwoCountersAction {
  final CounterAction action;
  const Counter1Action(this.action);
}

final class Counter2Action extends TwoCountersAction {
  final CounterAction action;
  const Counter2Action(this.action);
}

// Feature
class TwoCounters {
  static final reducer =
      Reducer<TwoCountersState, TwoCountersAction>((state, action) {
    return switch (action) {
      Counter1Action(action: final counterAction) => Reducer.pullback<
            TwoCountersState, TwoCountersAction, CounterState, CounterAction>(
          child: Counter.reducer,
          toChildState: (state) => state.counter1,
          fromChildState: (state, childState) => state.counter1 = childState,
          toChildAction: (action) => switch (action) {
            Counter1Action(action: final action) => action,
            _ => null,
          },
        ).reduce(state, action).effect,
      Counter2Action(action: final counterAction) => Reducer.pullback<
            TwoCountersState, TwoCountersAction, CounterState, CounterAction>(
          child: Counter.reducer,
          toChildState: (state) => state.counter2,
          fromChildState: (state, childState) => state.counter2 = childState,
          toChildAction: (action) => switch (action) {
            Counter2Action(action: final action) => action,
            _ => null,
          },
        ).reduce(state, action).effect,
    };
  });

  // Action creators
  static TwoCountersAction counter1(CounterAction action) =>
      Counter1Action(action);
  static TwoCountersAction counter2(CounterAction action) =>
      Counter2Action(action);
}

// MARK: - Feature view

class TwoCountersView extends StatelessWidget {
  final Store<TwoCountersState, TwoCountersAction> store;

  const TwoCountersView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Two Counters Demo')),
      body: Center(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CounterView(
                  count: store.state.counter1.count,
                  onIncrement: () => store.send(
                    TwoCounters.counter1(Counter.increment),
                  ),
                  onDecrement: () => store.send(
                    TwoCounters.counter1(Counter.decrement),
                  ),
                ),
                const SizedBox(width: 32),
                _CounterView(
                  count: store.state.counter2.count,
                  onIncrement: () => store.send(
                    TwoCounters.counter2(Counter.increment),
                  ),
                  onDecrement: () => store.send(
                    TwoCounters.counter2(Counter.decrement),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CounterView extends StatelessWidget {
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CounterView({
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Count'),
        Text(
          '$count',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: onDecrement,
              child: const Text('-'),
            ),
            const SizedBox(width: 16),
            FilledButton(
              onPressed: onIncrement,
              child: const Text('+'),
            ),
          ],
        ),
      ],
    );
  }
}
